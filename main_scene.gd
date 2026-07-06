extends Node2D

@export var scenario_start_id: String
@export_file("*.json") var arcweave_json_path: String = "res://resources/arcweave/2026-06-30/cdm-tutorial-trolley-dilemma-2026-06-30.json"

@export var trolley_scene = preload("uid://626m6cmlaikk")
@export var trolley_speed: float = 200.0

@export var game_complete_scene: PackedScene

@onready var start_path: PathWithLine = $StartPath
@onready var do_nothing_path: PathWithLine = $DoNothingPath
@onready var intervene_path: PathWithLine = $IntervenePath

@onready var victim_holder: VictimHolder = %VictimHolder

@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var continue_button: Button = %ContinueButton

@onready var ui_root: Node = $UI
@onready var the_choice_container: VBoxContainer = $UI/TheChoiceContainer

@onready var time_remaining_label: Label = %TimeRemainingLabel
@onready var timer_container: HBoxContainer = %TimerContainer


const START_TROLLEY_NAME := "Start_Trolley"
const SCENARIO_COMPLETE_NAME := "Scenario_Complete"
const KEY_MOMENT_NAME := "Key Moment"
const WEIGHT_1_NAME := "Weight_1"
const WEIGHT_2_NAME := "Weight_2"
const PLAYABLE_BOARD_NAME := "Life is in peril"

const START_TROLLEY_ID := "4f41e84a-9ec3-4bb5-a434-80cc705587f3"
const SCENARIO_COMPLETE_ID := "b20b2bd8-4972-4c3f-83df-83b2479fe83a"
const KEY_MOMENT_ID := "cba86ed8-c7c8-4326-b095-11099033e6eb"
const WEIGHT_2_ID := "a81c28a9-bb9d-4fdc-ae83-6f607eaba941"

const CONTEXT_TEXT_WIDTH := 860.0
const CONTEXT_TEXT_MIN_HEIGHT := 120.0
const CONTEXT_TEXT_MAX_HEIGHT_RATIO := 0.42
const CONTEXT_TEXT_PADDING := 28.0
const CONTEXT_TEXT_BUTTON_SPACE := 82.0
const STORY_AUDIO_PATH := "res://assets/sound/"
const OPENING_AUDIO_PATH := "res://assets/sound/0-Opening.wav"
const SCENARIO_AUDIO_KEYS_BY_ELEMENT_ID := {
	"276c9428-9e7b-407e-85b7-66b929ca7d01": "1",
	"637c302b-4689-4b9c-bcfa-b7e1980eea42": "2",
	"af289c08-0861-4bd1-968a-4050d59909f6": "3",
	"f7578fbb-7145-4751-ae7f-9a6bab452abd": "4A",
	"6cd72a4b-d097-480c-b99e-daf83f00aa08": "4B",
	"90417d79-25da-4abc-b84b-9d1e7f2b0cb0": "5A",
	"4e21d98b-7059-4b4e-af45-46f86e6724d7": "5B",
	"c19f57e1-6e41-4d5a-8604-6ac71c525e10": "6A",
	"4c64a685-7a3a-4dc9-a6ee-0ac889b6f0a1": "6B",
	"5c28a753-7cc2-483d-aadf-b30f90e55784": "7A",
	"fdb3a7fc-963a-447b-8e15-c98c21ea8172": "7B",
	"99d0554b-cef0-4225-8eb7-6ce49b6cc736": "7C"
}
const SCENARIO_AUDIO_TITLE_HINTS := {
	"smuggler": "1",
	"container": "2",
	"partner": "3",
	"reform": "4A",
	"broadcaster": "4B",
	"leader": "5A",
	"protest": "5B",
	"government": "7A",
	"govern": "7A",
	"rebel": "7B",
	"hostage": "7C"
}

const NARRATIVE_TAG_IDS := {
	"d48d83a2-5fe8-4454-9e5a-e45282863f37": "Harm",
	"890c658e-e0d2-4efb-bee8-ac9a54547133": "Pride",
	"d18d1371-6c9b-43b5-b40e-5703034f9110": "Neglect",
	"c679cb5f-226e-4348-845d-3dde65282f86": "Degredation",
	"25cc5d0c-e15b-4519-b6ab-b7c898b0ee31": "Oppression",
	"15afca38-a152-453c-b062-33762a31c826": "Subversion",
	"6ad1dd2c-d383-4cb5-a2c1-b2efb06e7b44": "Betrayal",
	"c3f68887-106e-4ea1-9f57-4d44829b5bf3": "Cheating",
	"d8918d9a-c753-4177-b478-80ed5eb8febe": "Humility",
	"c4f8b7cb-da4c-43fc-9069-f4afe4073d45": "Duty",
	"c7f670f1-9f44-4ff4-be03-48f656c59ece": "Sanctity",
	"68767e00-f7de-44de-ad26-dccc189b0001": "Liberty",
	"7414ad50-434b-4454-97a7-533770a72c5a": "Authority",
	"9ad36259-6f0d-4db3-b117-feca239e6642": "Loyalty",
	"a8b8e7f0-7268-4980-b4b7-b9ab69b44a1b": "Fairness",
	"32c2ca99-e388-4bb8-91ff-f6e9f7d473de": "Care"
}

const NARRATIVE_TAG_NAMES := [
	"Care",
	"Harm",
	"Fairness",
	"Cheating",
	"Loyalty",
	"Betrayal",
	"Authority",
	"Subversion",
	"Sanctity",
	"Degredation",
	"Degradation",
	"Liberty",
	"Oppression",
	"Pride",
	"Humility",
	"Duty",
	"Neglect"
]

const POSITIVE_TAG_NAMES := [
	"Humility",
	"Duty",
	"Sanctity",
	"Liberty",
	"Authority",
	"Loyalty",
	"Fairness",
	"Care"
]

const NEGATIVE_TAG_NAMES := [
	"Harm",
	"Pride",
	"Neglect",
	"Degredation",
	"Degradation",
	"Oppression",
	"Subversion",
	"Betrayal",
	"Cheating"
]


