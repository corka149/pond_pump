""" Messages are exchanged between connected devices. """
from enum import Enum

from pydantic import BaseModel


class MessageType(Enum):
    """ Type of an incoming message """
    BROADCAST = 'BROADCAST'
    SERVER = 'SERVER'


class MessageDTO(BaseModel):
    """ To be exchanged between devices """
    origin_access_id: str
    type: str
    target: str
    content: str
