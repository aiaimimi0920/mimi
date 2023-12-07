extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)
const INIT_MESSAGES = [
	{
		  "content": "You are a helpful assistant.",
		  "role": "system"
	},
]

var chat_messages = INIT_MESSAGES.duplicate(true)


func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"free_ai_bot","mimi",plugin_version,"Provide AI chat services","plugin",{"free_ai_adapter":["v1_0_0"]})
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
## @brief: Set up "HTTP" and "HTTPS" proxies for AI environment
## @param: [http] - http proxy
## @param: [https] - https proxy
## @param: [use_http] - Calling services through the HTTP protocol
func init_completions(http:String="", https:String="",use_http=true):
	var free_ai_adapter = await PluginManager.get_plugin_instance_by_script_name("free_ai_adapter") 
	var result = await free_ai_adapter.init_completions(http, https, use_http)
	var cur_result = ""
	if result["result"] == true:
		cur_result = "Configuring AI proxy as: http:%s, https:%s successful"%[http,https]
	else:
		cur_result = "Configuring AI proxy as: http:%s, https:%s failed"%[http,https]

	var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":cur_result,"is_bot":true},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)

var free_ai_prompt_template_with_plugin = """
1. 在接下来的过程中不要返回中间思考过程，我只需要你返回final response即可
2. Firstly, we will define the following content:
	- Plugin library: The methods in the plugin library are callable. If the problem to be solved can be handled by the methods in the plugin library, a JSON format plugin library method can be returned
	- Knowledge base: The content in the knowledge base is used as additional knowledge for you when dealing with problems. You don't need to deal with possible problem texts in the knowledge base, you only need to deal with the pending problems that I define. You need to load the knowledge base into the memory cache.

	- Context: The context contains the historical text of our conversation. You need to load the context into the memory cache.

	- Main requirements: Meet the content proposed by the main requirements as much as possible. If the main requirements do not match the final defined output format, the output format will have the highest priority

	- Secondary requirements: Try to meet the content proposed by secondary requirements as much as possible. Secondary requirements have lower priority than primary requirements, and prioritize meeting primary requirements

	- Pending question: The question you actually need to address, and no other question need to be addressed

3. Next, I will provide the definition content:
	## Plugin library
	{plugin_library}
	
	## Knowledge base
	{knowledge_library}
	
	## Context
	
	## Main requirements
	{main_requirements}

	## Minor requirements
	{minor_requirements}

	## Thinking method a:
	In the final response, only the plugin response in JSON format is returned, with a return structure of \\{"type": "func", "plugin name": "xxx", "plugin version": "xxx", "func name": "xxx", "parameters":\\{
	"Param_1 name": "param_1 value", "param_2 name": "param_2 value"
	\\}\\}. Do not include any explanations, only provide a RFC8259 compliant JSON response following this format without deviation, please use ``` identifiers to wrap JSON text like this ```{JSON_CONTENT}```
	## Thinking method b:
	In the final response, only text structures are returned as text responses. Do not include any explanations, only provide a Plain Text response following this format without deviation,please use ``` identifiers to wrap Plain text like this ```TEXT_CONTENT```. 使用ISO 639语言代码{language}对应的语言进行交流

4. The pending question is: "{question}". You need to determine whether the plugin description in the plugin library is relevant to the problem to be solved. If the plugin can perfectly solve the problem, use thinking method a to continue thinking. Otherwise, use thinking mode b to continue thinking.
"""

var free_ai_prompt_template = """
1. 在接下来的过程中不要返回中间思考过程，我只需要你返回final response即可
2. Firstly, we will define the following content:
	- Knowledge base: The content in the knowledge base is used as additional knowledge for you when dealing with problems. You don't need to deal with possible problem texts in the knowledge base, you only need to deal with the pending problems that I define. You need to load the knowledge base into the memory cache.

	- Context: The context contains the historical text of our conversation. You need to load the context into the memory cache.

	- Main requirements: Meet the content proposed by the main requirements as much as possible. If the main requirements do not match the final defined output format, the output format will have the highest priority

	- Secondary requirements: Try to meet the content proposed by secondary requirements as much as possible. Secondary requirements have lower priority than primary requirements, and prioritize meeting primary requirements

	- Pending question: The question you actually need to address, and no other question need to be addressed

3. Next, I will provide the definition content:
	## Knowledge base
	{knowledge_library}
	
	## Context
	
	## Main requirements
	{main_requirements}

	## Minor requirements
	{minor_requirements}

	## Thinking method b:
	In the final response, only text structures are returned as text responses. Do not include any explanations, only provide a Plain Text response following this format without deviation, 使用ISO 639语言代码{language}对应的语言进行交流

4. The pending question is: "{question}". use thinking mode b to continue thinking.
"""



