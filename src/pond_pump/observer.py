import logging
from collections import defaultdict
from typing import Dict, Any, Callable, List, Coroutine

AsyncCallable = Callable[[Any], Coroutine[Any, Any, Any]]


class ObserverRegistry:
    """ A general purpose observer registry """

    observers: Dict[Any, List[AsyncCallable]]
    _log = logging.getLogger(__name__)

    def __init__(self):
        self.observers = defaultdict(list)

    def register(self, event: Any) -> Callable[[AsyncCallable], AsyncCallable]:
        """ Registers a function as an observer for an event. """

        def actual_decorator(fn: Callable[[Any], Coroutine[Any, Any, Any]]):
            self.observers[event].append(fn)
            # no need to replace the original function
            return fn

        return actual_decorator

    async def notify(self, event: Any, *args, **kwargs):
        """ Notifies all observers to an event. """
        if len(self.observers[event]) == 0:
            self._log.info(f'No observer registered for event "{event}"')

        for fn in self.observers[event]:
            await fn(*args, **kwargs)
