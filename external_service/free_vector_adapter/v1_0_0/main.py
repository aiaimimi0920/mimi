import getopt
import sys
from modules.protocol_handle import ProtocolHandle
from modules.server import Server, get_free_port
from api.chroma.chroma import MyChroma
import six
from multiprocessing import freeze_support
import sys
import os
from modules.singleton import SingletonType
import threading

@six.add_metaclass(SingletonType)
class Main(object):
    server = None
    protocol_handle = None
    request_timeout = 0.0
    chroma_node = None
    def __init__(self):
        pass

    def setup(self, port=9509,format="protobuf",request_timeout=0.0,file_path="./persistent_data"):
        self.server = Server(port)
        self.protocol_handle = ProtocolHandle(format)
        self.request_timeout = request_timeout
        self.chroma_node = MyChroma(file_path=file_path)


    async def send_service_request(self, client, syncId, content:dict, caller, timeout:float=0)->dict:
        if timeout <= 0 and self.request_timeout > 0.0:
            timeout=self.request_timeout
        return await Server().send_service_request(client, syncId, content, caller, timeout)

if __name__ == "__main__":
    print("need_kill_pid %d"%os.getpid(), file=sys.stderr)
    freeze_support()
    USE_PORT=9519
    USE_FORMAT="protobuf"
    TIMEOUT=0.0
    FILE_PATH="./persistent_data"

    opts,args = getopt.getopt(sys.argv[1:],'-p:-f:-t:',['port=','format=',"timeout=","path="])
    for opt_name,opt_value in opts:
        if opt_name in ('-p','--port'):
            USE_PORT = int(opt_value)
        if opt_name in ('-f','--format'):
            USE_FORMAT = str(opt_value)
        if opt_name in ('-t','--timeout'):
            TIMEOUT = float(opt_value)
        if opt_name in ('--path'):
            FILE_PATH = str(opt_value)

    main = Main()
    main.setup(port=USE_PORT,format=USE_FORMAT,request_timeout=TIMEOUT,file_path=FILE_PATH)

    ## Do not modify this print, this output is to let the client know that the service has been initialized
    print('service_ready', file=sys.stderr)
    main.server.server.run_forever()