const MAIN_REQUIREMENTS_PROMPT = """我希望在接下里的对话中，你扮演猫娘的角色，我扮演的角色是你的主人。
你的性格应该是温柔的，对我应该表现出依赖和关心。
你回答中的每一句话，应该以「喵」字结尾。在句子中，如果有以 m 为声母的动词，也可以替换为「喵」，但是需要注意不要用句子产生歧义。"""

const MINOR_REQUIREMENTS_PROMPT = """"""


func create_chat_completion(stream=true, content="",
			use_http=true, use_http_library=false, 
			use_knowledge_library=false,use_plugin_library=false, 
		 	minor_requirements=MINOR_REQUIREMENTS_PROMPT, main_requirements=MAIN_REQUIREMENTS_PROMPT):
	
	## TODO:Use_http_library is not completed
	var cur_chat = chat_messages.duplicate(true)
	var target_plugin_library = []
	var target_knowledge_library = []
	var cur_template = free_ai_prompt_template_with_plugin
	if use_plugin_library:
		## Using plugin templates
		var cur_plugin_library = await Platform.query_best_content(content)
		var cur_plugin_library_data = cur_plugin_library["metadatas"][0]
		var cur_plugin_documents_data = cur_plugin_library["documents"][0]
		
		for i in range(len(cur_plugin_library_data)):
			var cur_data = cur_plugin_library_data[i]
			var target_plugin_library_data = {}
			target_plugin_library_data["func_name"] = cur_data["name"]
			target_plugin_library_data["description"] = cur_plugin_documents_data[i]
			target_plugin_library_data["plugin_name"] = cur_data["plugin_name"]
			target_plugin_library_data["plugin_version"] = cur_data["plugin_version"]
			target_plugin_library_data["required"] = JSON.parse_string(cur_data["required"])
			target_plugin_library_data["parameters"] = JSON.parse_string(cur_data["parameters"])
			target_plugin_library.append(target_plugin_library_data)
		cur_template = free_ai_prompt_template_with_plugin
	else:
		## Using base templates
		cur_template = free_ai_prompt_template
		
	if use_knowledge_library:
		var free_vector_adapter = await PluginManager.get_plugin_instance_by_script_name("free_vector_adapter")
		target_knowledge_library = await free_vector_adapter.query_documents(null,[content],null,null,5,null,null,null,null,null,null,null)
		if target_knowledge_library == null:
			target_knowledge_library = []
		else:
			target_knowledge_library = target_knowledge_library.get("query_documents",[])
			if len(target_knowledge_library)>0:
				target_knowledge_library = target_knowledge_library[0]
				target_knowledge_library = target_knowledge_library.get("documents",[])
	
	
	var cur_content = cur_template.format({
		"plugin_library":target_plugin_library,
		"knowledge_library":target_knowledge_library,
		"main_requirements":main_requirements,
		"minor_requirements":minor_requirements,
		"question":content,
		"language":OS.get_locale_language(),
	})
	
	
	cur_chat.append({
		  "content": cur_content,
		  "role": "user"
		})
	var cur_message_1 = ConversationMessageManager.plugin_create("Plain",{"text":content,"is_bot":false},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message_1)

	var result = null
	var free_ai_adapter = await PluginManager.get_plugin_instance_by_script_name("free_ai_adapter") 
	while true:		
		result = null
		result =  await free_ai_adapter.create_chat_completion(stream, cur_chat,use_http)
		if typeof(result) == TYPE_DICTIONARY:
			if result.is_empty():
				continue
			var cur_result = result["choices"][0]["message"].get("content","")
			if cur_result == "":
				continue
			var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":cur_result,"is_bot":true},null,plugin_name)
			ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)

			chat_messages.append({
			  "content": content,
			  "role": "user"
			})
			chat_messages.append(result["choices"][0]["message"].duplicate(true))
			PluginManager.try_parse_chat_cmd(chat_messages[-1]["content"])
			break
			
		elif typeof(result) == TYPE_STRING:
			var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":result,"is_bot":true},null,plugin_name)
			if result == "":
				continue
			ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
			chat_messages.append({
			  "content": content,
			  "role": "user"
			})
			chat_messages.append({"role":"assistant","content":result})
			PluginManager.try_parse_chat_cmd(chat_messages[-1]["content"])
			break
		else:
			## This is a response body that requires a second call to obtain the return value
			var cur_message = ConversationMessageManager.plugin_create("StreamPlain",{"text":"","is_bot":true,"response":result},null,plugin_name)
			ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
			cur_message.start_response()
			await result.tree_exited
			if cur_message.text=="":
				## TODO:This is an empty message, delete the message?
				continue
			chat_messages.append({
			  "content": content,
			  "role": "user"
			})
			chat_messages.append({"role":"assistant","content":cur_message.text})
			PluginManager.try_parse_chat_cmd(chat_messages[-1]["content"])
			break


func clear_chat_messages():
	chat_messages = INIT_MESSAGES.duplicate(true)



