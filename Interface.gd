extends PanelContainer

# Used to know we have a valid PCK archive
const ARCHIVE_MAGIC_NUMBER = 0x43504447
# The scenes we will use to create each file/folder line in the viewer
const ARCHIVE_FILE = preload("res://ArchiveFile.tscn")
const ARCHIVE_FOLDER = preload("res://ArchiveFolder.tscn")

# Get the needed nodes
export (NodePath) onready var title_label = get_node(title_label) as RichTextLabel
export (NodePath) onready var scroll_container = get_node(scroll_container) as ScrollContainer
export (NodePath) onready var files_list = get_node(files_list) as VBoxContainer

# The provided archive filename to open
var archive_filename : String = ""
# The entire archive content rearanged in a dictionary to handle folders
var archive_content : Dictionary = {is_root = true}
# The current folder we are displaying (this is pointing to the archive content dictionary)
var current_folder : Dictionary = archive_content
# Used to increase the folders ID (for the naming of the nodes in the scene)
var folder_id : int = 0
# Used to navigate in the dictionary
var keys : Array = []


# Method used to remove all the previously added files/folders to the viewer
func clear_files() -> void:
	# Reset the scroll container position
	scroll_container.scroll_vertical = 0
	
	# Get each child of the list node and remove it from the tree, then destroy it
	for l_child in files_list.get_children():
		files_list.remove_child(l_child)
		l_child.queue_free()


# Method used to convert bytes to a readable string (like 1.5 Gb or 327 bytes)
func convert_bytes_to_readable_size(a_bytes : int, a_decimals : int = 2) -> String:
	# If the size is 0
	if a_bytes == 0:
		return "0 Bytes"

	# 1 kilobyte value
	var l_k = 1024
	# Ensure the decimals are a positive number
	a_decimals = a_decimals if a_decimals > 0 else 0
	# Defines the sizes strings
	var l_sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
	# Get the biggest size from the array above
	var l_i = floor(log(a_bytes) / log(l_k))

	# If the size is only some bytes
	if l_i == 0:
		return str(a_bytes / pow(l_k, l_i)).pad_decimals(0) + " " + l_sizes[l_i]
	# If the size is more than 1 KB
	else:
		return str(a_bytes / pow(l_k, l_i)).pad_decimals(a_decimals) + " " + l_sizes[l_i]


# Method used to get the content of a provided folder
func get_folder_content(a_dictionary : Dictionary) -> String:
	# Used to compute the folder/files count
	var l_folders_count : int = 0
	var l_files_count : int = 0
	
	# For each key in the provided dictionary
	for key in a_dictionary.keys():
		# Only if the current key is a dictionary
		if a_dictionary[key] is Dictionary:
			# If we have a folder
			if a_dictionary[key].is_folder:
				# Increase the corresponding counter
				l_folders_count += 1
			# If we have a file
			else:
				# Increase the corresponding counter
				l_files_count += 1

	# Now create the resulting string
	
	return "Sub-folders: %s - Files: %s" % [l_folders_count, l_files_count]


# Method used to handle the provided command line arguments (if any)
func handle_arguments(a_filenames : PoolStringArray = []) -> void:
	# Here we handle the command line arguments (to load a file if provided)
	var l_command_line_arguments : PoolStringArray = OS.get_cmdline_args() if a_filenames.empty() else a_filenames
	
	# If we have an argument
	if not l_command_line_arguments.empty():
		# Get the first argument and set the archive filename from it
		archive_filename = l_command_line_arguments[0]


# Method called when the "get_back" signal is received by this node
func _on_get_back_signal() -> void:
	# We must go through all the dictionary again but without the last key
	keys.remove(keys.size() - 1)
	# We need to reset the current folder to the root as well
	current_folder = archive_content
	
	for key in keys:
		current_folder = current_folder[key]
	
	show_files()


# Method called when the "go_deeper" signal is received by this node
func _on_go_deeper_signal(a_folder_name : String) -> void:
	# We add a new key to the array of keys to navigate back easily
	keys.append(a_folder_name)
	# Select the next folder to show
	current_folder = current_folder[a_folder_name]
	show_files()


