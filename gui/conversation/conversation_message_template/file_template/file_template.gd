extends PanelContainer


## Do you want to add your favorite files?
## TODO
func _on_like_button_toggled(toggled_on):
	pass # Replace with function body.


## open file
func _on_file_button_pressed():
	OS.shell_open(message.get_file_path())

## open dir
func _on_folder_button_pressed():
	OS.shell_show_in_file_manager(message.get_file_path())

var message = null
func set_message(cur_message):
	message = cur_message
	%FileNameLabel.text = message.file_name
	%FileSize.text = message.get_format_file_size(message.file_size)
	update_download_button_status()

		
func update_download_button_status():
	var show_download_button = false
	show_download_button = message.get_file_path()== ""
	%DownloadButton.visible = show_download_button
	%FileButton.visible = not show_download_button
	%FolderButton.visible = not show_download_button


## TODO:Update the download progress here, or callback the update through the downloader's signal
func _on_timer_timeout():
	pass # Replace with function body.


func _on_download_button_toggled(toggled_on):
	if toggled_on == true:
		## TODO:Start downloading, note that the logic for handling possible breakpoint downloads needs to be handled here
		message.connect("download_finish", message_download_finish)
		message.begin_download()
		pass
	else:
		## TODO:Pause download here
		pass

func message_download_finish():
	update_download_button_status()
	%TextureProgressBar.value = 100
	%FileSize.text = message.get_format_file_size(message.file_size)

