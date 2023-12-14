extends PluginAPI 

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func get_music_adapter():
	var music_adapter = await PluginManager.get_plugin_instance_by_script_name("music_adapter")
	return music_adapter

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"music_bot","mimi",plugin_version,
		"Provide music search, music download, and music generation services","plugin",{"music_adapter":["v1_0_1"]})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)

var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	add_child(service_config_manager,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	pass

func _ready()->void:
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass
	
## @API
## @brief: Retrieve songs based on "song name" and "singer name"
## @param: [songName] - song name
## @param: [singer] - singer name
func search_music(songName:String="", singer:String=""):
	var music_adapter = await get_music_adapter()
	var answer = await music_adapter.search_music(songName, singer)
	var free_ai_adapter = await PluginManager.get_plugin_instance_by_script_name("free_ai_adapter") 
	var cur_chat =  [
		{
			"content": "You are a helpful assistant.",
			"role": "system"
		},
	]
	var cur_content = "returns a best match music information for matching singer:{singer} and song name:{songName} from {all_data},Prioritize matching song information that matches both the song name and the singer name perfectly. Do not include any explanations, only provide a RFC8259 compliant JSON response following this format without deviation".format({"singer":singer,"songName":songName,"all_data":JSON.stringify(answer["musicInfos"])})
	cur_chat.append({
		"content": cur_content,
		"role": "user"
	  })
	var result = null
	var result_json = {}
	while true:		
		result = null
		result = await free_ai_adapter.create_chat_completion(false,cur_chat,true)
		if typeof(result) == TYPE_DICTIONARY:
			if result.is_empty():
				continue
			var cur_result = result["choices"][0]["message"].get("content","")
			if cur_result == "":
				continue
			result_json = PluginManager.get_json_from_chat_cmd(cur_result)
			break
	var cur_data = {"is_bot":true}

	var sourceUrl = result_json["downloadUrl"]
	var cur_songName = result_json["songName"]
	var cur_singer = result_json["singer"]
	var cur_duration = result_json["duration"]
	var time_array = cur_duration.split(":")
	if time_array.size()==3:
		cur_duration = int(time_array[0])*60*60+int(time_array[1])*60+int(time_array[2])
	else:
		cur_duration = 0
	
	cur_data["audio_name"]= cur_songName
	cur_data["audio_singer"]= cur_singer
	cur_data["audio_url"]= sourceUrl
	cur_data["audio_duration"]= cur_duration

	var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":JSON.stringify(cur_data),"is_bot":true},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
	return cur_data


## @API
## @brief: Download songs based on "song name", "singer name", and "download address"
## @param: [songName] - song name
## @param: [singer] - singer name
## @param: [downloadUrl] - download address
func download_music(songName:String="", singer:String="", downloadUrl:String=""):
	var music_adapter = await get_music_adapter()
	if downloadUrl == "":
		var search_answer = await search_music(songName, singer)
		downloadUrl = search_answer["audio_url"]
	
	var answer = await music_adapter.download_music(songName, singer, downloadUrl)
	var audio64 = answer.get("audio64","")
	var filePath = answer.get("filePath","")
	var sourceUrl = answer.get("sourceUrl","")
	var cur_songName = answer.get("songName","")
	var cur_singer = answer.get("singer","")
	var cur_duration = answer.get("duration","0:0:0")
	var cur_data = {"is_bot":true}
	cur_data["audio_url"]= sourceUrl
	cur_data["audio_ref_path"]= filePath.simplify_path()
	cur_data["audio_base64"]= audio64
	cur_data["audio_name"]= cur_songName
	cur_data["audio_singer"]= cur_singer
	if typeof(cur_duration) == TYPE_FLOAT:
		cur_duration = int(cur_duration)
	elif typeof(cur_duration) == TYPE_STRING:
		var time_array = cur_duration.split(":")
		if time_array.size()==3:
			cur_duration = int(time_array[0])*60*60+int(time_array[1])*60+int(time_array[2])
		else:
			cur_duration = 0
	elif typeof(cur_duration) == TYPE_INT:
		pass
	else:
		cur_duration = 0
	cur_data["audio_duration"]= cur_duration
	var cur_message = ConversationMessageManager.plugin_create("Audio",cur_data,null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)


## @API
## @brief: Generate and download music based on tags and duration time
## @param: [tags] - Keywords for generating music
## @param: [duration] - Time to generate music
func create_music(tags:String="", duration:int=0):
	var music_adapter = await get_music_adapter()
	var answer = await music_adapter.create_music(tags, duration)
	var audio64 = answer.get("audio64","")
	var filePath = answer.get("filePath","")
	var sourceUrl = answer.get("sourceUrl","")
	var cur_data = {"is_bot":true}
	cur_data["audio_url"]= sourceUrl
	cur_data["audio_ref_path"]= filePath.simplify_path()
	cur_data["audio_base64"]= audio64
	cur_data["audio_duration"]= duration
	cur_data["audio_name"]= tags
	var cur_message = ConversationMessageManager.plugin_create("Audio",cur_data,null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
	
