from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
import json

class PiAi(AsyncGeneratorProvider):
    url                   = 'https://pi.ai'
    supports_stream       = True
    working               = True
    supports_gpt_4 = True

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
            "content-type": "application/json",
        }
        session =  await PiAiBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(5*1000)
            response = await session.js_fetch(f"{cls.url}/api/chat/start", data={}, headers=headers,stream=False,method="POST")

        prompt = messages[-1]["content"]
        data = {"text": prompt}
        response = await session.js_fetch(f"{cls.url}/api/chat", data=data, headers=headers,stream=stream,method="POST")
        if stream:
            async for line in response.iter_lines():  
                if not line:
                    continue    
                if line.startswith(b"<!DOCTYPE html>"):
                    RuntimeError("PiAi: 403 Forbidden")
                    return
                if line.startswith(b"data: "):
                    line = line[6:]  
                    if line:
                        cur_data = json.loads(line.decode())
                        if "text" in  cur_data:
                            yield cur_data["text"]
        else:
            result_content = ""
            lines = response.splitlines()
            for line in lines:
                if not line:
                    continue    
                if line.startswith("<!DOCTYPE html>"):
                    RuntimeError("PiAi: 403 Forbidden")
                    return
                if line.startswith("data: "):
                    line = line[6:]  
                    if line:
                        cur_data = json.loads(line)
                        if "text" in  cur_data:
                            result_content += cur_data["text"]
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
        await PiAiBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class PiAiBrowserSession(PlaywrightBrowserSession):
    pass