var current_path: Path2D
var current_path_length: float

var trolley: TrolleyPathFollow
var running: bool = false

var selected_output_index: int = -1
var selected_output_id: String = ""
var selected_option_text: String = ""
var selected_choices: Array = []

var current_element: ArcweaveElement
var scenario_complete: bool = false
var scenario_start_ids: Array[String] = []
var scenario_allowed_element_ids: Array[String] = []
var current_scenario_index: int = -1
var played_scenario_signatures: Array[String] = []
var current_scenario_started_at_msec := 0
var current_scenario_id := ""
var current_scenario_title := ""

var arcweave_json_data
var choice_buttons: Array[Button] = []
var current_choice_labels: Array[String] = []
var choice_button_layer: Control
var story_audio_player: AudioStreamPlayer
var story_audio_cache := {}
var current_story_audio_path := ""


func _ready() -> void:
	print("MAIN TROLLEY SCENE READY")
	_load_arcweave_json_data()
	_remove_old_choice_buttons()
	_create_choice_button_layer()
	_style_static_ui()
	_setup_story_audio_player()
	the_choice_container.hide()

	trolley = trolley_scene.instantiate()
	_set_path(start_path, 0.0)

	continue_button.pressed.connect(_on_continue_pressed)
	victim_holder.crash.connect(_on_trolley_crash)

	await get_tree().process_frame

	var starting_element: ArcweaveElement = ArcweaveManager.get_element(scenario_start_id)
	assert(starting_element != null, "Invalid starting element entered!")
	_load_scenario_start_element(starting_element)

	ArcweaveManager.element_changed.connect(_on_element_changed)


func _setup_story_audio_player() -> void:
	story_audio_player = AudioStreamPlayer.new()
	story_audio_player.name = "StoryAudioPlayer"
	story_audio_player.volume_db = 0.0
	add_child(story_audio_player)


func _style_static_ui() -> void:
	continue_button.custom_minimum_size = Vector2(180.0, 64.0)
	continue_button.add_theme_font_size_override("font_size", 30)

	rich_text_label.custom_minimum_size = Vector2(CONTEXT_TEXT_WIDTH, CONTEXT_TEXT_MIN_HEIGHT)
	rich_text_label.size = Vector2(CONTEXT_TEXT_WIDTH, CONTEXT_TEXT_MIN_HEIGHT)
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich_text_label.scroll_active = false
	rich_text_label.fit_content = true
	rich_text_label.add_theme_font_size_override("normal_font_size", 30)
	rich_text_label.add_theme_font_size_override("bold_font_size", 30)
	rich_text_label.add_theme_font_size_override("italics_font_size", 30)
	rich_text_label.add_theme_font_size_override("bold_italics_font_size", 30)
	rich_text_label.add_theme_font_size_override("mono_font_size", 26)
	_queue_fit_context_text_box()


func _queue_fit_context_text_box() -> void:
	call_deferred("_fit_context_text_box")


func _fit_context_text_box() -> void:
	if rich_text_label == null:
		return

	var viewport_height := get_viewport_rect().size.y
	var max_text_height: float = maxf(CONTEXT_TEXT_MIN_HEIGHT, viewport_height * CONTEXT_TEXT_MAX_HEIGHT_RATIO)
	var content_height := float(rich_text_label.get_content_height())
	if content_height <= 0.0:
		content_height = rich_text_label.get_combined_minimum_size().y

	var wanted_text_height := content_height + CONTEXT_TEXT_PADDING
	var text_height := clampf(wanted_text_height, CONTEXT_TEXT_MIN_HEIGHT, max_text_height)
	var needs_scroll := wanted_text_height > max_text_height

	rich_text_label.fit_content = not needs_scroll
	rich_text_label.scroll_active = needs_scroll
	rich_text_label.custom_minimum_size = Vector2(CONTEXT_TEXT_WIDTH, text_height)
	rich_text_label.size = Vector2(CONTEXT_TEXT_WIDTH, text_height)

	var margin_container := rich_text_label.get_parent() as Control
	if margin_container != null:
		margin_container.custom_minimum_size = Vector2(CONTEXT_TEXT_WIDTH + CONTEXT_TEXT_PADDING, text_height + CONTEXT_TEXT_PADDING)
		margin_container.size = margin_container.custom_minimum_size

	var text_panel: Control = null
	if margin_container != null:
		text_panel = margin_container.get_parent() as Control
	if text_panel != null:
		var button_space := CONTEXT_TEXT_BUTTON_SPACE if continue_button.visible else 0.0
		var panel_height := text_height + CONTEXT_TEXT_PADDING + button_space
		text_panel.custom_minimum_size = Vector2(CONTEXT_TEXT_WIDTH + CONTEXT_TEXT_PADDING, panel_height)
		text_panel.size = text_panel.custom_minimum_size


func _load_arcweave_json_data() -> void:
	arcweave_json_data = null

	if arcweave_json_path.strip_edges() == "":
		arcweave_json_path = "res://resources/arcweave/2026-06-30/cdm-tutorial-trolley-dilemma-2026-06-30.json"

	if not FileAccess.file_exists(arcweave_json_path):
		push_warning("Arcweave JSON file not found: " + arcweave_json_path)
		return

	var file := FileAccess.open(arcweave_json_path, FileAccess.READ)
	if file == null:
		push_warning("Could not open Arcweave JSON file: " + arcweave_json_path)
		return

	var json_text: String = file.get_as_text()
	var parsed = JSON.parse_string(json_text)

	if parsed == null:
		push_warning("Could not parse Arcweave JSON file: " + arcweave_json_path)
		return

	arcweave_json_data = parsed
	_build_scenario_start_list()
	print("Loaded Arcweave JSON for dynamic choice labels: ", arcweave_json_path)


