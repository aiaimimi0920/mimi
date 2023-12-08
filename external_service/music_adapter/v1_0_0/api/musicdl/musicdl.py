from singleton import SingletonType
import soundfile as sf
from . import musicdl_protocol_pb2 as sub_protocol_pb2
from modules.protocol_handle import ProtocolHandle
import six
import asyncio
from .musicdlapi import musicdl
import os
import sys
import random
@six.add_metaclass(SingletonType)
class MyMusic(object):
    songMap = {}
    urlMap = {}

    protocol_handle = None
    main = None

    def __init__(self):
        self.protocol_handle = ProtocolHandle()
        from main import Main
        self.main = Main()
        self.register_all_protocol()

        self.songMap = {}
        self.urlMap = {}

    def register_all_protocol(self):
        ## Register all server-side call protocols
        self.protocol_handle.register_protocol_format_with_object(sub_protocol_pb2, self)
        

    def create_musicdl(self,data):
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
            m_poxies = {}
            
        m_saveDir = "downloaded"
        if data.get("saveDir","")=="" or data["saveDir"]==None:
            pass
        else:
            m_saveDir = data["saveDir"]

        config = {'logfilepath': 'musicdl.log', 'savedir': m_saveDir, 'search_size_per_source': 10, 'proxies': m_poxies}
        music = musicdl.musicdl(config=config)

        return music

    def search_music(self, data, music = None):
        if music == None:
            music = self.create_musicdl(data)
        search_keyword = data.get("songName","") + " " + data.get("singer","")
        search_keyword = search_keyword.strip()
        target_srcs = [
                'kugou', 'qqmusic', 'qianqian', 'fivesing',
                'netease', 'joox', 'yiting',"fangpi",
            ]
        search_results = music.search(search_keyword, target_srcs)

        songinfos = []
        for key, values in search_results.items():
            for value in values:
                songinfos.append({
                    "songName": value['songname'],
                    "singer": value['singers'],
                    "downloadUrl": value['download_url'],
                    "source": value['source'],
                    "duration": value['duration'],
                })
                self.songMap[(value['songname']+"_"+value['singers']).strip()] = value
                self.urlMap[(value['download_url']).strip()] = value
        return songinfos

    def download_music(self, data):
        music = self.create_musicdl(data)
        song_key = (data.get("songName","") + "_" + data.get("singer","")).strip()
        url_key = data.get("downloadUrl","").strip()
        download_info = None

        if self.urlMap.get(url_key,None)!=None:
            download_info = self.urlMap[url_key]
        elif self.songMap.get(song_key,None)!=None:
            download_info = self.songMap[song_key]

        if data.get("just_mp3",True) and download_info:
            if not download_info.get("downloadUrl","").endswith(".mp3"):
                download_info = None

        if download_info == None:
            ## need auto search
            songinfos = self.search_music(data, music)
            if data.get("just_mp3",False):
                songinfos = [info for info in songinfos if (info.get("ext","")=="mp3" or info.get("downloadUrl","").endswith(".mp3"))]
            
            random.shuffle(songinfos)
            for info in songinfos:
                download_info = self.urlMap[info["downloadUrl"]]
                if download_info["source"]=="fangpi":
                    music.download([download_info])
                    return download_info
            
            for info in songinfos:
                download_info = self.urlMap[info["downloadUrl"]]
                music.download([download_info])
                return download_info
            return None
        music.download([download_info])
        return download_info

    ## The method name has the same name as the sub protocol
    async def S_C_SEARCH_MUSIC(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_SEARCH_MUSIC)


    ## The method name has the same name as the sub protocol
    async def C_S_SEARCH_MUSIC(self, client, syncId, content):
        core = asyncio.to_thread(self.search_music, content)
        search_data = await core
        await self.S_C_SEARCH_MUSIC(client, syncId, {"musicInfos":search_data})


    ## The method name has the same name as the sub protocol
    async def S_C_DOWNLOAD_MUSIC(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_DOWNLOAD_MUSIC)


    ## The method name has the same name as the sub protocol
    async def C_S_DOWNLOAD_MUSIC(self, client, syncId, content):
        core = asyncio.to_thread(self.download_music, content)
        download_info = await core
        data = {}
        if download_info != None:
            savepath = os.path.join(download_info['savedir'], f"{download_info['savename']}.{download_info['ext']}")
            lastsavepath = os.path.join(download_info['savedir'], f"{download_info['savename']}.mp3")
            data["sourceUrl"] = download_info["download_url"]
            data["filePath"] = lastsavepath
            if savepath!=lastsavepath:
                try:
                    read_data, samplerate = sf.read(savepath)
                    sf.write(lastsavepath, read_data, samplerate, format="mp3")
                    os.remove(savepath)
                except Exception as e:
                    if content.get("just_mp3",False):
                        await self.S_C_DOWNLOAD_MUSIC(client, syncId, {})
                        return 
                    content["just_mp3"] = True 
                    return await self.C_S_DOWNLOAD_MUSIC(client, syncId, content)
            # data["audio64"] = base64.b64encode(fix_data_output.getvalue()).decode()
            data["songName"] = download_info.get("songname","unknown")
            data["singer"] = download_info.get("singers","unknown")
            data["duration"] = download_info.get("duration","0:0:0")
        # fix_data_output.close()
        await self.S_C_DOWNLOAD_MUSIC(client, syncId, data)
