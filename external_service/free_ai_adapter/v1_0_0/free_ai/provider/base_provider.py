from __future__ import annotations

from asyncio import AbstractEventLoop
from concurrent.futures import ThreadPoolExecutor
from abc import ABC, abstractmethod

from .helper import get_event_loop, get_cookies, format_prompt
from ..self_typing import AsyncGenerator, CreateResult, Union


class BaseProvider(ABC):
    url: str
    working               = False
    needs_auth            = False
    supports_stream       = False
    supports_gpt_35_turbo = False
    supports_gpt_4        = False

    @staticmethod
    @abstractmethod
    async def create_completion(
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream: bool,
        **kwargs
    ) -> CreateResult:
        raise NotImplementedError()

    @classmethod
    async def create_async(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        *,
        loop: AbstractEventLoop = None,
        executor: ThreadPoolExecutor = None,
        **kwargs
    ) -> str:
        if not loop:
            loop = get_event_loop()
        def create_func():
            return "".join(cls.create_completion(
                model,
                messages,
                False,
                **kwargs
            ))
        return await loop.run_in_executor(
            executor,
            create_func
        )

    @classmethod
    @property
    def params(cls):
        params = [
            ("model", "str"),
            ("messages", "list[dict[str, str]]"),
            ("stream", "bool"),
        ]
        param = ", ".join([": ".join(p) for p in params])
        return f"free_ai.provider.{cls.__name__} supports: ({param})"


class AsyncProvider(BaseProvider):
    @classmethod
    async def create_completion(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream: bool = False,
        **kwargs
    ) -> CreateResult:
        loop = get_event_loop()
        coro = cls.create_async(model, messages, **kwargs)
        yield loop.run_until_complete(coro)

    @staticmethod
    @abstractmethod
    async def create_async(
        model: Union[str, None],
        messages: list[dict[str, str]],
        **kwargs
    ) -> str:
        raise NotImplementedError()
    

class AsyncGeneratorProvider(AsyncProvider):
    supports_stream = True

    @classmethod
    async def create_async(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream=False,
        **kwargs
    ) -> str:
        return "".join([
            chunk async for chunk in cls.create_async_generator(
                model,
                messages,
                stream=stream,
                **kwargs
            )
        ])
        
    @staticmethod
    @abstractmethod
    async def create_async_generator(
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream: bool,
        **kwargs
    ) -> AsyncGenerator:
        raise NotImplementedError()