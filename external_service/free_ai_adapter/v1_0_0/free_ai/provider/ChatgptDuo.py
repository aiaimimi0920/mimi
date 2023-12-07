from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
import json
class ChatgptDuo(AsyncGeneratorProvider):
    url                   = 'https://chatgptduo.com'
    working               = True
    supports_gpt_35_turbo = True
    supports_stream       = False

    @classmethod
    async def create_async_generator(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream: bool,
        timeout: int = 60,
        proxies: dict[str, str] = None,
        **kwargs
    ) -> AsyncGenerator:
        stream = cls.supports_stream and stream
        prompt = format_prompt(messages),

        headers = {
            "accept"             : "*/*",
            "origin"             : cls.url,
            "referer"            : cls.url,
            "content-type"       : "application/x-www-form-urlencoded; charset=UTF-8",
            "x-requested-with":  "XMLHttpRequest",
        }
        session =  await ChatgptDuoBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(1*1000)

        json_data = {
            "prompt": prompt[0],
            "purpose": "chat",
        }
        response = await session.js_fetch(f"{cls.url}/", data_params=json_data, headers=headers,stream=stream,method="POST")
        if stream:
            async for chunk in response.iter_content():
                yield bytes(chunk).decode()
        else:
            if response.startswith("<!DOCTYPE html>") or response.startswith("<!doctype html>"):
                RuntimeError("ChatgptDuo: 403 Forbidden")
                return
            response_data = json.loads(response)
            result = response_data["answer"].replace('<br />', '\n')
            yield result



    @classmethod
    @property
    def params(cls):
        params = [
            ('model', 'str'),
            ('messages', 'list[dict[str, str]]'),
            ('stream', 'bool'),
        ]
        param = ', '.join([': '.join(p) for p in params])
        return f'free_ai.provider.{cls.__name__} supports: ({param})'

    @classmethod
    async def clear_brower(cls):
        await ChatgptDuoBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class ChatgptDuoBrowserSession(PlaywrightBrowserSession):
    pass
