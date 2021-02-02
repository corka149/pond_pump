""" Pump light specific exceptions. """


class EndedTooEarlyException(BaseException):
    """ Will be thrown when somehow the listener finishes what never should happen. """
