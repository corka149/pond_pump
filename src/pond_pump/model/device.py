""" Collection of device models """
from datetime import datetime

from pydantic import BaseModel


class DeviceSubmittal(BaseModel):
    """
    Used for submissions: A device is a thing that can be everything like a fridge or Raspberry Pi.
    """
    name: str
    place: str
    description: str


class DeviceDTO(DeviceSubmittal):
    """ A device is a thing that can be everything like a fridge or Raspberry Pi """
    name: str
    place: str
    description: str
    created_at: datetime
    update_at: datetime
