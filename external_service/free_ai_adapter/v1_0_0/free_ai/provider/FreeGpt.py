from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,Union
import time, hashlib, random

domains = [
    # 'https://k.aifree.site',
    'https://s.aifree.site',
]

class FreeGpt(AsyncGeneratorProvider):
    url                   = 'https://freegpts1.aifree.site/'
    supports_stream       = True
    working               = True
    supports_gpt_35_turbo = True

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
        prompt = messages[-1]["content"]
        timestamp = int(time.time())
        json_data = {
            "messages": messages,
            "time": timestamp,
            "pass": None,
            "sign": generate_signature(timestamp, prompt)
        }
        headers = {
            "Accept": "*/*",
            "Origin": cls.url,
            "Referer": f"{cls.url}/",
        }
        session =  await FreeGptBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        url = random.choice(domains)
        if session.is_open_url == False:
            await session.open_url(url)
            await session.page.wait_for_timeout(5*1000)
        
        response = await session.js_fetch(f"{url}/api/generate", data=json_data, headers=headers,stream=stream,method="POST")
        if stream:
            async for chunk in response.iter_content():
                yield bytes(chunk).decode()
        else:
            if response.startswith("<!DOCTYPE html>") or response.startswith("<!doctype html>"):
                RuntimeError("FreeGpt: 403 Forbidden")
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
        await FreeGptBrowserSession().clear_browser()  

def generate_signature(timestamp: int, message: str, secret: str = ""):
    data = f"{timestamp}:{message}:{secret}"
    return hashlib.sha256(data.encode()).hexdigest()

import six
@six.add_metaclass(SingletonType)
class FreeGptBrowserSession(PlaywrightBrowserSession):
    pass
