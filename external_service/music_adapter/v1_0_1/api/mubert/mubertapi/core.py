import json
from .constants import BASE_URL,ANSWER_POST_SCRIPT,MUSIC_URL
import undetected_chromedriver as uc
from selenium.webdriver.common.proxy import Proxy, ProxyType
import requests
import os
import time
import re

class Mubert:
    """
    Mubert class for interacting with the Mubert API.
    """
    def __init__(
        self,
        timeout: int = 20,
        proxies: dict = None,
        browser: uc.Chrome = None,
    ):
        """
        Initialize the Mubert instance.

        Args:
            timeout (int): Request timeout in seconds.
            proxies (dict): Proxy configuration for requests.
            browser (uc.Chrome): Requests session object.
        """
        self.proxies = proxies
        self.timeout = timeout
        self.browser = self._get_browser(browser)
        self.initialized = False
        self.track_type = "track"


    def _get_browser(self, browser):
        """
        Get the browser object.

        Args:
            browser (uc.Chrome): browser object.

        Returns:
            uc.Chrome: The browser object.
        """
        if browser is None:
            prox = Proxy()
            prox.proxy_type = ProxyType.MANUAL
            prox.http_proxy = self.proxies.get("http",None) if self.proxies else None
            prox.https_proxy = self.proxies.get("https",None) if self.proxies else None
            capabilities = prox.to_capabilities()
            new_browser = uc.Chrome(headless=True,use_subprocess=True,desired_capabilities=capabilities)
            return new_browser
        else:
            return browser

    def start_answer(self):
        if self.initialized:
            return
        self.browser.get(BASE_URL)
        self.initialized = True

    def reset_conversation(self):
        self.initialized = False

    def create_music(self, input_text: str, duration:int, saveDir:str) -> str:
        self.start_answer()
        data = {"params":{"text": input_text,"duration":duration,"track_type":self.track_type}}
        data = json.dumps(data)
        resp = json.loads(self.browser.execute_script(ANSWER_POST_SCRIPT, data))
        url = MUSIC_URL.format(resp["data"]["session_id"])

        rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'
        save_name = re.sub(rstr, "_", input_text) 

        save_name='_'.join(save_name.split())
        save_path = self.download_file(url,saveDir,save_name)
        return [url,save_path]

    def download_file(self, url, save_dir, save_name):
        save_path = os.path.join(save_dir, f"{save_name}.mp3")
        count = 0
        while True:
            with requests.get(url, stream=True) as r:
                try:
                    count+=1
                    r.raise_for_status()
                except:
                    if count>20:
                        return ""
                    time.sleep(3)
                    continue
                with open(save_path, 'wb') as f:
                    for chunk in r.iter_content(chunk_size=8192): 
                        # If you have chunk encoded response uncomment if
                        # and set chunk_size parameter to None.
                        #if chunk: 
                        f.write(chunk)
                break
        return save_path



