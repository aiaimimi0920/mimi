from __future__ import annotations

import asyncio
from asyncio import AbstractEventLoop
from os import path
# import browser_cookie3
import rookiepy
_cookies: dict[str, dict[str, str]] = {}

# If event loop is already running, handle nested event loops
# If "nest_asyncio" is installed, patch the event loop.
def get_event_loop() -> AbstractEventLoop:
    # return asyncio.get_event_loop()
    try:
        asyncio.get_running_loop()
    except RuntimeError:
        try:
            return asyncio.get_event_loop()
        except RuntimeError:
            asyncio.set_event_loop(asyncio.new_event_loop())
            return asyncio.get_event_loop()
    try:
        event_loop = asyncio.get_event_loop()
        if not hasattr(event_loop.__class__, "_nest_patched"):
            import nest_asyncio
            nest_asyncio.apply(event_loop)
        return event_loop
    except ImportError:
        raise RuntimeError(
            'Use "create_async" instead of "create" function in a running event loop. Or install the "nest_asyncio" package.')

def get_cookies(cookie_domain: str) -> Dict[str, str]:
    if _cookies == {}:
        for cookie in rookiepy.load():
            if cookie["domain"] not in _cookies:
                _cookies[cookie["domain"]] = {}

            if cookie["expires"] == None:
                _cookies[cookie["domain"]][cookie["name"]] = {"value":cookie["value"],"expires":None}
            else:
                now_expires = _cookies[cookie["domain"]].get(cookie["name"],{}).get("expires",0)
                if now_expires != None:
                    if cookie["expires"] > now_expires:
                        _cookies[cookie["domain"]][cookie["name"]] = {"value":cookie["value"],"expires":cookie["expires"]}
    
    if cookie_domain=="":
        cur_cookie3 = {}
        for domain_name in _cookies:
            cur_cookie3[domain_name] = {}
            for key_name in _cookies[domain_name]:
                cur_cookie3[domain_name][key_name] = _cookies[domain_name][key_name]["value"]
        return cur_cookie3

    cur_cookie1 = _cookies.get(cookie_domain,None)
    cur_cookie2 = _cookies.get("."+cookie_domain,None)
    cur_cookie3 = {}
    if cur_cookie1 == None and cur_cookie2 == None:
        cur_cookie3 = {}
    elif cur_cookie1 == None:
        cur_cookie3 = cur_cookie2
    elif cur_cookie2 == None:
        cur_cookie3 = cur_cookie1
    else:
        cur_cookie3 = {}
        for cur_name in cur_cookie1:
            if cur_name not in cur_cookie2:
                cur_cookie3[cur_name] = cur_cookie1[cur_name]
            else:
                if cur_cookie1[cur_name]["expires"] > cur_cookie2[cur_name]["expires"]:
                    cur_cookie3[cur_name] = cur_cookie1[cur_name]
                else:
                    cur_cookie3[cur_name] = cur_cookie2[cur_name]

        for cur_name in cur_cookie2:
            if cur_name not in cur_cookie1:
                cur_cookie3[cur_name] = cur_cookie2[cur_name]
    
    for key_name in cur_cookie3:
        cur_cookie3[key_name] = cur_cookie3[key_name]["value"]
    return cur_cookie3


def format_prompt(messages: list[dict[str, str]], add_special_tokens=False):
    if add_special_tokens or len(messages) > 1:
        formatted = "\n".join(
            ["%s: %s" % ((message["role"]).capitalize(), message["content"]) for message in messages]
        )
        return f"{formatted}\nAssistant:"
    else:
        return str(messages[0]["content"])
    

def get_browser(user_data_dir: str = None):
    from undetected_chromedriver import Chrome
    from platformdirs import user_config_dir

    if not user_data_dir:
        user_data_dir = user_config_dir("free_ai")
        user_data_dir = path.join(user_data_dir, "Default")

    return Chrome(user_data_dir=user_data_dir)