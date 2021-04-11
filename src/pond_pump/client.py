""" Websocket and HTTP/S client for iot_server """
import logging
import socket
import traceback

from aiohttp import ClientSession

from pond_pump.infrastructure import config
from pond_pump.model.device import DeviceSubmittal
from pond_pump.model.exception import ExceptionSubmittal

_LOG = logging.getLogger(__name__)


class ExceptionReporter:
    """ Async contextmanager that reports exceptions to the IoT server """

    async def __aenter__(self):
        pass

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if exc_type and exc_val and exc_tb:
            stack = traceback.format_stack()

            exception_dto = ExceptionSubmittal(
                hostname=socket.gethostname(),
                clazz=str(exc_type),
                message=str(exc_val),
                stacktrace=''.join(stack)
            )
            await send_exception(exception_dto)
            # Exception was handled
            return True


async def send_exception(exception_dto: ExceptionSubmittal) -> None:
    """ Send a exception report to the iot server. """
    url = config.get_config('iot_server.address') + '/exception'

    async with ClientSession() as session:
        async with session.post(url, data=exception_dto.json(),
                                headers=config.basic_auth()) as response:
            msg = await response.text()
            _LOG.info('Response on error report: status=%s, message="%s"', response.status, msg)


async def create_device():
    """ Creates the represented device """
    name = config.get_config('device.name')
    place = config.get_config('device.place')
    description = config.get_config('device.description')

    url = config.get_config('iot_server.address') + '/device'
    submittal = DeviceSubmittal(name=name, place=place, description=description)
    async with ClientSession() as session:
        async with session.post(url, data=submittal.json(),
                                headers=config.basic_auth()) as response:
            response.raise_for_status()
            _LOG.info('Created: %s', submittal.json())


async def check_existence() -> bool:
    """ Checks if a device exists. """
    async with ClientSession() as session:
        async with session.get(config.build_device_url(), headers=config.basic_auth()) as response:
            _LOG.info('Response of checking existence: status=%s', response.status)
            return response.status == 200
