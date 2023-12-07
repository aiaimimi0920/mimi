extends RefCounted

class_name GifImage

signal changed()


var size:Vector2
var frames:Array[Dictionary]
var frame_generate_time:int = -1


static func init(img_size:Vector2)->GifImage:
	if img_size.x < 0 or img_size.y < 0:
		Logger.error("Unable to create GifImage image instance as the incoming image size cannot be less than 0!")
		return null
	var ins:GifImage = GifImage.new()
	ins.size = img_size
	return ins
	
	
func add_frame(image:Image,delay_time:float)->int:
	if !is_instance_valid(image):
		Logger.error("The specified image instance is invalid, therefore it cannot be added to Gif frames!")
		return ERR_INVALID_DATA
	if delay_time <= 0:
		Logger.error("The specified image frame delay time needs to be greater than 0, so it cannot be added to the Gif frame!")
		return ERR_INVALID_PARAMETER
	if image.is_empty():
		Logger.error("Unable to add the specified image to the Gif frame, please check if the image properties are empty!")
		return ERR_INVALID_DATA
	frames.append({"image":image,"delay_time":delay_time})
	emit_signal("changed")
	return OK


func insert_frame(idx:int,image:Image,delay_time:float)->int:
	if idx <= frames.size():
		if !is_instance_valid(image):
			Logger.error("The specified image instance is invalid, therefore it cannot be inserted into a Gif frame!")
			return ERR_INVALID_DATA
		if delay_time <= 0:
			Logger.error("The specified image frame delay time needs to be greater than 0, so it cannot be inserted into a Gif frame!")
			return ERR_INVALID_PARAMETER
		if image.is_empty():
			Logger.error("Unable to insert the specified image into the Gif frame, please check if the image properties are empty!")
			return ERR_INVALID_DATA
		frames.insert(idx,{"image":image,"delay_time":delay_time})
		if idx == 0:
			frame_generate_time = -1
		emit_signal("changed")
		return OK
	else:
		Logger.error("The specified position is invalid, therefore it cannot be inserted into a Gif frame!")
		return ERR_DOES_NOT_EXIST


func remove_frame(idx:int)->int:
	if idx <= frames.size()-1:
		frames.remove_at(idx)
		if idx == 0:
			frame_generate_time = -1
		emit_signal("changed")
		return OK
	else:
		Logger.error("The specified position is invalid, therefore it cannot be removed from Gif frames!")
		return ERR_DOES_NOT_EXIST
		

func get_frame_image(idx:int)->Image:
	if idx <= frames.size()-1:
		return frames[idx].image
	else:
		return null
		
		
func get_frame_delay_time(idx:int)->float:
	if idx <= frames.size()-1:
		return frames[idx].delay_time
	else:
		return 0.0
		
		
func set_frame_image(idx:int,image:Image)->int:
	if idx <= frames.size()-1:
		if !is_instance_valid(image):
			Logger.error("The specified image instance is invalid, therefore it cannot be set to Gif frames!")
			return ERR_INVALID_DATA
		if image.is_empty():
			Logger.error("Unable to set the specified image to Gif frame, please check if the image properties are empty!")
			return ERR_INVALID_DATA
		if frames[idx].image != image:
			frames[idx].image = image
			if idx == 0:
				frame_generate_time = -1
			emit_signal("changed")
		return OK
	else:
		Logger.error("The specified position is invalid, therefore the specified image cannot be set to a Gif frame!")
		return ERR_DOES_NOT_EXIST
		
		
func set_frame_delay_time(idx:int,delay_time:float)->int:
	if idx <= frames.size()-1:
		if delay_time <= 0:
			Logger.error("The specified image frame delay time needs to be greater than 0, so it cannot be added to the Gif frame!")
			return ERR_INVALID_PARAMETER
		if frames[idx].delay_time != delay_time:
			frames[idx].delay_time = delay_time
			if idx == 0:
				frame_generate_time = -1
			emit_signal("changed")
		return OK
	else:
		Logger.error("The specified position is invalid, therefore the specified delay time cannot be set to Gif frames!")
		return ERR_DOES_NOT_EXIST


func clear_frames()->void:
	frames.clear()
	frame_generate_time = -1
	emit_signal("changed")


func get_frames_count()->int:
	return frames.size()
	

func set_size(new_size:Vector2)->int:
	if new_size.x < 0 or new_size.y < 0:
		Logger.error("Unable to change the size of GifImage image instance as the incoming image size cannot be less than 0!")
		return ERR_INVALID_PARAMETER
	if size != new_size:
		size = new_size
		frame_generate_time = -1
		emit_signal("changed")
	return OK


func get_size()->Vector2:
	return size


func get_playback_time()->float:
	if frames.is_empty():
		Logger.error("There are no image frames in this Gif image instance, so the total playback time cannot be obtained！")
		return 0.0
	var _time:float = 0.0
	for f_dic in frames:
		_time += f_dic.delay_time
	return _time


