extends RefCounted #继承自CoreAPI


## RainyBot的Http请求结果类，可从其中快速获取某次Http请求的结果数据
class_name HttpRequestResult


var request_url:String = ""
var request_data = ""
var request_headers:PackedStringArray = []
var result_code:int = 0
var response_code:int = 0
var headers:PackedStringArray = []
var body:PackedByteArray = []


## 获取此请求的URL字符串
func get_request_url()->String:
	return request_url
	

## 获取此请求的请求数据
func get_request_data():
	return request_data
	

## 将此请求的请求数据解析为字典并返回
func get_request_data_dic()->Dictionary:
	if !(request_data is String):
		Logger.error("无法将Http请求数据获取为字典，因为其不是一个字符串!")
		return {}
	
	var _json:JSON = JSON.new()
	var _error:int = _json.parse(request_data)
	var _data:Dictionary = {}
	if !_error:
		_data = _json.get_data()
		Logger.info("成功将Http请求数据获取为字典: "+str(_data))
	else:
		Logger.error("无法将Http请求数据获取为字典，请检查其格式是否正确!")
	return _data
	

## 获取此请求的headers数组
func get_request_headers()->PackedStringArray:
	return request_headers
	

## 获取此请求的结果状态	
func get_result_status()->int:
	return result_code
	

## 获取此请求的结果响应码	
func get_response_code()->int:
	return response_code
	

## 获取此请求的结果的headers
func get_headers()->PackedStringArray:
	return headers


## 尝试将此请求的结果解析为字符串并返回
func get_as_text()->String:
	return body.get_string_from_utf8()
	

## 尝试将此请求的结果解析为字典并返回
func get_as_dic()->Dictionary:
	var _json:JSON = JSON.new()
	var _error:int = _json.parse(body.get_string_from_utf8())
	var _result:Dictionary = {}
	if !_error:
		_result = _json.get_data()
		Logger.info("成功将Http请求结果获取为字典: "+str(_result))
	else:
		Logger.error("无法将Http请求结果获取为字典，请检查其格式是否正确!")
	return _result


## 直接返回此请求的结果的元二进制数据数组
func get_as_byte()->PackedByteArray:
	return body


func get_as_image()->Image:
	var img:Image = Image.new()
	var formats:Array[String] = ["jpg","png","bmp","webp","tga"]
	for ext in formats:
		var err:int = img.call("load_%s_from_buffer"% ext,body)
		if !err:
			Logger.info("成功将Http请求结果获取为%s格式的图像实例!"% ext)
			return img
	Logger.error("无法将Http请求结果获取为图像实例，请求结果可能是不支持的图像格式 (支持的格式为: %s)，或无法被解析为图像!"% formats)
	return null

	
func get_as_png_image()->Image:
	var img:Image = Image.new()
	var err:int = img.load_png_from_buffer(body)
	if !err:
		Logger.info("成功将Http请求结果获取为png格式的图像实例!")
		return img
	else:
		Logger.error("无法将Http请求结果获取为png格式的图像实例，请检查其格式是否正确!")
		return null
	
	
func get_as_jpg_image()->Image:
	var img:Image = Image.new()
	var err:int = img.load_jpg_from_buffer(body)
	if !err:
		Logger.info("成功将Http请求结果获取为jpg格式的图像实例!")
		return img
	else:
		Logger.error("无法将Http请求结果获取为jpg格式的图像实例，请检查其格式是否正确!")
		return null
	
	
func get_as_bmp_image()->Image:
	var img:Image = Image.new()
	var err:int = img.load_bmp_from_buffer(body)
	if !err:
		Logger.info("成功将Http请求结果获取为bmp格式的图像实例!")
		return img
	else:
		Logger.error("无法将Http请求结果获取为bmp格式的图像实例，请检查其格式是否正确!")
		return null
	
	
func get_as_tga_image()->Image:
	var img:Image = Image.new()
	var err:int = img.load_tga_from_buffer(body)
	if !err:
		Logger.info("成功将Http请求结果获取为tga格式的图像实例!")
		return img
	else:
		Logger.error("无法将Http请求结果获取为tga格式的图像实例，请检查其格式是否正确!")
		return null


func get_as_webp_image()->Image:
	var img:Image = Image.new()
	var err:int = img.load_webp_from_buffer(body)
	if !err:
		Logger.info("成功将Http请求结果获取为webp格式的图像实例!")
		return img
	else:
		Logger.error("无法将Http请求结果获取为webp格式的图像实例，请检查其格式是否正确!")
		return null


func save_to_file(path:String)->int:
	var file:FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file:
		file.store_buffer(body)
		Logger.info("成功将Http请求结果储存到以下路径的文件: "+path)
	else:
		Logger.error("无法将Http请求结果储存到以下路径，请检查路径拼写及文件权限是否有误: "+path)
	return FileAccess.get_open_error()
