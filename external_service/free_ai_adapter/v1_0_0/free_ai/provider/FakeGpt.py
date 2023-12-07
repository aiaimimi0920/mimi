from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,AsyncResult,Messages,Union
import json
from .helper import get_cookies, format_prompt
import uuid
import rookiepy
import time
import random, string

class FakeGpt(AsyncGeneratorProvider):
    url                   = 'https://chat-shared2.zhile.io'
    supports_gpt_35_turbo = True
    working               = True
    _access_token         = None
    _cookie_jar           = None
    # _add_cookie          = None
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
        session =  await FakeGptBrowserSession.with_init_brower(headers={}, timeout=timeout, proxies=proxies)
        if session.is_open_url == False:
            await session.open_url(cls.url)
        is_first = False
        if (not access_token and not cls._access_token) or not (session.page.url == cls.url+"/" or session.page.url == cls.url):
            if cls._access_token:
                access_token = cls._access_token
            else:
                access_token = await cls.get_access_token(session, None)
                if access_token == False:
                    session =  await FakeGptBrowserSession.with_init_brower(headers={}, timeout=timeout, proxies=proxies)
                    access_token = await cls.get_access_token(session, None)   
                is_first = True
            await session.open_url(cls.url)
            await session.page.wait_for_timeout(1*1000)
            
            
        if not access_token:
            access_token = cls._access_token
        headers = {
            "content-type": "application/json",
            "Accept": "text/event-stream",
            "Authorization": f"Bearer {access_token}",
        }
        messages = [
            {
                "id": str(uuid.uuid4()),
                "author": {"role": "user"},
                "content": {"content_type": "text", "parts": [format_prompt(messages)]},
                "metadata": {},
            },
        ]
        data = {
            "action": "next",
            "messages": messages,
            "conversation_id": None,
            "parent_message_id": str(uuid.uuid4()),
            "model": "text-davinci-002-render-sha",
            "plugin_ids": [],
            "timezone_offset_min": -120,
            "suggestions": [],
            "history_and_training_disabled": True,
            "arkose_token": "",
            "force_paragen": False,
        }
        if is_first:
            await session.js_fetch(f"{cls.url}/api/conversation", data=data, headers=headers,stream=False,method="POST")
            await session.page.wait_for_timeout(2*1000)
            is_first = False
                
        response = await session.js_fetch(f"{cls.url}/api/conversation", data=data, headers=headers,stream=stream,method="POST")
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
        # cls._add_cookie = []
        # if len(cookies)==0:
        #     cookies = rookiepy.load()
        #     cls._add_cookie = [cookie for cookie in cookies if cookie.get("expires",True)]
        # else:
        #     for name in cookies:
        #         cls._add_cookie.append({"path":"/",
        #                     "domain":"chat.openai.com",
        #                     "name": name, 
        #                     "value": cookies[name]})
        
        # await session.browser.add_cookies(cls._add_cookie)
        response = await session.js_fetch(f"{cls.url}/api/loads",params={"t": int(time.time())},stream=False,method="GET")
        all_list = json.loads(response)["loads"]
        token_ids = [t["token_id"] for t in all_list if t["count"] == 0]
        data = {
                    "token_key": random.choice(token_ids),
                    "session_password": random_string()
                }
        login_headers = {
            "content-type": "application/x-www-form-urlencoded",
        }
        response = await session.js_fetch(f"{cls.url}/auth/login",headers = login_headers,data_params=data,stream=False,method="POST")
        await session.page.wait_for_timeout(2*1000)
        response = await session.js_fetch(f"{cls.url}/api/auth/session",stream=False,method="GET")
        await session.page.wait_for_timeout(2*1000)
        auth = json.loads(response) 
        if "accessToken" in auth:
            return auth["accessToken"]

    @classmethod
    async def get_access_token(cls, session, cookies: dict = None) -> str:
        if not cls._access_token:
            cookies = cookies if cookies else {}
            if cookies!=None:
                try:
                    cls._access_token = await cls.fetch_access_token(session, cookies)
                except Exception as e:
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
        await FakeGptBrowserSession().clear_browser()  

import six
@six.add_metaclass(SingletonType)
class FakeGptBrowserSession(PlaywrightBrowserSession):
    pass


def random_string(length: int = 10):
    return ''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(length))
