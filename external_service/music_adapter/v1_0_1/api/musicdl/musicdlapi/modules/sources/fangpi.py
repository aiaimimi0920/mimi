'''
Function:
    fangpi音乐下载: https://www.fangpi.net/
Author:
    Charles
微信公众号:
    Charles的皮卡丘
'''
import re
import time
import requests
from .base import Base
from ..utils import seconds2hms, filterBadCharacter


'''5SING音乐下载类'''
class Fangpi(Base):
    def __init__(self, config, logger_handle, **kwargs):
        super(Fangpi, self).__init__(config, logger_handle, **kwargs)
        self.source = 'fangpi'
        self.__initialize()
    '''歌曲搜索'''
    def search(self, keyword, disable_print=True):
        if not disable_print: self.logger_handle.info('正在%s中搜索 >>>> %s' % (self.source, keyword))
        cfg = self.config.copy()
        response = self.session.get(self.search_url+keyword, headers=self.headers)
        response.encoding = 'uft-8'
        result_info = []

        all_items = re.finditer(r'<div class="col-5 col-content">(.*?)<\/div>', response.text,re.M|re.S)
        
        for item in all_items:
            searchObj = re.search( r'href="(.*?)".*?"_blank">(.*?)<\/a>', item.group(1), re.M|re.S)
            href = searchObj.group(1)
            music_name = searchObj.group(2)
            result_info.append({
                "href":href.strip(),
                "songName":music_name.strip()
            })
        
        all_items = re.finditer(r'<div class="text-success col-4 col-content">(.*?)<\/div>', response.text,re.M|re.S)
        
        i = 0
        for item in all_items:
            result_info[i]["singer"] = item.group(1).strip()
            i = i + 1

        all_items = result_info
        songinfos = []
        for item in all_items:            
            response = self.session.get(self.songinfo_url+item["href"], headers=self.headers)
            response.encoding = 'uft-8'
            searchObj = re.search( r"\$\('#btn-download-mp3'\)\.attr\('href', '(.*?)'", response.text, re.M|re.S)
            item["download_url"] = searchObj.group(1).strip()
            searchObj = re.search( r"music/(.*)", item["href"], re.M|re.S)
            item["songId"] = searchObj.group(1).strip()
            item["lyric_url"] = self.lyric_url+item["songId"]

            searchObj = re.search( r"lrc: '(.*?)'", response.text, re.M|re.S)
            item["lyric"] = str(searchObj.group(1).strip())
            
            duration = '-:-:-'
            filesize = '-MB'
            songinfo = {
                'source': self.source,
                'songid': str(item['songId']),
                'singers': filterBadCharacter(item.get('singer', '-')),
                'album': filterBadCharacter('-'),
                'songname': filterBadCharacter(item.get('songName', '-')),
                'savedir': cfg['savedir'],
                'savename': filterBadCharacter(item.get('songName', f'{keyword}_{int(time.time())}')),
                'download_url': item["download_url"],
                'lyric': item["lyric"],
                'filesize': filesize,
                'ext': 'mp3',
                'duration': duration
            }
            songinfos.append(songinfo)
            if len(songinfos) == cfg['search_size_per_source']: break
        return songinfos
    '''初始化'''
    def __initialize(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36',
        }
        self.search_url = 'https://www.fangpi.net/s/'
        self.songinfo_url = 'https://www.fangpi.net'
        self.lyric_url = 'https://www.fangpi.net/download/lrc/'