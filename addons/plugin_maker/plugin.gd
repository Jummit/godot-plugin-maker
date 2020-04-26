tool
extends EditorPlugin

var create_plugin_dialog = preload("res://addons/plugin_maker/create_plugin_dialog.tscn").instance()

func _enter_tree():
	add_tool_menu_item("Create Plugin", self, "_on_CreatePlugin_clicked")
	get_editor_interface().get_base_control().add_child(create_plugin_dialog)
	create_plugin_dialog.connect("confirmed", self, "_on_CreatePluginDialog_confirmed")


func _exit_tree():
	remove_tool_menu_item("Create Plugin")
	create_plugin_dialog.queue_free()


func _on_CreatePlugin_clicked(ud):
	create_plugin_dialog.popup_centered()


func _on_CreatePluginDialog_confirmed():
	create_plugin(create_plugin_dialog.get_plugin_info())


func create_plugin(plugin_info : Dictionary):
	var plugin_folder_name : String = plugin_info.name.replace(" ", "_").to_lower()
	var plugin_path := "res://addons".plus_file(plugin_folder_name)
	
	var addons : Directory = Directory.new()
	addons.make_dir_recursive(plugin_path)
	
	var add_types_script := ""
	var remove_types_script := ""
	
	for node in plugin_info.nodes:
		var node_name : String = node
		var node_extends := "Node"
		if node.find("extends") != -1:
			node_name = node.split(" ")[0]
			node_extends = node.split(" ")[2]
		var node_code_name : String = node_name.to_lower()
		var node_script_path := plugin_path.plus_file(node_code_name + ".gd")
		var node_icon_file_path := plugin_path.plus_file(node_code_name + "_icon.svg")
		add_types_script += '	add_custom_type("%s", "%s", load("%s"), load("%s"))\n' % [node_name, node_extends, node_script_path, node_icon_file_path]
		remove_types_script += '	remove_custom_type("%s")\n' % node_name
		
		var node_file : File = File.new()
		node_file.open(node_script_path, File.WRITE)
		node_file.store_string("extends %s\n" % node_extends)
		node_file.close()

		var node_icon_file : File = File.new()
		var default_node_icon_file : File = File.new()
		node_icon_file.open(node_icon_file_path, File.WRITE)
		default_node_icon_file.open("res://addons/plugin_maker/default_node_icon.svg", File.READ)
		node_icon_file.store_buffer(default_node_icon_file.get_buffer(default_node_icon_file.get_len()))
		node_icon_file.close()
		default_node_icon_file.close()
	
	var plugin_script : File = File.new()
	plugin_script.open(plugin_path.plus_file("plugin.gd"), File.WRITE)
	plugin_script.store_string(
"""tool
extends EditorPlugin

func _enter_tree():
%s

func _exit_tree():
%s
""" % [add_types_script if add_types_script != "" else "	pass\n",
		remove_types_script if remove_types_script != "" else "	pass\n"])
	plugin_script.close()
	
	var plugin_config = ConfigFile.new()
	plugin_config.set_value("plugin", "name", plugin_info.name)
	plugin_config.set_value("plugin", "description", plugin_info.description)
	plugin_config.set_value("plugin", "author", "Jummit")
	plugin_config.set_value("plugin", "version", "1.0")
	plugin_config.set_value("plugin", "script", "plugin.gd")
	plugin_config.save(plugin_path.plus_file("plugin.cfg"))
	
	get_editor_interface().get_resource_filesystem().scan()
	get_editor_interface().get_resource_filesystem().scan_sources()
	yield(get_tree().create_timer(1), "timeout")
	get_editor_interface().set_plugin_enabled(plugin_folder_name, true)
