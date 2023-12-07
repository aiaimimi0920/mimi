from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
import json
import time

class ChatgptDemo(AsyncGeneratorProvider):
    url                   = 'https://chat.chatgptdemo.net'
    working               = True
    supports_gpt_35_turbo = True
    _user_id = None
    _chat_id = None

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
            "accept"             : "*/*",
            "origin"             : "https://chat.chatgptdemo.net",
            "referer"            : cls.url,
        }
        session =  await ChatgptDemoBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        
        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(5*1000)

        if not cls._user_id:
            element = await session.page.query_selector("#USERID")
            if element:
                cls._user_id = await element.inner_text()
            else:
                cls._user_id = None
            if not cls._user_id:
                raise RuntimeError("Nonce, post-id or bot-id not found")
            await session.page.wait_for_timeout(1*1000)

        if not cls._chat_id:
            response = await session.js_fetch(f"{cls.url}/new_chat", data={"user_id": cls._user_id}, headers=headers,stream=False,method="POST")
            try:
                cls._chat_id = json.loads(response)["id_"]
            except:
                cls._chat_id = None
            if not cls._chat_id:
                raise RuntimeError("Chat id not found")
            await session.page.wait_for_timeout(1*1000)

        json_data = {
            "question": format_prompt(messages),
            "chat_id": cls._chat_id,
            "timestamp": int(time.time()*1000),
        }

        response = await session.js_fetch(f"{cls.url}/chat_api_stream", data=json_data, headers=headers,stream=stream,method="POST")
        if stream:
            async for line in response.iter_lines():
                if line.startswith(b"<!DOCTYPE html>"):
                    RuntimeError("ChatgptDemo: 403 Forbidden")
                    return
                if line == b"<script>":
                    raise RuntimeError("Solve challenge and pass cookies")
                
                if b"platform's risk control" in line:
                    raise RuntimeError("Platform's Risk Control")
                if line.startswith(b"data: "):
                    line = json.loads(line.decode()[6:])
                    if "choices" in line:
                        content = line["choices"][0]["delta"].get("content")
                        if content:
                            yield content
                    else:
                        raise RuntimeError(f"Response: {line}")
        else:
            result_content = ""
            lines = response.splitlines()
            for line in lines:
                if line.startswith("<!DOCTYPE html>"):
                    RuntimeError("ChatgptDemo: 403 Forbidden")
                    return
                if line == "<script>":
                    raise RuntimeError("Solve challenge and pass cookies")
                if "platform's risk control" in line:
                    raise RuntimeError("Platform's Risk Control")
                if line.startswith("data: "):
                    line = json.loads(line[6:])
                    if "choices" in line:
                        content = line["choices"][0]["delta"].get("content")
                        if content:
                            result_content += content
                    else:
                        raise RuntimeError(f"Response: {line}")
            yield result_content


    @classmethod
    async def clear_brower(cls):
        await ChatgptDemoBrowserSession().clear_browser()

import six
@six.add_metaclass(SingletonType)
class ChatgptDemoBrowserSession(PlaywrightBrowserSession):
    pass
