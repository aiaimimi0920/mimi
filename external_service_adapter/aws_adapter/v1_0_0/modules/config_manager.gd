extends BasePluginConfigManager

var access_key:
	get:
		return get_value("AWS","AccessKey","")
	set(value):
		set_value("AWS","AccessKey",value)

var secret_access_key:
	get:
		return get_value("AWS","SecretAccessKey", "")
	set(value):
		set_value("AWS","SecretAccessKey",value)

var bucket_name:
	get:
		return get_value("AWS","BucketName", "")
	set(value):
		set_value("AWS","BucketName",value)

var region_name:
	get:
		return get_value("AWS","RegionName", "")
	set(value):
		set_value("AWS","RegionName",value)

var service_name:
	get:
		return get_value("AWS","ServiceName", "s3")
	set(value):
		set_value("AWS","ServiceName",value)