# Method used to read a project datas archive and extract some infos from it
func read_packed_datas(a_filename : String) -> bool:
	var l_file = File.new()
	
	#l_file.set_endian_swap(true)
	l_file.open(a_filename, File.READ)
	
	# First we check the file is really a supported archive datas
	if l_file.get_32() != ARCHIVE_MAGIC_NUMBER:
		return false
	
	# We need to read some dummy bytes now
	for _l_dummy in range(20):
		l_file.get_32()
	
	# Then we can get the number of files in the archive
	var l_files_count = l_file.get_32()
	# Set the application title now
	title_label.bbcode_text = "[center][b][color=#ff7f00]%s[/color] files found in the archive [color=#00bf00]\"%s\"[/color][/b][/center]" % [l_files_count, a_filename]
	
	# For each file in the archive
	for l_id in range(l_files_count):
		# We get the file infos
		var l_length = l_file.get_32()
		# Here we remove the "res://" reference and split the path to get the folders and sub-folders
		var l_path : Array = l_file.get_buffer(l_length).get_string_from_utf8().replace("res://", "").split("/")
		var l_offset = l_file.get_64()
		var l_size = l_file.get_64()
		var l_readable_size : String = ""
		var l_md5 = l_file.get_buffer(16)
		var l_readable_md5 : String = "MD5 Sum: "
		
		# Convert the size to a human readable value
		l_readable_size = convert_bytes_to_readable_size(l_size)
		
		# Convert the MD5 PoolByteArray to an hexadecimal readable string
		for l_byte in l_md5:
			l_readable_md5 += "%x" % l_byte
		
		# Now we store the datas in the archive content dictionary, starting at the root
		var l_current_folder : Dictionary = archive_content
		
		# If the current file is inside at least 1 sub-folder
		if l_path.size() > 1:
			# For each sub-folder
			while l_path.size() > 1:
				# If the folder does not exist yet in the archive content dictionary
				if not l_current_folder.has(l_path[0]):
					# Add the current sub-folder to the dictionary at that level
					l_current_folder[l_path[0]] = {is_folder = true, is_root = false, id = folder_id}
					# Increase the folder ID now
					folder_id += 1
				
				# Go to that new level in the dictionary now
				l_current_folder = l_current_folder[l_path[0]]
				# Delete the sub-folder from the array now
				l_path.remove(0)
		
		# At last, add the file to this current folder
		l_current_folder[l_path[0]] = {
			is_folder = false,
			is_root = false,
			id = l_id,
			size = l_readable_size,
			offset = l_offset,
			md5 = l_readable_md5
		}
		
	# Show the files at the archive root now
	show_files()
		
	# Close the file now
	l_file.close()
	
	return true


# Method called when the node is ready
func _ready() -> void:
	#handle_arguments(["Test2.pck"])
	handle_arguments()
	
	# Connect the navigation signals to the dedicated methods
	Events.connect(Events.SIGNAL_GET_BACK, self, "_on_get_back_signal")
	Events.connect(Events.SIGNAL_GO_DEEPER, self, "_on_go_deeper_signal")
	
	if not archive_filename.empty():
		if read_packed_datas(archive_filename):
			print("Archive \"%s\" successfully read!" % [archive_filename])
		else:
			var l_error : String = "ERROR: The archive \"%s\" is not supported!" % [archive_filename]
			title_label.bbcode_text = "[center][b][color=#ff7f00]%s[/color][/b][/center]" % [l_error]
			print(l_error)
	else:
		var l_error : String = "ERROR: No archive filename was provided as argument!"
		title_label.bbcode_text = "[center][b][color=#ff7f00]%s[/color][/b][/center]" % [l_error]
		print(l_error)


# Method used to create the visual list from the archive content
func show_files() -> void:
#	print("archive_content = %s" % [archive_content])
	# Used to get the current line in the viewer
	var l_id : int = 1
	
	# Clean the viewer lines first
	clear_files()
	
	# If the current folder is not the root one
	if not current_folder.is_root:
		# Add a special folder allowing us to get back to the parent folder
		var l_parent_folder = ARCHIVE_FOLDER.instance()
		l_parent_folder.name = "Folder%s" % [current_folder.id]
		files_list.add_child(l_parent_folder)
		var l_parent_folder_name : String = keys[keys.size() - 2] if keys.size() > 1 else "Archive root"
		l_parent_folder.populate(l_id, "Get Back", "You are currently in [color=#bfbfbf]%s[/color]. Click here to go back to [color=#bfbfbf]%s[/color]" % [keys[keys.size() - 1], l_parent_folder_name])
		# Increase the index of the lines
		l_id += 1
	
	# For each key of the current folder dictionary
	for l_entry in current_folder.keys():
		# Only if the current key is a dictionary
		if current_folder[l_entry] is Dictionary:
			# If we have a folder
			if current_folder[l_entry].is_folder:
				# Add a folder allowing us to navigate further in the hierarchy
				var l_folder = ARCHIVE_FOLDER.instance()
				l_folder.name = "Folder%s" % [current_folder[l_entry].id]
				files_list.add_child(l_folder)
				l_folder.populate(l_id, l_entry, get_folder_content(current_folder[l_entry]))
			# If we have a file
			else:
				# Add a file to the list
				var l_file = ARCHIVE_FILE.instance()
				l_file.name = "File%s" % [l_id]
				files_list.add_child(l_file)
				l_file.populate(l_id, l_entry, current_folder[l_entry].id, current_folder[l_entry].offset, current_folder[l_entry].size, current_folder[l_entry].md5)
			
			# Increase the index of the lines
			l_id += 1