func _build_scenario_start_list() -> void:
	scenario_start_ids.clear()
	scenario_allowed_element_ids.clear()

	if typeof(arcweave_json_data) != TYPE_DICTIONARY:
		return

	var boards: Dictionary = arcweave_json_data.get("boards", {})
	var elements: Dictionary = arcweave_json_data.get("elements", {})
	var board_element_ids: Array = []

	for board_id in boards.keys():
		var board_data: Dictionary = boards[board_id]
		if str(board_data.get("name", "")) == PLAYABLE_BOARD_NAME:
			board_element_ids = board_data.get("elements", [])
			break

	if board_element_ids.is_empty():
		push_warning("Arcweave board not found or empty: " + PLAYABLE_BOARD_NAME)
		return

	for element_id in board_element_ids:
		var element_id_string := str(element_id)
		if not elements.has(element_id_string):
			continue

		scenario_allowed_element_ids.append(element_id_string)
		var element_data: Dictionary = elements[element_id_string]
		var components: Array = element_data.get("components", [])

		if components.has(START_TROLLEY_ID):
			scenario_start_ids.append(element_id_string)

	print("Playable board: ", PLAYABLE_BOARD_NAME)
	print("Allowed board elements: ", scenario_allowed_element_ids.size())
	print("Scenario starts found: ", scenario_start_ids.size())


func _is_allowed_scenario_element(element: ArcweaveElement) -> bool:
	if element == null:
		return false

	return scenario_allowed_element_ids.has(str(element.id))


func _is_scenario_start_element(element: ArcweaveElement) -> bool:
	if element == null:
		return false

	for component_id in element.components:
		var component_id_string := str(component_id)
		var component_name := _get_component_name(component_id_string)
		if _is_start_trolley_component(component_id_string, component_name):
			return true

	return false


func _debug_print_scenario_starts() -> void:
	for index in range(scenario_start_ids.size()):
		var element_data: Dictionary = arcweave_json_data.get("elements", {}).get(scenario_start_ids[index], {})
		var title := str(element_data.get("title", "")).strip_edges()
		print("Scenario ", index + 1, ": ", scenario_start_ids[index], " ", title)


func _play_story_audio_for_element(element: ArcweaveElement) -> void:
	if element == null:
		return

	if _is_scenario_start_element(element):
		var scenario_audio_path := _find_story_audio_path(_get_scenario_audio_key(element), false)
		if scenario_audio_path == "":
			_stop_story_audio()
			return

		_play_story_audio(scenario_audio_path)
		return

	if _is_setup_audio_node(element):
		var setup_audio_path := _get_setup_audio_path(element)
		if setup_audio_path != "":
			_play_story_audio(setup_audio_path)
		return

	_stop_story_audio()


func _is_setup_audio_node(element: ArcweaveElement) -> bool:
	if element == null:
		return false

	if not _is_allowed_scenario_element(element):
		return false

	var title := _clean_choice_label(str(element.title_cleaned)).to_lower()
	return title == "start" or title == "setup"


func _get_setup_audio_path(element: ArcweaveElement) -> String:
	if element == null:
		return ""

	if str(element.id) == scenario_start_id:
		if FileAccess.file_exists(OPENING_AUDIO_PATH):
			return OPENING_AUDIO_PATH
		return ""

	var next_scenario_key := _get_next_scenario_audio_key(element)
	if next_scenario_key == "":
		return ""

	return _find_story_audio_path(next_scenario_key, true)


func _get_next_scenario_audio_key(element: ArcweaveElement) -> String:
	var visited: Array[String] = []
	var cursor := element

	for step in range(16):
		if cursor == null:
			return ""

		var cursor_id := str(cursor.id)
		if visited.has(cursor_id):
			return ""

		visited.append(cursor_id)

		if _is_scenario_start_element(cursor):
			return _get_scenario_audio_key(cursor)

		cursor = _get_first_output_target_element(cursor)

	return ""


func _get_scenario_audio_key(element: ArcweaveElement) -> String:
	if element == null:
		return ""

	var element_id := str(element.id)
	if SCENARIO_AUDIO_KEYS_BY_ELEMENT_ID.has(element_id):
		return str(SCENARIO_AUDIO_KEYS_BY_ELEMENT_ID[element_id])

	var title := _clean_choice_label(str(element.title_cleaned)).to_lower()
	for title_hint in SCENARIO_AUDIO_TITLE_HINTS.keys():
		if title.find(str(title_hint)) != -1:
			return str(SCENARIO_AUDIO_TITLE_HINTS[title_hint])

	return ""


func _find_story_audio_path(audio_key: String, setup_audio: bool) -> String:
	if audio_key == "":
		return ""

	var audio_directory := DirAccess.open(STORY_AUDIO_PATH)
	if audio_directory == null:
		return ""

	var audio_key_lower := audio_key.to_lower()
	audio_directory.list_dir_begin()
	var file_name := audio_directory.get_next()

	while file_name != "":
		if not audio_directory.current_is_dir() and _is_supported_story_audio_file(file_name):
			var stem := file_name.get_basename().to_lower()
			var matches_key := (
				stem == audio_key_lower
				or stem.begins_with(audio_key_lower + "-")
				or stem.begins_with(audio_key_lower + "_")
				or stem.begins_with(audio_key_lower + " ")
			)
			var is_setup_audio := stem.find("setup") != -1

			if matches_key and is_setup_audio == setup_audio:
				audio_directory.list_dir_end()
				return STORY_AUDIO_PATH + file_name

		file_name = audio_directory.get_next()

	audio_directory.list_dir_end()
	return ""


func _is_supported_story_audio_file(file_name: String) -> bool:
	var extension := file_name.get_extension().to_lower()
	return extension == "wav" or extension == "ogg" or extension == "mp3"


func _play_story_audio(audio_path: String) -> void:
	if audio_path == "" or story_audio_player == null:
		return

	if current_story_audio_path == audio_path and story_audio_player.playing:
		return

	var stream: AudioStream = null
	if story_audio_cache.has(audio_path):
		stream = story_audio_cache[audio_path] as AudioStream
	else:
		stream = load(audio_path) as AudioStream
		if stream == null:
			return
		story_audio_cache[audio_path] = stream

	current_story_audio_path = audio_path
	story_audio_player.stop()
	story_audio_player.stream = stream
	story_audio_player.play()


