from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator, Union
from json           import dumps
import json

class DeepInfra(AsyncGeneratorProvider):
    url                   = 'https://deepinfra.com'
    supports_message_history = True
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
            model = "meta-llama/Llama-2-70b-chat-hf"

        json_data = {
            "model": model,
            "messages": messages,
            "stream": True,
        }
        headers = {
            "Accept": "text/event-stream",
            "Connection": "keep-alive",
            "Origin": cls.url,
            "Referer": f"{cls.url}/",
            "Content-Type": "application/json",
            "x-deepinfra-source": "web-embed"
        }
        session =  await DeepInfraBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False or not (session.page.url == cls.url+"/" or session.page.url == cls.url):
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(1*1000)

        response = await session.js_fetch("https://api.deepinfra.com/v1/openai/chat/completions", data=json_data,headers=headers,credentials="omit",stream=stream,method="POST")
        if stream:
            start = b"data: "
            first = True
            async for line in response.iter_lines():
                if line.startswith(b"data: "):
                    if line.startswith(b"data: [DONE]"):
                        break
                    line = json.loads(line[len(start):])
                    if "choices" in line:
                        content = line["choices"][0]["delta"].get("content")
                        if content:
                            if first:
                                content = content.lstrip()
                                if content:
                                    first = False
                            yield content
                    else:
                        raise RuntimeError(f"Response: {line}")
        else:
            result_content = ""
            start = b"data: "
            lines = response.splitlines()
            first = True
            for line in lines:
                if line.startswith("data: "):
                    if line.startswith("data: [DONE]"):
                        break
                    line = json.loads(line[len(start):])
                    if "choices" in line:
                        content = line["choices"][0]["delta"].get("content")
                        if content:
                            if first:
                                content = content.lstrip()
                                if content:
                                    first = False
                            result_content += content
                    else:
                        raise RuntimeError(f"Response: {line}")     
            yield result_content

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
        await DeepInfraBrowserSession().clear_browser()
        pass


import six
@six.add_metaclass(SingletonType)
class DeepInfraBrowserSession(PlaywrightBrowserSession):
    pass
