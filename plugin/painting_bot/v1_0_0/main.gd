extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"painting_bot","mimi",plugin_version,"Provide painting generation services","plugin",{"stable_horde_adapter":["v1_0_0"]})
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

	
## @API
## @brief: Generate images based on prompt words
## @param: [prompt] - prompt words
## @param: [amount] - Number of generated images
## @param: [width] - Generate image width
## @param: [height] - Generate image height
## @param: [steps] - Number of steps to generate images
## @param: [sampler_name] - sampler name for generating images
## @param: [cfg_scale] - cfg scale for generating images
## @param: [clip_skip] - clip skip for generating images
func generate(prompt:String="",amount:int=1, width:int=512,height:int=512,steps:int=30,sampler_name:String="k_euler_a",
		cfg_scale:float=7.5,clip_skip:int=1):
	
	var replacement_prompt = prompt
	var replacement_params = {}
	replacement_params["n"] = amount
	replacement_params["width"] = width
	replacement_params["height"] = height
	replacement_params["steps"] = steps
	replacement_params["sampler_name"] = sampler_name
	replacement_params["cfg_scale"] = cfg_scale
	replacement_params["clip_skip"] = clip_skip
	var stable_horde_adapter = await PluginManager.get_plugin_instance_by_script_name("stable_horde_adapter")
	var completed_payload = await stable_horde_adapter.generate(replacement_prompt, replacement_params)
	var all_image_textures = completed_payload["image_textures"]
	for i in range(len(all_image_textures)):
		var cur_texture = all_image_textures[i]
		var cur_data = {"is_bot":true}
		var cur_message = ConversationMessageManager.plugin_create("Image",cur_data,null,plugin_name)
		cur_message.create_by_image(cur_texture.get_image())
		if len(all_image_textures)==1:
			cur_message.show_message_type=0
		elif i==0:
			cur_message.show_message_type=1
		elif i==len(all_image_textures)-1:
			cur_message.show_message_type=3
		else:
			cur_message.show_message_type=2
		ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