func _stop_story_audio() -> void:
	current_story_audio_path = ""
	if story_audio_player != null:
		story_audio_player.stop()


func _load_scenario_start_element(starting_element: ArcweaveElement) -> void:
	_prepare_scenario_start(starting_element)
	_on_element_changed(starting_element)


func _process_components(element: ArcweaveElement) -> void:
	var found_trolley_start: bool = false

	for component_id in element.components:
		var component_name := _get_component_name(str(component_id))

		if _is_start_trolley_component(str(component_id), component_name):
			var scenario_index := scenario_start_ids.find(str(element.id))
			if scenario_index != -1:
				current_scenario_index = scenario_index

			_prepare_scenario_start(element)
			_reset_choice_state()
			running = true
			found_trolley_start = true
			_start_trolley_timer()
			the_choice_container.show()
		elif _is_scenario_complete_component(str(component_id), component_name):
			scenario_complete = true

	if found_trolley_start:
		continue_button.hide()
	else:
		_clear_choice_buttons()
		the_choice_container.hide()
		continue_button.show()


func _reset_choice_state() -> void:
	selected_output_index = -1
	selected_output_id = ""
	selected_option_text = ""

	_build_choice_buttons()

	for button in choice_buttons:
		button.disabled = false
		button.button_pressed = false

	do_nothing_path.set_active(false)
	intervene_path.set_active(false)
	timer_container.show()
	timer_container.modulate = Color.WHITE


func _gather_victim_components(element: ArcweaveElement) -> Array[ArcweaveComponent]:
	var victim_components: Array[ArcweaveComponent] = []

	for component_id in element.components:
		var component: ArcweaveComponent = ArcweaveManager.get_component(component_id)
		if component == null:
			continue

		match str(component.name):
			"Inaction_x1", "Intervention_x1":
				victim_components.append(component)

	return victim_components


func _start_trolley_timer() -> void:
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(_on_trolley_timer_timeout)


func _process(delta: float) -> void:
	_position_choice_buttons()

	var trolley_progress: float = trolley.progress
	var new_progress: float = trolley_progress + (trolley_speed * delta)
	_process_time_left(new_progress)

	if running:
		if new_progress < current_path_length:
			trolley.progress = new_progress
		elif current_path == start_path:
			if selected_output_index == -1:
				trolley.progress = current_path_length
				running = false
				timer_container.hide()
				the_choice_container.show()
				return

			var over_shoot: float = new_progress - current_path_length

			if selected_output_index == 1:
				_set_path(intervene_path, over_shoot)
			else:
				_set_path(do_nothing_path, over_shoot)
		else:
			trolley.progress = current_path_length
			_on_trolley_crash()
			return


func _process_time_left(new_progress: float) -> void:
	if current_path == start_path:
		if new_progress < current_path_length:
			var time_remaining: float = (current_path_length - trolley.progress) / trolley_speed
			time_remaining = clampf(time_remaining, 0.0, 5.0)
			time_remaining_label.text = str("%1.2f" % time_remaining)

			if time_remaining < 1.01:
				timer_container.modulate = Color.MAROON
			else:
				timer_container.modulate = Color.WHITE
		else:
			timer_container.hide()


func _set_path(path: Path2D, progress: float) -> void:
	if current_path != null:
		current_path.remove_child(trolley)

	current_path = path
	current_path.set_active(true)
	current_path_length = current_path.curve.get_baked_length()
	current_path.add_child(trolley)
	trolley.progress = progress


func _on_continue_pressed() -> void:
	if scenario_complete:
		_record_telemetry_scenario_completed(current_element)
		_advance_to_next_scenario_or_finish()
		return

	if current_element == null:
		return

	if _is_allowed_scenario_element(current_element):
		var next_element := _get_first_output_target_element(current_element)
		if next_element == null or not _is_allowed_scenario_element(next_element):
			_finish_session()
			return

		if _is_scenario_start_element(next_element) and _has_played_scenario_like(next_element):
			print("Arcweave path returned to an already played scenario. Finishing session: ", next_element.id)
			_finish_session()
			return

		current_element = ArcweaveManager.goto_element(next_element.id)
	else:
		current_element = ArcweaveManager.goto_next_element(current_element)

	if current_element == null:
		_finish_session()
		return


func _advance_to_next_scenario_or_finish() -> void:
	_set_path(start_path, 0.0)
	scenario_complete = false

	var linked_next_element: ArcweaveElement = null
	if current_element != null and current_element.outputs.size() > 0:
		linked_next_element = _get_first_output_target_element(current_element)

	if linked_next_element != null and _is_allowed_scenario_element(linked_next_element):
		if _is_scenario_start_element(linked_next_element) and _has_played_scenario_like(linked_next_element):
			print("Arcweave output points to an already played scenario. Finishing session: ", linked_next_element.id)
			_finish_session()
			return

		print("Advancing through Arcweave output to: ", linked_next_element.id)
		ArcweaveManager.goto_element(linked_next_element.id)
		return

	if linked_next_element == null:
		print("Arcweave path ended after this scenario.")
	else:
		print("Arcweave output left ", PLAYABLE_BOARD_NAME, ": ", linked_next_element.id)

	print("Selected Arcweave path complete. Opening Keepsake Overlay.")
	_finish_session()


func _get_first_output_target_element(element: ArcweaveElement) -> ArcweaveElement:
	if element == null or element.outputs.is_empty():
		return null

	var connection: ArcweaveConnection = ArcweaveManager.project.connections.get(element.outputs[0])
	if connection == null:
		return null

	return ArcweaveManager.get_connection_target_element(connection)


func _prepare_scenario_start(starting_element: ArcweaveElement) -> void:
	_mark_scenario_played(starting_element)
	current_scenario_started_at_msec = Time.get_ticks_msec()
	current_scenario_id = str(starting_element.id)
	current_scenario_title = str(starting_element.title_cleaned)

	var inactive_victims: int = 0
	var intervention_victims: int = 0

	var victim_components := _gather_victim_components(starting_element)

	for component in victim_components:
		if str(component.name) == "Inaction_x1":
			inactive_victims += 1
		elif str(component.name) == "Intervention_x1":
			intervention_victims += 1

	victim_holder.set_victim_count(inactive_victims, intervention_victims)
	_record_telemetry_scenario_started(starting_element)


