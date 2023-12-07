from websocket_server import WebsocketServer
import logging
from .singleton import SingletonType
from .protocol_handle import ProtocolHandle
import os
get_random_id = lambda: int.from_bytes(os.urandom(8), 'little')
import six
import sys
import base64
import asyncio

import socket
def check_port(address, port):
    ## Create socket object
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    ## Check if the port is occupied
    result = sock.connect_ex((address, port))
    # Close socket
    sock.close()
    return result == 0

def get_free_port():  
    sock = socket.socket()
    sock.bind(('', 0))
    ip, port = sock.getsockname()
    sock.close()
    return port

@six.add_metaclass(SingletonType)
class Server(object):
    server = None
    processing_command = {}
    protocol_handle = None
    def __init__(self, port=9002):
        if check_port("127.0.0.1",port):
            new_port = get_free_port()
            ## Do not modify this print, this output is to let the client know that the service has changed the port
            print("port is used, use new port %d"%new_port, file=sys.stderr,flush=True)
            port = new_port
        self.server = WebsocketServer(port=port, loglevel=logging.INFO)
        self.server.set_fn_new_client(self.new_client)
        self.server.set_fn_message_received(self._on_data)
        self.server.set_fn_client_left(self.client_left)
        self.protocol_handle = ProtocolHandle()
        self.processing_command = {}

    # def shutdown_gracefully(self,):
    #     self.server.shutdown_gracefully()

    def new_client(self, client, server):
        print("Client(%d) connected" % client['id'],flush=True)

    def client_left(self, client, server):
        # self.shutdown_gracefully()
        print("Client(%d) disconnected" % client['id'],flush=True)
        

    def _on_data(self, client, server, message):
        message_data = self.protocol_handle.parse_data(base64.b64decode(message))
        data = message_data[0]
        callable = message_data[1]
        if ("server_syncId" in data) and data["server_syncId"] != None and data["server_syncId"] != "":
            server_syncId = int(data["server_syncId"])
            if server_syncId!=-1 and server_syncId in self.processing_command:
                self._parse_command_result(data)
        print("Server received message: ",data,file=sys.stderr,flush=True)

        if callable:
            asyncio.run(callable(client, data.get("syncId",-1), data["content"]))
            


    def _parse_command_result(self,result:dict):
        server_syncId:int = int(result["server_syncId"])
        if server_syncId!=-1 and server_syncId in self.processing_command:
            cmd:RequestInstance = self.processing_command[server_syncId]
            cmd.result = result["content"]
            cmd.future.set_result(True)
        

    async def send_service_request(self, client, syncId, content:dict, caller,timeout:float)->dict:
        if self.is_client_connected(client) == False:
            return False
        server_syncId:int = get_random_id()
        while (server_syncId==-1 or server_syncId in self.processing_command):
            server_syncId = int(get_random_id())
        data_array = self.protocol_handle.stringify(server_syncId, syncId, content, caller)
        data = data_array[0]
        data_dict = data_array[1]
        cmd:RequestInstance = RequestInstance(data_dict,server_syncId)

        self.processing_command[server_syncId] = cmd
        print("Server sends a message: ",data_dict,file=sys.stderr,flush=True)
        self.server.send_message(client, base64.b64encode(data))
        
        try:
            ret = await asyncio.wait_for(cmd.future, timeout)
        except asyncio.TimeoutError:
            pass
        self.processing_command.pop(server_syncId, None)
        return cmd.get_result()

    def is_client_connected(self, client):
        return client in self.server.clients


class RequestInstance(object):
    request:dict = {}
    result:dict = {}
    server_syncId:int = -1
    future = None

    def get_result(self)->dict:
        return self.result

    def __init__(self,request,server_syncId):
        self.request = request
        self.server_syncId = server_syncId
        self.future = asyncio.get_running_loop().create_future()

