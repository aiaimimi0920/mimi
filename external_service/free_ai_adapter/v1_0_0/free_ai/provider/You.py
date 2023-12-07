from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
import json


class You(AsyncGeneratorProvider):
    url                   = 'https://you.com'
    supports_stream       = True
    working               = True
    supports_gpt_35_turbo = True

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
        headers = {
            "Accept": "text/event-stream",
            "Referer": "https://you.com/search?fromSearchBar=true&tbm=youchat",
        }
        session =  await YouBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies,use_117=False)

        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(10*1000)
            
        params = {
            "q": format_prompt(messages), "domain": "youchat", "chat": ""
        }

        response = await session.js_fetch(f"{cls.url}/api/streamingSearch", params=params, headers=headers,stream=stream,method="GET")
        if stream:
            start = b'data: {"youChatToken": '
            async for line in response.iter_lines():     
                if line.startswith(b"<!DOCTYPE html>"):
                    RuntimeError("You: 403 Forbidden")     
                    return  
                if line.startswith(start):
                    line = json.loads(line.decode()[len(start):-1])
                    yield line
        else:
            result_content = ""
            lines = response.splitlines()
            
            start = 'data: {"youChatToken": '
            for line in lines:
                if line.startswith("<!DOCTYPE html>"):
                    RuntimeError("You: 403 Forbidden")
                    return
                if line.startswith(start):
                    line = json.loads(line[len(start):-1])
                    result_content += line
            yield result_content
            
    @classmethod
    @property
    def params(cls):
        params = [
            ("model", "str"),
            ("messages", "list[dict[str, str]]"),
            ("stream", "bool"),
            ("proxies", "str"),
            ("temperature", "float"),
            ("top_p", "int"),
        ]
        param = ", ".join([": ".join(p) for p in params])
        return f"free_ai.provider.{cls.__name__} supports: ({param})"

    @classmethod
    async def clear_brower(cls):
        await YouBrowserSession().clear_browser()    

import six
@six.add_metaclass(SingletonType)
class YouBrowserSession(PlaywrightBrowserSession):
    pass