func _mark_scenario_played(element: ArcweaveElement) -> void:
	var signature := _get_scenario_signature(element)
	if signature == "":
		return

	if not played_scenario_signatures.has(signature):
		played_scenario_signatures.append(signature)


func _has_played_scenario_like(element: ArcweaveElement) -> bool:
	var signature := _get_scenario_signature(element)
	return signature != "" and played_scenario_signatures.has(signature)


func _get_scenario_signature(element: ArcweaveElement) -> String:
	if element == null:
		return ""

	var element_data: Dictionary = arcweave_json_data.get("elements", {}).get(str(element.id), {})
	var title := _clean_choice_label(str(element_data.get("title", str(element.title_cleaned))))
	var content := _clean_choice_label(str(element_data.get("content", "")))

	return (title + "|" + content).strip_edges().to_lower()


func _finish_session() -> void:
	running = false
	scenario_complete = false
	_stop_story_audio()
	the_choice_container.hide()
	_clear_choice_buttons()
	continue_button.hide()

	if has_node("/root/TelemetryEngine"):
		TelemetryEngine.set_variable_summary(_get_arcweave_variables(), true)
		TelemetryEngine.send_session()


func _on_element_changed(element: ArcweaveElement) -> void:
	var previous_element_id := ""
	if current_element != null:
		previous_element_id = current_element.id

	current_element = element

	print("Current Arcweave Element ID: ", element.id)

	var evaluated_content: String = ArcweaveManager.get_evaluated_element_content(element.id)
	rich_text_label.text = evaluated_content
	_queue_fit_context_text_box()

	_play_story_audio_for_element(element)
	_process_components(element)

	if has_node("/root/TelemetryEngine"):
		TelemetryEngine.record_story_node_changed(
			previous_element_id,
			element.id,
			str(element.title_cleaned)
		)
		TelemetryEngine.set_variable_summary(_get_arcweave_variables(), true, {
			"element_id": element.id
		})


func _on_trolley_timer_timeout() -> void:
	running = true


func _remove_old_choice_buttons() -> void:
	for child in the_choice_container.get_children():
		if child is Button:
			child.queue_free()

	choice_buttons.clear()


func _create_choice_button_layer() -> void:
	choice_button_layer = Control.new()
	choice_button_layer.name = "DynamicChoiceButtonLayer"
	choice_button_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ui_root.add_child(choice_button_layer)

	choice_button_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	choice_button_layer.offset_left = 0.0
	choice_button_layer.offset_top = 0.0
	choice_button_layer.offset_right = 0.0
	choice_button_layer.offset_bottom = 0.0


func _clear_choice_buttons() -> void:
	for button in choice_buttons:
		if is_instance_valid(button):
			button.queue_free()

	choice_buttons.clear()
	current_choice_labels.clear()


func _build_choice_buttons() -> void:
	_clear_choice_buttons()

	if current_element == null:
		return

	if current_element.outputs.size() < 2:
		push_warning("Trolley decision element has fewer than two outputs: " + current_element.id)
		return

	var output_count: int = min(2, current_element.outputs.size())

	for output_index in output_count:
		var output_id: String = str(current_element.outputs[output_index])
		var label: String = _get_choice_label_from_arcweave_json(output_id, output_index)

		if label == "":
			label = _get_choice_label_from_runtime_connection(output_id)

		if label == "":
			_debug_missing_choice_label(output_id, output_index)
			label = "[missing Arcweave label] " + output_id

		current_choice_labels.append(label)

		var button := Button.new()
		button.name = "ArcweaveChoiceButton" + str(output_index)
		button.text = label
		button.toggle_mode = true
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = Vector2(520.0, 128.0)
		button.size = Vector2(560.0, 128.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_on_choice_button_pressed.bind(output_index))

		choice_button_layer.add_child(button)
		choice_buttons.append(button)

		print("Choice ", output_index, " output id: ", output_id, " label: ", label)

	_position_choice_buttons()


func _position_choice_buttons() -> void:
	if choice_buttons.is_empty():
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var button_size := Vector2(560.0, 128.0)

	for index in choice_buttons.size():
		var button := choice_buttons[index]
		if not is_instance_valid(button):
			continue

		button.size = button_size

		if index == 0:
			# Output 0 follows the upper/straight route.
			button.position = Vector2(
				(viewport_size.x * 0.72) - (button_size.x * 0.5),
				(viewport_size.y * 0.23) - (button_size.y * 0.5)
			)
		elif index == 1:
			# Output 1 follows the lower/branch route.
			button.position = Vector2(
				(viewport_size.x * 0.72) - (button_size.x * 0.5),
				(viewport_size.y * 0.74) - (button_size.y * 0.5)
			)
		else:
			button.position = Vector2(
				(viewport_size.x * 0.5) - (button_size.x * 0.5),
				(viewport_size.y * 0.5) - (button_size.y * 0.5) + (index * 96.0)
			)


func _debug_missing_choice_label(output_id: String, output_index: int) -> void:
	print("MISSING ARCWEAVE CHOICE LABEL")
	print("Current element id: ", current_element.id if current_element != null else "null")
	print("Output index: ", output_index)
	print("Output id: ", output_id)
	print("Arcweave JSON path: ", arcweave_json_path)

	if arcweave_json_data == null:
		print("Arcweave JSON data is not loaded. Set Arcweave Json Path in the scene Inspector.")
		return

	var current_element_json = _find_json_dictionary_by_id(arcweave_json_data, current_element.id)
	if current_element_json is Dictionary:
		print("Current element JSON keys: ", current_element_json.keys())
		print("Current element JSON preview: ", _preview_json(current_element_json))
	else:
		print("Could not find current element in JSON.")

	var output_json = _find_json_dictionary_by_id(arcweave_json_data, output_id)
	if output_json is Dictionary:
		print("Output JSON keys: ", output_json.keys())
		print("Output JSON preview: ", _preview_json(output_json))
	else:
		print("Could not find output id in JSON.")


