extends PanelContainer

var current_size: Vector2i = Vector2i(1, 1)
var aspect: float
var root_size:Vector2

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
		printt("%FFmpegMediaPlayer.is_paused()",%FFmpegMediaPlayer.is_paused())
		if %FFmpegMediaPlayer.is_paused() == true:
			%FFmpegMediaPlayer.set_paused(false)
		else:
			printt("kkkkkkkkkkkkk")
			init_stream()
			waiting_playing = true
			%FFmpegMediaPlayer.play()
	else:
		%Timer.stop()
		%FFmpegMediaPlayer.set_paused(true)

var total_stream_time
func set_stream_path(stream_path):
	printt("000000000")
	%FFmpegMediaPlayer.load_path(stream_path)
	printt("11111111111111")
	if message.video_width and message.video_height:
		root_size = Vector2(message.video_width, message.video_height)
	printt("2222222222222")
	total_stream_time = %FFmpegMediaPlayer.get_length()
	printt("3333333333333")
	%TimeSlider.min_value = 0
	%TimeSlider.max_value = total_stream_time
	%TimeSlider.step = 1
	var now_time_str = format_time_str(total_stream_time)
	%TotalTime.text = now_time_str


var update_size_flag = false

func _process(delta):
	if update_size_flag:
		_update_size()
		

func _update_size():
	aspect = float(current_size.x) / float(current_size.y);
	var root_aspect = root_size.x / root_size.y
	if root_size:
		if current_size == Vector2i(1, 1):
			%VideoTextureRect.custom_minimum_size = Vector2(root_size.x, root_size.y)
			return	
		if root_aspect > aspect:
			# Fit height
			%VideoTextureRect.custom_minimum_size = Vector2(root_size.y * aspect, root_size.y)
		else:
			# Fit width
			%VideoTextureRect.custom_minimum_size = Vector2(root_size.x, root_size.x / aspect)
	else:
		%VideoTextureRect.custom_minimum_size = Vector2(current_size.x, current_size.y)
		pass
	update_size_flag = false

func set_stream_volume(volume_data):
	%AudioStreamPlayer.volume_db = linear_to_db(volume_data)


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
	%FFmpegMediaPlayer.set_player(%AudioStreamPlayer)
	
	
func _on_audio_stream_player_finished():
	%Timer.stop()
	%PlayButton.set_pressed_no_signal(false)

func set_video_name_info(video_name = ""):
	%VideoLabel.text = video_name

func format_time_str(time_num):
	var now_time = int(round(time_num))
	var now_time_str = "%02d"%(int(now_time/60))+":"+"%02d"%(int(now_time%60))
	return now_time_str

var waiting_playing = false
## Reset the current time of video every second
func _on_timer_timeout():
	var now_time = %FFmpegMediaPlayer.get_playback_position()
	var length = %FFmpegMediaPlayer.get_length()
	var now_time_str = format_time_str(now_time)
	%NowTime.text = now_time_str
	if not drag_started:
		%TimeSlider.value = round(now_time)
	if waiting_playing:
		if now_time!=0:
			waiting_playing = false
	else:
		if now_time==0:
			if waiting_playing == false:
				## need stop music
				%PlayButton.set_pressed_no_signal(false)
				%FFmpegMediaPlayer.stop()
				%Timer.stop()
				waiting_playing = false
				last_drag_time = 0
			else:
				%TimeSlider.value = last_drag_time
		else:
			if not drag_started:
				%TimeSlider.value = round(now_time)
		

var message = null
func set_message(cur_message):
	message = cur_message
	set_video_name_info(message.video_name)
	#init_stream()
	
## Note that only the OGV format is supported, and other formats cannot be played properly
func init_stream():
	var cur_video_path = message.get_video_path()
	set_stream_path(cur_video_path)
	pass
	#var cur_video_path = message.get_video_path()
	#set_stream_path(cur_video_path)
	

var drag_started = false
func _on_time_slider_drag_started():
	drag_started = true


var last_drag_time = 0
func _on_time_slider_drag_ended(value_changed):
	if value_changed:
		waiting_playing = true
		last_drag_time = %TimeSlider.value
		%FFmpegMediaPlayer.seek(%TimeSlider.value)
	drag_started = false

func _on_ffmpeg_media_player_video_update(tex:Texture2D, size:Vector2i):
	if current_size!=size:
		update_size_flag = true
		current_size = size
	if (%VideoTextureRect != null):
		%VideoTextureRect.set_deferred("texture", tex);


func _ready():
	_init_stream_player()
	test_message()

func test_message():
	var message111111111 = VideoConversationMessage.new("a_e_123_456")
	message111111111.video_width = 300
	message111111111.video_height = 500
	#message111111111.video_url = r"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
	message111111111.video_ref_path = r"C:\Users\vmjcv\Downloads\23年6月编程固件说明校验软件包\23年6月编程固件说明校验软件包\键盘固件升级工具mac版\MAC升级指导视频.mp4"
	#message111111111.video_url = r"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
	message111111111.video_name = "test1"
	message111111111.video_id = "qqqq"
	set_message(message111111111)


