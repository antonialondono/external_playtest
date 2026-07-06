#extends Node
#
#var http_request: HTTPRequest
#var endpoint: String = "https://fbe6-206-12-10-243.ngrok-free.app"
#var keepsake_data: Dictionary = {}
#
#
#func _ready():
	#endpoint = TelemetryEngine.base_url
	#
	#http_request = HTTPRequest.new()
	#add_child(http_request)
#
	#http_request.request_completed.connect(_on_request_completed)
#
	#print("Keepsake endpoint:", endpoint)
	#
	#
#func request_keepsake(session_payload):
	#var headers = [
		#"Content-Type: application/json"
	#]
#
	#var body = JSON.stringify(session_payload)
#
	#var error = http_request.request(
		#endpoint,
		#headers,
		#HTTPClient.METHOD_POST,
		#body
	#)
#
	#if error != OK:
		#print("Keepsake request failed to start: ", error)
#
#
#func _on_request_completed(_result, response_code, _headers, body):
	#if response_code != 200:
		#print("Keepsake request failed. Response code: ", response_code)
		#return
#
	#var response = JSON.parse_string(body.get_string_from_utf8())
#
	#if response:
		#keepsake_data = response
		#show_keepsake()
	#else:
		#print("Could not parse keepsake response.")
#
#
#func show_keepsake():
	#var final_data = TelemetryEngine.get_final_keepsake_data(keepsake_data)
#
	#var scene = load("res://scenes/keepsake_overlay.tscn").instantiate()
	#get_tree().root.add_child(scene)
#
	#scene.load_keepsake_data(final_data)
	#scene.start_cards()
