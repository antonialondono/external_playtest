extends Node

@export_group("Game Context")
@export var game_title := "Trolley Troubles"
@export_multiline var game_description := ""

@export_group("Gemini Local AI")
@export var use_gemini := false
@export var gemini_api_key := ""
@export var gemini_model := "gemini-2.0-flash"
@export_multiline var ai_style_notes := "Reflective, concise, in-game, not diagnostic."

@export_group("Local Tracking")
@export var auto_finish_on_game_complete_scene := true
@export var game_complete_scene_hint := "res://scenes/game_complete/"
@export var save_session_json_to_downloads := true
@export var save_session_json_to_project_folder := true
@export var downloads_session_folder_name := "TrolleyTroublesTelemetry"
@export var debug_logs := true
@export var record_debug_transitions := false

@export_group("Legacy Server Field")
@export var base_url := ""

@export_group("Keepsake Default Cards")
@export var card_1: KeepsakeCardConfig
@export var card_2: KeepsakeCardConfig
@export var card_3: KeepsakeCardConfig

@export_group("Keepsake User Test")
@export var use_user_test_card_presets := true
@export var auto_select_user_test_card_version := true
@export_range(1, 4, 1) var user_test_card_version := 1

var session_id := ""
var started_at := 0
var ended_at := 0

var game_id := "local"
var event_buffer: Array = []
var final_variables: Dictionary = {}
var variable_snapshot: Dictionary = {}
var last_element_id := ""
var gemini_request_in_progress := false
var session_sent := false
var _last_recorded_choice_key := ""


func _ready() -> void:
	start_local_session()
	set_process(true)


func _process(_delta: float) -> void:
	if auto_finish_on_game_complete_scene:
		_check_for_game_complete_scene()

func _check_for_game_complete_scene() -> void:
	if session_sent:
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	var scene_path := str(current_scene.scene_file_path)
	if scene_path.begins_with(game_complete_scene_hint):
		call_deferred("send_session")

func start_local_session() -> void:
	session_id = str(Time.get_unix_time_from_system())
	started_at = Time.get_unix_time_from_system()
	ended_at = 0
	game_id = "local_" + session_id
	event_buffer.clear()
	final_variables.clear()
	variable_snapshot.clear()
	last_element_id = ""
	gemini_request_in_progress = false
	session_sent = false
	_last_recorded_choice_key = ""

	_log("TelemetryEngine: local session started " + session_id)


func reset_session() -> void:
	start_local_session()


func record_variable(var_name: String, value: Variant, context: Dictionary = {}) -> void:
	var old_value: Variant = variable_snapshot.get(var_name, null)
	variable_snapshot[var_name] = value

	if not record_debug_transitions:
		return

	var data := context.duplicate()
	data.merge({
		"variable": var_name,
		"old_value": old_value,
		"new_value": value
	}, true)

	record_event("variable_changed", data)


func set_variable_summary(variables: Dictionary, record_changes := false, context: Dictionary = {}) -> void:
	var previous := variable_snapshot.duplicate()
	variable_snapshot = variables.duplicate()

	if not record_changes or not record_debug_transitions:
		return

	for key in variable_snapshot.keys():
		var new_value: Variant = variable_snapshot[key]
		if not previous.has(key):
			var detected_data := context.duplicate()
			detected_data.merge({
				"variable": str(key),
				"value": new_value
			}, true)
			record_event("variable_detected", detected_data)
		elif previous[key] != new_value:
			var changed_data := context.duplicate()
			changed_data.merge({
				"variable": str(key),
				"old_value": previous[key],
				"new_value": new_value
			}, true)
			record_event("variable_changed", changed_data)


func record_story_node_changed(from_element_id: String, to_element_id: String, to_element_title := "", context: Dictionary = {}) -> void:
	last_element_id = to_element_id

	if not record_debug_transitions:
		return

	var data := context.duplicate()
	data.merge({
		"from_element_id": from_element_id,
		"to_element_id": to_element_id,
		"to_element_title": to_element_title
	}, true)

	record_event("element_changed", data)


func record_narrative_choice(choice_data: Dictionary) -> void:
	var raw_label := str(choice_data.get("raw_label", choice_data.get("chosen", "")))
	var clean_label := _clean_choice_label(raw_label)

	var label_tags := _extract_tags(raw_label)
	var target_tags: Array = choice_data.get("chosen_tags", [])
	var chosen_tags := _merge_unique(label_tags, target_tags)

	var opposing_tags: Array = choice_data.get("opposing_tags", [])

	var shared_tags := _get_shared_tags(chosen_tags, opposing_tags)
	var tension_chosen_tags := _without_tags(chosen_tags, shared_tags)
	var tension_opposing_tags := _without_tags(opposing_tags, shared_tags)

	# Skip normal transitions with no moral tags.
	if chosen_tags.is_empty() and opposing_tags.is_empty():
		if debug_logs:
			print("TelemetryEngine skipped non-tagged transition: ", clean_label)
		return

	var source_element_id := str(choice_data.get("source_element_id", ""))
	var target_element_id := str(choice_data.get("target_element_id", ""))
	var choice_id := str(choice_data.get("choice_id", source_element_id + "|" + target_element_id))
	var choice_key := choice_id + "|" + raw_label
	if choice_key == _last_recorded_choice_key:
		return

	_last_recorded_choice_key = choice_key

	var clean_options := _clean_choice_options(choice_data.get("options", []), clean_label)
	var not_chosen := _get_not_chosen_options(clean_options, clean_label)

	var event_data := {
		"choice_id": choice_id,
		"scenario_index": int(choice_data.get("scenario_index", 0)),
		"scenario_id": str(choice_data.get("scenario_id", "")),
		"scenario_title": str(choice_data.get("scenario_title", "")),
		"source_element_id": source_element_id,
		"source_element_title": str(choice_data.get("source_element_title", "")),
		"source_components": choice_data.get("source_components", []),
		"target_element_id": target_element_id,
		"target_element_title": str(choice_data.get("target_element_title", "")),
		"target_components": choice_data.get("target_components", []),

		"chosen_label": clean_label,
		"chosen": clean_label,
		"options": clean_options,
		"not_chosen": not_chosen,

		"chosen_tags": chosen_tags,
		"opposing_tags": opposing_tags,
		"moral_tensions": _build_tension_pairs(tension_chosen_tags, tension_opposing_tags),

		"chosen_positive_tag_count": int(choice_data.get("chosen_positive_tag_count", 0)),
		"chosen_negative_tag_count": int(choice_data.get("chosen_negative_tag_count", 0)),
		"chosen_tag_sentiment_score": int(choice_data.get("chosen_tag_sentiment_score", 0)),
		"opposing_positive_tag_count": int(choice_data.get("opposing_positive_tag_count", 0)),
		"opposing_negative_tag_count": int(choice_data.get("opposing_negative_tag_count", 0)),
		"opposing_tag_sentiment_score": int(choice_data.get("opposing_tag_sentiment_score", 0)),

		"decision_weight": int(choice_data.get("decision_weight", 1)),
		"is_key_moment": bool(choice_data.get("is_key_moment", false)),
		"time_to_decide_seconds": float(choice_data.get("time_to_decide_seconds", 0.0))
	}

	record_event("moral_choice_made", event_data)

	if debug_logs:
		print("TelemetryEngine tags read:")
		print("  Choice: ", clean_label)
		print("  Chosen tags: ", chosen_tags)
		print("  Opposing tags: ", opposing_tags)


