""" Exceptions that occur on device side. """

from pydantic.main import BaseModel


class ExceptionSubmittal(BaseModel):
    """ New not persisted exception. It has a hostname, clazz, message, stacktrace. """
    hostname: str
    clazz: str
    message: str
    stacktrace: str
