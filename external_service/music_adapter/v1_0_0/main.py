import getopt
import sys
from singleton import SingletonType
from modules.protocol_handle import ProtocolHandle
from modules.server import Server
from api.musicdl.musicdl import MyMusic
from api.mubert.mubert import MyMubert
import asyncio
import six
@six.add_metaclass(SingletonType)
class Main(object):
    server = None
    protocol_handle = None
    request_timeout = 0.0
    musicdl_node = None
    mubert_node = None

    def __init__(self):
        pass

    def setup(self, port=7798,format="protobuf",request_timeout=0.0):
        self.server = Server(port)
        self.protocol_handle = ProtocolHandle(format)
        self.request_timeout = request_timeout
        self.musicdl_node = MyMusic()
        self.mubert_node = MyMubert()

    async def send_service_request(self, client, syncId, content:dict, caller, timeout:float=0)->dict:
        if timeout <= 0 and self.request_timeout > 0.0:
            timeout=self.request_timeout
        return await Server().send_service_request(client, syncId, content, caller, timeout)


if __name__ == "__main__":
    USE_PORT=7798
    USE_FORMAT="protobuf"
    TIMEOUT=0.0
    opts,args = getopt.getopt(sys.argv[1:],'-p:-f:-t:',['port=','format=',"timeout="])
    for opt_name,opt_value in opts:
        if opt_name in ('-p','--port'):
            USE_PORT = int(opt_value)
        if opt_name in ('-f','--format'):
            USE_FORMAT = str(opt_value)
        if opt_name in ('-t','--timeout'):
            TIMEOUT = float(opt_value)

    main = Main()
    main.setup(port=USE_PORT,format=USE_FORMAT,request_timeout=TIMEOUT)

    ## Do not modify this print, this output is to let the client know that the service has been initialized
    print('service_ready', file=sys.stderr)
    main.server.server.run_forever()

