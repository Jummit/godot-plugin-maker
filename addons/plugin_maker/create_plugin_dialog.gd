tool
extends ConfirmationDialog

onready var plugin_name := $Content/PluginNameEdit
onready var plugin_description := $Content/PluginDescriptionEdit
onready var node_list := $Content/CustomNodeList
onready var rename_edit := $Content/CustomNodeList/RenameEdit

var renaming_item := -1

func _on_about_to_show():
	plugin_name.text = ""
	plugin_description.text = ""
	rename_edit.text = ""
	node_list.clear()


func _on_RemoveNodeButton_pressed():
	if node_list.get_selected_items().size() > 0:
		var selected : int = node_list.get_selected_items()[0]
		node_list.remove_item(selected)
		if node_list.items.size() >= selected:
			node_list.select(selected)


func _on_AddNodeButton_pressed():
	node_list.add_item("UntitledNode", preload("res://addons/plugin_maker/default_node_icon.svg"))


func _on_CustomNodeList_item_activated(index):
	rename_edit.rect_global_position = get_global_mouse_position()
	rename_edit.text = node_list.get_item_text(index)
	rename_edit.show()
	rename_edit.grab_focus()
	renaming_item = index


func _on_RenameEdit_text_entered(new_text):
	rename_edit.hide()
	node_list.set_item_text(renaming_item, new_text)


func _on_RenameEdit_focus_exited():
	rename_edit.hide()


func get_plugin_info() -> Dictionary:
	var nodes : PoolStringArray = []
	for index in node_list.get_item_count():
		nodes.append(node_list.get_item_text(index))
	return {
		name = plugin_name.text,
		description = plugin_description,
		nodes = nodes
	}

