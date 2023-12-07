extends BasePluginConfigManager

var service_ai_address:
	get:
		return get_value("General","ServiceAIAddress","127.0.0.1")
	set(value):
		set_value("General","ServiceAIAddress",value)

var service_ai_address_host:
	get:
		return "http://"+service_ai_address

var service_ai_port:
	get:
		return int(get_value("General","ServiceAIPort",8080))
	set(value):
		set_value("General","ServiceAIPort",value)

var service_ai_address_port:
	get:
		if service_ai_address!="":
			return service_ai_address_host+":"+"%s"%(service_ai_port)
		return ""
