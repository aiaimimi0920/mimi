from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,Union
import time, hashlib, random

models = {
    "meta-llama/Llama-2-7b-chat-hf": {"name": "Llama 2 7B", "version": "d24902e3fa9b698cc208b5e63136c4e26e828659a9f09827ca6ec5bb83014381", "shortened":"7B"},
    "meta-llama/Llama-2-13b-chat-hf": {"name": "Llama 2 13B", "version": "9dff94b1bed5af738655d4a7cbcdcde2bd503aa85c94334fe1f42af7f3dd5ee3", "shortened":"13B"},
    "meta-llama/Llama-2-70b-chat-hf": {"name": "Llama 2 70B", "version": "2796ee9483c3fd7aa2e171d38f4ca12251a30609463dcfd4cd76703f22e96cdf", "shortened":"70B"},
    "Llava": {"name": "Llava 13B", "version": "6bc1c7bb0d2a34e413301fee8f7cc728d2d4e75bfab186aa995f63292bda92fc", "shortened":"Llava"}
}

class Llama2(AsyncGeneratorProvider):
    url                   = "https://www.llama2.ai"
    working = True
    supports_message_history = True
    supports_stream = True

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
            model = "meta-llama/Llama-2-70b-chat-hf"
        elif model not in models:
            raise ValueError(f"Model are not supported: {model}")
        
        stream = cls.supports_stream and stream 

        version = models[model]["version"]

        headers = {
            "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/118.0",
            "Accept": "*/*",
            "Accept-Language": "de,en-US;q=0.7,en;q=0.3",
            "Accept-Encoding": "gzip, deflate, br",
            "Referer": f"{cls.url}/",
            "Content-Type": "text/plain;charset=UTF-8",
            "Origin": cls.url,
            "Connection": "keep-alive",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache",
            "TE": "trailers"
        }
        prompt = format_prompt(messages)
        json_data = {
            "prompt": prompt,
            "version": version,
            "systemPrompt": kwargs.get("system_message", "You are a helpful assistant."),
            "temperature": kwargs.get("temperature", 0.75),
            "topP": kwargs.get("top_p", 0.9),
            "maxTokens": kwargs.get("max_tokens", 8000),
            "image": None
        }
        session =  await Llama2BrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)
        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(1*1000)

        response = await session.js_fetch(f"{cls.url}/api", data=json_data,headers=headers,stream=stream,method="POST")
        started = False
        if stream:
            async for line in response.iter_lines():
                if not started:
                    line = line.lstrip()
                    started = True
                yield line.decode()
        else:
            result_content = ""
            lines = response.splitlines()
            for line in lines:
                if started:
                    line = line.lstrip()
                    if line:
                        started = False
                result_content += line 
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
        await Llama2BrowserSession().clear_browser()  

def generate_signature(timestamp: int, message: str, secret: str = ""):
    data = f"{timestamp}:{message}:{secret}"
    return hashlib.sha256(data.encode()).hexdigest()

import six
@six.add_metaclass(SingletonType)
class Llama2BrowserSession(PlaywrightBrowserSession):
    pass


def format_prompt(messages):
    messages = [
        f"[INST] {message['content']} [/INST]"
        if message["role"] == "user"
        else message["content"]
        for message in messages
    ]
    return "\n".join(messages) + "\n"