from singleton import SingletonType
import soundfile as sf
import six
from .mubertapi import MubertAsync
from . import mubert_protocol_pb2 as sub_protocol_pb2
from modules.protocol_handle import ProtocolHandle

@six.add_metaclass(SingletonType)
class MyMubert(object):
    protocol_handle = None
    main = None
    mubert = None
    def __init__(self):
        self.protocol_handle = ProtocolHandle()
        from main import Main
        self.main = Main()
        self.register_all_protocol()

    def register_all_protocol(self):
        ## Register all server-side call protocols
        self.protocol_handle.register_protocol_format_with_object(sub_protocol_pb2, self)
        

    async def create_ai_music(self,data):
        m_poxies = {}
        if data.get("proxiesHttp","")=="" or data["proxiesHttp"]==None:
            pass
        else:
            m_poxies["http"] = "http://"+data["proxiesHttp"]

        if data.get("proxiesHttps","")=="" or data["proxiesHttps"]==None:
            pass
        else:
            m_poxies["https"] = "http://"+data["proxiesHttps"]
        if len(m_poxies)==0:
            m_poxies = None
        browser = None
        if self.mubert is None:
            self.mubert = MubertAsync(proxies=m_poxies, browser=browser)
            self.mubert.reset_conversation()

        url, save_file_path = await self.mubert.create_music(data.get("tags",""), data.get("duration",60), data.get("saveDir",""))

        return [url, save_file_path]



    ## The method name has the same name as the sub protocol
    async def S_C_CREATE_MUSIC(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_CREATE_MUSIC)


    ## The method name has the same name as the sub protocol
    async def C_S_CREATE_MUSIC(self, client, syncId, content):
        url, save_file_path = await self.create_ai_music(content)
        data = {}
        data["filePath"] = save_file_path
        data["sourceUrl"] = url
        await self.S_C_CREATE_MUSIC(client, syncId, data)
