extends BasePluginConfigManager

var account_id:
	get:
		return get_value("Cloudflare","AccountID","")
	set(value):
		set_value("Cloudflare","AccountID",value)


var access_key:
	get:
		return get_value("Cloudflare","AccessKey","")
	set(value):
		set_value("Cloudflare","AccessKey",value)

var secret_access_key:
	get:
		return get_value("Cloudflare","SecretAccessKey", "")
	set(value):
		set_value("Cloudflare","SecretAccessKey",value)

var read_access_key:
	get:
		return get_value("Cloudflare","ReadAccessKey","")
	set(value):
		set_value("Cloudflare","ReadAccessKey",value)

var read_secret_access_key:
	get:
		return get_value("Cloudflare","ReadSecretAccessKey", "")
	set(value):
		set_value("Cloudflare","ReadSecretAccessKey",value)

var bucket_name:
	get:
		return get_value("Cloudflare","BucketName", "")
	set(value):
		set_value("Cloudflare","BucketName",value)

var region_name:
	get:
		return get_value("Cloudflare","RegionName", "")
	set(value):
		set_value("Cloudflare","RegionName",value)

var service_name:
	get:
		return get_value("Cloudflare","ServiceName", "")
	set(value):
		set_value("Cloudflare","ServiceName",value)


#var pub_url:
	#get:
		#return get_value("Cloudflare","PubURL", "")
	#set(value):
		#set_value("Cloudflare","PubURL",value)