func save(path:String)->int:
	if frames.is_empty():
		Logger.error("There are no image frames in this Gif image instance, so it cannot be saved as a file！")
		return ERR_DOES_NOT_EXIST
	Logger.info("Generating Gif image data, please wait")
	var _start_time:int = Time.get_ticks_msec()
	var _thread:Thread = Thread.new()
	var _err:int = _thread.start(_export_data.bind(path,frames))
	if !_err:
		while _thread.is_alive():
			await GlobalManager.get_tree().physics_frame
		var _result:bool = _thread.wait_to_finish()
		if !_result:
			Logger.error("Unable to save the specified Gif image data to file% s, please check if the file path or permissions are correct!"% path)
			return ERR_CANT_CREATE
		var _end_time:int = Time.get_ticks_msec()
		var _passed_time:int = _end_time-_start_time
		frame_generate_time = int(round(float(_passed_time)/float(frames.size())))
		Logger.info("Successfully saved Gif image data to file %s (total time: %s seconds)"% [path,float(_passed_time)/1000.0])
		return OK
	else:
		Logger.error("Unable to create a thread for generating Gif images, please try again!")
		return ERR_CANT_CREATE


func get_generate_time()->float:
	if frames.is_empty():
		Logger.error("There are no image frames in this Gif image instance, so the expected generation time cannot be obtained!")
		return 0.0
	if frame_generate_time == -1:
		if (await _test_generate_speed()) != OK:
			Logger.error("Gif image generation speed test failed, therefore the expected generation time cannot be obtained!")
			return 0.0
	return float(frame_generate_time * frames.size())/1000.0


func _test_generate_speed()->int:
	if frames.is_empty():
		return ERR_CANT_RESOLVE
	Logger.info("Testing the generation speed of Gif image data, please wait")
	var _test_frames:Array = [frames[0]]
	var _f_path:String = GlobalManager.file_path.path_join("gif-image-test-"+Time.get_datetime_string_from_system().replace(":","-")+"-"+str(randi())+".gif")
	var _start_time:int = Time.get_ticks_msec()
	var _thread:Thread = Thread.new()
	var _err:int = _thread.start(_export_data.bind(_f_path,_test_frames))
	if !_err:
		while _thread.is_alive():
			await GlobalManager.get_tree().physics_frame
		var _result:bool = _thread.wait_to_finish()
		if !_result:
			return ERR_CANT_CREATE
		var _end_time:int = Time.get_ticks_msec()
		if FileAccess.file_exists(_f_path):
			DirAccess.remove_absolute(_f_path)
		frame_generate_time = _end_time-_start_time
		Logger.info("Gif image data generation speed test completed! The relevant data has been saved to the Gif image instance for estimating the generation time!")
		return OK
	else:
		Logger.error("Unable to create thread for testing Gif image data generation speed, please try again!")
		return ERR_CANT_CREATE


func _export_data(_file_path:String,_img_frames:Array)->bool:
	if _img_frames.is_empty():
		return false
	var _exporter:GifExporter = GifExporter.new()
	var _success:bool = _exporter.begin_export(_file_path,size.x,size.y,int(round(_img_frames[0].delay_time*100)))
	if !_success:
		_exporter.end_export()
		if FileAccess.file_exists(_file_path):
			DirAccess.remove_absolute(_file_path)
		return false
	for _img_dic in _img_frames:
		var _img:Image = _img_dic.image
		var _delay:int = int(round(_img_dic.delay_time*100))
		_img.convert(Image.FORMAT_RGBA8)
		_success = _exporter.write_frame(_img,Color.WHITE,_delay)
		if !_success:
			_exporter.end_export()
			if FileAccess.file_exists(_file_path):
				DirAccess.remove_absolute(_file_path)
			return false
	_exporter.end_export()
	return true

##  返回的类型是[AnimatedTexture, size]
static func read(path:String)-> Array:
	Logger.info("Reading Gif image data, please wait")
	var image_frames:ImageFrames = ImageFrames.new()
	image_frames.load(path)
	var animated_texture:AnimatedTexture = create_animated_texture(image_frames)
	return [animated_texture,image_frames.get_bounding_rect().size]

static func read_buffer(buffer:PackedByteArray)-> Array:
	Logger.info("Reading Gif image data, please wait")
	var image_frames:ImageFrames = ImageFrames.new()
	image_frames.load_gif_from_buffer(buffer)
	var animated_texture:AnimatedTexture = create_animated_texture(image_frames)
	return [animated_texture,image_frames.get_bounding_rect().size]


static func create_animated_texture(image_frames:ImageFrames)-> AnimatedTexture:
	var animated_texture:AnimatedTexture = AnimatedTexture.new()
	animated_texture.frames = image_frames.get_frame_count()
	for i in image_frames.get_frame_count():
		animated_texture.set_frame_texture(i, ImageTexture.create_from_image(image_frames.get_frame_image(i)))
		animated_texture.set_frame_duration(i, image_frames.get_frame_duration(i))
	Logger.info("Successfully read Gif image data, texture size: %s"%image_frames.get_bounding_rect().size)
	return animated_texture
	