func _preview_json(value) -> String:
	var json_text: String = JSON.stringify(value)
	if json_text.length() > 1200:
		return json_text.substr(0, 1200) + "..."

	return json_text


func _on_choice_button_pressed(output_index: int) -> void:
	_choose_output(output_index)


func _choose_output(output_index: int) -> void:
	if selected_output_index != -1:
		return

	if current_element == null:
		return

	if current_element.outputs.size() <= output_index:
		return

	selected_output_index = output_index
	selected_output_id = str(current_element.outputs[output_index])
	selected_option_text = current_choice_labels[output_index] if current_choice_labels.size() > output_index else "Choice " + str(output_index + 1)

	for index in choice_buttons.size():
		var button := choice_buttons[index]
		button.button_pressed = index == output_index
		button.disabled = true

	do_nothing_path.set_active(output_index == 0)
	intervene_path.set_active(output_index == 1)

	print("REAL CHOICE MADE")
	print("selected_output_index = ", selected_output_index)
	print("selected_output_id = ", selected_output_id)
	print("selected_option_text = ", selected_option_text)
	print("Current element = ", current_element.id)

	if current_path == start_path and trolley.progress >= current_path_length:
		if selected_output_index == 1:
			_set_path(intervene_path, 0.0)
		else:
			_set_path(do_nothing_path, 0.0)

		running = true


func _get_choice_label_from_arcweave_json(output_id: String, output_index: int) -> String:
	if arcweave_json_data == null:
		return ""

	var output_json = _find_json_dictionary_by_id(arcweave_json_data, output_id)

	if output_json is Dictionary:
		var direct_label: String = _get_label_from_dictionary(output_json)
		if direct_label != "" and not _is_generic_choice_label(direct_label):
			return direct_label

		var target_label: String = _get_target_label_from_output_dictionary(output_json)
		if target_label != "":
			return target_label

	var current_element_json = _find_json_dictionary_by_id(arcweave_json_data, current_element.id)
	if current_element_json is Dictionary:
		var nested_output_json = _find_json_dictionary_by_id(current_element_json, output_id)
		if nested_output_json is Dictionary:
			var nested_label: String = _get_label_from_dictionary(nested_output_json)
			if nested_label != "" and not _is_generic_choice_label(nested_label):
				return nested_label

		var indexed_label: String = _get_label_by_output_index_from_element_dictionary(current_element_json, output_index)
		if indexed_label != "":
			return indexed_label

	return ""


func _get_choice_label_from_runtime_connection(output_id: String) -> String:
	var connection: ArcweaveConnection = ArcweaveManager.project.connections.get(output_id)
	if connection == null:
		return ""

	var possible_property_names: Array[String] = [
		"label",
		"title",
		"name",
		"text",
		"content",
		"description"
	]

	for property_name in possible_property_names:
		var value = connection.get(property_name)
		if value != null and str(value).strip_edges() != "":
			var label := _clean_choice_label(str(value))
			if not _is_generic_choice_label(label):
				return label

	return ""


func _find_json_dictionary_by_id(value, id_to_find: String):
	if value is Dictionary:
		if value.has("id") and str(value["id"]) == id_to_find:
			return value

		for key in value.keys():
			if str(key) == id_to_find and value[key] is Dictionary:
				return value[key]

			var found = _find_json_dictionary_by_id(value[key], id_to_find)
			if found is Dictionary:
				return found

	elif value is Array:
		for item in value:
			var found = _find_json_dictionary_by_id(item, id_to_find)
			if found is Dictionary:
				return found

	return null


func _get_label_by_output_index_from_element_dictionary(element_dictionary: Dictionary, output_index: int) -> String:
	var possible_output_keys: Array[String] = [
		"outputs",
		"outlets",
		"choices",
		"options",
		"connections"
	]

	for key in possible_output_keys:
		if not element_dictionary.has(key):
			continue

		var outputs_value = element_dictionary[key]
		if outputs_value is Array and outputs_value.size() > output_index:
			var output_value = outputs_value[output_index]

			if output_value is Dictionary:
				var label: String = _get_label_from_dictionary(output_value)
				if label != "":
					return label

			elif typeof(output_value) == TYPE_STRING:
				var output_dictionary = _find_json_dictionary_by_id(arcweave_json_data, str(output_value))
				if output_dictionary is Dictionary:
					var label: String = _get_label_from_dictionary(output_dictionary)
					if label != "" and not _is_generic_choice_label(label):
						return label

	return ""


func _get_target_label_from_output_dictionary(output_dictionary: Dictionary) -> String:
	var possible_target_keys: Array[String] = [
		"target",
		"targetid",
		"target_id",
		"targetId",
		"target_element",
		"target_element_id",
		"targetElementId",
		"to",
		"toid",
		"to_id",
		"toId",
		"element",
		"elementid",
		"element_id",
		"elementId"
	]

	for key in possible_target_keys:
		if not output_dictionary.has(key):
			continue

		var target_id: String = str(output_dictionary[key])
		var target_dictionary = _find_json_dictionary_by_id(arcweave_json_data, target_id)
		if target_dictionary is Dictionary:
			var label: String = _get_label_from_dictionary(target_dictionary)
			if label != "":
				return label

	return ""


func _get_label_from_dictionary(dictionary: Dictionary) -> String:
	var possible_label_keys: Array[String] = [
		"label",
		"title",
		"name",
		"text",
		"content",
		"description",
		"choice",
		"caption"
	]

	for key in possible_label_keys:
		if dictionary.has(key) and typeof(dictionary[key]) == TYPE_STRING:
			var label: String = str(dictionary[key]).strip_edges()
			if label != "":
				return _clean_choice_label(label)

	return ""