func track_decision(choice_id: String, chosen: String, tags: Array = [], description: String = "") -> void:
	var clean_label := _clean_choice_label(chosen)
	_last_recorded_choice_key = choice_id + "|" + chosen

	record_event("moral_choice_made", {
		"choice_id": choice_id,
		"chosen": clean_label,
		"raw_label": chosen,
		"tags": tags,
		"description": description
	})


func record_event(event_name: String, data: Dictionary) -> void:
	event_buffer.append({
		"event_name": event_name,
		"data": data,
		"timestamp": Time.get_datetime_string_from_system(true),
		"unix_timestamp": Time.get_unix_time_from_system()
	})

	if debug_logs:
		print("TelemetryEngine recorded event: ", event_name)


func record_scenario_started(data: Dictionary) -> void:
	record_event("scenario_started", {
		"scenario_index": int(data.get("scenario_index", 0)),
		"scenario_id": str(data.get("scenario_id", "")),
		"scenario_title": str(data.get("scenario_title", "")),
		"scenario_tags": data.get("scenario_tags", []),
		"is_key_moment": bool(data.get("is_key_moment", false))
	})


func record_scenario_completed(data: Dictionary) -> void:
	record_event("scenario_completed", {
		"scenario_index": int(data.get("scenario_index", 0)),
		"scenario_id": str(data.get("scenario_id", "")),
		"scenario_title": str(data.get("scenario_title", "")),
		"result_element_id": str(data.get("result_element_id", "")),
		"result_title": str(data.get("result_title", "")),
		"final_tags": data.get("final_tags", [])
	})


func record_choice(
	choice_id: String,
	chosen: String,
	options: Array = [],
	tags: Array = [],
	description: String = ""
) -> void:
	record_event("moral_choice_made", {
		"choice_id": choice_id,
		"chosen": chosen,
		"options": options,
		"tags": tags,
		"description": description
	})


func record_moral_choice(
	choice_id: String,
	scenario: String,
	question: String,
	options: Array,
	chosen: String,
	tags: Array = []
) -> void:
	var not_chosen := []

	for option in options:
		if option != chosen:
			not_chosen.append(option)

	record_event("moral_choice_made", {
		"choice_id": choice_id,
		"scenario": scenario,
		"question": question,
		"options": options,
		"chosen": chosen,
		"not_chosen": not_chosen,
		"tags": tags
	})


func flush_events() -> void:
	# Kept only for compatibility with older code.
	# There is no server in the local Gemini MVP.
	return


func build_variable_summary() -> Dictionary:
	return variable_snapshot.duplicate()


func build_session_payload() -> Dictionary:
	final_variables = build_variable_summary()
	var gameplay_summary := build_gameplay_summary()
	var generated_at := Time.get_unix_time_from_system()

	return {
		"session_id": session_id,
		"game_id": game_id,
		"game_title": game_title,
		"game_description": game_description,
		"started_at": started_at,
		"started_at_timestamp": _format_unix_timestamp(started_at),
		"ended_at": ended_at,
		"ended_at_timestamp": _format_unix_timestamp(ended_at),
		"duration_seconds": max(0, ended_at - started_at),
		"generated_at": generated_at,
		"generated_at_timestamp": _format_unix_timestamp(generated_at),

		"summary": gameplay_summary,
		"events": event_buffer,

		"important_note": "This is local single-session gameplay telemetry collected inside Godot. Interpret it as narrative reflection, not diagnosis."
	}


func build_gameplay_summary() -> Dictionary:
	var tag_summary := build_tag_summary()

	return {
		"scenarios_started": _count_events_named("scenario_started"),
		"scenarios_completed": _count_events_named("scenario_completed"),
		"choices_made": _count_events_named("moral_choice_made"),
		"tag_counts": build_tag_counts(),
		"tag_summary": tag_summary,
		"choice_tag_log": build_choice_tag_log(),
		"dominance_matrix": build_dominance_matrix(),
		"dominant_tags": _top_count_keys(tag_summary.get("chosen_tag_counts", {}), 5),
		"avoided_tags": _top_count_keys(tag_summary.get("opposed_tag_counts", {}), 5),
		"key_moments": build_key_moment_log()
	}
	
func build_tag_summary() -> Dictionary:
	var chosen_counts := {}
	var opposed_counts := {}
	var all_counts := {}

	for event in event_buffer:
		if typeof(event) != TYPE_DICTIONARY:
			continue

		if event.get("event_name", "") != "moral_choice_made":
			continue

		var data: Dictionary = event.get("data", {})

		var chosen_tags: Array = data.get("chosen_tags", data.get("tags", []))
		var opposing_tags: Array = data.get("opposing_tags", [])

		for tag in chosen_tags:
			var key := str(tag)
			chosen_counts[key] = int(chosen_counts.get(key, 0)) + 1
			all_counts[key] = int(all_counts.get(key, 0)) + 1

		for tag in opposing_tags:
			var key := str(tag)
			opposed_counts[key] = int(opposed_counts.get(key, 0)) + 1
			all_counts[key] = int(all_counts.get(key, 0)) + 1

	return {
		"chosen_tag_counts": chosen_counts,
		"opposed_tag_counts": opposed_counts,
		"all_tag_mentions": all_counts
	}


func build_choice_tag_log() -> Array:
	var log: Array = []

	for event in event_buffer:
		if typeof(event) != TYPE_DICTIONARY:
			continue

		if event.get("event_name", "") != "moral_choice_made":
			continue

		var data: Dictionary = event.get("data", {})

		log.append({
			"choice_id": str(data.get("choice_id", "")),
			"scenario_index": int(data.get("scenario_index", 0)),
			"scenario_title": str(data.get("scenario_title", "")),
			"chosen": str(data.get("chosen_label", data.get("chosen", ""))),
			"target_element_title": str(data.get("target_element_title", "")),
			"chosen_tags": data.get("chosen_tags", data.get("tags", [])),
			"opposing_tags": data.get("opposing_tags", []),
			"moral_tensions": data.get("moral_tensions", []),
			"decision_weight": int(data.get("decision_weight", 1)),
			"is_key_moment": bool(data.get("is_key_moment", false))
		})

	return log


