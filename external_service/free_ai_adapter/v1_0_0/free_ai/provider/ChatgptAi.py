from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator
import json
import re, html, random, string


class ChatgptAi(AsyncGeneratorProvider):
    url                   = 'https://chatgpt.ai'
    working               = True
    supports_gpt_35_turbo = True
    _system = None

    @classmethod
    async def create_async_generator(
        cls,
        model: [str, None],
        messages: list[dict[str, str]],
        stream: bool,
        timeout: int = 60,
        proxies: dict[str, str] = None,
        **kwargs
    ) -> AsyncGenerator:
        stream = cls.supports_stream and stream
        headers = {
            "accept"             : "*/*",
            "origin"             : cls.url,
            "referer"            : cls.url,
            "content-type"       : "application/json",
        }
        session =  await ChatgptAiBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)
        if session.is_open_url == False:
            await session.open_url(cls.url)
            response_html = await session.js_fetch(cls.url, headers=headers,stream=False,method="GET")
            if result := re.search(r"data-system='(.*?)'", response_html):
                cls._system = json.loads(html.unescape(result.group(1)))
            if not cls._system:
                raise RuntimeError("System args not found")

        json_data = {
                "botId": cls._system["botId"],
                "customId": cls._system["customId"],
                "session": cls._system["sessionId"],
                "chatId": "".join(random.choices(f"{string.ascii_lowercase}{string.digits}", k=11)),
                "contextId": cls._system["contextId"],
                "messages": format_prompt(messages),
                "newMessage": messages[-1]["content"],
                "stream": True
        }
        
        response = await session.js_fetch(f"{cls.url}/wp-json/mwai-ui/v1/chats/submit", data=json_data, headers=headers,stream=stream,method="POST")
        if stream:
            start = "data: "
            async for line in response.iter_lines():
                if line.startswith(b"<!DOCTYPE html>"):
                    RuntimeError("ChatgptAi: 403 Forbidden")
                    return
                if line.startswith(b"data: "):
                    if line.startswith(b"data: [DONE]"):
                        break
                    line = json.loads(line[len(start):])
                    if line["type"] == "error":
                        RuntimeError("ChatgptAi: 403 Forbidden")
                        return
                    elif line["type"] == "live":
                        yield line["data"]
                    elif line["type"] == "end":
                        break
        else:
            result_content = ""
            start = "data: "
            lines = response.splitlines()
            for line in lines:
                if line.startswith("<!DOCTYPE html>"):
                    RuntimeError("ChatgptAi: 403 Forbidden")
                    return
                if line.startswith("data: "):
                    if line.startswith("data: [DONE]"):
                        break
                    line = json.loads(line[len(start):])
                    if line["type"] == "error":
                        RuntimeError("ChatgptAi: 403 Forbidden")
                        return
                    elif line["type"] == "live":
                        result_content += line["data"]
                    elif line["type"] == "end":
                        break
            yield result_content

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
        await ChatgptAiBrowserSession().clear_browser()

import six
@six.add_metaclass(SingletonType)
class ChatgptAiBrowserSession(PlaywrightBrowserSession):
    pass


def format_prompt(messages: list[dict[str, str]]):
    cur_messages = []
    for message in messages[1:]:
        cur_messages.append({
            "role": message["role"],
            "content": message["content"],
            "who":"User: " if message["role"] == "user" else "AI: "
        })
    return cur_messages