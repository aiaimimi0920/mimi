from free_ai import SingletonType, MessageQueue, Message, MessageLevel, ProcessEngine
from . import chat_protocol_pb2 as sub_protocol_pb2
from modules.protocol_handle import ProtocolHandle
import random
import string
import time
import six
@six.add_metaclass(SingletonType)
class MyChat(object):
    protocol_handle = None
    main = None
    def __init__(self):
        self.protocol_handle = ProtocolHandle()
        from main import Main
        self.main = Main()
        self.register_all_protocol()

    def register_all_protocol(self):
        ## Register all server-side call protocols
        self.protocol_handle.register_protocol_format_with_object(sub_protocol_pb2, self)
    

    ## It is best to call the interface through network calls. 
    ## The interface for network access calls is different from the interface for local calls, and the underlying layer is the same
    ## It should be noted that interfaces called through this method cannot use Steam and will be called in the form of stream=false by default
    async def init_completions(self, data):
        cur_proxy = data.get("proxy",None)
        if cur_proxy:
            if "http" in cur_proxy:
                if cur_proxy["http"] == "" or cur_proxy["http"] == None:
                    del cur_proxy["http"]
            if "https" in cur_proxy:
                if cur_proxy["https"] == "" or cur_proxy["https"] == None:
                    del cur_proxy["https"]
        ProcessEngine().set_proxy(proxy=cur_proxy)
        return True
    
    
    ## Note that stream=false will be forcibly set
    async def create_chat_completion(self, data):
        now_message = Message(stream=False, messages = data["messages"], level=data.get("messages_level",MessageLevel.MEDIUM))
        MessageQueue().push(now_message)
        await now_message.processed.wait()
        response = now_message.response

        completion_id = ''.join(random.choices(string.ascii_letters + string.digits, k=28))
        completion_timestamp = int(time.time())

        response_text = ""

        try:
            async for chunk in response:
                response_text += chunk
        except Exception as e:
            now_message.have_error = True
            pass
        finally:
            if response_text=="":
                now_message.have_error = True
            
            now_message.response_finished.set()
            ## Note using message here_ Body is used as a field, but in reality it is a message
            ## The main reason is that message is a keyword in protobuf, so it cannot be used here_ Body substitution
            ## Both ends have been parsed and replaced, so using message is sufficient for normal use
            return {
                'id': f'chatcmpl-{completion_id}',
                'object': 'chat.completion',
                'created': completion_timestamp,
                'model': "",
                'choices': [
                    {
                        'index': 0,
                        'message_body': {
                            'role': 'assistant',
                            'content': response_text,
                        },
                        'finish_reason': 'stop',
                    }
                ],
                'usage': {
                    'prompt_tokens': None,
                    'completion_tokens': None,
                    'total_tokens': None,
                },
            }

        
    ## The method name has the same name as the sub protocol
    async def S_C_INIT_COMPLETIONS(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_INIT_COMPLETIONS)

    ## The method name has the same name as the sub protocol
    async def  S_C_CREATE_CHAT_COMPLETION(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_CREATE_CHAT_COMPLETION)


    ## The method name has the same name as the sub protocol
    async def C_S_INIT_COMPLETIONS(self, client, syncId ,content):
        answer_data = await self.init_completions(content)
        await self.S_C_INIT_COMPLETIONS(client, syncId, answer_data)

    ## The method name has the same name as the sub protocol
    async def C_S_CREATE_CHAT_COMPLETION(self, client, syncId ,content):
        answer_data = await self.create_chat_completion(content)
        await self.S_C_CREATE_CHAT_COMPLETION(client, syncId, answer_data)

