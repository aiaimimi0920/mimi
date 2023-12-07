from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,AsyncResult,Messages,Union
import json
from .helper import get_cookies, format_prompt
import uuid
import rookiepy
import time
import random, string
import re

class ChatgptFree(AsyncGeneratorProvider):
    url                   = 'https://chatgptfree.ai'
    supports_gpt_35_turbo = True
    working               = True
    _post_id              = None
    _nonce                = None
    supports_stream       = True

    @classmethod
    async def create_async_generator(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream: bool=False,
        timeout: int = 60,
        proxies: dict[str, str] = None,
        access_token = None,
        **kwargs
    ) -> AsyncGenerator:
        stream = cls.supports_stream and stream 

        session =  await ChatgptFreeBrowserSession.with_init_brower(timeout=timeout, proxies=proxies)
        
        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(10*1000)

        if not cls._nonce:
            response = await session.js_fetch(f"{cls.url}/",stream=False,method="GET")
            result = re.search(r'data-post-id="([0-9]+)"', response)
            if not result:
                raise RuntimeError("No post id found")
            cls._post_id = result.group(1)
            
            if result := re.search(r'data-nonce="(.*?)"', response):
                cls._nonce = result.group(1)
            else:
                raise RuntimeError("No nonce found")

        prompt = format_prompt(messages)
        data = {
                "_wpnonce": cls._nonce,
                "post_id": cls._post_id,
                "url": cls.url,
                "action": "wpaicg_chat_shortcode_message",
                "message": prompt,
                "bot_id": "0"
            }

                
        response = await session.js_fetch(f"{cls.url}/wp-admin/admin-ajax.php", data=data,stream=stream,method="POST")
        yield (await response.json())["data"]


    @classmethod
    @property
    def params(cls):
        params = [
            ("model", "str"),
            ("messages", "list[dict[str, str]]"),
            ("stream", "bool"),
            ("poxies", "str"),
        ]
        param = ", ".join([": ".join(p) for p in params])
        return f"free_ai.provider.{cls.__name__} supports: ({param})"
    
    @classmethod
    async def clear_brower(cls):
        cls._nonce = None
        await ChatgptFreeBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class ChatgptFreeBrowserSession(PlaywrightBrowserSession):
    pass

