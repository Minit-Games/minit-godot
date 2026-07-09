@tool
extends EditorPlugin
## Registers the `Minit` autoload singleton when this plugin is enabled, and
## removes it when disabled. Once enabled, call the SDK from anywhere via the
## global `Minit` (e.g. `Minit.report_result(score)`).

const AUTOLOAD_NAME := "Minit"
const FACADE_PATH := "res://addons/minit/minit.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, FACADE_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
