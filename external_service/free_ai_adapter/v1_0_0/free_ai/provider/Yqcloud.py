from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider,format_prompt
from ..self_typing import AsyncGenerator,Union

class Yqcloud(AsyncGeneratorProvider):
    url                   = 'https://chat18.aichatos.xyz'
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
            "Accept": "application/json, text/plain, */*",
            "Content-Type":"application/json",
            "accept-language": "zh-CN,zh;q=0.9",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "cross-site",
            "authority"         : "api.aichatos.cloud",
        }

        payload = _create_payload(messages)
        session =  await YqcloudBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(2*1000)

        response = await session.js_fetch(f"https://api.aichatos.cloud/api/generateStream", data=payload, headers=headers,stream=stream,method="POST",credentials="omit")

        if stream:
            first = True
            async for chunk in response.iter_content():
                chunk_str = bytes(chunk).decode()
                if first:
                    if chunk_str.startswith("sorry, 您的ip已由于触发防滥用检测而被封禁"):
                        RuntimeError("Yqcloud: 403 Forbidden")
                        break
                    first = False
                yield chunk_str
        else:
            if response.startswith("<!DOCTYPE html>") or response.startswith("<!doctype html>") or response.startswith("sorry, 您的ip已由于触发防滥用检测而被封禁"):
                RuntimeError("Yqcloud: 403 Forbidden")
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
        await YqcloudBrowserSession().clear_browser()    

def _create_payload(messages: list[dict[str, str]]):
    return {
        "prompt": format_prompt(messages),
        "network": True,
        "system": "",
        "withoutContext": False,
        "stream": True,
        "userId": "#/chat/1696841004726"
    }

import six
@six.add_metaclass(SingletonType)
class YqcloudBrowserSession(PlaywrightBrowserSession):
    pass
