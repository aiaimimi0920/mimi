from __future__ import annotations
import warnings, json
from typing import AsyncGenerator
from playwright.async_api import async_playwright
import playwright_stealth
import undetected_playwright
import time
from requests_toolbelt.multipart.encoder import MultipartEncoder
import urllib.parse

## https://github.com/Granitosaurus/playwright-stealth/blob/fbb50332284751db75728eab6900ebd2b7f56446/playwright_stealth/js/navigator.webdriver.js#L4
custom_playwright_stealth_script = """
if (navigator.webdriver === false) {
    // Post Chrome 89.0.4339.0 and already good
} else if (navigator.webdriver === undefined) {
    // Pre Chrome 89.0.4339.0 and already good
} else {
    // Pre Chrome 88.0.4291.0 and needs patching
    delete Object.getPrototypeOf(navigator).webdriver
}
"""
async def add_stealth(page):
    await page.add_init_script(custom_playwright_stealth_script)
    return True

__EXECUTABLE_PATH__  = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"

PLAYWRIGHT_JS_SCRIPT =  """
fetch("{url}", {{
"headers": {headers},
"referrer": "{referrer}",
"referrerPolicy": "{referrerPolicy}",
"body": {body},
"method": "{method}",
"mode": "{mode}",
"credentials": "{credentials}"
}}).then(res => res.text());
"""

PLAYWRIGHT_STREAM_JS_SCRIPT =  """
(async () => {{
fetch("{url}", {{
"headers": {headers},
"referrer": "{referrer}",
"referrerPolicy": "{referrerPolicy}",
"body": {body},
"method": "{method}",
"mode": "{mode}",
"credentials": "{credentials}"
}}).then(response => {{
  free_ai_response_list_{uuid} = []
  if (!response.ok) {{
    free_ai_response_list_{uuid}.unshift("free_ai_response_list_done");
    throw new Error('Network response was not ok');
  }}
  // Get the readable stream of the response
  const responseStream = response.body;

  // Create a readable stream reader
  const reader = responseStream.getReader();
  // Iterative reading of data
  function readChunk() {{
    return reader.read().then(({{ value, done }}) => {{
      if (done) {{
        free_ai_response_list_{uuid}.unshift(value);
        free_ai_response_list_{uuid}.unshift("free_ai_response_list_done");
        return;
      }}
      // Process the read data (this can be processed as needed)
      free_ai_response_list_{uuid}.unshift(value);
      // Continue reading the next block of data
      readChunk();
    }});
  }}
  // Start reading data
  readChunk();
}})
.catch(error => {{
  console.error('have error:', error);
}});
}})()
"""

