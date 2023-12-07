extends PanelContainer

func _on_play_button_toggled(toggled_on):
	if toggled_on:
		if message.get_audio_path() == "":
			message.begin_download()
			await message.download_finish
			init_stream()
			if %PlayButton.button_pressed == false:
				return 
				
		%Timer.start()
		if %audio_stream_player.stream_paused == true:
			%audio_stream_player.stream_paused = false
		else:
			%audio_stream_player.play()
			
	else:
		%Timer.stop()
		%audio_stream_player.stream_paused = true


var total_stream_time
func set_stream(stream):
	%audio_stream_player.stream = stream
	total_stream_time = %audio_stream_player.stream.get_length()
	%TimeSlider.min_value = 0
	%TimeSlider.max_value = total_stream_time
	%TimeSlider.step = 1
	var now_time_str = format_time_str(total_stream_time)
	%TotalTime.text = now_time_str


func _init_stream_player():
	%audio_stream_player.volume_db = linear_to_db(0.5)
	
func _on_audio_stream_player_finished():
	%Timer.stop()
	%PlayButton.set_pressed_no_signal(false)


func format_time_str(time_num):
	var now_time = int(round(time_num))
	var now_time_str = "%02d"%(int(now_time/60))+":"+"%02d"%(int(now_time%60))
	return now_time_str


## Reset the current time of music every second
func _on_timer_timeout():
	var now_time = %audio_stream_player.get_playback_position()
	var now_time_str = format_time_str(now_time)
	%NowTime.text = now_time_str
	%TimeSlider.value = round(now_time)

var message = null
func set_message(cur_message):
	message = cur_message
	init_stream()
	
	
func init_stream():
	var cur_audio_path = message.get_audio_path()
	var target_type = "MP3"
	if cur_audio_path != "":
		if cur_audio_path.get_extension().to_upper() == "OGG":
			target_type = "OGG"
		elif cur_audio_path.get_extension().to_upper() == "MP3":
			target_type = "MP3"
			
		var voice
		if target_type == "OGG":
			voice = AudioStreamOggVorbis.new()
			voice = AudioStreamOggVorbis.load_from_buffer(message.get_audio_buffer_data())
		else:
			voice = AudioStreamMP3.new()
			voice.data = message.get_audio_buffer_data()
	
		set_stream(voice)

func _ready():
	_init_stream_player()
