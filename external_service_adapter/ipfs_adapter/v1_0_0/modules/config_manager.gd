extends BasePluginConfigManager

var need_zip_file = ["pck"]

var pinata_key:
	get:
		return get_value("PinServices","Pinata_Key","")
	set(value):
		set_value("PinServices","Pinata_Key",value)

var gateway:
	get:
		return get_value("PinServices","Endpoint", "https://gateway.pinata.cloud")
	set(value):
		set_value("PinServices","Endpoint",value)
