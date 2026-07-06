@tool
extends EditorPlugin

const AUTOLOAD_NAME := "TelemetryEngine"
const AUTOLOAD_PATH := "res://addons/telemetry_engine/TelemetryEngine.tscn"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
