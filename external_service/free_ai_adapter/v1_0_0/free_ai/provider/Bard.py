from __future__ import annotations

from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
from bardapi import BardAsyncCookies
from .helper import get_cookies


class Bard(AsyncGeneratorProvider):
    url                   = 'https://bard.google.com'
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
        m_poxies = {}
        if proxies:
            if "http" in proxies:
                m_poxies["http://"] = "http://"+proxies["http"]
            if "https" in proxies:
                m_poxies["https://"] = "http://"+proxies["https"]
        cur_cookie_dict = get_cookies("google.com")
        bard = BardAsyncCookies(cookie_dict=cur_cookie_dict, timeout = 200, proxies=m_poxies, token_from_browser=True)
        try:
            data = await bard.get_answer(str(format_prompt(messages)))
            if data.get("status_code",400)==200:
                yield data["content"]
            else:
                raise RuntimeError("Bard error: "+data["content"])
        except Exception as e:
            return 


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
        return True