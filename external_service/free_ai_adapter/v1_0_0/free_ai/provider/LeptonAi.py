from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,Union
import json

models = {
    'llama2-7b': {'id': 'codellama-7b', 'name': 'LLAMA2-7B'},
    'llama2-13b': {'id': 'llama2-13b', 'name': 'LLAMA2-13B'},
    'llama2-70b': {'id': 'llama2-70b', 'name': 'LLAMA2-70b'},
    'codellama-7b': {'id': 'codellama-7b', 'name': 'CODELLAMA-7B'},
    'codellama-13b': {'id': 'codellama-13b', 'name': 'CODELLAMA-13B'},
    'codellama-34b': {'id': 'codellama-34b', 'name': 'CODELLAMA-34B'},
}

class LeptonAi(AsyncGeneratorProvider):
    url                   = 'https://www.lepton.ai/playground/llama2'
    supports_stream       = True
    working               = True
    supports_gpt_4 = True

    @classmethod
    async def create_async_generator(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        stream: bool=True,
        timeout: int = 60,
        proxies: dict[str, str] = None,
        **kwargs
    ) -> AsyncGenerator:
        stream = cls.supports_stream and stream
        if not model:
            model = "llama2-70b"
        elif model not in models:
            raise ValueError(f"Model is not supported: {model}")


        headers = {
            "content-type": "application/json",
        }
        data = {
            "max_tokens":512,
            "temperature":0.5,
            "top_p":0.8,
            "model":model,
            "stream":stream,
            "messages":messages,
        }
        session =  await LeptonAiBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False:
            await session.open_url(cls.url)
        
        response = await session.js_fetch(f'https://{model}.lepton.run/api/v1/chat/completions', data=data, headers=headers,credentials="omit",stream=stream,method="POST")
        if stream:
            async for line in response.iter_lines():  
                if line.startswith(b"<!DOCTYPE html>"):
                    RuntimeError("LeptonAi: 403 Forbidden")
                    return
                if line.startswith(b"data: "):
                    line = line[6:]  
                if line == b"[DONE]":
                    break
                try:
                    line = json.loads(line)
                except:
                    continue
                try:
                    content = line["choices"][0]["delta"].get("content")
                    if content:
                        yield content
                except:
                    continue
                
        else:
            all_content = ""
            lines = response.splitlines()
            for line in lines:
                if line.startswith("<!DOCTYPE html>"):
                    RuntimeError("LeptonAi: 403 Forbidden")
                    return
                if line.startswith("data: "):
                    line = line[6:]  
                if line == "[DONE]":
                    break
                try:

                    line = json.loads(line)
                except Exception as e:
                    continue
                try:
                    content = line["choices"][0]["message"].get("content")
                    if content:
                        all_content += content
                except:
                    continue
            yield all_content

                    

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
        await LeptonAiBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class LeptonAiBrowserSession(PlaywrightBrowserSession):
    pass
