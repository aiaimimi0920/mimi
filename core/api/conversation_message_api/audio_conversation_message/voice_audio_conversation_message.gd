extends AudioConversationMessage
class_name VoiceAudioConversationMessage

func get_MessageType():
	return "VoiceAudio"
	
func get_as_text()->String:
	return "[Voice"+ audio_name +"]"

