extends PanelContainer

@export var use_modulate:Color
@export var not_use_modulate:Color

func play_pause_trigger(toggled_on):
	if toggled_on:
		play_trigger()
	else:
		pause_trigger()

func pause_trigger():
	%Timer.stop()
	%AudioStreamPlayer.stream_paused = true

func play_trigger():
	%Timer.start()
	if %AudioStreamPlayer.stream_paused:
		%AudioStreamPlayer.stream_paused = false
	else:
		init_stream()
		%AudioStreamPlayer.play()

func stop_trigger():
	%Timer.stop()
	%AudioStreamPlayer.stop()


func init_stream():
	if %AudioStreamPlayer.stream:
		return 
	var cur_audio_path = message.get_audio_path()
	if cur_audio_path != "":
		if cur_audio_path.get_extension().to_upper() == "OGG" and not (cur_audio_path.to_upper().begins_with("HTTP")):
			var voice = AudioStreamOggVorbis.new()
			voice = AudioStreamOggVorbis.load_from_buffer(message.get_audio_buffer_data())
			set_stream(voice)
		elif cur_audio_path.get_extension().to_upper() == "MP3" and not (cur_audio_path.to_upper().begins_with("HTTP")):
			var voice = AudioStreamMP3.new()
			voice.data = message.get_audio_buffer_data()
			set_stream(voice)
		else:
			var voice = FFmpegAudioStream.new()
			voice.file = cur_audio_path
			set_stream(voice)

func set_stream(stream):
	%AudioStreamPlayer.stream = stream
	update_show_time()
			
func update_show_time():
	var total_stream_time = %AudioStreamPlayer.stream.get_length()
	%TimeSlider.min_value = 0
	%TimeSlider.max_value = total_stream_time
	%TimeSlider.step = 1
	var now_time_str = format_time_str(total_stream_time)
	%TotalTime.text = now_time_str
	if total_stream_time == 0:
		await get_tree().create_timer(1).timeout
		update_show_time()


func _init_stream_player():
	pass

func _on_audio_stream_player_finished():
	%Timer.stop()
	%PlayButton.set_pressed_no_signal(false)

func format_time_str(time_num):
	var now_time = int(round(time_num))
	var now_time_str = "%02d"%(int(now_time/60))+":"+"%02d"%(int(now_time%60))
	return now_time_str


var message = null
func set_message(cur_message):
	message = cur_message

## Reset the current time of audio every second
func _on_timer_timeout():
	var now_time = %AudioStreamPlayer.get_playback_position()
	var now_time_str = format_time_str(now_time)
	%NowTime.text = now_time_str
	%TimeSlider.value = round(now_time)


func _ready():
	_init_stream_player()
	#test_message()

func test_message():
	var cur_message = VoiceAudioConversationMessage.new("a_e_123_456")
	#cur_message.audio_ref_path = r"C:\Users\xxx\AppData\Roaming\Godot\app_userdata\MiMi\main\file\1.mp3"
	#cur_message.audio_ref_path = r"C:\Users\xxx\Downloads\trailer.mp4"
	cur_message.audio_url = r"https://media.w3.org/2010/05/sintel/trailer.mp4"
	cur_message.audio_name = "just_test_song"
	cur_message.audio_singer = "just_test_singer"
	cur_message.audio_id = "test1"
	set_message(cur_message)
