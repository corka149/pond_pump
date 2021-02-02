import asyncio
import logging
import os

from pond_pump import client
from pond_pump.infrastructure import config


async def main():
    """ Main that tires all logic together. """
    logger = logging.getLogger('pond_pump')

    # Preparing config
    profile = os.getenv('IOT_SERVER_PROFILE', 'dev')
    logger.info('PROFILE: %s', profile)
    config.init(profile)

    # Observer the pump and reports its activity
    event_queue = asyncio.Queue(maxsize=100, loop=asyncio.get_event_loop())
    asyncio.get_event_loop().create_task(observe_power(event_queue), name='observe power')
    await report(event_queue)


async def report(event_queue: asyncio.Queue):
    """ Report power status """
    while True:
        # noinspection PyBroadException
        try:
            # Throttle down
            await asyncio.sleep(20)

            exists = client.check_existence()

            if exists:
                await client.send_status(event_queue)
            else:
                await client.create_device()

        except Exception as ex:
            await client.send_exception(ex)


async def observe_power(event_queue: asyncio.Queue):
    """ Checks the power level """
    while True:
        try:
            # Throttle down
            await asyncio.sleep(20)

            await event_queue.put("1")  # TODO read the actual value
            await asyncio.sleep(5)
        except Exception as ex:
            await client.send_exception(ex)


asyncio.get_event_loop().run_until_complete(main())
