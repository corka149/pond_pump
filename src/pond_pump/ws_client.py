""" WS client for IOT server """
import logging
from asyncio.queues import Queue
from collections import defaultdict
from datetime import datetime
from typing import Callable, Dict, Coroutine

import aiohttp
from aiohttp import ClientSession, WSMessage, ClientWebSocketResponse

from pond_pump.infrastructure import config
from pond_pump.model.message import MessageType, MessageDTO

_LOG = logging.getLogger(__name__)


async def report_status_changes(event_queue: Queue):
    """ Waits for incoming WS message and applies event handler on them. """
    url = config.build_device_url() + '/exchange'
    handler = __build_handler()

    async with ClientSession() as session:
        async with session.ws_connect(url, headers=config.basic_auth()) as websocket:
            msg: dict = await websocket.receive_json()
            if 'access_id' in msg:
                access_id = msg.get('access_id')
                _LOG.info(f'Got id={access_id}')

            while True:
                type_ = 'ACTIVITY'
                content = await event_queue.get()  # Determines the speed of looping
                target = MessageType.BROADCAST.value
                message = MessageDTO(origin_access_id=access_id, type=type_, content=content, target=target)

                await websocket.send_str(message.json())
                msg: WSMessage = await websocket.receive()

                handler_func = handler[msg.type]
                await handler_func(websocket, msg)


# noinspection PyTypeChecker
def __build_handler() -> Dict[int, Callable[[ClientWebSocketResponse, WSMessage], Coroutine[None, None, None]]]:
    handler = defaultdict(__handle_message_default)
    handler[aiohttp.WSMsgType.TEXT] = __handle_text_message
    handler[aiohttp.WSMsgType.ERROR] = __handle_end_message
    handler[aiohttp.WSMsgType.CLOSE] = __handle_end_message
    handler[aiohttp.WSMsgType.CLOSED] = __handle_end_message
    handler[aiohttp.WSMsgType.CLOSING] = __handle_end_message

    return handler


async def __handle_text_message(_websocket: ClientWebSocketResponse, msg: WSMessage) -> None:
    if 'ACK' == msg.data:
        _LOG.info(f'{datetime.now()}: Server acknowledged')
    else:
        _LOG.info(msg.data)


async def __handle_end_message(websocket: ClientWebSocketResponse, msg: WSMessage) -> None:
    _LOG.info('Closing websocket because of message type "%s"', msg.type)
    await websocket.close()


async def __handle_message_default(_websocket: ClientWebSocketResponse, msg: WSMessage) -> None:
    _LOG.info(str(msg))