func _clean_choice_label(label: String) -> String:
	var cleaned: String = _strip_html(_strip_bbcode(label)).strip_edges()

	if cleaned.begins_with("Option "):
		var dash_index: int = _find_first_choice_separator(cleaned)
		if dash_index != -1:
			cleaned = cleaned.substr(dash_index + 1).strip_edges()

	var prefixes: Array[String] = ["A", "B"]
	for prefix in prefixes:
		if cleaned.begins_with(prefix + " - "):
			return cleaned.substr((prefix + " - ").length()).strip_edges()
		if cleaned.begins_with(prefix + ": "):
			return cleaned.substr((prefix + ": ").length()).strip_edges()

	return cleaned


func _is_generic_choice_label(label: String) -> bool:
	var cleaned := _strip_html(_strip_bbcode(label)).strip_edges().to_lower()
	return (
		cleaned == "choice the first"
		or cleaned == "choice the second"
		or cleaned == "choice first"
		or cleaned == "choice second"
		or cleaned == "choice 1"
		or cleaned == "choice 2"
	)


func _find_first_choice_separator(text: String) -> int:
	var separators: Array[String] = ["—", "–", "-"]
	var best_index: int = -1

	for separator in separators:
		var separator_index: int = text.find(separator)
		if separator_index != -1 and (best_index == -1 or separator_index < best_index):
			best_index = separator_index

	return best_index


func _strip_bbcode(text: String) -> String:
	var result: String = ""
	var inside_tag: bool = false

	for index in text.length():
		var character: String = text[index]
		if character == "[":
			inside_tag = true
			continue
		if character == "]":
			inside_tag = false
			continue
		if not inside_tag:
			result += character

	return result


func _strip_html(text: String) -> String:
	var result: String = ""
	var inside_tag: bool = false

	for index in text.length():
		var character: String = text[index]
		if character == "<":
			inside_tag = true
			continue
		if character == ">":
			inside_tag = false
			continue
		if not inside_tag:
			result += character

	return result


func _record_choice(connection: ArcweaveConnection) -> void:
	if current_element == null:
		return

	var target_element: ArcweaveElement = null
	if connection != null:
		target_element = ArcweaveManager.get_element(connection.targetid)

	selected_choices.append({
		"element_id": current_element.id,
		"element_title": str(current_element.title_cleaned),
		"selected_output": selected_output_id,
		"selected_option": selected_option_text,
		"target_element_id": connection.targetid if connection != null else "",
		"target_element_title": str(target_element.title_cleaned) if target_element != null else ""
	})

	print("Selected choices:")
	print(selected_choices)


func _on_trolley_crash() -> void:
	if scenario_complete == true:
		return

	if current_element == null:
		push_error("No current Arcweave element found on trolley crash.")
		return

	if selected_output_index == -1:
		running = false
		timer_container.hide()
		the_choice_container.show()
		return

	if current_element.outputs.size() <= selected_output_index:
		push_error("Selected output index does not exist on current Arcweave element.")
		return

	var connection: ArcweaveConnection = ArcweaveManager.project.connections.get(selected_output_id)

	if connection == null:
		push_error("No Arcweave connection found for selected output.")
		return

	_record_choice(connection)
	_record_telemetry_choice(connection)

	var next_element: ArcweaveElement = ArcweaveManager.follow_connection(connection)
	if next_element != null and current_element != next_element:
		_on_element_changed(next_element)

	running = false


func _record_telemetry_choice(connection: ArcweaveConnection) -> void:
	if connection == null:
		return

	if not has_node("/root/TelemetryEngine"):
		return

	var target_element: ArcweaveElement = ArcweaveManager.get_element(connection.targetid)
	var raw_label := selected_option_text if selected_option_text.strip_edges() != "" else str(connection.label)
	var chosen_tags := _get_narrative_tags(target_element)
	var opposing_tags := _get_opposing_tags(connection)
	var chosen_tag_sentiment := _measure_tag_sentiment(chosen_tags)
	var opposing_tag_sentiment := _measure_tag_sentiment(opposing_tags)

	TelemetryEngine.record_narrative_choice({
		"choice_id": connection.id,
		"scenario_index": current_scenario_index + 1,
		"scenario_id": current_scenario_id,
		"scenario_title": current_scenario_title,
		"source_element_id": connection.sourceid,
		"source_element_title": str(current_element.title_cleaned) if current_element != null else "",
		"source_components": _get_component_names(current_element),
		"target_element_id": connection.targetid,
		"target_element_title": str(target_element.title_cleaned) if target_element != null else "",
		"target_components": _get_component_names(target_element),
		"raw_label": raw_label,
		"connection_label": str(connection.label),
		"options": _build_telemetry_choice_options(connection),
		"chosen_tags": chosen_tags,
		"opposing_tags": opposing_tags,
		"chosen_positive_tag_count": chosen_tag_sentiment["positive_tag_count"],
		"chosen_negative_tag_count": chosen_tag_sentiment["negative_tag_count"],
		"chosen_tag_sentiment_score": chosen_tag_sentiment["tag_sentiment_score"],
		"opposing_positive_tag_count": opposing_tag_sentiment["positive_tag_count"],
		"opposing_negative_tag_count": opposing_tag_sentiment["negative_tag_count"],
		"opposing_tag_sentiment_score": opposing_tag_sentiment["tag_sentiment_score"],
		"decision_weight": _get_decision_weight(current_element),
		"is_key_moment": _has_key_moment(current_element) or _has_key_moment(target_element),
		"time_to_decide_seconds": _get_current_scenario_elapsed_seconds()
	})


func _record_telemetry_scenario_started(element: ArcweaveElement) -> void:
	if element == null:
		return

	if not has_node("/root/TelemetryEngine"):
		return

	TelemetryEngine.record_scenario_started({
		"scenario_index": current_scenario_index + 1,
		"scenario_id": str(element.id),
		"scenario_title": str(element.title_cleaned),
		"scenario_tags": _get_narrative_tags(element),
		"is_key_moment": _has_key_moment(element)
	})


