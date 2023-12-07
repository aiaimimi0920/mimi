extends ConversationMessageAPI
class_name AudioConversationMessage

func get_MessageType():
	return "Audio"

var audio_id
var audio_url
var audio_base64
var audio_ref_path

var audio_name
var audio_singer
var audio_duration

var audio_lyric_url
var audio_lyric_base64
var audio_lyric_ref_path

func reload_message():
	super.reload_message()
	if conversation_message_data:
		audio_id = conversation_message_data.get("audio_id",null)
		audio_url = conversation_message_data.get("audio_url",null)
		audio_base64 = conversation_message_data.get("audio_base64",null)
		audio_ref_path = conversation_message_data.get("audio_ref_path",null)
		audio_name = conversation_message_data.get("audio_name",null)
		audio_singer = conversation_message_data.get("audio_singer",null)
		audio_duration = conversation_message_data.get("audio_duration",null)
		audio_lyric_url = conversation_message_data.get("audio_lyric_url",null)
		audio_lyric_base64 = conversation_message_data.get("audio_lyric_base64",null)
		audio_lyric_ref_path = conversation_message_data.get("audio_lyric_ref_path",null)
	return self
	
func get_as_text()->String:
	return "[音乐"+ audio_name +"]"

func get_audio_path():
	if audio_ref_path:
		if FileAccess.file_exists(audio_ref_path):
			return audio_ref_path
	var cur_audio_path = GlobalManager.file_path.path_join(str(audio_id))
	if FileAccess.file_exists(cur_audio_path):
		return cur_audio_path
	if audio_url:
		cur_audio_path = GlobalManager.file_path.path_join(audio_url)
		## TODO:If there are no files available locally, you can try downloading them from the network
		if FileAccess.file_exists(cur_audio_path):
			return cur_audio_path
	return ""

func get_audio_lyric_path():
	if audio_lyric_ref_path:
		if FileAccess.file_exists(audio_lyric_ref_path):
			return audio_lyric_ref_path
	var cur_audio_path = GlobalManager.file_path.path_join("lyric-" + str(audio_id))
	if FileAccess.file_exists(cur_audio_path):
		return cur_audio_path
	if audio_lyric_url:
		cur_audio_path = GlobalManager.file_path.path_join(audio_lyric_url)
		## TODO:If there are no files available locally, you can try downloading them from the network
		if FileAccess.file_exists(cur_audio_path):
			return cur_audio_path
	return ""

## It will be returned in buffer format. If you need to customize the return, use get_image_path
func get_audio_buffer_data()->PackedByteArray:
	if audio_base64!=null and audio_base64!="":
		return Marshalls.base64_to_raw(audio_base64)
	var file_path = get_audio_path()
	if file_path != "":
		var file = FileAccess.open(file_path,FileAccess.READ)
		var content = file.get_buffer(file.get_length())
		return content
	return PackedByteArray()


## It will be returned in buffer format. If you need to customize the return, use get_image_path
func get_audio_lyric_buffer_data()->PackedByteArray:
	if audio_lyric_base64!=null and audio_lyric_base64!="":
		return Marshalls.base64_to_raw(audio_lyric_base64)
	var file_path = get_audio_lyric_path()
	if file_path != "":
		var file = FileAccess.open(file_path,FileAccess.READ)
		var content = file.get_buffer(file.get_length())
		return content
	return PackedByteArray()

func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["audio_id"] = audio_id
	all_data["data"]["audio_url"] = audio_url
	all_data["data"]["audio_base64"] = audio_base64
	all_data["data"]["audio_ref_path"] = audio_ref_path
	all_data["data"]["audio_name"] = audio_name
	all_data["data"]["audio_singer"] = audio_singer
	all_data["data"]["audio_duration"] = audio_duration
	all_data["data"]["audio_lyric_url"] = audio_lyric_url
	all_data["data"]["audio_lyric_base64"] = audio_lyric_base64
	all_data["data"]["audio_lyric_ref_path"] = audio_lyric_ref_path
	return all_data


func create_by_audio(audio:AudioStream):
	if is_instance_valid(audio):
		if audio is AudioStreamMP3:
			var f_path:String = GlobalManager.file_path.path_join("audio-"+Time.get_datetime_string_from_system().replace(":","-")+"-"+str(randi())+".mp3")
			var file = FileAccess.open(f_path,FileAccess.WRITE)
			if file:
				file.store_buffer(audio.data)
				audio_ref_path = f_path.simplify_path()
				Logger.info("Successfully cached audio instance to file and constructed as audio message: %s"% f_path)
				return self
			else:
				Logger.error("Unable to cache AudioStream audio instance to file% s, therefore it cannot be constructed as an audio message. Please check if the path or permissions are correct!"% f_path)
		elif audio is AudioStreamWAV:
			var f_path:String = GlobalManager.file_path.path_join("audio-"+Time.get_datetime_string_from_system().replace(":","-")+"-"+str(randi())+".wav")
			var err:int = audio.save_to_wav(f_path)
			if !err:
				audio_ref_path = f_path.simplify_path()
				Logger.info("Successfully cached audio instance to file and constructed as audio message: %s"% f_path)
				return self
			else:
				Logger.error("Unable to cache AudioStream audio instance to file% s, therefore it cannot be constructed as an audio message. Please check if the path or permissions are correct!"% f_path)
		elif audio is AudioStreamOggVorbis:
			var f_path:String = GlobalManager.file_path.path_join("audio-"+Time.get_datetime_string_from_system().replace(":","-")+"-"+str(randi())+".ogg")
			var file = FileAccess.open(f_path,FileAccess.WRITE)
			if file:
				file.store_buffer(audio.packet_sequence.packet_data)
				audio_ref_path = f_path.simplify_path()
				Logger.info("Successfully cached audio instance to file and constructed as audio message: %s"% f_path)
				return self
			else:
				Logger.error("Unable to cache AudioStream audio instance to file% s, therefore it cannot be constructed as an audio message. Please check if the path or permissions are correct!"% f_path)
				
	else:
		Logger.error("The passed in instance is invalid, therefore the specified audio instance cannot be constructed as an audio message!")
	return null

var download_start = false
## Download resources from the URL
func begin_download():
	if download_start == true:
		return
	download_start = true
	if audio_url:
		audio_ref_path = await base_begin_download(audio_url)
		audio_ref_path = audio_ref_path.simplify_path()
	if audio_lyric_url:
		audio_lyric_ref_path = await base_begin_download(audio_lyric_url)
	download_start = false
	emit_signal("download_finish")
	
