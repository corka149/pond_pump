""" Observing via decorators """
import logging
from collections import defaultdict
from typing import Dict, Any, Callable, List, Coroutine

AsyncCallable = Callable[..., Coroutine[Any, Any, Any]]


class ObserverRegistry:
    """ A general purpose observer registry """

    _observer_funcs: Dict[Any, List[AsyncCallable]]
    _log = logging.getLogger(__name__)

    def __init__(self):
        self._observer_funcs = defaultdict(list)

    def observe(self, event: Any) -> Callable[[AsyncCallable], AsyncCallable]:
        """ Registers a function as an observer for an event. """

        def actual_decorator(func: AsyncCallable):
            self._observer_funcs[event].append(func)
            # no need to replace the original function
            return func

        return actual_decorator

    async def notify(self, event: Any, *args, **kwargs):
        """ Notifies all observers to an event. """
        if len(self._observer_funcs[event]) == 0:
            self._log.info('No observer registered for event "%s"', event)

        for func in self._observer_funcs[event]:
            await func(*args, **kwargs)
