extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


var main_protocol

var protocol_map = {}
var c_s_protocol_map = {}
var s_c_protocol_map = {}

var data_format:
	get:
		return plugin_node.service_config_manager.data_format

func _init():
	main_protocol = load(plugin_node.get_absolute_path("modules/main_protocol.gd"))
	pass

## When all s_c and c_s Calling protocol methods when they are all within an object
func register_protocol_format_with_object(sub_protocol, object):
	## Register all server call protocols
	register_c_s_protocol_format_with_object(sub_protocol, object)
	register_s_c_protocol_format_with_object(sub_protocol, object)

func get_main_potocol_id(potocol_cls):
	var main_protocol_name = 0
	for key in potocol_cls.keys():
		if potocol_cls.get(key)!=0:
			main_protocol_name = key
			break
	return main_protocol_name

func get_sub_protocol_map(potocol_cls):
	var sub_protocol_map = {}
	for key in potocol_cls.keys():
		if potocol_cls.get(key)!=0:
			sub_protocol_map[key] = potocol_cls.get(key)
	return sub_protocol_map

func register_c_s_protocol_format_with_object(sub_protocol, object):
	var main_protocol_name = get_main_potocol_id(sub_protocol.C2SMAINPROTOCOL)
	var sub_protocol_map = get_sub_protocol_map(sub_protocol.C2SPROTOCOL)
	for protocol_name in sub_protocol_map:
		register_c_s_protocol_format(main_protocol_name, sub_protocol_map[protocol_name], sub_protocol.get("M_"+protocol_name), Callable(object, protocol_name))

func register_s_c_protocol_format_with_object(sub_protocol, object):
	var main_protocol_name = get_main_potocol_id(sub_protocol.S2CMAINPROTOCOL)
	var sub_protocol_map = get_sub_protocol_map(sub_protocol.S2CPROTOCOL)
	for protocol_name in sub_protocol_map:
		register_s_c_protocol_format(main_protocol_name, sub_protocol_map[protocol_name], sub_protocol.get("M_"+protocol_name), Callable(object, protocol_name))
	

func register_c_s_protocol_format(protocol_name, sub_protocol, probuf_cls, callable=null):
	register_protocol_format(protocol_name,sub_protocol,probuf_cls, main_protocol.C2SPROTOCOL, c_s_protocol_map, callable)

func register_s_c_protocol_format(protocol_name, sub_protocol, probuf_cls, callable=null):
	register_protocol_format(protocol_name,sub_protocol,probuf_cls, main_protocol.S2CPROTOCOL, s_c_protocol_map, callable)
		
func register_protocol_format(protocol_name, sub_protocol, probuf_cls, main_protocol_cls, protocol_map, callable=null):
	var protocol = protocol_name
	if protocol_name is String:
		protocol = main_protocol_cls.get(protocol_name)
	if protocol not in protocol_map:
		protocol_map[protocol] = {}
	protocol_map[protocol][sub_protocol] = {"format":probuf_cls,"callable":callable}
	protocol_map[callable] = {"protocol":protocol, "sub_protocol": sub_protocol}

func unregister_c_s_protocol_format(protocol_name, sub_protocol):
	unregister_protocol_format(protocol_name, sub_protocol, main_protocol.C2SPROTOCOL, c_s_protocol_map)

func unregister_s_c_protocol_format(protocol_name, sub_protocol):
	unregister_protocol_format(protocol_name, sub_protocol, main_protocol.S2CPROTOCOL, s_c_protocol_map)

func unregister_protocol_format(protocol_name, sub_protocol, main_protocol_cls, protocol_map):
	var protocol = protocol_name
	if protocol_name is String:
		protocol = main_protocol_cls.get(protocol_name)
	if protocol not in protocol_map:
		return 
	if sub_protocol in protocol_map[protocol] and "callable" in protocol_map[protocol][sub_protocol]:
		protocol_map.erase(protocol_map[protocol][sub_protocol]["callable"])
	protocol_map[protocol].erase(sub_protocol)

func parse_data(data):
	var result_data:Dictionary
	if data_format.to_lower() == "json":
		var json:JSON = JSON.new()
		var err:int = json.parse(data)
		if !err:
			result_data = json.get_data()
	elif data_format.to_lower() == "protobuf":
		if data is PackedByteArray:
			var s2c = main_protocol.S2C.new()
			var state = s2c.from_bytes(data)
			if state!=OK:
				pass
			var protocol = s2c.get_protocol()
			var sub_protocol = s2c.get_sub_protocol()
			var syncId = s2c.get_syncId()
			var server_syncId = s2c.get_server_syncId()
			var content = s2c.get_content()
			content = parse_content(protocol, sub_protocol, content)
			result_data = {
				"protocol":protocol,
				"sub_protocol":sub_protocol,
				"syncId":syncId,
				"server_syncId":server_syncId,
				"content":content,
			}
	var callable = null
	if (result_data["protocol"] in s_c_protocol_map) and (result_data["sub_protocol"] in s_c_protocol_map[result_data["protocol"]]):
		callable = s_c_protocol_map[result_data["protocol"]][result_data["sub_protocol"]].get("callable",null)
	return [result_data, callable]

