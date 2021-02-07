import asyncio
import logging
import os

from pond_pump import client, ws_client
from pond_pump.infrastructure import config

_LOG = logging.getLogger('pond_pump')


async def main():
    """ Main that tires all logic together. """
    logging.basicConfig(level=logging.INFO)

    # Preparing config
    profile = os.getenv('IOT_SERVER_PROFILE', 'dev')
    _LOG.info('PROFILE: %s', profile)
    config.init(profile)

    # Observer the pump and reports its activity
    event_queue = asyncio.Queue(maxsize=100)
    asyncio.get_event_loop().create_task(observe_power(event_queue), name='observe power')
    await report(event_queue)


async def report(event_queue: asyncio.Queue):
    """ Report power status """
    while True:
        # noinspection PyBroadException
        try:
            # Throttle down
            await asyncio.sleep(20)

            exists = await client.check_existence()

            if exists:
                await ws_client.report_status_changes(event_queue)
            else:
                await client.create_device()

        except Exception as ex:
            _LOG.exception('Error while report', exc_info=ex)
            await client.send_exception(ex)


async def observe_power(event_queue: asyncio.Queue):
    """ Checks the power level """
    power_detector = config.build_power_detector()
    ready_delay: int = config.get_config('read_delay')
    while True:
        try:
            # Throttle down
            await asyncio.sleep(ready_delay)

            is_active = 0.5 < power_detector.value
            activity = '1' if is_active else '0'
            await event_queue.put(activity)
            _LOG.info('Put %s on queue', activity)
            await asyncio.sleep(5)
        except Exception as ex:
            _LOG.exception('Error while observe', exc_info=ex)
            await client.send_exception(ex)


asyncio.get_event_loop().run_until_complete(main())
