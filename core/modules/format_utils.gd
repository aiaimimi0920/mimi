class_name FormatUtils

## Unit in bytes
static func get_format_file_size(cur_file_size):
	if typeof(cur_file_size)==TYPE_INT or typeof(cur_file_size)==TYPE_FLOAT:
		var kb = int(cur_file_size/1024)
		var show_kb = int(kb%1024)
		var mb = int(kb/1024)
		var show_mb = mb%1024
		var gb = int(mb/1024)
		var show_gb = gb%1024
		var tb = int(gb/1024)
		var show_tb = tb
		if show_tb!=0:
			## Display TB
			return "%.2f TB"%(show_tb+(show_gb*1.0/1024))
		if show_gb!=0:
			## Display GB
			return "%.2f GB"%(show_gb+(show_mb*1.0/1024))
		if show_mb!=0:
			## Display MB
			return "%.2f MB"%(show_mb+(show_kb*1.0/1024))
		if show_kb!=0:
			## Display KB
			return "%.2f KB"%(show_kb)
		return "0 KB"
	if cur_file_size:
		return cur_file_size
	else:
		return "0 KB"

## Unit in bytes
static func get_format_time(cur_time):
	if typeof(cur_time)==TYPE_INT or typeof(cur_time)==TYPE_FLOAT:
		var second = int(floor(cur_time))
		var show_second = int(second%60)
		
		var minute = int(floor(cur_time/60))
		var show_minute = int(floor(minute%60))
		
		var hour = int(floor(minute/60))
		var show_hour = int(floor(hour%24))
		
		var day = int(floor(hour/24))
		var show_day = int(day)
		
		if show_day!=0:
			return "%d day %d hour "%[show_day,show_hour]
		if show_hour!=0:
			return "%d hour %d minute "%[show_hour,show_minute]
		if show_minute!=0:
			return "%d minute %d second "%[show_minute,show_second]
		if show_second!=0:
			return "%d second "%[show_second]
		return "0 second"
	if cur_time:
		return cur_time
	else:
		return "0 second"
