@tool
extends Resource
class_name ggsSetting

var current: Variant: set = set_current, get = get_current
var default: Variant
var value_type: Variant.Type
var value_hint: PropertyHint
var value_hint_string: String
var name: String: get = get_name
var category: String: get = get_category
var read_only_values: bool = false
var show_visible: bool = true # 为false的时候不显示在面板中
var show_name: String:
	get:
		if show_name==null or show_name=="":
			return name
		return show_name

var show_ui: int = 0
var save_path:String

func _get_property_list() -> Array:
	var read_only: PropertyUsageFlags =  PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
	var current_default_usage: PropertyUsageFlags = read_only if read_only_values else PROPERTY_USAGE_DEFAULT
	var enum_string_types: String = ggsUtils.get_enum_string("Variant.Type")
	var enum_string_property_hints: String = ggsUtils.get_enum_string("PropertyHint")
	var enum_string_ui_types: String = ggsUtils.get_enum_string("UIType")
	
	var properties: Array
	properties.append_array([
		{"name": "Game Setting", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY},
		{"name": "current", "type": value_type, "usage": current_default_usage, "hint": value_hint, "hint_string": value_hint_string},
		{"name": "default", "type": value_type, "usage": current_default_usage, "hint": value_hint, "hint_string": value_hint_string},
		{"name": "Internal", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP},
		{"name": "name", "type": TYPE_STRING, "usage": read_only},
		{"name": "category", "type": TYPE_STRING, "usage": read_only},
		{"name": "value_type", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_ENUM, "hint_string": enum_string_types},
		{"name": "value_hint", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_ENUM, "hint_string": enum_string_property_hints},
		{"name": "value_hint_string", "type": TYPE_STRING, "usage": PROPERTY_USAGE_DEFAULT},
		{"name": "show_visible", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT},
		{"name": "show_name", "type": TYPE_STRING, "usage": PROPERTY_USAGE_DEFAULT},
		{"name": "show_ui", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_ENUM, "hint_string": enum_string_ui_types},
	])
	
	return properties


func _get(property: StringName) -> Variant:
	if property == "resource_name":
		resource_name = name
		return resource_name
	
	return null


func set_current(value: Variant) -> void:
	current = value
	
	if not category.is_empty() or not name.is_empty():
		var cur_file = ggsSaveFile.new()
		cur_file.set_path(save_path)
		cur_file.set_key(category, name, value)


func get_current() -> Variant:
	var save_file: ggsSaveFile = ggsSaveFile.new()
	save_file.set_path(save_path)
	if save_file.has_section_key(category, name):
		return save_file.get_value(category, name)
	else:
		return default


func get_name() -> String:
	var path_dict: Dictionary = _get_path_dict()
	var group: String = ""
	if path_dict["group"].is_empty():
		return path_dict["name"]
	else:
		return "%s_%s"%[path_dict["group"], path_dict["name"]]


func get_category() -> String:
	return _get_path_dict()["category"]


func _get_path_dict() -> Dictionary:
	var result: Dictionary = {
		"category": "",
		"group": "",
		"name": "",
	}
	
	var path_array = resource_path.split("/")
	var target_index = len(path_array)-1
	for i in range(len(path_array)-1,-1,-1):
		if path_array[i]=="settings":
			target_index = i
			break
	var dir_settings = "/".join(path_array.slice(0,target_index+1))
	var base_path: String = resource_path.trim_prefix(dir_settings)
	var path_components: PackedStringArray = base_path.split("/", false)
	
	if path_components.size() < 2 or path_components.size() > 3:
		return result
	
	result["category"] = path_components[0]
	if path_components.size() == 3:
		result["group"] = path_components[1]
		result["name"] = path_components[2].get_basename()
	else:
		result["name"] = path_components[1].get_basename()
	
	return result
