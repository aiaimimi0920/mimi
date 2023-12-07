#
# Class: Appender
#	Responsible for Delivering a Log Event to its Destination.
#

class_name Appender
extends Resource


var layout: Layout = PatternLayout.new()
var logger_format: int = 030

var _logger_level : int = 999

var logger_level :
	get:
		return _logger_level
	set(value):
		_logger_level = value
	
var name = "appender"
var is_open = false


func _set_logger_level(level: int):
	logger_level = level

var _logger_name : String = ""

var logger_name :
	get:
		return _logger_name
	set(value):
		_logger_name = value

func _set_logger_name(cur_name: String):
	logger_name = cur_name

#Function: start
#	Start this Appender
func start():
	pass

#Function: stop
#	Stop this Appender
func stop():
	pass

#Function: append
#	Logs an Event in whatever logic this Appender has
func append(message: LoggerMessage):
	pass


#Function: append_raw
#	Send Raw Text to the Appender
func append_raw(text: String):
	pass


func _init():
	pass