func build_key_moment_log() -> Array:
	var log: Array = []

	for event in event_buffer:
		if typeof(event) != TYPE_DICTIONARY:
			continue

		if event.get("event_name", "") != "moral_choice_made":
			continue

		var data: Dictionary = event.get("data", {})
		if not bool(data.get("is_key_moment", false)):
			continue

		log.append({
			"scenario_index": int(data.get("scenario_index", 0)),
			"scenario_title": str(data.get("scenario_title", "")),
			"choice": str(data.get("chosen_label", data.get("chosen", ""))),
			"chosen_tags": data.get("chosen_tags", []),
			"opposing_tags": data.get("opposing_tags", [])
		})

	return log

func build_tag_counts() -> Dictionary:
	var counts := {}

	for event in event_buffer:
		if typeof(event) != TYPE_DICTIONARY:
			continue

		if event.get("event_name", "") != "moral_choice_made":
			continue

		var data: Dictionary = event.get("data", {})
		var tags: Array = data.get("chosen_tags", data.get("tags", []))

		for tag in tags:
			var key := str(tag)
			counts[key] = int(counts.get(key, 0)) + 1

	return counts

func build_dominance_matrix() -> Dictionary:
	var matrix := {}

	for event in event_buffer:
		if typeof(event) != TYPE_DICTIONARY:
			continue

		if event.get("event_name", "") != "moral_choice_made":
			continue

		var data: Dictionary = event.get("data", {})
		var weight := int(data.get("decision_weight", 1))
		var tensions: Array = data.get("moral_tensions", [])

		for tension in tensions:
			if typeof(tension) != TYPE_DICTIONARY:
				continue

			var chosen := str(tension.get("chosen", ""))
			var opposed := str(tension.get("opposed", ""))

			if chosen == "" or opposed == "":
				continue

			if not matrix.has(chosen):
				matrix[chosen] = {}

			matrix[chosen][opposed] = int(matrix[chosen].get(opposed, 0)) + weight

	return matrix


func _top_count_keys(counts: Dictionary, limit := 5) -> Array:
	var remaining := counts.duplicate()
	var result: Array = []

	while result.size() < limit and not remaining.is_empty():
		var best_key := ""
		var best_count := -1

		for key in remaining.keys():
			var count := int(remaining[key])
			if count > best_count:
				best_count = count
				best_key = str(key)

		if best_key == "":
			break

		result.append(best_key)
		remaining.erase(best_key)

	return result


func _clean_choice_options(options: Variant, chosen_label: String) -> Array:
	var result: Array = []

	if typeof(options) != TYPE_ARRAY:
		return result

	for option in options:
		if typeof(option) == TYPE_DICTIONARY:
			var option_data: Dictionary = option
			var label := _clean_choice_label(str(option_data.get("label", "")))
			if label == "":
				continue

			result.append({
				"label": label,
				"target_id": str(option_data.get("target_id", "")),
				"target_title": str(option_data.get("target_title", "")),
				"tags": option_data.get("tags", []),
				"positive_tag_count": int(option_data.get("positive_tag_count", 0)),
				"negative_tag_count": int(option_data.get("negative_tag_count", 0)),
				"sentiment_score": int(option_data.get("sentiment_score", 0)),
				"was_chosen": bool(option_data.get("was_chosen", label == chosen_label))
			})
		else:
			var plain_label := _clean_choice_label(str(option))
			if plain_label != "":
				result.append({
					"label": plain_label,
					"target_id": "",
					"target_title": "",
					"tags": [],
					"positive_tag_count": 0,
					"negative_tag_count": 0,
					"sentiment_score": 0,
					"was_chosen": plain_label == chosen_label
				})

	return result


func _get_not_chosen_options(options: Array, chosen_label: String) -> Array:
	var result: Array = []

	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue

		if bool(option.get("was_chosen", false)):
			continue

		var label := str(option.get("label", ""))
		if label != "" and label != chosen_label:
			result.append(label)

	return result


func send_session() -> void:
	if gemini_request_in_progress:
		_log("TelemetryEngine: Gemini request already in progress.")
		return

	if session_sent:
		_log("TelemetryEngine: session was already sent. Showing latest local/fallback cards again.")
		var repeat_data := get_final_keepsake_data({})
		repeat_data["session_duration_text"] = format_session_duration(ended_at - started_at)
		show_keepsake_overlay(repeat_data)
		return

	session_sent = true
	ended_at = Time.get_unix_time_from_system()

	record_event("game_completed", {
		"started_at": started_at,
		"ended_at": ended_at,
		"duration_seconds": ended_at - started_at,
		"summary": build_gameplay_summary()
	})

	var session_payload := build_session_payload()
	save_session_summary(session_payload)

	if debug_logs:
		print("TelemetryEngine local session payload:")
		print(JSON.stringify(session_payload, "\t"))

	var final_data := {}

	if use_gemini and not gemini_api_key.strip_edges().is_empty():
		gemini_request_in_progress = true
		final_data = await request_gemini_cards(session_payload)
		gemini_request_in_progress = false
	else:
		_log("TelemetryEngine: Gemini disabled or missing API key. Using local fallback cards.")

	final_data = get_final_keepsake_data(final_data)
	if final_data.has("selected_user_test_card_version"):
		session_payload["local_keepsake"] = {
			"version": int(final_data.get("selected_user_test_card_version", user_test_card_version)),
			"selection_data": final_data.get("selection_data", {})
		}
		save_session_summary(session_payload)

	final_data["session_duration_text"] = format_session_duration(ended_at - started_at)
	show_keepsake_overlay(final_data)


func save_session_summary(session_payload: Dictionary) -> void:
	var folder := "user://telemetry_sessions/"
	var file_name := "session_" + session_id + ".json"
	var json_text := JSON.stringify(session_payload, "\t")
	_save_session_json(folder, file_name, json_text)

	if save_session_json_to_project_folder:
		_save_session_json("res://telemetry_sessions/", file_name, json_text)

	if not save_session_json_to_downloads:
		return

	var downloads_folder := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if downloads_folder.strip_edges().is_empty():
		push_warning("TelemetryEngine could not find the Downloads folder.")
		return

	var downloads_session_folder := downloads_folder.path_join(downloads_session_folder_name) + "/"
	_save_session_json(downloads_session_folder, file_name, json_text)


func _save_session_json(folder: String, file_name: String, json_text: String) -> void:
	var absolute_folder := _get_absolute_path(folder)
	var error := DirAccess.make_dir_recursive_absolute(absolute_folder)

	if error != OK:
		push_warning("TelemetryEngine could not create local session folder: " + absolute_folder)
		return

	var path := folder.path_join(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		push_warning("TelemetryEngine could not save local session summary: " + _get_absolute_path(path))
		return

	file.store_string(json_text)
	file.close()

	_log("TelemetryEngine saved local session summary: " + _get_absolute_path(path))


func _get_absolute_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)

	return path

