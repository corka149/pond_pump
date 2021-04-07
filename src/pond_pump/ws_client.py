""" WS client for IOT server """
import logging
from asyncio.queues import Queue
from datetime import datetime
from typing import Callable, Dict, Coroutine

import aiohttp
from aiohttp import ClientSession, WSMessage, ClientWebSocketResponse

from pond_pump.exception import EndedTooEarlyException
from pond_pump.infrastructure import config
from pond_pump.model.message import MessageType, MessageDTO
from pond_pump.observer import ObserverRegistry

_LOG = logging.getLogger(__name__)
_REG = ObserverRegistry()

WebsocketHandler = Dict[int, Callable[[
                                          ClientWebSocketResponse, WSMessage], Coroutine[None, None, None]]]


async def report_status_changes(event_queue: Queue):
    """ Waits for incoming WS message and applies event handler on them. """
    url = config.build_device_url() + '/exchange'

    async with ClientSession() as session:
        async with session.ws_connect(url, headers=config.basic_auth()) as websocket:
            json_msg: dict = await websocket.receive_json()
            access_id = json_msg.get('access_id')
            _LOG.info('Got access_id=%s', access_id)

            while access_id:
                message = await new_message(access_id, event_queue)

                await websocket.send_str(message.json())
                msg: WSMessage = await websocket.receive()

                await _REG.notify(msg.type, websocket, msg)

    raise EndedTooEarlyException()


async def new_message(access_id: str, event_queue: Queue):
    """ Creates a new message based on the output of the queue. """
    type_ = 'ACTIVITY'
    content = await event_queue.get()  # Determines the speed of looping
    target = MessageType.BROADCAST.value
    message = MessageDTO(origin_access_id=access_id, type=type_, content=content, target=target)
    return message


# ===== ===== ===== ======= ===== ===== =====
# ===== ===== ===== HANDLER ===== ===== =====
# ===== ===== ===== ======= ===== ===== =====


@_REG.register(aiohttp.WSMsgType.TEXT)
async def __handle_text_message(_websocket: ClientWebSocketResponse, msg: WSMessage) -> None:
    if msg.data == 'ACK':
        _LOG.info('%s: Server acknowledged', datetime.now())
    else:
        _LOG.info(msg.data)


@_REG.register(aiohttp.WSMsgType.ERROR)
async def __handle_end_message(websocket: ClientWebSocketResponse, msg: WSMessage) -> None:
    _LOG.info('Closing websocket because of message type "%s"', msg.type)
    await websocket.close()
