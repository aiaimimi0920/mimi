from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator, Union
from json           import dumps
import json

class GeekGpt(AsyncGeneratorProvider):
    url                   = 'https://chat.geekgpt.org'
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
            model = "gpt-3.5-turbo"

        json_data = {
            "model"       : model,
            "messages"    : messages,
            'temperature': kwargs.get('temperature', 0.9),
            'presence_penalty': kwargs.get('presence_penalty', 0),
            'top_p': kwargs.get('top_p', 1),
            'frequency_penalty': kwargs.get('frequency_penalty', 0),
            'stream': True
        }
        headers = {
            "Accept": "*/*",
            # 'authority': 'ai.fakeopen.com',
            "Authorization": "Bearer pk-this-is-a-real-free-pool-token-for-everyone",
            'accept': '*/*',
            "Origin": cls.url,
            "Referer": f"{cls.url}/",
            "content-type": "application/json",
        }
        session =  await GeekGptBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False or not (session.page.url == cls.url+"/" or session.page.url == cls.url):
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(1*1000)

        response = await session.js_fetch("https://ai.fakeopen.com/v1/chat/completions", data=json_data,credentials = "omit", headers=headers,stream=stream,method="POST")
        if stream:
            async for line in response.iter_lines():
                if b'content' in line:
                    json_data = line.decode().replace("data: ", "")
                    if json_data == "[DONE]":
                        break
                    content = None
                    try:
                        content = json.loads(json_data)["choices"][0]["delta"].get("content")
                    except Exception as e:
                        continue
                        # raise RuntimeError(f'error | {e} :', json_data)
                    
                    if content:
                        yield content
        else:
            result_content = ""
            lines = response.splitlines()
            for line in lines:
                if 'content' in line:
                    json_data = line.replace("data: ", "")
                    if json_data == "[DONE]":
                        break
                    try:
                        content = json.loads(json_data)["choices"][0]["delta"].get("content")
                        if content:
                            result_content += content
                    except Exception as e:
                        raise RuntimeError(f'error | {e} :', json_data)
                    
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
        await GeekGptBrowserSession().clear_browser()
        pass


import six
@six.add_metaclass(SingletonType)
class GeekGptBrowserSession(PlaywrightBrowserSession):
    pass
