from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,Union
import time
import hashlib
class ChatForAi(AsyncGeneratorProvider):
    url                   = 'https://chatforai.com'
    supports_stream       = True
    working               = True
    supports_gpt_35_turbo = True
    _conversation_id = None
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
        if not model:
            model = "gpt-3.5-turbo"

        stream = cls.supports_stream and stream
        prompt = messages[-1]["content"]
        json_data = {
            "conversationId": "temp",
            "conversationType": "chat_continuous",
            "botId": "chat_continuous",
            "globalSettings":{
                "baseUrl": "https://api.openai.com",
                "model": model if model else "gpt-3.5-turbo",
                "messageHistorySize": 5,
                "temperature": 0.7,
                "top_p": 1,
                **kwargs
            },
            "botSettings": {},
            "prompt": prompt,
            "messages": messages
        }
        headers = {
            "Accept": "*/*",
            "Origin": cls.url,
            "Referer": f"{cls.url}/",
        }
        session =  await ChatForAiBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)
        if session.is_open_url == False:
            await session.open_url(cls.url)
            timestamp = int(time.time()*1000)
            cls._conversation_id = "id_"+str(timestamp)
            await session.page.wait_for_timeout(2*1000)

        json_data["conversationId"] = cls._conversation_id
        json_data["timestamp"] = int(time.time()*1000)
        json_data["sign"] = generateSignature({"t":json_data["timestamp"],"m":messages[-1]["content"],"id":json_data["conversationId"]})
        response = await session.js_fetch(f"{cls.url}/api/handle/provider-openai", data=json_data, headers=headers,stream=stream,method="POST")
        if stream:
            async for chunk in response.iter_content():
                yield bytes(chunk).decode()
        else:
            if response.startswith("<!DOCTYPE html>") or response.startswith("<!doctype html>"):
                RuntimeError("ChatForAi: 403 Forbidden")
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
        await ChatForAiBrowserSession().clear_browser()

def digestMessage(t):
    if hasattr(hashlib, "sha256"):
        e = t.encode()
        a = hashlib.sha256(e).digest()
        return "".join(format(x, "02x") for x in a)
    else:
        raise Exception("SHA-256 not supported")

def generateSignature(t):
    e, a, r = t["t"], t["m"], t["id"]
    s = f"{e}:{r}:{a}:7YN8z6d6"
    return digestMessage(s)

import six
@six.add_metaclass(SingletonType)
class ChatForAiBrowserSession(PlaywrightBrowserSession):
    pass
