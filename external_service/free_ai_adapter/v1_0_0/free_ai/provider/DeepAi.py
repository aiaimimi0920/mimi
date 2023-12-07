from __future__ import annotations

from ..requests import PlaywrightBrowserSession
from ..singleton import SingletonType
from .base_provider import AsyncGeneratorProvider
from ..self_typing import AsyncGenerator,Union
import json
import js2py
import random

class DeepAi(AsyncGeneratorProvider):
    url                   = 'https://deepai.org'
    supports_stream       = False
    working               = True
    supports_gpt_35_turbo = True
    _user_agent = None
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
        model = model if model else "gpt-3.5-turbo"
        headers = {
            "Origin"             : cls.url,
            "Referer"            : cls.url + "/",
            "content-type": "application/json",
        }
        session =  await DeepAiBrowserSession.with_init_brower(headers=headers, timeout=timeout, proxies=proxies)

        if session.is_open_url == False:
            await session.open_url(cls.url)
            cls._user_agent = await session.page.evaluate("navigator.userAgent")

        ## Use a new key every time, so it won't be recognized by the robot
        api_key = get_api_key(cls._user_agent)
        headers["api-key"] = api_key
        payload = {"chat_style": "chat", "chatHistory": json.dumps(messages)}
        fill = "ing_is"
        fill = f"ack{fill}_a_crim"
        response = await session.js_fetch(f"https://api.deepai.org/h{fill}e", form=payload, headers=headers,credentials="omit",stream=stream,method="POST")
        if response.startswith("<!DOCTYPE html>") or response.startswith("<!doctype html>") or response.startswith('{"status": "anonymous try it exceeded"}'):
          RuntimeError("DeepAi: 403 Forbidden")
          return
        yield response

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
        await DeepAiBrowserSession().clear_browser() 

def get_api_key(user_agent: str):
    ## This JavaScript code is directly found on the Deepai official website. If you want to change the authentication, you can change this method
    js_code = """
g = (function () {
  for (var p = [], r = 0; 64 > r; )
    p[r] = 0 | (4294967296 * Math.sin(++r % Math.PI));
  return function (z) {
    var B,
      G,
      H,
      ca = [(B = 1732584193), (G = 4023233417), ~B, ~G],
      X = [],
      x = unescape(encodeURI(z)) + "\u0080",
      v = x.length;
    z = (--v / 4 + 2) | 15;
    for (X[--z] = 8 * v; ~v; )
      X[v >> 2] |= x.charCodeAt(v) << (8 * v--);
    for (r = x = 0; r < z; r += 16) {
      for (
        v = ca;
        64 > x;
        v = [
          (H = v[3]),
          B +
            (((H =
              v[0] +
              [
                (B & G) | (~B & H),
                (H & B) | (~H & G),
                B ^ G ^ H,
                G ^ (B | ~H),
              ][(v = x >> 4)] +
              p[x] +
              ~~X[r | ([x, 5 * x + 1, 3 * x + 5, 7 * x][v] & 15)]) <<
              (v = [
                7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15,
                21,
              ][4 * v + (x++ % 4)])) |
              (H >>> -v)),
          B,
          G,
        ]
      )
        (B = v[1] | 0), (G = v[2]);
      for (x = 4; x; ) ca[--x] += v[x];
    }
    for (z = ""; 32 > x; )
      z += ((ca[x >> 3] >> (4 * (1 ^ x++))) & 15).toString(16);
    return z.split("").reverse().join("");
  };
})();
"""
    g = js2py.eval_js(js_code)
    e = str(round(1E11 * random.random()))
    return f"tryit-{e}-" + g(user_agent + g(user_agent + g(user_agent + e + "x")))


import six
@six.add_metaclass(SingletonType)
class DeepAiBrowserSession(PlaywrightBrowserSession):
    pass
