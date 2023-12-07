import getopt
import sys
from modules.protocol_handle import ProtocolHandle
from modules.server import Server, get_free_port
from api.chat.chat import MyChat
import six
import asyncio
import uvicorn
from multiprocessing import freeze_support,Manager
import sys
import os
from free_ai import ProcessEngine, SingletonType
import threading

@six.add_metaclass(SingletonType)
class Main(object):
    server = None
    protocol_handle = None
    request_timeout = 0.0
    chat_node = None
    def __init__(self):
        pass

    def setup(self, port=9509,format="protobuf",request_timeout=0.0):
        self.server = Server(port)
        self.protocol_handle = ProtocolHandle(format)
        self.request_timeout = request_timeout
        self.chat_node = MyChat()

    async def send_service_request(self, client, syncId, content:dict, caller, timeout:float=0)->dict:
        if timeout <= 0 and self.request_timeout > 0.0:
            timeout=self.request_timeout
        return await Server().send_service_request(client, syncId, content, caller, timeout)

def run_local_ai_server(port):
    # loop = asyncio.get_event_loop()
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    ## Not starting reload is due to a conflict between FastAPI and Playwright
    ## https://github.com/microsoft/playwright-python/issues/1099#issuecomment-1323131861    
    uvicorn.run(app="free_ai.server.app:app",port = port, reload=False,timeout_keep_alive=300)

def init_chat_completion(proxy):
    # loop = asyncio.get_event_loop()
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    ProcessEngine(proxy=proxy)
    # loop.run_until_complete()

if __name__ == "__main__":
    print("need_kill_pid %d"%os.getpid(), file=sys.stderr)
    freeze_support()
    manager = Manager()
    USE_PORT=9509
    USE_FORMAT="protobuf"
    TIMEOUT=0.0
    HTTP_PROXY=None
    HTTPS_PROXY=None

    opts,args = getopt.getopt(sys.argv[1:],'-p:-f:-t:',['port=','format=',"timeout=","http=","https="])
    for opt_name,opt_value in opts:
        if opt_name in ('-p','--port'):
            USE_PORT = int(opt_value)
        if opt_name in ('-f','--format'):
            USE_FORMAT = str(opt_value)
        if opt_name in ('-t','--timeout'):
            TIMEOUT = float(opt_value)
        if opt_name in ("--http"):
            HTTP_PROXY = str(opt_value)
        if opt_name in ('--https'):
            HTTPS_PROXY = str(opt_value)

    main = Main()
    main.setup(port=USE_PORT,format=USE_FORMAT,request_timeout=TIMEOUT)

    local_ai_port = get_free_port()

    uvicorn_process = threading.Thread(target=run_local_ai_server,args=(local_ai_port,), daemon = True)
    print("ai port use %d"%local_ai_port, file=sys.stderr)
    uvicorn_process.start()

    proxy = None
    if HTTP_PROXY == "":
        HTTP_PROXY = None
    if HTTPS_PROXY == "":
        HTTPS_PROXY = None
    if HTTP_PROXY!=None or HTTPS_PROXY!=None:
        if HTTP_PROXY==None:
            HTTP_PROXY = HTTPS_PROXY
        if HTTPS_PROXY==None:
            HTTPS_PROXY = HTTP_PROXY
        proxy = {"http":HTTP_PROXY,"https":HTTPS_PROXY}
    else:
        proxy = None
    
    p = threading.Thread(target=init_chat_completion, args=(proxy,), daemon = True)
    p.start()

    ## Do not modify this print, this output is to let the client know that the service has been initialized
    print('service_ready', file=sys.stderr)
    main.server.server.run_forever()


