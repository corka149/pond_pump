""" Websocket and HTTP/S client for iot_server """
import base64
import logging
import socket
from asyncio import Queue
from datetime import datetime
from typing import Dict

import aiohttp
from aiohttp import ClientSession, WSMessage

from pond_pump.infrastructure import config
from pond_pump.model.device import DeviceSubmittal
from pond_pump.model.exception import ExceptionSubmittal
from pond_pump.model.message import MessageDTO, MessageType

_LOG = logging.getLogger(__name__)


async def report_status_changes(event_queue: Queue):
    """ Waits for incoming WS message and applies event handler on them. """
    url = __build_device_url() + '/exchange'

    async with ClientSession() as session:
        async with session.ws_connect(url, headers=__basic_auth()) as websocket:
            msg: dict = await websocket.receive_json()
            if 'access_id' in msg:
                access_id = msg.get('access_id')
                _LOG.info(f'Got id={access_id}')

            while True:
                type_ = 'ACTIVITY'
                content = await event_queue.get()  # Determines the speed of sending
                target = MessageType.BROADCAST.value
                message = MessageDTO(origin_access_id=access_id, type=type_, content=content, target=target)

                await websocket.send_str(message.json())
                msg: WSMessage = await websocket.receive()

                if msg.type == aiohttp.WSMsgType.TEXT:
                    if 'ACK' == msg.data:
                        _LOG.info(f'{datetime.now()}: Server acknowledged')
                    else:
                        await websocket.close()
                else:
                    _LOG.error('Unexpected response: type=%s, data=%s', msg.type, msg.data)


async def send_exception(exception: Exception) -> None:
    """ Send a exception report to the iot server. """
    url = config.get_config('iot_server.address') + '/exception'

    async with ClientSession() as session:
        exception_dto = ExceptionSubmittal(
            hostname=socket.gethostname(),
            clazz=exception.__class__.__name__,
            message='Exception on listener side',
            stacktrace=str(exception)
        )

        async with session.post(url, data=exception_dto.json(), headers=__basic_auth()) as response:
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
        async with session.post(url, data=submittal.json(), headers=__basic_auth()) as response:
            response.raise_for_status()
            _LOG.info('Created: %s', submittal.json())


async def check_existence() -> bool:
    """ Checks if a device exists. """
    async with ClientSession() as session:
        async with session.get(__build_device_url(), headers=__basic_auth()) as response:
            _LOG.info('Response of checking existence: status=%s', response.status)
            return response.status == 200


def __build_device_url() -> str:
    url = config.get_config('iot_server.address')
    device_name = config.get_config('device.name')
    return url + f'/device/{device_name}'


def __basic_auth() -> Dict[str, str]:
    username = config.get_config('security.basic.username')
    passwd = config.get_config('security.basic.password')
    b64 = base64.b64encode(bytes(f'{username}:{passwd}', 'ascii'))
    return {'Authorization': f'Basic {b64.decode("ascii")}'}
