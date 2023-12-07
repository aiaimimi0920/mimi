
#
#Class: ConsoleAppender
#	Logs an Event to the Console Window.
#

class_name ConsoleAppender
extends Appender

func append(message: LoggerMessage):
	print(layout.build(message, logger_format))


func append_raw(text: String):
	print(text)


func _init():
	name = "console appender"
	print("** Console Appender Initialized **")
	print(" ")
