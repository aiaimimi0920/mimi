from __future__ import annotations

from .base_provider import AsyncGeneratorProvider, format_prompt
from ..self_typing import AsyncGenerator,Union
from aiohttp import ClientSession
from aiohttp.http import WSMsgType
import json
import random
import string
models = {
    'gpt-3.5-turbo-0613': {'id': 'gpt-3.5-turbo-0613', 'name': 'GPT-3.5'},
    'h2oai/h2ogpt-4096-llama2-70b-chat': {'id': 'h2oai/h2ogpt-4096-llama2-70b-chat"', 'name': 'h2oai/h2ogpt-4096-llama2-70b-chat'},
    'h2oai/h2ogpt-4096-llama2-13b-chat': {'id': 'h2oai/h2ogpt-4096-llama2-13b-chat"', 'name': 'h2oai/h2ogpt-4096-llama2-13b-chat'},
    'h2oai/h2ogpt-4096-llama2-7b-chat': {'id': 'h2oai/h2ogpt-4096-llama2-7b-chat"', 'name': 'h2oai/h2ogpt-4096-llama2-7b-chat'},
    'h2oai/h2ogpt-16k-codellama-34b-instruct': {'id': 'h2oai/h2ogpt-16k-codellama-34b-instruct', 'name': 'h2oai/h2ogpt-16k-codellama-34b-instruct'},
}

class H2o(AsyncGeneratorProvider):
    url = "https://gpt.h2o.ai/"
    working = True
    model = "gpt-3.5-turbo-0613"

    @classmethod
    async def create_async_generator(
        cls,
        model: Union[str, None],
        messages: list[dict[str, str]],
        proxies: dict[str, str] = None,
        timeout: int = 90,
        **kwargs
    ) -> AsyncGenerator:
        if not model:
            model = "gpt-3.5-turbo-0613"
        elif model not in models:
            raise ValueError(f"Model is not supported: {model}")
        headers = {"Referer": cls.url + "/"}
        async with ClientSession(
            headers=headers
        ) as session:
            session_hash = generate_random_string(11)  
            # session_hash = "z0nt291he7c"
            async with session.ws_connect(
                "wss://gpt.h2o.ai/queue/join",
                autoping=False,
                timeout=timeout,
                proxy="http://"+proxies["http"] if proxies else None,
            ) as wss:
                cur_str = await wss.receive_str()
                fn_index = 121
                message = json.dumps({"fn_index": fn_index, "session_hash": session_hash})
                await wss.send_str(message)
                cur_str = await wss.receive_str()
                cur_str = await wss.receive_str()
                template_data = {"data":[{"MyData":[None,None,None]},{"headers":"","host":"","username":""},"Submit","Submit"],"event_data":None,"fn_index":fn_index,"session_hash":session_hash}
                await wss.send_str(json.dumps(template_data))

            async with session.ws_connect(
                "wss://gpt.h2o.ai/queue/join",
                autoping=False,
                timeout=timeout,
                proxy="http://"+proxies["http"] if proxies else None,
            ) as wss:
                session_hash = generate_random_string(11)  
                session_hash = "z0nt291he7c"
                cur_str = await wss.receive_str()
                fn_index = 124
                message = json.dumps({"fn_index": fn_index, "session_hash": session_hash})
                await wss.send_str(message)
                cur_str = await wss.receive_str()
                cur_str = await wss.receive_str()
                message_list = [message["content"] for message in  messages]
                message_list2 = []

                for i in range(int(len(message_list)/2)):
                    message_list2.append([message_list[2*i],message_list[2*i+1]])
                
                message_list2.append([message_list[-1],None])
                template_data = {"data":["","","",True,"llama2","{   'PreInput': None,\n    'PreInstruct': '<s>[INST] ',\n    'PreResponse': '[/INST]',\n    'botstr': '[/INST]',\n    'chat_sep': ' ',\n    'chat_turn_sep': ' </s>',\n    'generates_leading_space': False,\n    'humanstr': '[INST]',\n    'promptA': '',\n    'promptB': '',\n    'system_prompt': '',\n    'terminate_response': ['[INST]', '</s>']}",0.2,0.85,70,0,1,1024,0,False,120,1.07,1,False,True,"","","LLM",True,"Query",[],4,True,512,"Relevant",["All"],"Pay attention and remember the information below, which will help to answer the question or imperative after the context ends.\n","According to only the information in the document sources provided within the context above, ","In order to write a concise single-paragraph or bulleted list summary, pay attention to the following text\n","Using only the information in the document sources above, write a condensed and concise summary of key results (preferably as bullet points):\n","",["DocTR","Caption"],["PyMuPDF"],["Unstructured"],".[]",[model],"",False,"[]","[]","reverse_ucurve_sort",256,3100,8192,"split_or_merge","\n\n",0,"auto",False,None,{"langchain_modes":["MyData","LLM","Disabled"],"langchain_mode_paths":{},"langchain_mode_types":{"UserData":"shared","github h2oGPT":"shared","DriverlessAI docs":"shared","wiki":"shared","wiki_full":"","MyData":"personal","LLM":"either","Disabled":"either"}},None,[],[],[],message_list2,[],[]],"event_data":None,"fn_index":fn_index,"session_hash":session_hash}
                await wss.send_str(json.dumps(template_data))
                cur_result_data = ["","","","","","",""]
                async for message in wss:
                    if message.type != WSMsgType.TEXT:
                        continue
                    data = json.loads(message.data)

                    if data["msg"] == "process_starts":
                        continue
                    elif data["msg"] == "process_completed":
                        return 
                    elif data["msg"] == "process_generating":
                        for i in range(len(data["output"]["data"])):
                            cur_data = data["output"]["data"][i]
                            if cur_data != "" and cur_data != None and len(cur_data)>0:
                                if cur_data[-1][-1]!="":
                                    temp_data = cur_data[-1][-1]
                                    if temp_data!=None:
                                        if temp_data!=cur_result_data[i]:
                                            yield temp_data[len(cur_result_data[i]):]
                                            cur_result_data[i] = temp_data


    @classmethod
    @property
    def params(cls):
        params = [
            ("model", "str"),
            ("messages", "list[dict[str, str]]"),
            ("stream", "bool"),
            ("temperature", "float"),
            ("truncate", "int"),
            ("max_new_tokens", "int"),
            ("do_sample", "bool"),
            ("repetition_penalty", "float"),
            ("return_full_text", "bool"),
        ]
        param = ", ".join([": ".join(p) for p in params])
        return f"free_ai.provider.{cls.__name__} supports: ({param})"


    @classmethod
    async def clear_brower(cls):
        pass


def generate_random_string(length):
    characters = string.ascii_lowercase + string.digits
    return ''.join(random.choice(characters) for _ in range(length))