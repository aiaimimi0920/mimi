import time
import asyncio
import heapq
from enum import Enum, IntEnum
from .singleton import SingletonType
import six

class MessageLevel(IntEnum):
    SPECIAL = 4
    HIGH = 3
    MEDIUM = 2
    LOW = 1

class Message:
    value_map = {
        MessageLevel.SPECIAL: 10,
        MessageLevel.HIGH: 5,
        MessageLevel.MEDIUM: 2,
        MessageLevel.LOW: 1,
    }

    def __init__(self, stream, messages, level, has_call_obj=True):
        self.stream = stream
        self.messages = messages
        self.level = level
        self.timestamp = time.time()
        self.sort_value = 0
        self.processed = asyncio.Event()
        self.response_finished = asyncio.Event()
        self.response = None
        self.has_call_obj = has_call_obj
        self.have_error = False

    def get_value(self):
        return self.value_map[self.level]

    def calculate_value(self, now_time=time.time()):
        return (now_time - self.timestamp) * self.get_value()

    def calculate_sort_value(self, now_time=time.time()):
        self.sort_value = self.calculate_value(now_time)

    def __lt__(self, other):
        if self.level == MessageLevel.SPECIAL and other.level != MessageLevel.SPECIAL:
            return True
        elif self.level != MessageLevel.SPECIAL and other.level == MessageLevel.SPECIAL:
            return False
        else:
            self_value = self.sort_value
            other_value = other.sort_value
            return self_value > other_value if self_value != other_value else self.timestamp < other.timestamp

@six.add_metaclass(SingletonType)
class MessageQueue:
    def __init__(self):
        self.timer = None
        self._queue = []
        self.start_timer()

    def start_timer(self):
        # Cancel old timers
        if self.timer:
            self.timer.cancel()

        # Create a new timer and check every 5 seconds for any running elements
        self.timer = asyncio.get_event_loop().call_later(5, self.check_if_message_can_be_processed)


    def push(self, message):
        message.calculate_sort_value(time.time())
        heapq.heappush(self._queue, message)
        self.check_if_message_can_be_processed()

    def pop(self):
        now_time = time.time()
        for message in self._queue:
            message.calculate_sort_value(now_time)
        heapq.heapify(self._queue)
        if self._queue:
            top_message = heapq.heappop(self._queue)
            return top_message
        return None

    def peek(self):
        now_time = time.time()
        for message in self._queue:
            message.calculate_sort_value(now_time)
        heapq.heapify(self._queue)
        return self._queue[0] if self._queue else None

    def __len__(self):
        return len(self._queue)

    def __bool__(self):
        return bool(self._queue)

    def check_if_message_can_be_processed(self):
        self.start_timer()
        if len(self) > 0:
            loop = asyncio.get_event_loop()
            loop.create_task(self.async_check_if_message_can_be_processed())

    async def async_check_if_message_can_be_processed(self):
        await ProcessEngine().check_if_message_can_be_processed()

from .process_engine import ProcessEngine