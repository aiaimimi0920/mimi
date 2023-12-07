extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"Plugin packaging robot","mimi",plugin_version,"Can help you quickly submit locally developed plugins",
		"plugin",{"file_list":["v1_0_0"]})
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
## @brief: Package files or folders into a PCK format package
## @param: [path] - Package file path
func generate_pck(path:String=""):
	var pck_adapter = await PluginManager.get_plugin_instance_by_script_name("pck_adapter")
	var save_path = await pck_adapter.pck_package_file(path)
	var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":"File saved: %s, pck Package address: %s"%[path,save_path],"is_bot":true},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)


## @API
## @brief: Package the plugin into a PCK format package and upload it to the cloud storage provider
## @param: [cur_plugin_name] - Name of the plugin to be packaged
func generate_plugin_file(cur_plugin_name:String=""):
	# Remember to package plugins. If the plugin directory contains unnecessary files, be sure to delete them before packaging
	var need_pck_file = PluginManager.res_external_service_adapter_dir_path.path_join(cur_plugin_name)
	var dir = DirAccess.open("user://")
	var root_path = ""
	var base_path = PluginManager.get_plugin_file_dir_path(plugin_name)
	var pck_adapter = await PluginManager.get_plugin_instance_by_script_name("pck_adapter")
	if DirAccess.dir_exists_absolute(need_pck_file):
		var save_path = await pck_adapter.pck_package_file(need_pck_file, true)
		root_path = base_path.path_join(cur_plugin_name)
		FileManager.remove_directory_recursively(root_path)
		dir.remove(root_path)
		dir.make_dir_recursive(root_path)
		var external_service_adapter_name = PluginManager.external_service_adapter_name
		var external_service_adapter_path = root_path.path_join(external_service_adapter_name)
		dir.make_dir_recursive(external_service_adapter_path)
		dir.copy(save_path,external_service_adapter_path.path_join(PluginManager.plugin_pck_name))
		var res_external_service_path = PluginManager.res_external_service_dir_path.path_join(cur_plugin_name)
		
		## First, determine whether there are external dependency files
		if DirAccess.dir_exists_absolute(res_external_service_path):
			res_external_service_path = PluginManager.get_big_version_folder(res_external_service_path,true)
			res_external_service_path = ProjectSettings.globalize_path(res_external_service_path)
			var external_service_name = PluginManager.external_service_name
			var external_service_path = root_path.path_join(external_service_name)
			dir.make_dir_recursive(external_service_path)
			FileManager.copy_directory_recursively(res_external_service_path,external_service_path)
	else:
		need_pck_file = PluginManager.get_res_plugin_path(cur_plugin_name)
		if not DirAccess.dir_exists_absolute(need_pck_file):
			Logger.info("Without this plugin: %s"%cur_plugin_name)
			return
		var save_path = await pck_adapter.pck_package_file(need_pck_file, true)
		root_path = base_path.path_join(cur_plugin_name)
		FileManager.remove_directory_recursively(root_path)
		dir.remove(root_path)
		dir.make_dir_recursive(root_path)
		dir.copy(save_path,root_path.path_join(PluginManager.plugin_pck_name))
		
		
	## Pop up a window asking whether to upload to the storage platform
	var cur_text_message = ConversationMessageManager.plugin_create("Plain",
		{"text":"Enter the platform you want to save and press the submit button to submit. If you want to upload it to the storage platform yourself, please press submit directly","is_bot":true},null,plugin_name)
	cur_text_message.show_message_type = 1
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_text_message)
	var cur_input_form_message = ConversationMessageManager.plugin_create("InputForm",
		{"text_map":{"platform_name":{"placeholder_text":"platform name(ipfs/cloudflare/aws/ipfs_self/cloudflare_self/aws_self)"}},
		"is_bot":true,
		"trigger_counts":1,
		},null,plugin_name)
	cur_input_form_message.show_message_type = 3
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_input_form_message)
	var cur_result_1 = await cur_input_form_message.call_finished
	if cur_result_1 == false:
		return 
		
	var data_dict = cur_input_form_message.cur_text_map
	var platform_name = data_dict["platform_name"].to_lower()
	var sub_path = ""
	var ipfs_id = ""
	var ipfs_adapter = null
	var aws_adapter = null
	var cloudflare_adapter = null
	var file_list = await PluginManager.get_plugin_instance_by_script_name("file_list")
	if platform_name in ["ipfs","cloudflare","aws"]:
		var cur_text_message_2 = ConversationMessageManager.plugin_create("Plain",{"text":"Enter the necessary key information and press the submit button to submit","is_bot":true},null,plugin_name)
		cur_text_message_2.show_message_type = 1
		ConversationManager.plugin_conversation_append_message(plugin_name,cur_text_message_2)
		var cur_input_form_message_2
		if platform_name == "ipfs":
			ipfs_adapter = await PluginManager.get_plugin_instance_by_script_name("ipfs_adapter")
			cur_input_form_message_2 = ConversationMessageManager.plugin_create("InputForm",
			{"text_map":{
				"pinata_key":{"placeholder_text":"pinta key","default_text":ipfs_adapter.service_config_manager.pinata_key}
			},
			"is_bot":true,
			"trigger_counts":1,
			},null,plugin_name)
		elif platform_name == "cloudflare":
			cloudflare_adapter = await PluginManager.get_plugin_instance_by_script_name("cloudflare_adapter")
			cur_input_form_message_2 = ConversationMessageManager.plugin_create("InputForm",
			{"text_map":{
				"region":{"placeholder_text":"region name","default_text":cloudflare_adapter.service_config_manager.region_name},
				"bucket":{"placeholder_text":"bucket name","default_text":cloudflare_adapter.service_config_manager.bucket_name},
				"access_key":{"placeholder_text":"access key","default_text":cloudflare_adapter.service_config_manager.access_key},
				"secret_key":{"placeholder_text":"secret key","default_text":cloudflare_adapter.service_config_manager.secret_access_key},
				"service":{"placeholder_text":"service name","default_text":cloudflare_adapter.service_config_manager.service_name},
				"account_id":{"placeholder_text":"account id","default_text":cloudflare_adapter.service_config_manager.account_id},
			},
			"is_bot":true,
			"trigger_counts":1,
			},null,plugin_name)
		elif platform_name == "aws":
			aws_adapter = await PluginManager.get_plugin_instance_by_script_name("aws_adapter")
			cur_input_form_message_2 = ConversationMessageManager.plugin_create("InputForm",
			{"text_map":{
				"region":{"placeholder_text":"region name","default_text":aws_adapter.service_config_manager.region_name},
				"bucket":{"placeholder_text":"bucket name","default_text":aws_adapter.service_config_manager.bucket_name},
				"access_key":{"placeholder_text":"access key","default_text":aws_adapter.service_config_manager.access_key},
				"secret_key":{"placeholder_text":"secret key","default_text":aws_adapter.service_config_manager.secret_access_key},
				"service":{"placeholder_text":"service name","default_text":aws_adapter.service_config_manager.service_name},
			},
			"is_bot":true,
			"trigger_counts":1,
			},null,plugin_name)

		cur_input_form_message_2.show_message_type = 3
		ConversationManager.plugin_conversation_append_message(plugin_name,cur_input_form_message_2)
		var cur_result_2 = await cur_input_form_message_2.call_finished
		if cur_result_2 == false:
			return 
		
		var data_dict_2 = cur_input_form_message_2.cur_text_map
		
		var save_result_text = ""
		if platform_name == "ipfs":
			var pinata_key = data_dict_2["pinata_key"]
			ipfs_id = await file_list.fs_upload_form(root_path,"",0,"",
				"","","","","",pinata_key)
			save_result_text = "Plugin saved: %s ,ipfs id：%s"%[cur_plugin_name,ipfs_id]
		elif platform_name == "cloudflare":
			var region = data_dict_2["region"]
			var bucket = data_dict_2["bucket"]
			var access_key = data_dict_2["access_key"]
			var secret_key = data_dict_2["secret_key"]
			var service = data_dict_2["service"]
			var account_id = data_dict_2["account_id"]
			var cur_s3_path = root_path
			var fs_upload_form_result = await file_list.fs_upload_form(root_path,base_path,1,region,
					bucket,access_key,secret_key,service,account_id)
			sub_path = fs_upload_form_result[0]
			var cloudflare_url_path = 'https://'+ fs_upload_form_result[4] + "." + fs_upload_form_result[3]+"."+ '.cloudflarestorage.com/'+fs_upload_form_result[2]+"/"+fs_upload_form_result[0]
			save_result_text = "Plugin saved: %s ,url：%s"%[cur_plugin_name, cloudflare_url_path]
		elif platform_name == "aws":
			var region = data_dict_2["region"]
			var bucket = data_dict_2["bucket"]
			var access_key = data_dict_2["access_key"]
			var secret_key = data_dict_2["secret_key"]
			var service = data_dict_2["service"]
			var cur_s3_path = root_path
			
			var fs_upload_form_result = await file_list.fs_upload_form(root_path,base_path,2,region,
					bucket,access_key,secret_key,service)
			
			sub_path = fs_upload_form_result[0]
			var aws_url_path = 'https://'+ fs_upload_form_result[2] + "." + fs_upload_form_result[3]+"."+ fs_upload_form_result[1] + '.amazonaws.com/'+fs_upload_form_result[0]
			save_result_text = "Plugin saved: %s ,url：%s"%[cur_plugin_name, aws_url_path]

		dir.remove(root_path)
		var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":save_result_text,"is_bot":true},null,plugin_name)
		ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
	
	
	## Pop up a window asking whether to upload to the platform
	var cur_text_message_3 = ConversationMessageManager.plugin_create("Plain",
		{"text":"If you want to upload to the platform, please enter the key information and press the submit button to submit. The plugin introduction and method functions will be automatically extracted.","is_bot":true},null,plugin_name)
	cur_text_message_3.show_message_type = 1
	
	var cur_input_form_message_3
	
	if platform_name in ["ipfs","ipfs_self"]:
		cur_input_form_message_3 = ConversationMessageManager.plugin_create("InputForm",
			{"text_map":{
				"content_name":{"placeholder_text":"content name"},
				"anonymous_search_level":{"placeholder_text":"anonymous search level: 0-3","default_text":"3"},
				"free":{"placeholder_text":"is free content: true/false","default_text":"true"},
				"ipfs_id":{"placeholder_text":"ipfs id","default_text":ipfs_id},
			},
			"is_bot":true,
			"trigger_counts":1,
			},null,plugin_name)
	elif platform_name in ["cloudflare","cloudflare_self"]:
		cur_input_form_message_3 = ConversationMessageManager.plugin_create("InputForm",
			{"text_map":{
				"content_name":{"placeholder_text":"content name"},
				"anonymous_search_level":{"placeholder_text":"anonymous search level: 0-3","default_text":"3"},
				"free":{"placeholder_text":"is free content: true/false","default_text":"true"},
				"region":{"placeholder_text":"cloudflare region name","default_text":cloudflare_adapter.service_config_manager.region_name if cloudflare_adapter else ""},
				"bucket":{"placeholder_text":"cloudflare bucket name","default_text":cloudflare_adapter.service_config_manager.bucket_name if cloudflare_adapter else ""},
				"service":{"placeholder_text":"cloudflare service name","default_text":cloudflare_adapter.service_config_manager.service_name if cloudflare_adapter else ""},
				"sub_path":{"placeholder_text":"cloudflare store path","default_text":sub_path},
				"account_id":{"placeholder_text":"cloudflare account id","default_text":cloudflare_adapter.service_config_manager.account_id if cloudflare_adapter else ""},
				"read_access_key":{"placeholder_text":"cloudflare read access key","default_text":cloudflare_adapter.service_config_manager.read_access_key if cloudflare_adapter else ""},
				"read_secret_access_key":{"placeholder_text":"cloudflare read secret access key","default_text":cloudflare_adapter.service_config_manager.read_secret_access_key if cloudflare_adapter else ""},
			},
			"is_bot":true,
			"trigger_counts":1,
			},null,plugin_name)
	elif platform_name in ["aws","aws_self"]:
		cur_input_form_message_3 = ConversationMessageManager.plugin_create("InputForm",
			{"text_map":{
				"content_name":{"placeholder_text":"content name"},
				"anonymous_search_level":{"placeholder_text":"anonymous search level: 0-3","default_text":"3"},
				"free":{"placeholder_text":"is free content: true/false","default_text":"true"},
				"region":{"placeholder_text":"aws region name","default_text":aws_adapter.service_config_manager.region_name if aws_adapter else ""},
				"bucket":{"placeholder_text":"aws bucket name","default_text":aws_adapter.service_config_manager.bucket_name if aws_adapter else ""},
				"service":{"placeholder_text":"aws service name","default_text":aws_adapter.service_config_manager.service_name if aws_adapter else ""},
				"sub_path":{"placeholder_text":"aws store path","default_text":sub_path},
			},
			"is_bot":true,
			"trigger_counts":1,
			},null,plugin_name)
	else:
		print("have error")
		return 
		
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_text_message_3)
	cur_input_form_message_3.show_message_type = 3
	ConversationManager.plugin_conversation_append_message(plugin_name, cur_input_form_message_3)
	var cur_result_3 = await cur_input_form_message_3.call_finished
	if cur_result_3 == false:
		return 
	var data_dict_3 = cur_input_form_message_3.cur_text_map
	var cur_anonymous_search_level = 3
	cur_anonymous_search_level = data_dict_3["anonymous_search_level"].to_int()
	if cur_anonymous_search_level>3:
		cur_anonymous_search_level = 3
	if cur_anonymous_search_level<0:
		cur_anonymous_search_level = 0
	var cur_free = true
	if data_dict_3["anonymous_search_level"].to_lower()=="true":
		cur_free = true
	else:
		cur_free = false

	var cur_plugin_base_dir = PluginManager.get_plugin_base_dir_by_plugin_name(cur_plugin_name)
	var cur_plugin_version_base_dir = PluginManager.get_big_version_folder(cur_plugin_base_dir,true)
	var cur_plugin_version = PluginManager.get_version_by_str(cur_plugin_version_base_dir.get_file())
	var cur_plugin_script = PluginManager.get_plugin_script_by_plugin_name(cur_plugin_name,cur_plugin_version)
	var method_info = PluginManager.create_plugin_api_methods(load(cur_plugin_script))
	
	if platform_name in ["ipfs","ipfs_self"]:
		await Platform.create_content(data_dict_3["content_name"], 
			false, cur_anonymous_search_level,cur_free,
			{"platform":"ipfs","ipfs_id":data_dict_3["ipfs_id"]},method_info, 1, cur_plugin_version)
	elif platform_name in ["cloudflare","cloudflare_self"]:
		await Platform.create_content(data_dict_3["content_name"], 
			false, cur_anonymous_search_level,cur_free,
			{"platform":"cloudflare","region":data_dict_3["region"],"bucket":data_dict_3["bucket"],
			"service":data_dict_3["service"],"sub_path":data_dict_3["sub_path"],
			"account_id":data_dict_3["account_id"],
			"read_access_key":data_dict_3["read_access_key"],
			"read_secret_access_key":data_dict_3["read_secret_access_key"],
			},
			method_info, 1, cur_plugin_version)
	elif platform_name in ["aws","aws_self"]:
		await Platform.create_content(data_dict_3["content_name"], 
			false, cur_anonymous_search_level,cur_free,
			{"platform":"aws","region":data_dict_3["region"],"bucket":data_dict_3["bucket"],"service":data_dict_3["service"],"sub_path":data_dict_3["sub_path"]},
			method_info, 1, cur_plugin_version)

	var result_message = ConversationMessageManager.plugin_create("Plain",{"text":"Successfully uploaded plugin","is_bot":true},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,result_message)


