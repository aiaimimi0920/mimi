extends PanelContainer

var current_size: Vector2i = Vector2i(1, 1)
var aspect: float
var root_size:Vector2

enum VideoPlayerType {NATIVE, FFMPEG}

var use_type = VideoPlayerType.NATIVE


var now_play_position:
	get:
		if use_type == VideoPlayerType.NATIVE:
			return %NativeVideoStreamPlayer.stream_position
		elif use_type == VideoPlayerType.FFMPEG:
			return %FFmpegMediaPlayer.get_playback_position()

var stream_length:
	get:
		if use_type == VideoPlayerType.NATIVE:
			return %NativeVideoStreamPlayer.get_stream_length()
		elif use_type == VideoPlayerType.FFMPEG:
			return %FFmpegMediaPlayer.get_length()

var player_paused:
	set(val):
		if use_type == VideoPlayerType.NATIVE:
			%NativeVideoStreamPlayer.paused = val
		elif use_type == VideoPlayerType.FFMPEG:
			%FFmpegMediaPlayer.set_paused(val)
	get:
		if use_type == VideoPlayerType.NATIVE:
			return %NativeVideoStreamPlayer.paused
		elif use_type == VideoPlayerType.FFMPEG:
			return %FFmpegMediaPlayer.is_paused()

func player_play():
	if use_type == VideoPlayerType.NATIVE:
		%NativeVideoStreamPlayer.play()
	elif use_type == VideoPlayerType.FFMPEG:
		%FFmpegMediaPlayer.play()

func player_stop():
	if use_type == VideoPlayerType.NATIVE:
		%NativeVideoStreamPlayer.stop()
	elif use_type == VideoPlayerType.FFMPEG:
		%FFmpegMediaPlayer.stop()

func _on_play_button_toggled(toggled_on):
	if toggled_on:
		%Timer.start()
		if player_paused == true:
			player_paused = false
		else:
			init_stream()
			waiting_playing = true
			changed_time_slider = true
			player_play()
	else:
		%Timer.stop()
		player_paused = true
		

func set_stream(stream):
	if use_type == VideoPlayerType.NATIVE:
		%NativeVideoStreamPlayer.stream = stream
	elif use_type == VideoPlayerType.FFMPEG:
		%FFmpegMediaPlayer.load_path(stream)

	if message.video_width and message.video_height:
		root_size = Vector2(message.video_width, message.video_height)

	var total_stream_time = stream_length
	%TimeSlider.min_value = 0
	%TimeSlider.max_value = total_stream_time
	%TimeSlider.step = 1
	var now_time_str = format_time_str(total_stream_time)
	%TotalTime.text = now_time_str

func set_stream_volume(volume_data):
	%AudioStreamPlayer.volume_db = linear_to_db(volume_data)

var update_size_flag = false

func _process(delta):
	if update_size_flag:
		_update_size()
		

func _update_size():
	var show_node
	if use_type == VideoPlayerType.NATIVE:
		show_node = %NativeVideoStreamPlayer
	elif use_type == VideoPlayerType.FFMPEG:
		show_node = %FFmpegVideoTextureRect

	aspect = float(current_size.x) / float(current_size.y)
	var root_aspect = root_size.x / root_size.y
	if root_size:
		if current_size == Vector2i(1, 1):
			show_node.custom_minimum_size = Vector2(root_size.x, root_size.y)
			return	
		if root_aspect > aspect:
			# Fit height
			show_node.custom_minimum_size = Vector2(root_size.y * aspect, root_size.y)
		else:
			# Fit width
			show_node.custom_minimum_size = Vector2(root_size.x, root_size.x / aspect)
	else:
		show_node.custom_minimum_size = Vector2(current_size.x, current_size.y)
		pass
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
var last_play_position = 0
var will_close = false
## Reset the current time of video every second
func _on_timer_timeout():
	var now_time = now_play_position
	var now_time_str = format_time_str(now_time)
	%NowTime.text = now_time_str
	if waiting_playing:
		if not drag_started:
			%TimeSlider.value = last_drag_time
		if round(now_time)-3 <= last_drag_time and last_drag_time<=round(now_time)+3:
			if now_time!=0:
				waiting_playing = false
	else:
		if now_time==0:
			if waiting_playing == false and changed_time_slider == false and will_close:
				# need stop music
				%PlayButton.set_pressed_no_signal(false)
				player_stop()
				%Timer.stop()
				waiting_playing = false
				last_drag_time = 0
				if not drag_started:
					%TimeSlider.value = 0
				will_close = false
				pass
			else:
				if not drag_started:
					%TimeSlider.value = last_drag_time
				
		else:
			if not drag_started:
				%TimeSlider.value = round(now_time)
			if changed_time_slider:
				changed_time_slider = false
			
			if now_time>=stream_length-3:
				will_close = true
		

var message = null
func set_message(cur_message):
	message = cur_message
	set_video_name_info(message.video_name)
	
## Note that only the OGV format is supported, and other formats cannot be played properly
func init_stream():
	var cur_video_path = message.get_video_path()
	if cur_video_path != "":
		if cur_video_path.get_extension().to_upper() == "OGV" and not (cur_video_path.to_upper().begins_with("HTTP")):
			use_type = VideoPlayerType.NATIVE
			var voice = VideoStreamTheora.new()
			voice.file = cur_video_path
			set_stream(voice)
		else:
			use_type = VideoPlayerType.FFMPEG
			set_stream(cur_video_path)
			

var drag_started = false
func _on_time_slider_drag_started():
	drag_started = true


var last_drag_time = 0
var changed_time_slider = false
func _on_time_slider_drag_ended(value_changed):
	if value_changed:
		if use_type == VideoPlayerType.NATIVE:
			last_drag_time = %TimeSlider.value
			%NativeVideoStreamPlayer.stream_position = %TimeSlider.value
			waiting_playing = true
			changed_time_slider = true
		else:
			if waiting_playing == false:
				## because this: https://github.com/Elly2018/elly_videoplayer/issues/5
				## so modification of progress bar is not allowed
				last_drag_time = %TimeSlider.value
				%FFmpegMediaPlayer.seek(%TimeSlider.value)
				waiting_playing = true
				changed_time_slider = true
	drag_started = false

func _on_ffmpeg_media_player_video_update(tex:Texture2D, size:Vector2i):
	if current_size!=size:
		update_size_flag = true
		current_size = size
	if (%FFmpegVideoTextureRect != null):
		%FFmpegVideoTextureRect.set_deferred("texture", tex);


func _ready():
	_init_stream_player()
	#test_message()

func test_message():
	var cur_message = VideoConversationMessage.new("a_e_123_456")
	cur_message.video_width = 300
	cur_message.video_height = 500
	#cur_message.video_ref_path = r"C:\Users\xxx\Downloads\xxx.mp4"
	#cur_message.video_ref_path = r"C:\Users\xxx\Downloads\video_en.ogv"
	cur_message.video_url = r"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
	cur_message.video_name = "just_test"
	cur_message.video_id = "test1"
	set_message(cur_message)