func _record_telemetry_scenario_completed(result_element: ArcweaveElement) -> void:
	if not has_node("/root/TelemetryEngine"):
		return

	TelemetryEngine.record_scenario_completed({
		"scenario_index": current_scenario_index + 1,
		"scenario_id": current_scenario_id,
		"scenario_title": current_scenario_title,
		"result_element_id": str(result_element.id) if result_element != null else "",
		"result_title": str(result_element.title_cleaned) if result_element != null else "",
		"final_tags": _get_narrative_tags(result_element)
	})


func _build_telemetry_choice_options(chosen_connection: ArcweaveConnection) -> Array:
	var options: Array = []

	if current_element == null:
		return options

	for output_id in current_element.outputs:
		var option_connection: ArcweaveConnection = ArcweaveManager.project.connections.get(output_id)
		if option_connection == null:
			continue

		if option_connection.target_type != "elements":
			continue

		var option_element: ArcweaveElement = ArcweaveManager.get_element(option_connection.targetid)
		var option_label := _get_choice_label_for_connection(option_connection)
		var option_tags := _get_narrative_tags(option_element)
		var sentiment := _measure_tag_sentiment(option_tags)

		options.append({
			"label": option_label,
			"target_id": str(option_connection.targetid),
			"target_title": str(option_element.title_cleaned) if option_element != null else "",
			"tags": option_tags,
			"positive_tag_count": sentiment["positive_tag_count"],
			"negative_tag_count": sentiment["negative_tag_count"],
			"sentiment_score": sentiment["tag_sentiment_score"],
			"was_chosen": option_connection.id == chosen_connection.id
		})

	return options


func _get_choice_label_for_connection(connection: ArcweaveConnection) -> String:
	if connection == null:
		return ""

	if connection.id == selected_output_id and selected_option_text.strip_edges() != "":
		return selected_option_text

	var output_index := -1
	if current_element != null:
		output_index = current_element.outputs.find(connection.id)

	var label := _get_choice_label_from_arcweave_json(connection.id, output_index)
	if label != "":
		return label

	label = _get_choice_label_from_runtime_connection(connection.id)
	if label != "":
		return label

	label = _clean_choice_label(str(connection.label))
	return "" if _is_generic_choice_label(label) else label


func _get_current_scenario_elapsed_seconds() -> float:
	if current_scenario_started_at_msec <= 0:
		return 0.0

	return float(Time.get_ticks_msec() - current_scenario_started_at_msec) / 1000.0


func _get_component_names(element: ArcweaveElement) -> Array:
	var names: Array = []

	if element == null:
		return names

	for component_id in element.components:
		var component = ArcweaveManager.get_component(component_id)
		if component != null:
			names.append(str(component.name))

	return names


func _get_narrative_tags(element: ArcweaveElement) -> Array:
	var tags: Array = []

	if element == null:
		return tags

	for component_id in element.components:
		var component_id_string := str(component_id)
		var tag_name := str(NARRATIVE_TAG_IDS.get(component_id_string, ""))

		if tag_name == "":
			var component_name := _get_component_name(component_id_string)
			if NARRATIVE_TAG_NAMES.has(component_name):
				tag_name = component_name

		if not tag_name.is_empty() and not tags.has(tag_name):
			tags.append(tag_name)

	return tags


func _get_opposing_tags(chosen_connection: ArcweaveConnection) -> Array:
	var tags: Array = []

	if current_element == null:
		return tags

	for output_id in current_element.outputs:
		if output_id == chosen_connection.id:
			continue

		var other_connection: ArcweaveConnection = ArcweaveManager.project.connections.get(output_id)
		if other_connection == null:
			continue

		if other_connection.target_type != "elements":
			continue

		var other_element: ArcweaveElement = ArcweaveManager.get_element(other_connection.targetid)
		tags = _merge_unique(tags, _get_narrative_tags(other_element))

	return tags


func _measure_tag_sentiment(tags: Array) -> Dictionary:
	var positive_count := 0
	var negative_count := 0

	for tag in tags:
		var tag_name := str(tag)
		if POSITIVE_TAG_NAMES.has(tag_name):
			positive_count += 1
		elif NEGATIVE_TAG_NAMES.has(tag_name):
			negative_count += 1

	return {
		"positive_tag_count": positive_count,
		"negative_tag_count": negative_count,
		"tag_sentiment_score": positive_count - negative_count
	}


func _merge_unique(first: Array, second: Array) -> Array:
	var result: Array = []

	for item in first:
		var value := str(item)
		if value != "" and not result.has(value):
			result.append(value)

	for item in second:
		var value := str(item)
		if value != "" and not result.has(value):
			result.append(value)

	return result


func _get_decision_weight(element: ArcweaveElement) -> int:
	if element == null:
		return 1

	for component_id in element.components:
		var component_id_string := str(component_id)
		var component_name := _get_component_name(component_id_string)

		if component_id_string == WEIGHT_2_ID or component_name == WEIGHT_2_NAME:
			return 2

	return 1


func _has_key_moment(element: ArcweaveElement) -> bool:
	if element == null:
		return false

	for component_id in element.components:
		var component_id_string := str(component_id)
		var component_name := _get_component_name(component_id_string)

		if component_id_string == KEY_MOMENT_ID or component_name == KEY_MOMENT_NAME:
			return true

	return false


func _get_arcweave_variables() -> Dictionary:
	var variables := {}

	if ArcweaveManager.state == null:
		return variables

	for key in ArcweaveManager.state.variables:
		variables[key] = ArcweaveManager.get_variable(key)

	return variables


func _get_component_name(component_id: String) -> String:
	var component: ArcweaveComponent = ArcweaveManager.get_component(component_id)
	if component == null:
		return ""

	return str(component.name)


func _is_start_trolley_component(component_id: String, component_name: String) -> bool:
	return component_id == START_TROLLEY_ID or component_name == START_TROLLEY_NAME


func _is_scenario_complete_component(component_id: String, component_name: String) -> bool:
	return component_id == SCENARIO_COMPLETE_ID or component_name == SCENARIO_COMPLETE_NAME
