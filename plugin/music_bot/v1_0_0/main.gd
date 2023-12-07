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
		"Provide music search, music download, and music generation services","plugin",{"music_adapter":["v1_0_0"]})
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
	var cur_data = {"is_bot":true}
	for cur_answer in answer["musicInfos"]:
		var sourceUrl = cur_answer["downloadUrl"]
		var cur_songName = cur_answer["songName"]
		var cur_singer = cur_answer["singer"]
		var cur_duration = cur_answer["duration"]
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


## @API
## @brief: Download songs based on "song name", "singer name", and "download address"
## @param: [songName] - song name
## @param: [singer] - singer name
## @param: [downloadUrl] - download address
func download_music(songName:String="", singer:String="", downloadUrl:String=""):
	var music_adapter = await get_music_adapter()
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
	
