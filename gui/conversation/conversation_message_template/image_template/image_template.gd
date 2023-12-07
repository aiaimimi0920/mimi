extends PanelContainer


## Do you want to add your favorite files?
## TODO
func _on_like_button_toggled(toggled_on):
	pass

var message = null
func set_message(cur_message):
	message = cur_message
	set_image_texture()

func set_image_texture():
	var image_body = message.get_image_buffer_data()
	if image_body.is_empty():
		message.connect("download_finish", set_image_texture)
		message.begin_download()
	else:
		var texture
		var source_size
		var image = Image.new()
		var is_gif = false
		if message.image_ref_path:
			if message.image_ref_path.get_extension()=="gif":
				var result = GifImage.read(message.image_ref_path)
				texture = result[0]
				source_size = result[1]
			else:
				image = image.load_from_file(message.image_ref_path)
				texture = ImageTexture.new()
				texture = texture.create_from_image(image)
				source_size = image.get_size()
		else:
			if image_body and image_body.is_empty()==false:
				var image_error = image.load_webp_from_buffer(image_body)
				if image_error != OK:
					image_error = image.load_jpg_from_buffer(image_body)
					if image_error != OK:
						## 可能是gif格式
						is_gif = true
				if is_gif:
					var result = GifImage.read_buffer(image_body)
					texture = result[0]
					source_size = result[1]
				else:
					texture = ImageTexture.new()
					texture = texture.create_from_image(image)
					source_size = image.get_size()
		
		if message.image_width and message.image_height:
			var target_size = Vector2(message.image_width, message.image_height)
			if target_size:
				source_size = target_size
		
		%ImageTexture.texture = texture
		%ImageTexture.custom_minimum_size = source_size

