extends Window


var data:
	get:
		return data
	
	set(val):
		data = val
		update_ui()

func update_ui():
	%Icon.texture = data.get("icon",null)
	%NameVersionLabel.text = data.get("name","unknown")+" "+data.get("version","v1_0_0")
	%AuthorLabel.text = data.get("author","anonymous")
	%WebsiteLinkButton.text = data.get("url","")
	%WebsiteLinkButton.uri = data.get("url","")
	var cur_description = data.get("description",null)
	if cur_description!=null:
		%DescriptionVBoxContainer.visible = true
		%DescriptionLabel.text = cur_description
		pass
	else:
		%DescriptionVBoxContainer.visible = false
	
	var cur_dependency = data.get("dependency",{})
	var use_dependency_version = data.get("use_dependency_version",{})
	if cur_dependency.is_empty()==false:
		%DependencyVBoxContainer.visible = true
		var all_children = %DependencyContainer.get_children()
		for node in all_children:
			node.queue_free()
		
		for dependency_name in cur_dependency:
			var cur_dependency_data = cur_dependency[dependency_name]
			var cur_label = Label.new()
			if len(cur_dependency_data) == 1:
				## Only the minimum version
				cur_label.text = dependency_name+" "+use_dependency_version.get(dependency_name,"-")+"(%s)"%[cur_dependency_data[0]]
				pass
			elif len(cur_dependency_data) == 2:
				## minimum version and maximum version
				cur_label.text = dependency_name+" "+use_dependency_version.get(dependency_name,"-")+"(%s-%s)"%[cur_dependency_data[0],cur_dependency_data[1]]
				pass
			else:
				cur_label.text = dependency_name+" "+use_dependency_version.get(dependency_name,"-")
			
			%DependencyContainer.add_child(cur_label)
			pass
		pass
	else:
		%DependencyVBoxContainer.visible = false

