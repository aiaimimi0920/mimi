extends PanelContainer

func _on_play_button_toggled(toggled_on):
	if toggled_on:
		## download file
		if message.get_video_path() == "":
			message.begin_download()
			await message.download_finish
			init_stream()
			if %PlayButton.button_pressed == false:
				return 
		%Timer.start()
		if %VideoStreamPlayer.paused == true:
			%VideoStreamPlayer.paused = false
		else:
			%VideoStreamPlayer.play()
	else:
		%Timer.stop()
		%VideoStreamPlayer.paused = true


var total_stream_time
func set_stream(stream):
	%VideoStreamPlayer.stream = stream
	var target_size = Vector2(message.video_width, message.video_height)
	if target_size:
		%VideoStreamPlayer.expand = true
		%VideoStreamPlayer.custom_minimum_size = target_size
	else:
		%VideoStreamPlayer.expand = false
	
	total_stream_time = %VideoStreamPlayer.get_stream_length()
	%TimeSlider.min_value = 0
	%TimeSlider.max_value = total_stream_time
	%TimeSlider.step = 1
	var now_time_str = format_time_str(total_stream_time)
	%TotalTime.text = now_time_str

func set_stream_volume(volume_data):
	%VideoStreamPlayer.volume_db = linear_to_db(volume_data)


## 是否要加入喜欢的视频，暂时不做处理?
## TODO
func _on_like_button_toggled(toggled_on):
	pass # Replace with function body.


var last_mute_volume_value = 0.5
## Record the last time when pressed, but do not record normal changes
func _on_mute_button_toggled(toggled_on):
	if toggled_on:
		last_mute_volume_value = %VolumeSlider.value
		%VolumeSlider.value = 0
	else:
		%VolumeSlider.value = last_mute_volume_value
		

var last_play_volume_value = last_mute_volume_value
## Set playback volume
func _on_h_slider_2_value_changed(value):
	if last_play_volume_value==value:
		pass
	else:
		last_play_volume_value = value
		set_stream_volume(last_play_volume_value)
	
	## using set_pressed_no_signal prevent loop callbacks
	if value!=0 and %MuteButton.button_pressed == true:
		%MuteButton.set_pressed_no_signal(false)
	elif value==0 and %MuteButton.button_pressed == false:
		%MuteButton.set_pressed_no_signal(true)

func _init_stream_player():
	%VolumeSlider.value = last_play_volume_value
	
	
func _on_audio_stream_player_finished():
	%Timer.stop()
	%PlayButton.set_pressed_no_signal(false)

func set_video_name_info(video_name = ""):
	%VideoLabel.text = video_name

func format_time_str(time_num):
	var now_time = int(round(time_num))
	var now_time_str = "%02d"%(int(now_time/60))+":"+"%02d"%(int(now_time%60))
	return now_time_str


## Reset the current time of video every second
func _on_timer_timeout():
	var now_time = %VideoStreamPlayer.stream_position
	var now_time_str = format_time_str(now_time)
	%NowTime.text = now_time_str
	if not drag_started:
		%TimeSlider.value = round(now_time)

var message = null
func set_message(cur_message):
	message = cur_message
	set_video_name_info(message.video_name)
	init_stream()
	
## Note that only the OGV format is supported, and other formats cannot be played properly
func init_stream():
	var cur_video_path = message.get_video_path()
	var target_type = "OGV"
	if cur_video_path != "":
		if cur_video_path.get_extension().to_upper() == "OGV":
			target_type = "OGV"
			
		var voice
		if target_type == "OGV":
			voice = VideoStreamTheora.new()
			voice.file = cur_video_path

		set_stream(voice)
	

var drag_started = false
func _on_time_slider_drag_started():
	drag_started = true



func _on_time_slider_drag_ended(value_changed):
	if value_changed:
		%VideoStreamPlayer.stream_position = %TimeSlider.value
	drag_started = false

func _ready():
	_init_stream_player()

