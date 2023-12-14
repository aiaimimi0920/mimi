extends PanelContainer

var current_size: Vector2i = Vector2i(1, 1)
var aspect: float
var root_size:Vector2

func play_pause_trigger(toggled_on):
	if toggled_on:
		play_trigger()
	else:
		pause_trigger()
	
func pause_trigger():
	%Timer.stop()
	%VideoStreamPlayer.set_paused(true)
	
func play_trigger():
	%Timer.start()
	if %VideoStreamPlayer.paused:
		%VideoStreamPlayer.set_paused(false)
	else:
		init_stream()
		%VideoStreamPlayer.play()
	
func stop_trigger():
	%Timer.stop()
	%VideoStreamPlayer.stop()
	

## Note that only the OGV format is supported, and other formats cannot be played properly
func init_stream():
	if %VideoStreamPlayer.stream:
		return 
	var cur_video_path = message.get_video_path()
	if cur_video_path != "":
		if cur_video_path.get_extension().to_upper() == "OGV" and not (cur_video_path.to_upper().begins_with("HTTP")):
			var video = VideoStreamTheora.new()
			video.file = cur_video_path
			set_stream(video)
		else:
			var video = FFmpegVideoStream.new()
			video.file = cur_video_path
			set_stream(video)

func set_stream(stream):
	%VideoStreamPlayer.stream = stream
	if message.video_width and message.video_height:
		root_size = Vector2(message.video_width, message.video_height)

	var total_stream_time = %VideoStreamPlayer.get_stream_length()
	%TimeSlider.min_value = 0
	%TimeSlider.max_value = total_stream_time
	%TimeSlider.step = 1
	var now_time_str = format_time_str(total_stream_time)
	%TotalTime.text = now_time_str

func set_stream_volume(volume_data):
	%VideoStreamPlayer.volume_db = linear_to_db(volume_data)

var update_size_flag = false

func _process(delta):
	if update_size_flag:
		_update_size()
		

func _update_size():
	aspect = float(current_size.x) / float(current_size.y)
	var root_aspect = root_size.x / root_size.y
	if root_size:
		if current_size == Vector2i(1, 1):
			%VideoStreamPlayer.custom_minimum_size = Vector2(root_size.x, root_size.y)
			return	
		if root_aspect > aspect:
			# Fit height
			%VideoStreamPlayer.custom_minimum_size = Vector2(root_size.y * aspect, root_size.y)
		else:
			# Fit width
			%VideoStreamPlayer.custom_minimum_size = Vector2(root_size.x, root_size.x / aspect)
	else:
		%VideoStreamPlayer.custom_minimum_size = Vector2(current_size.x, current_size.y)
	update_size_flag = false

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
	
func _on_video_stream_player_finished():
	%Timer.stop()
	%PlayButton.set_pressed_no_signal(false)
	#%VideoStreamPlayer.stop()
	#await get_tree().process_frame
	#%VideoStreamPlayer.stream = null
	

func set_video_name_info(video_name = ""):
	%VideoLabel.text = video_name

func format_time_str(time_num):
	var now_time = int(round(time_num))
	var now_time_str = "%02d"%(int(now_time/60))+":"+"%02d"%(int(now_time%60))
	return now_time_str

var message = null
func set_message(cur_message):
	message = cur_message
	set_video_name_info(message.video_name)

var drag_started = false
func _on_time_slider_drag_started():
	drag_started = true

var last_drag_time = 0
func _on_time_slider_drag_ended(value_changed):
	if value_changed:
		last_drag_time = %TimeSlider.value
		%VideoStreamPlayer.stream_position = %TimeSlider.value
	drag_started = false


## Reset the current time of video every second
func _on_timer_timeout():
	var now_time = %VideoStreamPlayer.stream_position

	var now_time_str = format_time_str(now_time)
	%NowTime.text = now_time_str
	if not drag_started:
		%TimeSlider.value = round(now_time)

func _ready():
	_init_stream_player()
	test_message()

func test_message():
	var cur_message = VideoConversationMessage.new("a_e_123_456")
	cur_message.video_width = 300
	cur_message.video_height = 500
	#cur_message.video_ref_path = r"C:\Users\xxx\Downloads\trailer.mp4"
	cur_message.video_url = r"https://media.w3.org/2010/05/sintel/trailer.mp4"
	cur_message.video_name = "just_test"
	cur_message.video_id = "test1"
	set_message(cur_message)
	
