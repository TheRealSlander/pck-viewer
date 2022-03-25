extends PanelContainer

class_name ArchiveFolder

# Get the needed nodes
export (NodePath) onready var spacer = get_node(spacer) as Control
export (NodePath) onready var up_arrow = get_node(up_arrow) as TextureRect
export (NodePath) onready var folder_name = get_node(folder_name) as RichTextLabel
export (NodePath) onready var folder_content = get_node(folder_content) as RichTextLabel

# Used to store the background color as we will change it dynamically on mouse hover
var panel_style : StyleBox


# Method called when an event is triggered on this node
func _on_archive_folder_gui_input(a_event : InputEvent) -> void:
	# Get the event as a mouse button one
	var l_mouse_event : InputEventMouseButton = a_event as InputEventMouseButton
	
	# If the left button mouse is released
	if l_mouse_event and l_mouse_event.button_index == BUTTON_LEFT and not l_mouse_event.pressed:
		# If the "button" text is "get back"
		if folder_name.text == "Get Back":
			Events.signal_get_back()
		# If we want to dive in the hierarchy
		else:
			Events.signal_go_deeper(folder_name.text)


# Method called when the mouse enters the node
func _on_archive_folder_mouse_entered() -> void:
	# Get the panel we want to customize
	var l_panel : StyleBox = get_stylebox("panel").duplicate()
	# Set the panel background colors accordingly
	l_panel.bg_color = Color("#7f1f7f1f")
	# Set the new stylebox to the panel
	add_stylebox_override("panel", l_panel)
	# Change the cursor pointer as well
	mouse_default_cursor_shape = CURSOR_POINTING_HAND


# Method called when the mouse exits the node
func _on_archive_folder_mouse_exited() -> void:
	# Restore the panel style
	add_stylebox_override("panel", panel_style)
	# Restore the cursor pointer as well
	mouse_default_cursor_shape = CURSOR_ARROW


# Methode used to populate the labels of the scene
func populate(a_index : int, a_folder_name : String, a_folder_content : String) -> void:
	folder_name.bbcode_text = "[color=#007fff]%s[/color]" % [a_folder_name]
	folder_content.bbcode_text = "[i][color=#7f7faf]%s[/color][/i]" % [a_folder_content]
	
	# If the folder name is "Get Back"
	if a_folder_name == "Get Back":
		# Show the arrow
		up_arrow.show()
		spacer.hide()
	# If the folder name is anything else
	else:
		# Hide the arrow
		up_arrow.hide()
		spacer.show()
	
	# Get the panel we want to customize
	var l_panel : StyleBox = get_stylebox("panel").duplicate()

	# If the ID is even
	if a_index % 2 == 0:
		# Set the panel background colors accordingly
		l_panel.bg_color = Color("#1f1f1f1f")
		# Set the new stylebox to the panel
		add_stylebox_override("panel", l_panel)

	# Store the panel stylebox
	panel_style = l_panel
