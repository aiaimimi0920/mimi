extends Label

@export var scroll_speed:float = 60

func _process(delta):
	if need_scroll:
		position.x -= scroll_speed * delta
		if position.x < -size.x:
			position.x = 0

var need_scroll = false

func set_scroll_text(val):
	text = val
	position.x = 0
	if self.size.x>get_parent().size.x:
		need_scroll = true
		
