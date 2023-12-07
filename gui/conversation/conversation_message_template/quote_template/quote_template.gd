extends PanelContainer


var message = null
func set_message(cur_message):
	message = cur_message
	set_quote_array()

func set_quote_array():
	var all_child = %QuoteContainer.get_children()
	for child_node in all_child:
		child_node.queue_free()
	
	if message.quote_array:
		for child_message in message.quote_array:
			var cur_label = Label.new()
			%QuoteContainer.add_child(cur_label)
			cur_label.text = child_message