class PlaywrightBrowserSession:
    headers = {}
    timeout = 60
    proxies = None
    browser = None
    is_open_url = False
    use_117 = True
    p = None
    page = None

    def __init__(self,headers:dict[str, str]= {}, timeout=60, proxies=None, use_117=True) -> None:
        self.headers = headers
        self.timeout = timeout
        self.proxies = proxies
        self.use_117 = use_117

    @classmethod
    async def with_init_brower(cls, proxies=None,**kwargs):
        self = cls(proxies=proxies,**kwargs)
        if self.browser is None:
            await self.set_proxy(proxies)
        else:
            if self.proxies != proxies:
                await self.set_proxy(proxies)
        return self

    async def clear_browser(self):
        if self.page:
            self.page = None
        if self.browser:
            await self.browser.close()
            self.browser = None
        if self.p:
            await self.p.stop()
            self.p = None
        self.is_open_url = False

    async def init_brower(self):
        await self.clear_browser()
        proxy_data = None
        if self.proxies and self.proxies!=False and (self.proxies.get("http") or self.proxies.get("https")):
            proxy_data = {"server": "http://"+self.proxies.get("http",self.proxies.get("https"))}
        
        ua = None
        if self.use_117:
            ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36'

        self.p = await async_playwright().start()
        self.browser = await self.p.firefox.launch_persistent_context(
                                    user_data_dir = "",
                                    headless=True,
                                    timeout = self.timeout*1000,
                                    proxy=proxy_data,
                                    user_agent=ua,
                                    # executable_path=__EXECUTABLE_PATH__,
                                    extra_http_headers = self.headers,)
        ## https://github.com/QIN2DIM/undetected-playwright
        await undetected_playwright.stealth_async(self.browser)

    async def set_proxy(self,proxies):
        if proxies == self.proxies:
            if self.browser:
                return self.browser
            else:
                await self.init_brower()
                return self.browser
        self.proxies = proxies
        await self.init_brower()
        return self.browser

    async def get_browser(self):
        if self.browser is None:
            await self.init_brower()
        return self.browser

    async def open_url(self, base_url):
        self.page = self.browser.pages[0]
        ## https://github.com/Granitosaurus/playwright-stealth
        await playwright_stealth.stealth_async(self.page)
        await add_stealth(self.page)
        await self.page.goto(base_url)
        result = await self.open_url_initialize()
        if result:
            self.is_open_url = True

    async def open_url_initialize(self):
        return True

    async def get(self, url, params=None, headers={}, data=None,
                          form = None,timeout=None,stream=True, **kwargs):
        response = await self.page.request.get(
            url,
            params = params,
            headers = headers,
            data = data,
            form = form,
            timeout = timeout,
        )
        return response

    async def post(self, url, params=None, headers={}, data=None,
                          form = None,timeout=None,stream=True, **kwargs):
        response = await self.page.request.post(
            url,
            params = params,
            headers = headers,
            data = data,
            form = form,
            timeout = timeout,
        )
        return response

    async def js_fetch(self, url, params=None,data_params=None, headers={}, data=None,
                          form = None,timeout=None,stream=True,referrer = None,referrerPolicy = "strict-origin-when-cross-origin",
                          method = "POST",mode = "cors",credentials = "include",**kwargs):
        result_url = url
        if params!=None:
            result_url = url+"?"+urllib.parse.urlencode(params)
        
        ## Pay attention to data, form, and data_params can only have one value
        result_headers = headers
        result_data = None
        if data_params:
            result_data = urllib.parse.urlencode(data_params)
            result_data = "\""+result_data+"\""
        if form:
            multipart_encoder = MultipartEncoder(fields=form, boundary="----WebKitFormBoundaryF5qR4oA9jWZYBeey")
            form_data = multipart_encoder.to_string()
            result_headers["content-type"] = 'multipart/form-data; boundary={}'.format(multipart_encoder.boundary_value)
            result_data = json.dumps(bytes.decode(form_data))[1:-1]
            result_data = "\""+result_data+"\""
        if data:
            result_data = json.dumps(data)
            result_data = json.dumps({"result": result_data})[12:-2]
            result_data = "\""+result_data+"\""
        
        if result_data == None:
            result_data = "null"

        response_text = ""
        result_headers_str = json.dumps(result_headers)
        if stream == False:
            cur_js_script = PLAYWRIGHT_JS_SCRIPT.format(
                url = result_url,
                headers = result_headers_str,
                referrer = referrer if referrer else self.page.url,
                referrerPolicy = referrerPolicy,
                body = result_data,
                method = method,
                mode = mode,
                credentials = credentials
            )
            ## Note that attaching headers in JavaScript does not work, so it is necessary to manually set it here
            await self.page.set_extra_http_headers(result_headers)
            response_text = await self.page.evaluate(cur_js_script)
        else:
            js_uuid = int(time.time()*1000)
            cur_js_script = PLAYWRIGHT_STREAM_JS_SCRIPT.format(
                url = result_url,
                headers = result_headers_str,
                referrer = referrer if referrer else self.page.url,
                referrerPolicy = referrerPolicy,
                body = result_data,
                method = method,
                mode = mode,
                credentials = credentials,
                uuid = js_uuid
            )
            ## Note that attaching headers in JavaScript does not work, so it is necessary to manually set it here
            await self.page.set_extra_http_headers(result_headers)
            ## If it is streaming, a streaming response should be returned
            await self.page.evaluate(cur_js_script)
            response_text = PlaywrightStreamResponse(self.page, js_uuid)
        return response_text


class PlaywrightStreamResponse:
    def __init__(self, page, uuid):
        self.page = page
        self.queue = []
        self.uuid = uuid

    async def text(self) -> str:
        content = await self.read()
        return content

    
    async def json(self, **kwargs):
        cur_json = await self.read()
        return json.loads(cur_json, **kwargs)

    async def get_one_data(self, start_time):
        try:
            data = await self.page.evaluate("free_ai_response_list_%d.pop().toString();"%self.uuid) 
        except Exception as e:
            data = None
        if data == False:
            return False
        if data is None:
            await self.page.wait_for_timeout(0.2*1000)
            if self.page == None:
                return "free_ai_response_list_done"
            if round(time.time()-start_time, 2)>30:
                return "free_ai_response_list_done"
            cur_one_data = await self.get_one_data(start_time)
            return cur_one_data
        if data == "free_ai_response_list_done":
            return "free_ai_response_list_done"
        self.queue.append(data)
        return [int(one_data) for one_data in data.split(",")]

    async def iter_lines(self, chunk_size=None, decode_unicode=False, delimiter=None) -> AsyncGenerator[bytes]:
        """
        Copied from: https://requests.readthedocs.io/en/latest/_modules/requests/models/
        which is under the License: Apache 2.0
        """
        pending = None
        async for chunk in self.iter_content(
            chunk_size=chunk_size, decode_unicode=decode_unicode
        ):  
            chunk = bytearray(chunk)
            if pending is not None:
                chunk = pending + chunk
            if delimiter:
                lines = chunk.split(delimiter)
            else:
                lines = chunk.splitlines()
            if lines and lines[-1] and chunk and lines[-1][-1] == chunk[-1]:
                pending = lines.pop()
            else:
                pending = None

            for line in lines:
                yield line

        if pending is not None:
            yield pending

    async def iter_content(self, chunk_size=None, decode_unicode=False) -> As:
        if chunk_size:
            warnings.warn("chunk_size is ignored, there is no way to tell curl that.")
        if decode_unicode:
            raise NotImplementedError()
        while True:
            start_time = time.time()
            chunk = await self.get_one_data(start_time = start_time)
            if chunk == False:
                return
            if chunk == "free_ai_response_list_done":
                return
            yield chunk

    async def read(self) -> str:
        return "".join([bytes(chunk).decode() async for chunk in self.iter_content()])
    
