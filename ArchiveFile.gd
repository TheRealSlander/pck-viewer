extends PanelContainer

class_name ArchiveFile

# Get the needed nodes
export (NodePath) onready var file_id = get_node(file_id) as RichTextLabel
export (NodePath) onready var file_name = get_node(file_name) as RichTextLabel
export (NodePath) onready var file_size = get_node(file_size) as RichTextLabel
export (NodePath) onready var file_offset = get_node(file_offset) as RichTextLabel
export (NodePath) onready var file_md5 = get_node(file_md5) as RichTextLabel


# Methode used to populate the labels of the scene
func populate(a_index : int, a_file_name : String, a_id : int, a_offset : int, a_size : String, a_md5 : String) -> void:
	file_id.bbcode_text = "[right][color=#ff7f00]%s[/color][/right]" % [a_id]
	file_name.bbcode_text = "%s" % [a_file_name]
	file_offset.bbcode_text = "[right][i][color=#7f7faf]Offset: %s[/color][/i][/right]" % [a_offset]
	file_size.bbcode_text = "[right]%s[/right]" % [a_size]
	file_md5.bbcode_text = "[i][color=#7f7faf]%s[/color][/i]" % [a_md5]
	
	# If the ID is even
	if a_index % 2 == 0:
		# Get the panel we want to customize
		var l_panel : StyleBox = get_stylebox("panel").duplicate()
		# Set the panel background colors accordingly
		l_panel.bg_color = Color("#1f1f1f1f")
		# Set the new stylebox to the panel
		add_stylebox_override("panel", l_panel)
