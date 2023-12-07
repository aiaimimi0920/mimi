from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
import random, string
from datetime import datetime
import json

class Phind(AsyncGeneratorProvider):
    url                   = 'https://www.phind.com'
    supports_stream       = True
    working               = True
    supports_gpt_4 = True

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
        chars = string.ascii_lowercase + string.digits
        user_id = ''.join(random.choice(chars) for _ in range(24))
        data = {
            "question": format_prompt(messages),
            "webResults": [],
            "options": {
                "date": datetime.now().strftime("%Y/%m/%d"),
                "language": "zh-CN",
                "detailed": True,
                "anonUserId": "",
                "answerModel": "GPT-4",
                "creativeMode": True,
                "customLinks": []
            },
            "context":"",
        }
        generate_e = data["question"]+data["context"]+json.dumps(data["options"],separators=(',', ':'))
        # test_generate_e = 'Hello, who are you? Answer in detail much as possible.{"date":"2023/11/10","language":"zh-CN","detailed":true,"anonUserId":"","answerModel":"GPT-4","creativeMode":true,"customLinks":[]}'
        js_script = '''
        generate_e  => {
            function generateChallenge(e) {
                var t = function(e) {
                    var t = 0;
                    for (var n = 0; n < e.length; n += 1)
                        t = (t << 5) - t + e.charCodeAt(n) | 0;
                    return t
                }(e);
                return (9301 * t + 49297) % 233280 / 233280
            }
            return generateChallenge(generate_e)
        }
        '''
        headers = {
            "Authority": cls.url,
            "Accept": "application/json",
            "Origin": cls.url,
            "Referer": f"{cls.url}/"
        }
        session =  await PhindBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)
        
        if session.is_open_url == False:
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(5*1000)

        data["challenge"] = await session.page.evaluate(js_script, generate_e)

        response = await session.js_fetch(f"{cls.url}/api/infer/answer", data=data, headers=headers,stream=stream,method="POST")
        if stream:
            new_lines = 0
            async for line in response.iter_lines():
                if not line:
                    continue      
                if line.startswith(b"<!DOCTYPE html>"):
                    RuntimeError("Phind: 403 Forbidden")
                    return 
                if line.startswith(b"data: "):
                    line = line[6:]  
                if line.startswith(b"<PHIND_METADATA>"):
                    continue 
                if line:
                    if new_lines>=4:
                        yield "".join(["\n" for _ in range(int(new_lines / 4))])
                    new_lines = 0
                    yield line.decode()
                else:
                    new_lines += 1
        else:
            result_content = ""
            lines = response.splitlines()
            new_lines = 0
            for line in lines:
                if not line:
                    continue  
                if line.startswith("<!DOCTYPE html>"):
                    RuntimeError("Phind: 403 Forbidden")
                    return
                if line.startswith("data: "):
                    line = line[6:]  
                if line.startswith("<PHIND_METADATA>"):
                    continue 
                if line:
                    if new_lines>=4:
                        yield "".join(["\n" for _ in range(int(new_lines / 4))])
                    new_lines = 0
                    result_content += line
                else:
                    new_lines += 1
            yield result_content    


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
        await PhindBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class PhindBrowserSession(PlaywrightBrowserSession):
    pass

