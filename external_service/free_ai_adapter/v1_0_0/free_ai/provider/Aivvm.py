from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator, Union

models = {
    'gpt-3.5-turbo': {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5'},
    'gpt-3.5-turbo-0613': {'id': 'gpt-3.5-turbo-0613', 'name': 'GPT-3.5-0613'},
    'gpt-3.5-turbo-16k': {'id': 'gpt-3.5-turbo-16k', 'name': 'GPT-3.5-16K'},
    'gpt-3.5-turbo-16k-0613': {'id': 'gpt-3.5-turbo-16k-0613', 'name': 'GPT-3.5-16K-0613'},
    'gpt-4': {'id': 'gpt-4', 'name': 'GPT-4'},
    'gpt-4-0613': {'id': 'gpt-4-0613', 'name': 'GPT-4-0613'},
    'gpt-4-32k': {'id': 'gpt-4-32k', 'name': 'GPT-4-32K'},
    'gpt-4-32k-0613': {'id': 'gpt-4-32k-0613', 'name': 'GPT-4-32K-0613'},
}

class Aivvm(AsyncGeneratorProvider):
    url                   = 'https://chat.aivvm.com'
    supports_stream       = True
    working               = True
    supports_gpt_35_turbo = True
    supports_gpt_4        = True

    @classmethod
    async def create_async_generator(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream: bool=False,
        timeout: int = 60,
        proxies: dict[str, str] = None,
        **kwargs
    ) -> AsyncGenerator:
        stream = cls.supports_stream and stream 

        if not model:
            model = "gpt-3.5-turbo"
        elif model not in models:
            raise ValueError(f"Model is not supported: {model}")

        json_data = {
            "model"       : models[model],
            "messages"    : messages,
            "key"         : "",
            "prompt"      : kwargs.get("system_message", "You are ChatGPT, a large language model trained by OpenAI. Follow the user's instructions carefully. Respond using markdown."),
            "temperature" : kwargs.get("temperature", 0.7)
        }
        headers = {
            "Accept": "*/*",
            "Origin": cls.url,
            "Referer": f"{cls.url}/zh",
        }
        session =  await AivvmBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False or not (session.page.url == cls.url+"/" or session.page.url == cls.url):
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(5*1000)

        response = await session.js_fetch(f"{cls.url}/api/chat", data=json_data, headers=headers,stream=stream,method="POST")
        if stream:
            async for chunk in response.iter_content():
                yield bytes(chunk).decode()
        else:
            if response.startswith("<!DOCTYPE html>") or response.startswith("<!doctype html>"):
                RuntimeError("Aivvm: 403 Forbidden")
                return 
            yield response
        

    @classmethod
    @property
    def params(cls):
        params = [
            ('model', 'str'),
            ('messages', 'list[dict[str, str]]'),
            ('stream', 'bool'),
            ('temperature', 'float'),
        ]
        param = ', '.join([': '.join(p) for p in params])
        return f'free_ai.provider.{cls.__name__} supports: ({param})'
    
    @classmethod
    async def clear_brower(cls):
        await AivvmBrowserSession().clear_browser()


import six
@six.add_metaclass(SingletonType)
class AivvmBrowserSession(PlaywrightBrowserSession):
    pass
