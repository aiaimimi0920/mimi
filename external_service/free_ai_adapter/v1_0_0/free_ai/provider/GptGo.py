from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
import json

class GptGo(AsyncGeneratorProvider):
    url                   = "https://gptgo.ai"
    supports_gpt_35_turbo = True
    working               = True


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

        headers = {
            "User-Agent"         : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36",
            "Accept"             : "*/*",
            "Accept-language"    : "en,fr-FR;q=0.9,fr;q=0.8,es-ES;q=0.7,es;q=0.6,en-US;q=0.5,am;q=0.4,de;q=0.3",
            "Origin"             : cls.url,
            "Referer"            : cls.url + "/",
            "Sec-Fetch-Dest"     : "empty",
            "Sec-Fetch-Mode"     : "cors",
            "Sec-Fetch-Site"     : "same-origin",
        }
        session =  await GptGoBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(5*1000)

        response = await session.js_fetch(f"{cls.url}/action_get_token.php", 
                    params={
                    "q": format_prompt(messages),
                    "hlgpt": "default",
                    "hl": "en"}, headers=headers,stream=False,method="GET")
        
        if response.startswith("<!DOCTYPE html>") or response.startswith("<!doctype html>"):
            RuntimeError("GptGo: 403 Forbidden")
            return
        token = json.loads(response)["token"]

        response = await session.js_fetch(f"{cls.url}/action_ai_gpt.php", 
                    params={
                    "token": token,}, headers=headers,stream=stream,method="GET")

        if stream:
            start = "data: "
            async for line in response.iter_lines():
                if line.startswith(b"<!DOCTYPE html>"):
                    RuntimeError("GptGo: 403 Forbidden")
                    return
                if line.startswith(b"data: "):
                    if line.startswith(b"data: [DONE]"):
                        break
                    line = json.loads(line[len(start):])
                    if "choices" in line:
                        content = line["choices"][0]["delta"].get("content")
                        if content:
                            yield content
                    else:
                        raise RuntimeError(f"Response: {line}")
        else:
            result_content = ""
            start = "data: "
            lines = response.splitlines()
            for line in lines:
                if line.startswith("<!DOCTYPE html>"):
                    RuntimeError("GptGo: 403 Forbidden")
                    return
                if line.startswith("data: "):
                    if line.startswith("data: [DONE]"):
                        break
                    line = json.loads(line[len(start):])
                    if "choices" in line:
                        content = line["choices"][0]["delta"].get("content")
                        if content:
                            result_content += content
                    else:
                        raise RuntimeError(f"Response: {line}")     
            yield result_content

    @classmethod
    async def clear_brower(cls):
        await GptGoBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class GptGoBrowserSession(PlaywrightBrowserSession):
    pass
