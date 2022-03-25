extends Node

# Used by the folders to navigate in the hierarchy
signal signal_get_back()
const SIGNAL_GET_BACK : String = "signal_get_back"
func signal_get_back() -> void:
	emit_signal(SIGNAL_GET_BACK)

signal signal_go_deeper(a_folder_name)
const SIGNAL_GO_DEEPER : String = "signal_go_deeper"
func signal_go_deeper(a_folder_name : String) -> void:
	emit_signal(SIGNAL_GO_DEEPER, a_folder_name)