func request_gemini_cards(session_payload: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)

	var url := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" % [
		gemini_model.strip_edges(),
		gemini_api_key.strip_edges().uri_encode()
	]

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var request_body := {
		"contents": [
			{
				"role": "user",
				"parts": [
					{
						"text": build_gemini_prompt(session_payload)
					}
				]
			}
		],
		"generationConfig": {
			"temperature": 0.7,
			"response_mime_type": "application/json",
			"response_schema": cards_response_schema()
		}
	}

	var error := http.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(request_body)
	)

	if error != OK:
		_log("TelemetryEngine: Gemini request error " + str(error))
		http.queue_free()
		return {}

	var result: Array = await http.request_completed
	http.queue_free()

	var response_code: int = result[1]
	var raw_body: PackedByteArray = result[3]
	var response_text := raw_body.get_string_from_utf8()

	if debug_logs:
		print("Gemini response code: ", response_code)
		print("Gemini response body: ", response_text)

	if response_code < 200 or response_code >= 300:
		_log("TelemetryEngine: Gemini HTTP error " + str(response_code))
		return {}

	var parsed: Variant = JSON.parse_string(response_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_log("TelemetryEngine: Could not parse Gemini response.")
		return {}

	var generated_text := extract_gemini_text(parsed)
	if generated_text.strip_edges().is_empty():
		_log("TelemetryEngine: Gemini returned empty text.")
		return {}

	var card_data: Variant = JSON.parse_string(generated_text)
	if typeof(card_data) != TYPE_DICTIONARY:
		_log("TelemetryEngine: Gemini card JSON was invalid.")
		return {}

	return normalize_keepsake_data(card_data)


func build_gemini_prompt(session_payload: Dictionary) -> String:
	return """
You are generating an in-game keepsake deck for a narrative choice-based game.

Your job:
Read the local Godot gameplay telemetry and create exactly 3 player cards.

Tone:
%s

Rules:
- Use only the provided telemetry.
- Do not invent choices that are not present in the variables or events.
- Do not judge the player as good, bad, ethical, unethical, healthy, unhealthy, etc.
- Do not make psychological, clinical, or diagnostic claims.
- Present the output as a reflective narrative souvenir.
- If the data is limited, acknowledge that the reading is based on a short session.
- Keep all text concise enough to fit on game cards.
- Return only valid JSON.

Return this exact JSON shape:
{
  "cards": [
    {
	  "type": "defining_moment",
	  "card_detail_tab": "DEFINING MOMENT",
	  "title": "short title",
	  "description": "1 sentence description",
	  "details": ["short detail 1", "short detail 2"],
	  "dyk_bar_text": "optional short line or empty string",
	  "scratchable_dyk": "",
	  "reveal_title": "short reveal title",
	  "reveal_body": "1 sentence reveal text"
    },
    {
	  "type": "journey",
	  "card_detail_tab": "THE TRAIL YOU LEFT",
	  "title": "short title",
	  "description": "1 sentence description",
	  "details": ["short detail 1", "short detail 2"],
	  "dyk_bar_text": "optional short line or empty string",
	  "scratchable_dyk": "",
	  "reveal_title": "short reveal title",
	  "reveal_body": "1 sentence reveal text"
    },
    {
	  "type": "archetype",
	  "card_detail_tab": "ARCHETYPE REVEAL",
	  "title": "short title",
	  "description": "1 sentence description",
	  "details": ["short trait 1", "short trait 2"],
	  "dyk_bar_text": "optional short line or empty string",
	  "scratchable_dyk": "",
	  "reveal_title": "short reveal title",
	  "reveal_body": "1 sentence reveal text"
    }
  ]
}

Telemetry:
%s
""" % [ai_style_notes, JSON.stringify(session_payload, "\t")]


func cards_response_schema() -> Dictionary:
	var card_schema := {
		"type": "OBJECT",
		"properties": {
			"type": {"type": "STRING"},
			"card_detail_tab": {"type": "STRING"},
			"title": {"type": "STRING"},
			"description": {"type": "STRING"},
			"details": {
				"type": "ARRAY",
				"items": {"type": "STRING"}
			},
			"dyk_bar_text": {"type": "STRING"},
			"scratchable_dyk": {"type": "STRING"},
			"reveal_title": {"type": "STRING"},
			"reveal_body": {"type": "STRING"}
		},
		"required": [
			"type",
			"card_detail_tab",
			"title",
			"description",
			"details",
			"dyk_bar_text",
			"scratchable_dyk",
			"reveal_title",
			"reveal_body"
		]
	}

	return {
		"type": "OBJECT",
		"properties": {
			"cards": {
				"type": "ARRAY",
				"items": card_schema
			}
		},
		"required": ["cards"]
	}


func extract_gemini_text(parsed_response: Dictionary) -> String:
	var candidates: Array = parsed_response.get("candidates", [])
	if candidates.is_empty():
		return ""

	var candidate: Dictionary = candidates[0]
	var content: Dictionary = candidate.get("content", {})
	var parts: Array = content.get("parts", [])
	if parts.is_empty():
		return ""

	var first_part: Dictionary = parts[0]
	return str(first_part.get("text", ""))


func normalize_keepsake_data(data: Dictionary) -> Dictionary:
	var normalized_cards: Array = []
	var incoming_cards: Array = data.get("cards", [])

	for card in incoming_cards:
		if typeof(card) != TYPE_DICTIONARY:
			continue

		normalized_cards.append({
			"type": str(card.get("type", "journey")),
			"card_detail_tab": str(card.get("card_detail_tab", "PLAYER CARD")),
			"title": str(card.get("title", "Untitled Card")),
			"description": str(card.get("description", "")),
			"details": _normalize_details(card.get("details", [])),
			"dyk_bar_text": str(card.get("dyk_bar_text", "")),
			"scratchable_dyk": str(card.get("scratchable_dyk", "")),
			"reveal_title": str(card.get("reveal_title", "A Card Reveals Itself")),
			"reveal_body": str(card.get("reveal_body", "Your choices left a visible trace.")),
			"border_image": null,
			"background_texture": null,
			"logo": null,
			"main_image": null,
			"icon_1": null,
			"icon_2": null
		})

	return {
		"cards": normalized_cards
	}


func _normalize_details(value: Variant) -> Array:
	var details: Array = []

	if typeof(value) == TYPE_ARRAY:
		for item in value:
			details.append(str(item))
	else:
		details.append(str(value))

	while details.size() < 2:
		details.append("")

	if details.size() > 2:
		details = details.slice(0, 2)

	return details


func get_final_keepsake_data(ai_data: Dictionary = {}) -> Dictionary:
	if use_user_test_card_presets:
		var selected_version := user_test_card_version
		var selection_data := {}
		if auto_select_user_test_card_version:
			selection_data = select_user_test_card_version()
			selected_version = int(selection_data.get("version", user_test_card_version))

		var keepsake_data := build_user_test_keepsake_data(selected_version)
		keepsake_data["selected_user_test_card_version"] = selected_version
		keepsake_data["selection_data"] = selection_data
		return keepsake_data

	if ai_data.has("cards") and typeof(ai_data["cards"]) == TYPE_ARRAY and not ai_data["cards"].is_empty():
		return ai_data

	var local_cards := build_local_data_cards()
	if not local_cards.is_empty():
		return {
			"cards": local_cards
		}

	var inspector_cards := build_default_keepsake_cards()
	if not inspector_cards.is_empty():
		return {
			"cards": inspector_cards
		}

	return {
		"cards": build_prototype_fallback_cards()
	}


func select_user_test_card_version() -> Dictionary:
	var scores := {
		1: 0,
		2: 0,
		3: 0,
		4: 0
	}
	var chosen_tag_scores := {
		"Liberty": 0,
		"Fairness": 0,
		"Care": 0
	}
	var matched_signals: Array[String] = []
	var signal_sources: Array = []
	var moral_choice_count := 0

	for event in event_buffer:
		if typeof(event) != TYPE_DICTIONARY:
			continue

		if event.get("event_name", "") != "moral_choice_made":
			continue

		moral_choice_count += 1
		var data: Dictionary = event.get("data", {})
		var weight := int(data.get("decision_weight", 1))
		var chosen_tags: Array = data.get("chosen_tags", data.get("tags", []))

		for tag in chosen_tags:
			var tag_name := str(tag)
			if chosen_tag_scores.has(tag_name):
				chosen_tag_scores[tag_name] = int(chosen_tag_scores[tag_name]) + weight

		var card_signal := _get_user_test_card_signal(data)
		if card_signal != "":
			matched_signals.append(card_signal)
			signal_sources.append({
				"signal": card_signal,
				"scenario_title": str(data.get("scenario_title", "")),
				"choice": str(data.get("chosen_label", data.get("chosen", "")))
			})
			var signal_version := _get_user_test_version_for_signal(card_signal)
			scores[signal_version] = int(scores[signal_version]) + _get_user_test_signal_weight(card_signal)

	if moral_choice_count == 0:
		return {
			"version": user_test_card_version,
			"reason": "No moral choices recorded yet. Using manual user_test_card_version.",
			"scores": scores,
			"chosen_tag_scores": chosen_tag_scores
		}

	var liberty := int(chosen_tag_scores.get("Liberty", 0))
	var fairness := int(chosen_tag_scores.get("Fairness", 0))
	var care := int(chosen_tag_scores.get("Care", 0))

	scores[1] = int(scores[1]) + liberty * 3 + care * 2 + fairness
	scores[2] = int(scores[2]) + fairness * 3 + liberty * 2 + care
	scores[3] = int(scores[3]) + fairness * 3 + care * 2 + liberty
	scores[4] = int(scores[4]) + care * 3 + fairness * 2 + liberty

	var key_moment_hint := _pick_primary_user_test_signal(matched_signals)
	var selected_version := _get_user_test_version_for_signal(key_moment_hint) if key_moment_hint != "" else 1

	if key_moment_hint == "":
		var selected_score := int(scores[1])
		for version in [2, 3, 4]:
			var score := int(scores[version])
			if score > selected_score:
				selected_version = version
				selected_score = score

	return {
		"version": selected_version,
		"reason": _get_user_test_version_reason(selected_version, key_moment_hint),
		"scores": scores,
		"chosen_tag_scores": chosen_tag_scores,
		"key_moment_hint": key_moment_hint,
		"matched_signals": matched_signals,
		"signal_sources": signal_sources,
		"moral_choice_count": moral_choice_count
	}


func _get_user_test_card_signal(data: Dictionary) -> String:
	var scenario_text := _normalize_selection_text(
		str(data.get("scenario_title", "")) + " " + str(data.get("source_element_title", ""))
	)
	var choice_text := _normalize_selection_text(
		str(data.get("chosen_label", data.get("chosen", ""))) + " " + str(data.get("target_element_title", ""))
	)
	var combined_text := scenario_text + " " + choice_text

	if _contains_any(scenario_text, ["protest", "march"]) and _contains_any(choice_text, [
		"peaceful protest",
		"keep the protest peaceful",
		"kept it peaceful",
		"no violence",
		"nonviolence"
	]):
		return "peaceful_protest"

	if _contains_any(scenario_text, ["partner", "discovery", "truth", "conspiracy", "broadcaster"]) and _contains_any(choice_text, [
		"help your partner",
		"help them expose",
		"expose the conspiracy",
		"exposed truth",
		"bring the truth",
		"release the story"
	]):
		return "exposed_truth"

	if _contains_any(combined_text, ["superweapon", "weapon"]):
		if _contains_any(choice_text, [
			"control the weapon",
			"control it",
			"kept control",
			"keep control",
			"negotiate peace"
		]):
			return "controlled_weapon"

		if _contains_any(choice_text, [
			"destroy the weapon",
			"destroy it",
			"remove the weapon",
			"broken weapon"
		]):
			return "destroyed_weapon"

	return ""


func _normalize_selection_text(value: String) -> String:
	var text := value.to_lower()
	text = text.replace("’", "'")
	text = text.replace("â€™", "'")
	text = text.replace("—", "-")
	text = text.replace("â€”", "-")
	return text


func _contains_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true

	return false


func _pick_primary_user_test_signal(signals: Array[String]) -> String:
	if signals.is_empty():
		return ""

	for priority_signal in ["peaceful_protest", "exposed_truth", "controlled_weapon", "destroyed_weapon"]:
		if signals.has(priority_signal):
			return priority_signal

	return signals.back()


func _get_user_test_version_for_signal(card_signal: String) -> int:
	match card_signal:
		"destroyed_weapon":
			return 1
		"exposed_truth":
			return 2
		"controlled_weapon":
			return 3
		"peaceful_protest":
			return 4

	return 1


func _get_user_test_signal_weight(card_signal: String) -> int:
	match card_signal:
		"peaceful_protest":
			return 120
		"exposed_truth":
			return 110
		"controlled_weapon":
			return 100
		"destroyed_weapon":
			return 90

	return 0


func _build_choice_search_text(data: Dictionary) -> String:
	var parts: Array[String] = [
		str(data.get("chosen", "")),
		str(data.get("raw_label", "")),
		str(data.get("connection_label", "")),
		str(data.get("target_element_title", "")),
		str(data.get("choice_id", ""))
	]

	var target_components: Array = data.get("target_components", [])
	for component in target_components:
		parts.append(str(component))

	var source_components: Array = data.get("source_components", [])
	for component in source_components:
		parts.append(str(component))

	var search_text := ""
	for part in parts:
		search_text += part + " "

	return search_text.to_lower()


func _get_key_moment_hint(searchable_text: String) -> String:
	if searchable_text.contains("weapon") or searchable_text.contains("superweapon"):
		if (
			searchable_text.contains("destroy")
			or searchable_text.contains("broken")
			or searchable_text.contains("remove")
		):
			return "destroyed_weapon"

		if (
			searchable_text.contains("control")
			or searchable_text.contains("held")
			or searchable_text.contains("negotiate")
			or searchable_text.contains("peace")
		):
			return "controlled_weapon"

	if (
		searchable_text.contains("truth")
		or searchable_text.contains("conspiracy")
		or searchable_text.contains("expose")
		or searchable_text.contains("exposed")
	):
		return "exposed_truth"

	if (
		searchable_text.contains("protest")
		or searchable_text.contains("march")
		or searchable_text.contains("peaceful")
	):
		return "peaceful_protest"

	return ""


func _get_user_test_version_reason(version: int, key_moment_hint: String) -> String:
	if key_moment_hint != "":
		match key_moment_hint:
			"destroyed_weapon":
				return "Matched key moment: destroyed or removed the weapon."
			"exposed_truth":
				return "Matched key moment: exposed truth or conspiracy."
			"controlled_weapon":
				return "Matched key moment: controlled the weapon to negotiate peace."
			"peaceful_protest":
				return "Matched key moment: protest or peaceful march."

	match version:
		1:
			return "Highest combined Liberty and Care pattern."
		2:
			return "Highest combined Fairness and Liberty pattern."
		3:
			return "Highest combined Fairness and Care pattern."
		_:
			return "Highest Care-led protector pattern."


func build_user_test_keepsake_data(version: int) -> Dictionary:
	var common_intro := [
		"As an enforcer in the war, your decisions shaped the world.",
		"After [Time] of difficult decisions, here's what your journey has revealed."
	]

	match clampi(version, 1, 4):
		1:
			return {
				"intro_lines": common_intro,
				"deck_title": "Share Your Revelation",
				"cards": [
					_make_user_test_card(
						"journey",
						"THE TRAIL YOU LEFT",
						"The Freedom Path",
						"No freedom can be overlooked under your watch.",
						[
							"4x Protected others' freedom of choice",
							"5x Showed compassion toward people in danger",
							"3x Chose equal and just treatment for others"
						],
						"",
						["From facing refugees to rebellion, your choices left a trail.", "This is the path you made."]
					),
					_make_user_test_card(
						"defining_moment",
						"KEY MOMENT",
						"The Broken Weapon",
						"You chose to remove the weapon that could decide the future from everyone's hands.",
						["Destroyed the weapon.", "Protected freedom."],
						"46% of players who reached this weapon choice destroyed it.",
						["Your journey was shaped by many choices,", "but one moment reflected them most clearly."]
					),
					_make_user_test_card(
						"archetype",
						"CHOICE SIGN",
						"The Compassionate Liberator",
						"By Disrupting Structures",
						[
							"Free Will! Protects freedom no matter the challenges.",
							"I Care! Taking care of people is your way.",
							"Challenge Power! Challenges systems when they stand in the way."
						],
						"32% of players share this sign. You're a little special.",
						["When your choices align,", "they reveal the pattern within you."]
					)
				]
			}
		2:
			return {
				"intro_lines": common_intro,
				"deck_title": "Share Your Revelation",
				"cards": [
					_make_user_test_card(
						"journey",
						"THE TRAIL YOU LEFT",
						"The Right Path",
						"Fairness is what keeps you going.",
						[
							"5x Chose equal and just treatment for others",
							"3x Protected others' freedom of choice",
							"4x Showed compassion toward people in danger"
						],
						"",
						["Across secrets, systems, and public truth, your choices left a trail.", "This is the path you made."]
					),
					_make_user_test_card(
						"defining_moment",
						"KEY MOMENT",
						"The Exposed Truth",
						"You chose to help your partner bring the truth for justice.",
						["Helped expose the conspiracy.", "Challenged the system."],
						"63% of players who reached the protest kept it peaceful.",
						["Your journey was shaped by many choices,", "but one moment reflected them most clearly."]
					),
					_make_user_test_card(
						"archetype",
						"CHOICE SIGN",
						"The Free-Spirited Advocate",
						"By Disrupting Structures",
						[
							"Equality! Defends equal and just treatment for a better society.",
							"Free Will! Protects freedom no matter the challenges.",
							"Challenge Power! Challenges systems when they stand in the way."
						],
						"27% of players share this sign. You're a little special.",
						["When your choices align,", "they reveal the pattern within you."]
					)
				]
			}
		3:
			return {
				"intro_lines": common_intro,
				"deck_title": "Share Your Revelation",
				"cards": [
					_make_user_test_card(
						"journey",
						"THE TRAIL YOU LEFT",
						"The Justice Path",
						"Your empathy always guided you toward justice.",
						[
							"5x Chose equal and just treatment for others",
							"4x Showed compassion toward people in danger",
							"2x Protected others' freedom of choice"
						],
						"",
						["From hidden refugees to people in the streets, your choices left a trail.", "This is the path you made."]
					),
					_make_user_test_card(
						"defining_moment",
						"KEY MOMENT",
						"The Held Weapon",
						"When the weapon could decide the future, you kept control of it to negotiate peace.",
						["Controlled the weapon.", "Negotiated peace."],
						"37% of players who reached this weapon choice controlled it.",
						["Your journey was shaped by many choices,", "but one moment reflected them most clearly."]
					),
					_make_user_test_card(
						"archetype",
						"CHOICE SIGN",
						"The Compassionate Advocate",
						"By Disrupting Structures",
						[
							"Equality! Defends equal and just treatment for a better society.",
							"I Care! Taking care of people is your way.",
							"Challenge Power! Challenges systems when they stand in the way."
						],
						"22% of players share this sign. You're a little special.",
						["When your choices align,", "they reveal the pattern within you."]
					)
				]
			}
		_:
			return {
				"intro_lines": common_intro,
				"deck_title": "Share Your Revelation",
				"cards": [
					_make_user_test_card(
						"journey",
						"THE TRAIL YOU LEFT",
						"The Protector's Path",
						"Whenever people were caught between procedure and danger, your compassionate instinct guided your path.",
						[
							"6x Showed compassion toward people in danger",
							"3x Chose equal and just treatment over convenient authority",
							"3x Protected others' freedom of choice"
						],
						"",
						["Between orders and people in danger, your choices left a trail.", "This is the path you made."]
					),
					_make_user_test_card(
						"defining_moment",
						"KEY MOMENT",
						"The People's March",
						"Even under threat, you still believed in change without turning to violence.",
						["Led the protest.", "Kept it peaceful."],
						"63% of players who reached the protest kept it peaceful.",
						["Your journey was shaped by many choices,", "but one moment reflected them most clearly."]
					),
					_make_user_test_card(
						"archetype",
						"CHOICE SIGN",
						"The Justice Protector",
						"By Disrupting Structures",
						[
							"I Care! Taking care of people is your way.",
							"Equality! Defends equal and just treatment for a better society.",
							"Challenge Power! Challenges systems when they stand in the way."
						],
						"8% of players share this sign. You're rare.",
						["When your choices align,", "they reveal the pattern within you."]
					)
				]
			}


func _make_user_test_card(
	type: String,
	card_detail_tab: String,
	title: String,
	description: String,
	details: Array,
	dyk_bar_text: String,
	reveal_lines: Array
) -> Dictionary:
	return {
		"type": type,
		"card_detail_tab": card_detail_tab,
		"title": title,
		"description": description,
		"details": details,
		"dyk_bar_text": dyk_bar_text,
		"scratchable_dyk": "",
		"reveal_lines": reveal_lines,
		"reveal_title": reveal_lines[0] if not reveal_lines.is_empty() else "",
		"reveal_body": reveal_lines[1] if reveal_lines.size() > 1 else "",
		"border_image": null,
		"background_texture": null,
		"logo": null,
		"main_image": null,
		"icon_1": null,
		"icon_2": null
	}


func build_local_data_cards() -> Array:
	var variables := final_variables if not final_variables.is_empty() else build_variable_summary()
	if variables.is_empty() and event_buffer.is_empty():
		return []

	var highest_signal := _get_highest_numeric_signal(variables)
	var defining_moment_summary := _get_defining_moment_summary()
	var event_count := _count_events_named("moral_choice_made")

	var archetype_title := "The Reflective Player"
	var archetype_description := "Your session left a small but readable trail of choices."
	var archetype_traits := ["Observed Choices", "Short Session"]

	match highest_signal:
		"Empathy":
			archetype_title = "The Compassionate Responder"
			archetype_description = "Your strongest signal came from choices connected to care and emotional response."
			archetype_traits = ["Empathy-led", "Responsive"]
		"Principle":
			archetype_title = "The Principled Actor"
			archetype_description = "Your strongest signal came from choices connected to rules, duty, or consistency."
			archetype_traits = ["Principled", "Steady"]
		"Guilt":
			archetype_title = "The Burdened Witness"
			archetype_description = "Your strongest signal came from choices connected to consequence and emotional cost."
			archetype_traits = ["Consequence-aware", "Reflective"]
		"Heroism":
			archetype_title = "The Active Protector"
			archetype_description = "Your strongest signal came from choices connected to intervention and rescue."
			archetype_traits = ["Action-oriented", "Protective"]

	return [
		{
			"type": "defining_moment",
			"card_detail_tab": "DEFINING MOMENT",
			"title": "The Trolley Turned",
			"description": defining_moment_summary,
			"details": [
				"Choices tracked: " + str(event_count),
				"Variables captured: " + str(variables.size())
			],
			"dyk_bar_text": "Generated locally in Godot.",
			"scratchable_dyk": "",
			"reveal_title": "A Defining Moment",
			"reveal_body": "One branch of the story became the clearest trace of your playthrough.",
			"border_image": null,
			"background_texture": null,
			"logo": null,
			"main_image": null,
			"icon_1": null,
			"icon_2": null
		},
		{
			"type": "journey",
			"card_detail_tab": "THE TRAIL YOU LEFT",
			"title": "Signals in Motion",
			"description": "Your final variables show which narrative pressures appeared most strongly by the end.",
			"details": _top_variable_lines(variables),
			"dyk_bar_text": "Based only on this local session.",
			"scratchable_dyk": "",
			"reveal_title": "The Trail You Left",
			"reveal_body": "Even a short session leaves a pattern of actions, hesitation, and consequence.",
			"border_image": null,
			"background_texture": null,
			"logo": null,
			"main_image": null,
			"icon_1": null,
			"icon_2": null
		},
		{
			"type": "archetype",
			"card_detail_tab": "ARCHETYPE REVEAL",
			"title": archetype_title,
			"description": archetype_description,
			"details": archetype_traits,
			"dyk_bar_text": "Prototype reading · not a diagnosis.",
			"scratchable_dyk": "",
			"reveal_title": "An Archetype Emerges",
			"reveal_body": "The game reflects your choices back as a story pattern, not a fixed identity.",
			"border_image": null,
			"background_texture": null,
			"logo": null,
			"main_image": null,
			"icon_1": null,
			"icon_2": null
		}
	]


func build_default_keepsake_cards() -> Array:
	var result: Array = []

	if is_card_config_filled(card_1):
		result.append(card_config_to_dictionary(card_1))

	if is_card_config_filled(card_2):
		result.append(card_config_to_dictionary(card_2))

	if is_card_config_filled(card_3):
		result.append(card_config_to_dictionary(card_3))

	return result


func card_config_to_dictionary(card: KeepsakeCardConfig) -> Dictionary:
	return {
		"type": card.type,
		"title": card.title,
		"card_detail_tab": card.card_detail_tab,
		"description": card.description,
		"details": card.content_lines,
		"dyk_bar_text": card.dyk_bar_text,
		"scratchable_dyk": card.scratchable_dyk,
		"reveal_title": card.reveal_title,
		"reveal_body": card.reveal_body,
		"border_image": card.border_image,
		"background_texture": card.background_texture,
		"logo": card.logo,
		"main_image": card.main_image,
		"icon_1": card.icon_1,
		"icon_2": card.icon_2
	}


func build_prototype_fallback_cards() -> Array:
	return [
		{
			"type": "defining_moment",
			"card_detail_tab": "DEFINING MOMENT",
			"title": "Session Recorded",
			"description": "The game captured your local playthrough, but no AI card data was available.",
			"details": [
				"Local Godot telemetry active.",
				"Gemini unavailable or empty."
			],
			"dyk_bar_text": "Fallback card.",
			"scratchable_dyk": "",
			"reveal_title": "A Local Trace",
			"reveal_body": "Your choices were recorded inside Godot without using a server.",
			"border_image": null,
			"background_texture": null,
			"logo": null,
			"main_image": null,
			"icon_1": null,
			"icon_2": null
		},
		{
			"type": "journey",
			"card_detail_tab": "THE TRAIL YOU LEFT",
			"title": "Local Journey",
			"description": "Your session data stayed inside the Godot client for this MVP.",
			"details": [
				"Events: " + str(event_buffer.size()),
				"Variables: " + str(final_variables.size())
			],
			"dyk_bar_text": "No backend required.",
			"scratchable_dyk": "",
			"reveal_title": "The Trail You Left",
			"reveal_body": "A local telemetry trail was enough to produce a prototype keepsake.",
			"border_image": null,
			"background_texture": null,
			"logo": null,
			"main_image": null,
			"icon_1": null,
			"icon_2": null
		},
		{
			"type": "archetype",
			"card_detail_tab": "ARCHETYPE REVEAL",
			"title": "The Reflective Player",
			"description": "This placeholder appears when the AI card generation cannot complete.",
			"details": [
				"Prototype-safe",
				"Not diagnostic"
			],
			"dyk_bar_text": "Try again with a valid Gemini key.",
			"scratchable_dyk": "",
			"reveal_title": "An Archetype Emerges",
			"reveal_body": "The final production version should protect the AI key behind a backend.",
			"border_image": null,
			"background_texture": null,
			"logo": null,
			"main_image": null,
			"icon_1": null,
			"icon_2": null
		}
	]


func show_keepsake_overlay(final_data: Dictionary) -> void:
	var overlay_scene = preload("res://addons/telemetry_engine/keepsake_overlay.tscn")
	var overlay = overlay_scene.instantiate()
	get_tree().root.add_child(overlay)

	overlay.load_keepsake_data(final_data)


func format_session_duration(seconds: float) -> String:
	var total_seconds := int(max(0.0, seconds))
	if total_seconds < 60:
		return "under a minute"

	var total_minutes := int(round(float(total_seconds) / 60.0))
	if total_minutes == 1:
		return "1 minute"

	return str(total_minutes) + " minutes"


func _format_unix_timestamp(unix_timestamp: Variant) -> String:
	var numeric_time := int(float(unix_timestamp))
	if numeric_time <= 0:
		return ""

	return Time.get_datetime_string_from_unix_time(numeric_time)


func is_card_config_filled(card: KeepsakeCardConfig) -> bool:
	if card == null:
		return false

	return (
		card.title.strip_edges() != ""
		or card.card_detail_tab.strip_edges() != ""
		or card.description.strip_edges() != ""
		or not card.content_lines.is_empty()
		or card.main_image != null
		or card.logo != null
		or card.icon_1 != null
		or card.icon_2 != null
		or card.dyk_bar_text.strip_edges() != ""
	)


func _extract_tags(raw_label: String) -> Array:
	var tags: Array = []
	var regex := RegEx.new()
	var error := regex.compile("tags\\s*=\\s*([A-Za-z0-9_, -]+)")

	if error != OK:
		return tags

	var result := regex.search(raw_label)
	if result == null:
		return tags

	var tag_string := result.get_string(1)
	for tag in tag_string.split(","):
		var cleaned := tag.strip_edges()
		if cleaned != "":
			tags.append(cleaned)

	return tags

const MORAL_TAG_COMPONENTS := [
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


func _filter_moral_tags(component_names: Array) -> Array:
	var tags: Array = []

	for component_name in component_names:
		var clean_name := str(component_name)

		if MORAL_TAG_COMPONENTS.has(clean_name) and not tags.has(clean_name):
			tags.append(clean_name)

	return tags


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


func _get_shared_tags(first: Array, second: Array) -> Array:
	var shared: Array = []

	for item in first:
		if second.has(item) and not shared.has(item):
			shared.append(item)

	return shared


func _without_tags(source: Array, tags_to_remove: Array) -> Array:
	var result: Array = []

	for item in source:
		if not tags_to_remove.has(item):
			result.append(item)

	return result


func _build_tension_pairs(chosen_tags: Array, opposing_tags: Array) -> Array:
	var pairs: Array = []

	for chosen_tag in chosen_tags:
		for opposing_tag in opposing_tags:
			if chosen_tag == opposing_tag:
				continue

			pairs.append({
				"chosen": chosen_tag,
				"opposed": opposing_tag
			})

	return pairs


func _extract_decision_weight(component_names: Array) -> int:
	if component_names.has("Weight_2"):
		return 2

	if component_names.has("Weight_1"):
		return 1

	return 1

func _clean_choice_label(raw_label: String) -> String:
	var text := raw_label

	var tag_regex := RegEx.new()
	if tag_regex.compile("tags\\s*=\\s*([A-Za-z0-9_, -]+)") == OK:
		text = tag_regex.sub(text, "", true)

	var code_regex := RegEx.new()
	if code_regex.compile("<pre><code>.*?</code></pre>") == OK:
		text = code_regex.sub(text, "", true)

	var html_regex := RegEx.new()
	if html_regex.compile("<[^>]+>") == OK:
		text = html_regex.sub(text, "", true)

	text = text.replace("\n", " ").replace("\t", " ")
	text = text.strip_edges()

	if text == "":
		return "Continue"

	return text

func _get_highest_numeric_signal(variables: Dictionary) -> String:
	var best_key := ""
	var best_value := -INF

	for key in variables.keys():
		var value: Variant = variables[key]
		var number := 0.0
		var is_number := false

		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			number = float(value)
			is_number = true
		elif typeof(value) == TYPE_BOOL:
			number = 1.0 if value else 0.0
			is_number = true

		if is_number and number > best_value:
			best_value = number
			best_key = str(key)

	return best_key


func _top_variable_lines(variables: Dictionary) -> Array:
	var numeric_pairs: Array = []

	for key in variables.keys():
		var value: Variant = variables[key]
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			numeric_pairs.append({"key": str(key), "value": float(value)})
		elif typeof(value) == TYPE_BOOL:
			numeric_pairs.append({"key": str(key), "value": 1.0 if value else 0.0})

	numeric_pairs.sort_custom(func(a, b): return a["value"] > b["value"])

	var lines: Array = []
	for item in numeric_pairs:
		lines.append(str(item["key"]) + ": " + str(item["value"]))
		if lines.size() >= 2:
			break

	while lines.size() < 2:
		lines.append("Session data captured")

	return lines


func _get_defining_moment_summary() -> String:
	var key_moments := build_key_moment_log()
	if not key_moments.is_empty():
		var first_key_moment: Dictionary = key_moments[0]
		var choice := str(first_key_moment.get("choice", "")).strip_edges()
		if choice != "":
			return "One key moment stood out: " + choice

	var choice_count := _count_events_named("moral_choice_made")
	if choice_count > 0:
		return "Your playthrough left a clear trail across " + str(choice_count) + " moral choices."

	return "Your playthrough reached its final branch and left a trace in the session data."


func _count_events_named(event_name: String) -> int:
	var count := 0
	for event in event_buffer:
		if typeof(event) == TYPE_DICTIONARY and event.get("event_name", "") == event_name:
			count += 1
	return count


func _log(message: String) -> void:
	if debug_logs:
		print(message)