func parse_content(protocol, sub_protocol, content):
	if protocol not in s_c_protocol_map:
		return content
	if sub_protocol not in s_c_protocol_map[protocol]:
		return content
	var s2c = s_c_protocol_map[protocol][sub_protocol]["format"].new()
	var state = s2c.from_bytes(content)
	if state!=OK:
		pass
	var content_map = get_element(s2c)
	return content_map

func get_element(element):
	if typeof(element) in [TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]:
		return element
	var content_map = {}
	for key in element.data:
		var service = element.data[key]
		content_map[service.field.name] = element.call("get_%s"%[service.field.name])
		if typeof(content_map[service.field.name]) in [TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]:
			pass
		elif typeof(content_map[service.field.name]) == TYPE_ARRAY:
			for i in range(len(content_map[service.field.name])):
				content_map[service.field.name][i] = get_element(content_map[service.field.name][i])
		elif typeof(content_map[service.field.name]) == TYPE_DICTIONARY:
			for key_name in content_map[service.field.name]:
				content_map[service.field.name][key_name] = get_element(content_map[service.field.name][key_name])
		elif typeof(content_map[service.field.name]) == TYPE_OBJECT:
			content_map[service.field.name] = get_element(content_map[service.field.name])
	return content_map


func stringify(syncId, server_syncId, content, caller):
	if caller not in c_s_protocol_map:
		## Method not called
		return false
	var protocol = c_s_protocol_map[caller]["protocol"]
	var sub_protocol = c_s_protocol_map[caller]["sub_protocol"]
	var dict_data = {
			"protocol":protocol,
			"sub_protocol":sub_protocol,
			"syncId":syncId,
			"server_syncId":server_syncId,
			"content":content,
		}
	var result_data
	if data_format.to_lower() == "json":
		var json:JSON = JSON.new()
		var data = dict_data
		result_data = json.stringify(data)
	elif data_format.to_lower() == "protobuf":
		var c2s = main_protocol.C2S.new()
		c2s.set_protocol(protocol)
		c2s.set_sub_protocol(sub_protocol)
		c2s.set_syncId(syncId)
		c2s.set_content(stringify_content(protocol, sub_protocol, content))
		result_data = c2s.to_bytes()
		
	return [result_data,dict_data]
	
func stringify_content(protocol, sub_protocol, content):
	if protocol not in c_s_protocol_map:
		return content
	if sub_protocol not in c_s_protocol_map[protocol]:
		return content
	var c2s = c_s_protocol_map[protocol][sub_protocol]["format"].new()
	set_element(c2s, content)
	return c2s.to_bytes()

func set_element(element, data):
	for key in element.data:
		var service = element.data[key]
		if not (service.field.name in data):
			continue

		var cur_data = data[service.field.name]
		if cur_data == null:
			continue
		if service.func_ref:
			if typeof(cur_data)==TYPE_DICTIONARY and service.field.type == main_protocol.PB_DATA_TYPE.MAP  and service.field.rule == main_protocol.PB_RULE.REPEATED:
				for cur_key in cur_data:
					var new_element = service.func_ref.call()
					set_element(new_element, {"key":cur_key,"value":cur_data[cur_key]})
			elif typeof(cur_data) == TYPE_DICTIONARY and service.field.type == main_protocol.PB_DATA_TYPE.MESSAGE and service.field.rule in [main_protocol.PB_RULE.OPTIONAL,main_protocol.PB_RULE.REQUIRED]:
				var new_element = service.func_ref.call()
				set_element(new_element, cur_data)
			elif typeof(cur_data) == TYPE_ARRAY and service.field.type == main_protocol.PB_DATA_TYPE.MESSAGE and service.field.rule == main_protocol.PB_RULE.REPEATED:
				for i in range(len(cur_data)):
					var new_element = service.func_ref.call()
					set_element(new_element, cur_data[i])
		else:
			if typeof(cur_data) == TYPE_ARRAY and service.field.rule == main_protocol.PB_RULE.OPTIONAL:
				element.call("set_%s"%[service.field.name], cur_data)
			elif typeof(cur_data) == TYPE_ARRAY and service.field.rule == main_protocol.PB_RULE.REPEATED:
				for one_data in cur_data:
					element.call("add_%s"%[service.field.name], one_data)
			else:
				if element.has_method("set_%s"%[service.field.name]):
					element.call("set_%s"%[service.field.name], cur_data)
	
