extends ConversationMessageAPI
class_name ImageConversationMessage

func get_MessageType():
	return "Image"

var image_width
var image_height

var image_id
var image_url
var image_base64
var image_ref_path

func reload_message():
	super.reload_message()
	if conversation_message_data:
		image_width = conversation_message_data.get("image_width",null)
		image_height = conversation_message_data.get("image_height",null)
		image_id = conversation_message_data.get("image_id",null)
		image_url = conversation_message_data.get("image_url",null)
		image_base64 = conversation_message_data.get("image_base64",null)
		image_ref_path = conversation_message_data.get("image_ref_path",null)
	return self
	
	
func get_as_text()->String:
	return "[Image"+ image_id +"]"

func get_image_path():
	if image_ref_path:
		if FileAccess.file_exists(image_ref_path):
			return image_ref_path
	var cur_image_path = GlobalManager.file_path.path_join(image_id)
	if FileAccess.file_exists(cur_image_path):
		return cur_image_path
	if image_url:
		cur_image_path = GlobalManager.file_path.path_join(image_url)
		## TODO: If there are no files available locally, you can try downloading files from the network
		if FileAccess.file_exists(cur_image_path):
			return cur_image_path
		else:
			begin_download()
	return ""

## It will be returned in buffer format. If you need to customize the return, use get_file_path
func get_image_buffer_data()->PackedByteArray:
	if image_base64:
		return Marshalls.base64_to_raw(image_base64)
	var file_path = get_image_path()
	if file_path != "":
		var file = FileAccess.open(file_path,FileAccess.READ)
		var content = file.get_buffer(file.get_length())
		return content
	return PackedByteArray()

func create_by_image(image):
	if is_instance_valid(image):
		if image is Image:
			var f_path:String = GlobalManager.file_path.path_join("image-"+Time.get_datetime_string_from_system().replace(":","-")+"-"+str(randi())+".png")
			var err:int = image.save_png(f_path)
			if !err:
				image_ref_path = f_path.simplify_path()
				Logger.info("Successfully cached Image image instance to file and constructed as image message:% s"% f_path)
				return self
			else:
				Logger.error("Unable to cache Image image instance to file% s, therefore it cannot be constructed as an image message. Please check if the path or permissions are correct!"% f_path)
		elif image is GifImage:
			var f_path:String = GlobalManager.file_path.path_join("gif-image-"+Time.get_datetime_string_from_system().replace(":","-")+"-"+str(randi())+".gif")
			var err:int = await image.save(f_path)
			if !err:
				image_ref_path = f_path.simplify_path()
				Logger.info("Successfully cached GifImage image instance to file and constructed as image message: %s"% f_path)
				return self
			else:
				Logger.error("Unable to cache GifImage image instance to file% s, therefore it cannot be constructed as an image message. Please check if the path or permissions are correct!"% f_path)
	else:
		Logger.error("The passed in instance is invalid, therefore the specified image instance cannot be constructed as an image message!")
	return null

func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["image_width"] = image_width
	all_data["data"]["image_height"] = image_height
	all_data["data"]["image_id"] = image_id
	all_data["data"]["image_url"] = image_url
	all_data["data"]["image_base64"] = image_base64
	all_data["data"]["image_ref_path"] = image_ref_path
	return all_data

var download_start = false
## Download resources from the URL
func begin_download():
	if download_start == true:
		return
	download_start = true
	image_ref_path = await base_begin_download(image_url)
	image_ref_path = image_ref_path.simplify_path()
	download_start = false
	emit_signal("download_finish")
