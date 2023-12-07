extends PanelContainer

@export var use_modulate:Color
@export var not_use_modulate:Color

func _on_loop_button_toggled(toggled_on):
	if toggled_on:
		%LoopButton.modulate = use_modulate
	else:
		%LoopButton.modulate = not_use_modulate
	


func _on_play_button_toggled(toggled_on):
	if toggled_on:
		## download file
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

func set_stream_volume(volume_data):
	%audio_stream_player.volume_db = linear_to_db(volume_data)


## Do you want to add your favorite music?
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
	
	## Using set_pressed_no_signal prevents loop callback
	if value!=0 and %MuteButton.button_pressed == true:
		%MuteButton.set_pressed_no_signal(false)
	elif value==0 and %MuteButton.button_pressed == false:
		%MuteButton.set_pressed_no_signal(true)



func _init_stream_player():
	%VolumeSlider.value = last_play_volume_value
	
	
func _on_audio_stream_player_finished():
	if %LoopButton.button_pressed == true:
		%Timer.start()
		%audio_stream_player.play()
	else:
		%Timer.stop()
		%PlayButton.set_pressed_no_signal(false)

func set_audio_name_info(album_name = "",song_name = "",signer_name = ""):
	%AlbumLabel.visible = album_name!=""
	%SplitOne.visible = album_name!=""
	%AlbumLabel.text = str(album_name)
	
	%SongLabel.visible = song_name!=""
	%SplitTwo.visible = song_name!=""
	%SongLabel.text = str(song_name)

	%SignerLabel.visible = signer_name!=""
	%SignerLabel.text = str(signer_name)

func format_time_str(time_num):
	var now_time = int(round(time_num))
	var now_time_str = "%02d"%(int(now_time/60))+":"+"%02d"%(int(now_time%60))
	return now_time_str


## Reset the current time of music every second
func _on_timer_timeout():
	var now_time = %audio_stream_player.get_playback_position()
	var now_time_str = format_time_str(now_time)
	%NowTime.text = now_time_str
	if not drag_started:
		%TimeSlider.value = round(now_time)
	var lryic_time = now_time*60
	if next_lyric_index<audio_lyric_map.size():
		while lryic_time>=audio_lyric_map[next_lyric_index].time:
			if next_lyric_index<audio_lyric_map.size():
				if lryic_time<audio_lyric_map[next_lyric_index+1].time:
					## Switch to this display line
					%ScrollLyric.set_scroll_text(audio_lyric_map[next_lyric_index].content)
					next_lyric_index = next_lyric_index + 1
					break
				else:
					## the middle attribute should be ignored
					## This logic should not be reached. If it occurs, it is likely that the timeout is too fast
					next_lyric_index = next_lyric_index + 1
					pass
			else:
				%ScrollLyric.set_scroll_text(audio_lyric_map[next_lyric_index].content)
				next_lyric_index = 0
				break


func set_audio_texture(cur_texture):
	%SongTexture.texture = cur_texture
	pass


var audio_lyric = ""
var audio_lyric_map = []
var audio_all_lyric = ""
var next_lyric_index = 0
func set_audio_lyric(cur_audio_lyric):
	audio_lyric = cur_audio_lyric
	var regex = RegEx.new()
	regex.compile("\\[(?<minute>\\d+):(?<second>\\d+)\\.(?<millisecond>\\d+)\\](?<content>.*)")
	
	for cur_one_lyric in cur_audio_lyric.split("\n"):
		var result = regex.search(cur_one_lyric)
		if result:
			var cur_time = 0
			var minute = result.get_string("minute")
			if minute!="":
				cur_time+=int(minute)
			cur_time*=60
			
			var second = result.get_string("second")
			if second!="":
				cur_time+=int(second)
			
			cur_time*=60
			
			var millisecond = result.get_string("millisecond")
			if millisecond!="":
				## Some milliseconds may have multiple fields, so only the first two digits are taken
				cur_time+=int(str(int(minute)).left(2))
			
			audio_lyric_map.append({
				"time":cur_time,
				"content":result.get_string("content")
			})
			audio_all_lyric+=result.get_string("content")
			audio_all_lyric+="\n"
	
	%AllLyric.text = audio_all_lyric

var message = null
func set_message(cur_message):
	message = cur_message
	set_audio_name_info("",message.audio_name, message.audio_singer)
	set_audio_texture(message.get("audio_texture"))
	set_audio_lyric(message.get_audio_lyric_buffer_data().get_string_from_utf8())
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

		## Note that time will use the actual length of the file being used, rather than using the time of the message
		set_stream(voice)
	

func _on_lyric_container_mouse_entered():
	%AllLyric.visible = true
	%ScrollLyric.visible = false


func _on_lyric_container_mouse_exited():
	if %AllLyric.get_global_rect().has_point(get_viewport().get_mouse_position()):
		pass
	else:
		%AllLyric.visible = false
		%ScrollLyric.visible = true

var drag_started = false
func _on_time_slider_drag_started():
	drag_started = true


func _on_time_slider_drag_ended(value_changed):
	if value_changed:
		%audio_stream_player.seek(%TimeSlider.value)
		next_lyric_index = 0
	drag_started = false

func _ready():
	_init_stream_player()

