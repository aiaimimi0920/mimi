from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,AsyncResult,Messages,Union
import json
from .helper import get_cookies, format_prompt
import uuid
import sys

class OpenaiChat(AsyncGeneratorProvider):
    url                   = 'https://chat.openai.com'
    supports_stream       = True
    working               = True
    supports_gpt_35_turbo = True
    _access_token         = None
    _add_cookie          = None
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

        session =  await OpenaiChatBrowserSession.with_init_brower(headers={}, timeout=timeout, proxies=proxies)
        if session.is_open_url == False:
            await session.open_url(cls.url+"/auth/login")
        is_first = False
        if (not access_token and not cls._access_token) or not (session.page.url == cls.url+"/" or session.page.url == cls.url):
            if cls._access_token:
                access_token = cls._access_token
                await session.browser.add_cookies(cls._add_cookie)
            else:
                access_token = await cls.get_access_token(session, None)
                if access_token == False:
                    session =  await OpenaiChatBrowserSession.with_init_brower(headers={}, timeout=timeout, proxies=proxies)
                    await session.open_url(cls.url+"/auth/login")
                    access_token = await cls.get_access_token(session, None)
                    
                is_first = True
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(1*1000)
            
            
        if not access_token:
            access_token = cls._access_token
        headers = {
            "content-type": "application/json",
            "Authorization": f"Bearer {access_token}",
        }
        messages = [
            {
                "id": str(uuid.uuid4()),
                "author": {"role": "user"},
                "content": {"content_type": "text", "parts": [format_prompt(messages)]},
            },
        ]
        data = {
            "action": "next",
            "arkose_token":None,
            "messages": messages,
            "conversation_id": None,
            "parent_message_id": str(uuid.uuid4()),
            "model": "text-davinci-002-render-sha",
            "history_and_training_disabled": True,
            "arkose_token": "",
        }
        if is_first:
            await session.js_fetch(f"{cls.url}/backend-api/conversation", data=data, headers=headers,stream=False,method="POST")
            await session.page.wait_for_timeout(2*1000)
            is_first = False
                
        response = await session.js_fetch(f"{cls.url}/backend-api/conversation", data=data, headers=headers,stream=stream,method="POST")
        last_message = ""
        if stream:
            async for line in response.iter_lines():  
                if not line:
                    continue      
                if line.startswith(b"data: "):
                    line = line[6:]  
                if line == b"[DONE]":
                    continue
                try:
                    line = json.loads(line)
                except:
                    continue
                try:
                    if line["message"]["metadata"]["message_type"] == "next":
                        new_message = line["message"]["content"]["parts"][0]
                        yield new_message[len(last_message):]
                        last_message = new_message
                except:
                    continue
        else:
            result_content = ""
            lines = response.splitlines()
            for line in lines:
                if not line:
                    continue      
                if line.startswith("data: "):
                    line = line[6:]  
                if line == "[DONE]":
                    continue
                try:
                    line = json.loads(line)
                except:
                    continue
                try:
                    if line["message"]["metadata"]["message_type"] == "next":
                        new_message = line["message"]["content"]["parts"][0]
                        result_content += new_message[len(last_message):]
                        last_message = new_message
                except:
                    continue
            yield result_content


    @classmethod
    async def fetch_access_token(cls, session, cookies: dict) -> str:
        cls._add_cookie = [{"path":"/",
                        "domain":"chat.openai.com",
                        "name": "__Secure-next-auth.session-token", 
                        "value": cookies["__Secure-next-auth.session-token"]}]
        await session.browser.add_cookies(cls._add_cookie)
        await session.open_url(f"{cls.url}/api/auth/session")
        cur_headers = {
            "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "accept-language": "zh-CN,zh;q=0.9",
            "cache-control": "max-age=0",
            "if-none-match": "W/\"133wjauuiz21a8\"",
            "sec-ch-ua": "\"Google Chrome\";v=\"117\", \"Not;A=Brand\";v=\"8\", \"Chromium\";v=\"117\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "document",
            "sec-fetch-mode": "navigate",
            "sec-fetch-site": "none",
            "sec-fetch-user": "?1",
            "upgrade-insecure-requests": "1"
            }
        response = await session.js_fetch(f"{cls.url}/api/auth/session", headers=cur_headers,stream=False,method="GET")
        if "cf-spinner-please-wait" in response:
            await session.page.wait_for_timeout(5*1000)
            return await cls.fetch_access_token(session, cookies)
        await session.page.wait_for_timeout(2*1000)
        auth = json.loads(response) 
        if "accessToken" in auth:
            return auth["accessToken"]

    @classmethod
    async def get_access_token(cls, session, cookies: dict = None) -> str:
        if not cls._access_token:
            cookies = cookies if cookies else get_cookies("chat.openai.com")
            if cookies:
                try:
                    cls._access_token = await cls.fetch_access_token(session, cookies)
                except:
                    await cls.clear_brower()
                    return False
        if not cls._access_token:
            raise RuntimeError("Read access token failed")
        return cls._access_token

    @classmethod
    @property
    def params(cls):
        params = [
            ("model", "str"),
            ("messages", "list[dict[str, str]]"),
            ("stream", "bool"),
            ("poxies", "str"),
            ("access_token", "str"),
            ("cookies", "dict[str, str]")
        ]
        param = ", ".join([": ".join(p) for p in params])
        return f"free_ai.provider.{cls.__name__} supports: ({param})"
    
    @classmethod
    async def clear_brower(cls):
        cls._access_token = None
        await OpenaiChatBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class OpenaiChatBrowserSession(PlaywrightBrowserSession):
    pass
