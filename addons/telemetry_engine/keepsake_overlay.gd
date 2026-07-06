extends Control

const BG_DARK := Color("#0A0A0A")
const BG_LIGHT := Color("#F5F2ED")
const GOLD := Color("#C9A84C")
const GOLD_DARK := Color("#8B6F2A")
const GOLD_LIGHT := Color("#DDBF66")
const CARD_SIZE := Vector2(396, 580)
const CARD_EXPORT_PADDING := 64
const DECK_EXPORT_PADDING := 48
const MINI_CARD_SIZE := Vector2(238, 348)
const MINI_CARD_GAP := 26
const DYK_SCRATCH_RECT := Rect2(48, 506, 300, 60)
const DYK_SCRATCH_LABEL_RECT := Rect2(48, 524, 300, 24)
const DYK_SCRATCH_OVERLAY_RECT := Rect2(48, 506, 300, 60)
const DYK_SCRATCH_TILE_SIZE := Vector2(16, 12)
const DYK_SCRATCH_BRUSH_RADIUS := 31.0
const DYK_SCRATCH_REVEAL_RATIO := 0.68
const PLAYTEST_ASSET_BASE := "res://addons/telemetry_engine/Keepsake/Assets/"
const PLAYTEST_ASSET_SETS := {
	"journey": {
		"background": "Path_6_Background_Back.png",
		"image": "Path_4_Image.png",
		"front": "Path_5_Background_Front.png",
		"body": "Path_3_Body.png",
		"icons": "Path_2_Icons.png",
		"logo": "Path_1_Logo.png"
	},
	"defining_moment": {
		"background": "Key_6_Background_Back.png",
		"image": "Key_4_Image.png",
		"front": "Key_5_Background_Front.png",
		"body": "Key_3_Body.png",
		"icons": "Key_2_Icons.png",
		"logo": "Key_1_Logo.png"
	},
	"archetype": {
		"background": "Card3_8_Background_Back.png",
		"image": "Card3_6_Image.png",
		"front": "Card3_7_Background_front.png",
		"body": "Card3_3_Body+DYK (Option).png",
		"icons": "Card3_2_ICONS.png",
		"logo": "Card3_1_Logo.png",
		"dyk": "Card3_5_Banner.png"
	}
}
const DEFAULT_INTRO_LINES: Array[String] = [
	"You spent [b][Time][/b] on this journey.",
	"Every choice left a [b]trail[/b].",
	"Here's what your journey revealed."
]

@onready var background: ColorRect = $Background

@onready var intro_container: CenterContainer = $IntroContainer
@onready var intro_label: RichTextLabel = $IntroContainer/IntroVBox/IntroLabel
@onready var open_button: Button = $IntroContainer/IntroVBox/OpenButton

@onready var reveal_container: CenterContainer = $RevealContainer
@onready var reveal_title: Label = $RevealContainer/RevealVBox/RevealTitle
@onready var reveal_body: Label = $RevealContainer/RevealVBox/RevealBody

@onready var card_container: Control = $CardContainer
@onready var card_panel: PanelContainer = $CardContainer/CardPanel

@onready var card_art_root: Control = $CardContainer/CardPanel/CardArtRoot

@onready var art_base_background: TextureRect = $CardContainer/CardPanel/CardArtRoot/BaseBackground
@onready var art_main_image: TextureRect = $CardContainer/CardPanel/CardArtRoot/MainImage
@onready var art_image_frame: TextureRect = $CardContainer/CardPanel/CardArtRoot/ImageFrame
@onready var art_title_frame: TextureRect = $CardContainer/CardPanel/CardArtRoot/TitleFrame
@onready var art_text_box: TextureRect = $CardContainer/CardPanel/CardArtRoot/TextBox
@onready var art_dyk_frame: TextureRect = $CardContainer/CardPanel/CardArtRoot/DYKFrame
@onready var art_logo_seal: TextureRect = $CardContainer/CardPanel/CardArtRoot/LogoSeal

@onready var art_card_detail_tab: Label = $CardContainer/CardPanel/CardArtRoot/CardDetailTab
@onready var art_card_title: Label = $CardContainer/CardPanel/CardArtRoot/CardTitle
@onready var art_card_description: Label = $CardContainer/CardPanel/CardArtRoot/CardDescription
@onready var art_detail_text_1: Label = $CardContainer/CardPanel/CardArtRoot/DetailText1
@onready var art_detail_text_2: Label = $CardContainer/CardPanel/CardArtRoot/DetailText2
@onready var art_dyk_bar_text: Label = $CardContainer/CardPanel/CardArtRoot/DYKBarText

@onready var progress_container: VBoxContainer = $ProgressContainer

@onready var deck_container: CenterContainer = $DeckContainer
@onready var deck_vbox: VBoxContainer = $DeckContainer/DeckVBox
@onready var deck_title: Label = $DeckContainer/DeckVBox/DeckTitle
@onready var cards_row: HBoxContainer = $DeckContainer/DeckVBox/CardsRow
@onready var share_button: Button = $DeckContainer/DeckVBox/ShareButton
@onready var replay_button: Button = $DeckContainer/DeckVBox/ReplayButton


var current_card := 0
var showing_reveal := false
var placeholder_textures := {}
var intro_tween: Tween
var reveal_tween: Tween
var card_entry_tween: Tween
var card_float_tween: Tween
var intro_step := 0
var intro_finished := false
var reveal_lines: Array[String] = []
var reveal_step := 0
var playtest_texture_cache := {}
var dyk_scratch_overlay: Control
var dyk_scratch_tiles: Array = []
var dyk_scratch_revealed_tiles := 0
var dyk_scratch_active := false
var continue_hint_label: Label
var continue_input_locked := false

var cards: Array = []
var intro_time_text := "some time"
var final_deck_title := "Your collection is ready."
var deck_button_spacer: Control
var intro_lines: Array[String] = [
	"You spent [b][Time][/b] on this journey.",
	"Every choice left a [b]trail[/b].",
	"Here's what your journey revealed."
]


func _ready() -> void:
	force_card_size()
	apply_card_style()
	apply_art_text_style()
	setup_continue_hint()
	apply_keepsake_ui_style()
	setup_initial_state()

	open_button.pressed.connect(start_cards)
	replay_button.pressed.connect(replay)
	share_button.pressed.connect(share_deck)

	progress_container.z_index = 20
	progress_container.add_theme_constant_override("separation", 9)


func apply_keepsake_ui_style() -> void:
	intro_label.custom_minimum_size = Vector2(720, 150)
	intro_label.add_theme_font_size_override("normal_font_size", 34)
	intro_label.add_theme_font_size_override("bold_font_size", 34)
	intro_label.add_theme_font_size_override("italics_font_size", 34)
	intro_label.add_theme_font_size_override("bold_italics_font_size", 34)

	open_button.text = "OPEN MY COLLECTION"
	open_button.custom_minimum_size = Vector2(320, 58)
	open_button.add_theme_font_size_override("font_size", 16)
	open_button.add_theme_color_override("font_color", BG_DARK)
	open_button.add_theme_color_override("font_hover_color", BG_DARK)
	open_button.add_theme_color_override("font_pressed_color", BG_DARK)
	open_button.add_theme_stylebox_override("normal", _make_gold_button_style(GOLD))
	open_button.add_theme_stylebox_override("hover", _make_gold_button_style(GOLD_LIGHT))
	open_button.add_theme_stylebox_override("pressed", _make_gold_button_style(GOLD_DARK))
	open_button.add_theme_stylebox_override("focus", _make_gold_button_style(GOLD))

	reveal_title.custom_minimum_size = Vector2(760, 96)
	reveal_body.custom_minimum_size = Vector2(760, 120)


func _make_gold_button_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = GOLD_DARK
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style


func setup_continue_hint() -> void:
	continue_hint_label = Label.new()
	continue_hint_label.name = "ContinueHintLabel"
	continue_hint_label.text = "scroll or tap to continue"
	continue_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_hint_label.z_index = 200
	continue_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_hint_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 0.78))
	continue_hint_label.add_theme_font_size_override("font_size", 14)
	add_child(continue_hint_label)
	_position_continue_hint()


func _position_continue_hint() -> void:
	if continue_hint_label == null or not is_instance_valid(continue_hint_label):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	continue_hint_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	continue_hint_label.position = Vector2(0, maxf(0.0, viewport_size.y - 72.0))
	continue_hint_label.size = Vector2(viewport_size.x, 24)
	continue_hint_label.custom_minimum_size = continue_hint_label.size


func update_continue_hint_visibility() -> void:
	if continue_hint_label == null or not is_instance_valid(continue_hint_label):
		return

	continue_hint_label.visible = (
		(intro_container.visible and not open_button.visible)
		or reveal_container.visible
		or card_container.visible
	)


func setup_initial_state() -> void:
	background.color = BG_DARK

	intro_container.visible = true
	reveal_container.visible = false
	card_container.visible = false
	deck_container.visible = false
	progress_container.visible = false

	intro_label.bbcode_enabled = true
	intro_label.text = ""
	intro_label.modulate.a = 0.0
	intro_label.scale = Vector2(0.94, 0.94)
	open_button.visible = false
	open_button.modulate.a = 0.0
	open_button.scale = Vector2(0.96, 0.96)
	intro_step = 0
	intro_finished = false

	intro_container.modulate.a = 1.0
	reveal_container.modulate.a = 1.0
	card_container.modulate.a = 1.0
	deck_container.modulate.a = 1.0
	card_panel.modulate.a = 1.0
	card_panel.scale = Vector2.ONE
	update_continue_hint_visibility()

	call_deferred("show_intro_line", 0)


func show_intro_line(index: int) -> void:
	if intro_tween != null and intro_tween.is_running():
		intro_tween.kill()

	if intro_lines.is_empty():
		_reset_intro_lines()

	intro_step = clampi(index, 0, intro_lines.size() - 1)
	var intro_text := intro_lines[intro_step].replace("[Time]", intro_time_text)
	intro_label.text = "[center]" + intro_text + "[/center]"
	intro_label.modulate.a = 0.0
	intro_label.scale = Vector2(0.94, 0.94)
	update_continue_hint_visibility()

	intro_tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.tween_property(intro_label, "modulate:a", 1.0, 1.2)
	intro_tween.tween_property(intro_label, "scale", Vector2.ONE, 1.2)


func advance_intro_line() -> void:
	if intro_finished:
		return

	if intro_tween != null and intro_tween.is_running():
		intro_tween.kill()
		intro_label.modulate.a = 1.0
		intro_label.scale = Vector2.ONE
		return

	if intro_step < intro_lines.size() - 1:
		show_intro_line(intro_step + 1)
		return

	intro_finished = true
	open_button.visible = true
	open_button.modulate.a = 0.0
	open_button.scale = Vector2(0.96, 0.96)
	update_continue_hint_visibility()

	intro_tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.tween_property(open_button, "modulate:a", 1.0, 1.0)
	intro_tween.tween_property(open_button, "scale", Vector2.ONE, 1.0)


func force_card_size() -> void:
	card_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	card_panel.custom_minimum_size = CARD_SIZE
	card_panel.size = CARD_SIZE
	card_panel.position = (get_viewport_rect().size - card_panel.size) / 2.0

	card_art_root.custom_minimum_size = CARD_SIZE
	card_art_root.size = CARD_SIZE
	apply_card_layout()

	progress_container.position = Vector2(24, (get_viewport_rect().size.y - 100) / 2.0)
	progress_container.custom_minimum_size = Vector2(20, 100)
	_position_continue_hint()


func apply_card_layout() -> void:
	_place_card_control(art_base_background, Rect2(Vector2.ZERO, CARD_SIZE))
	_place_card_control(art_main_image, Rect2(Vector2.ZERO, CARD_SIZE))
	_place_card_control(art_image_frame, Rect2(Vector2.ZERO, CARD_SIZE))
	_place_card_control(art_title_frame, Rect2(Vector2.ZERO, CARD_SIZE))
	_place_card_control(art_text_box, Rect2(Vector2.ZERO, CARD_SIZE))
	_place_card_control(art_dyk_frame, Rect2(Vector2.ZERO, CARD_SIZE))
	_place_card_control(art_logo_seal, Rect2(Vector2.ZERO, CARD_SIZE))

	for layer in [
		art_base_background,
		art_main_image,
		art_image_frame,
		art_title_frame,
		art_text_box,
		art_dyk_frame,
		art_logo_seal
	]:
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE

	_place_card_control(art_card_detail_tab, Rect2(92, 444, 248, 14))
	_place_card_control(art_card_title, Rect2(92, 458, 248, 30))
	_place_card_control(art_card_description, Rect2(92, 490, 248, 34))
	_place_card_control(art_detail_text_1, Rect2(92, 524, 248, 18))
	_place_card_control(art_detail_text_2, Rect2(92, 542, 248, 32))
	_place_card_control(art_dyk_bar_text, Rect2(48, 526, 300, 38))


func _place_card_control(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
	control.custom_minimum_size = rect.size


func _get_playtest_asset_set(data: Dictionary) -> Dictionary:
	var card_type := str(data.get("type", "journey"))
	if PLAYTEST_ASSET_SETS.has(card_type):
		return PLAYTEST_ASSET_SETS[card_type]

	return PLAYTEST_ASSET_SETS["defining_moment"]


func _load_playtest_texture(file_name: String) -> Texture2D:
	if file_name.strip_edges() == "":
		return null

	var path := PLAYTEST_ASSET_BASE + file_name
	if playtest_texture_cache.has(path):
		return playtest_texture_cache[path]

	var texture := load(path) as Texture2D
	playtest_texture_cache[path] = texture
	return texture


func _apply_playtest_card_assets(data: Dictionary) -> void:
	var assets := _get_playtest_asset_set(data)

	art_base_background.texture = _load_playtest_texture(str(assets.get("background", "")))
	art_main_image.texture = _load_playtest_texture(str(assets.get("front", "")))
	art_image_frame.texture = _load_playtest_texture(str(assets.get("image", "")))
	art_title_frame.texture = _load_playtest_texture(str(assets.get("body", "")))
	art_text_box.texture = _load_playtest_texture(str(assets.get("icons", "")))
	art_dyk_frame.texture = _load_playtest_texture(str(assets.get("dyk", assets.get("banner", ""))))
	art_logo_seal.texture = _load_playtest_texture(str(assets.get("logo", "")))

	art_title_frame.visible = art_title_frame.texture != null
	art_text_box.visible = art_text_box.texture != null
	art_dyk_frame.visible = art_dyk_frame.texture != null
	art_logo_seal.visible = art_logo_seal.texture != null


func _get_card_image_texture(data: Dictionary) -> Texture2D:
	var texture: Texture2D = data.get("main_image", null)
	if texture != null:
		return texture

	var card_type := str(data.get("type", "journey"))
	if placeholder_textures.has(card_type):
		return placeholder_textures[card_type]

	var top_color := Color("#202234")
	var bottom_color := Color("#17395F")
	var accent_color := Color("#D8B65A")
	var line_color := Color(1.0, 1.0, 1.0, 0.24)

	match card_type:
		"journey":
			top_color = Color("#112A17")
			bottom_color = Color("#123D23")
			accent_color = Color("#CFAF4D")
		"archetype":
			top_color = Color("#2B1835")
			bottom_color = Color("#15284B")
			accent_color = Color("#E0BE63")

	var width := 364
	var height := 228
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y in range(height):
		var t := float(y) / float(height - 1)
		var row_color := top_color.lerp(bottom_color, t)
		for x in range(width):
			var radial: float = 1.0 - clampf(Vector2(x - width * 0.5, y - height * 0.42).length() / 260.0, 0.0, 1.0)
			var pixel_color: Color = row_color.lerp(accent_color, radial * 0.13)
			image.set_pixel(x, y, pixel_color)

	_draw_placeholder_frame(image, line_color)
	_draw_placeholder_symbol(image, card_type, accent_color, line_color)

	var image_texture := ImageTexture.create_from_image(image)
	placeholder_textures[card_type] = image_texture
	return image_texture


func _draw_placeholder_frame(image: Image, color: Color) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var margin := 18

	for x in range(margin, width - margin):
		_set_placeholder_pixel(image, x, margin, color)
		_set_placeholder_pixel(image, x, height - margin - 1, color)

	for y in range(margin, height - margin):
		_set_placeholder_pixel(image, margin, y, color)
		_set_placeholder_pixel(image, width - margin - 1, y, color)

	for offset in range(-140, 141, 28):
		_draw_placeholder_line(image, Vector2i(offset, height - margin), Vector2i(offset + height, margin), Color(1.0, 1.0, 1.0, 0.055))


func _draw_placeholder_symbol(image: Image, card_type: String, accent_color: Color, line_color: Color) -> void:
	var center := Vector2i(int(image.get_width() / 2), int(image.get_height() / 2))

	match card_type:
		"journey":
			_draw_placeholder_line(image, center + Vector2i(-54, 20), center + Vector2i(-18, -22), accent_color)
			_draw_placeholder_line(image, center + Vector2i(-18, -22), center + Vector2i(18, 20), accent_color)
			_draw_placeholder_line(image, center + Vector2i(18, 20), center + Vector2i(54, -18), accent_color)
			_draw_placeholder_circle(image, center + Vector2i(-54, 20), 7, line_color)
			_draw_placeholder_circle(image, center + Vector2i(-18, -22), 7, line_color)
			_draw_placeholder_circle(image, center + Vector2i(18, 20), 7, line_color)
			_draw_placeholder_circle(image, center + Vector2i(54, -18), 7, line_color)
		"archetype":
			_draw_placeholder_diamond(image, center, 52, accent_color)
			_draw_placeholder_diamond(image, center, 28, line_color)
		_:
			_draw_placeholder_circle(image, center, 44, accent_color)
			_draw_placeholder_line(image, center + Vector2i(-30, 0), center + Vector2i(30, 0), line_color)
			_draw_placeholder_line(image, center + Vector2i(0, -30), center + Vector2i(0, 30), line_color)


func _draw_placeholder_line(image: Image, from_point: Vector2i, to_point: Vector2i, color: Color) -> void:
	var delta := to_point - from_point
	var steps := int(max(abs(delta.x), abs(delta.y)))
	if steps <= 0:
		return

	for index in range(steps + 1):
		var t := float(index) / float(steps)
		var point := Vector2i(
			int(round(lerpf(float(from_point.x), float(to_point.x), t))),
			int(round(lerpf(float(from_point.y), float(to_point.y), t)))
		)
		_set_placeholder_pixel(image, point.x, point.y, color)
		_set_placeholder_pixel(image, point.x + 1, point.y, color)


func _draw_placeholder_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for angle_index in range(96):
		var angle := TAU * float(angle_index) / 96.0
		var point := center + Vector2i(int(round(cos(angle) * radius)), int(round(sin(angle) * radius)))
		_set_placeholder_pixel(image, point.x, point.y, color)
		_set_placeholder_pixel(image, point.x + 1, point.y, color)


func _draw_placeholder_diamond(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var top := center + Vector2i(0, -radius)
	var right := center + Vector2i(radius, 0)
	var bottom := center + Vector2i(0, radius)
	var left := center + Vector2i(-radius, 0)

	_draw_placeholder_line(image, top, right, color)
	_draw_placeholder_line(image, right, bottom, color)
	_draw_placeholder_line(image, bottom, left, color)
	_draw_placeholder_line(image, left, top, color)


func _set_placeholder_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return

	var current := image.get_pixel(x, y)
	image.set_pixel(x, y, current.lerp(color, color.a))


func _get_reveal_copy(card: Dictionary) -> Array[String]:
	var custom_reveal_lines = card.get("reveal_lines", [])
	if typeof(custom_reveal_lines) == TYPE_ARRAY and not custom_reveal_lines.is_empty():
		var result: Array[String] = []
		for line in custom_reveal_lines:
			result.append(str(line))
		return result

	match str(card.get("type", "")):
		"journey":
			return [
				"Your choices left a trail.",
				"This was your path."
			]
		"archetype":
			return [
				"When stars align, they show a sign.",
				"When your choices align,",
				"they reveal patterns within you."
			]
		_:
			return [
				"Your journey was shaped by many choices,",
				"but one moment stood out as a reflection of your character."
			]


func apply_card_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)

	card_panel.add_theme_stylebox_override("panel", style)


func apply_normal_card_style() -> void:
	apply_card_style()


func apply_archetype_card_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0.79, 0.66, 0.29, 0.35)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 10)

	card_panel.add_theme_stylebox_override("panel", style)


func apply_art_text_style() -> void:
	art_card_detail_tab.add_theme_color_override("font_color", Color("#B58A2A"))
	art_card_detail_tab.add_theme_font_size_override("font_size", 9)
	art_card_detail_tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_card_detail_tab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_card_detail_tab.clip_text = true

	art_card_title.add_theme_color_override("font_color", Color("#2A1A3D"))
	art_card_title.add_theme_font_size_override("font_size", 17)
	art_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	art_card_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_card_title.clip_text = true

	art_card_description.add_theme_color_override("font_color", Color("#8A8680"))
	art_card_description.add_theme_font_size_override("font_size", 10)
	art_card_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	art_card_description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	art_card_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_card_description.clip_text = true

	art_detail_text_1.add_theme_color_override("font_color", Color("#1A1A1A"))
	art_detail_text_2.add_theme_color_override("font_color", Color("#1A1A1A"))
	art_detail_text_1.add_theme_font_size_override("font_size", 9)
	art_detail_text_2.add_theme_font_size_override("font_size", 9)
	art_detail_text_1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_detail_text_2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_detail_text_1.clip_text = true
	art_detail_text_2.clip_text = true

	art_dyk_bar_text.add_theme_color_override("font_color", Color("#0A0A0A"))
	art_dyk_bar_text.add_theme_font_size_override("font_size", 8)
	art_dyk_bar_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_dyk_bar_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_dyk_bar_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_dyk_bar_text.clip_text = true


func _apply_playtest_card_text(data: Dictionary) -> void:
	var card_type := str(data.get("type", ""))
	var playtest_text := _get_playtest_text_bundle(data)

	art_card_detail_tab.text = str(playtest_text.get("heading", ""))
	art_card_title.text = str(playtest_text.get("row_1", ""))
	art_card_description.text = str(playtest_text.get("row_2", ""))
	art_detail_text_1.text = str(playtest_text.get("row_3", ""))
	art_detail_text_2.text = ""

	if card_type == "archetype":
		art_dyk_bar_text.text = str(playtest_text.get("dyk", ""))
	else:
		art_dyk_bar_text.text = ""


func _get_playtest_text_bundle(data: Dictionary) -> Dictionary:
	var details := _get_clean_detail_lines(data)
	var card_type := str(data.get("type", ""))
	var dyk_text := ""
	if card_type == "archetype":
		dyk_text = _format_archetype_dyk(str(data.get("dyk_bar_text", "")))

	return {
		"heading": _get_playtest_heading(data),
		"row_1": _get_line_or_empty(details, 0),
		"row_2": _get_line_or_empty(details, 1),
		"row_3": _get_line_or_empty(details, 2),
		"dyk": dyk_text
	}


func _get_heading_color(data: Dictionary) -> Color:
	if str(data.get("type", "")) == "archetype":
		return Color("#6A4AA0")

	return Color("#F5F2ED")


func _get_heading_font_size(data: Dictionary, mini: bool = false) -> int:
	var heading := _get_playtest_heading(data)
	var is_archetype := str(data.get("type", "")) == "archetype"
	if not is_archetype:
		return 9 if mini else 20

	if heading.length() >= 23:
		return 6 if mini else 15
	if heading.length() >= 18:
		return 7 if mini else 16

	return 8 if mini else 18


func _get_playtest_heading(data: Dictionary) -> String:
	var card_type := str(data.get("type", ""))
	if card_type == "journey":
		return _clean_card_heading(str(data.get("card_detail_tab", "THE TRAIL YOU LEFT")), false)
	if card_type == "archetype":
		return _clean_card_heading(str(data.get("title", "CHOICE SIGN")), true)

	return _clean_card_heading(str(data.get("title", "KEY MOMENT")), false)


func _clean_card_heading(raw_heading: String, strip_leading_the: bool) -> String:
	var heading := raw_heading.strip_edges()
	if strip_leading_the and heading.begins_with("The "):
		heading = heading.substr(4)
	return heading.to_upper()


func _get_line_or_empty(lines: Array[String], index: int) -> String:
	if index < 0 or index >= lines.size():
		return ""

	return lines[index]


func _get_clean_detail_lines(data: Dictionary) -> Array[String]:
	var details: Array = data.get("details", [])
	if details.is_empty() and data.has("content"):
		details = [str(data["content"])]

	var lines: Array[String] = []
	for detail in details:
		var line := _clean_detail_line(str(detail))
		if line != "":
			lines.append(line)

	return lines


func _clean_detail_line(raw_line: String) -> String:
	var line := raw_line.strip_edges()
	line = line.replace("\\!", "!")
	line = _strip_detail_icon_prefix(line)
	while line.find("  ") != -1:
		line = line.replace("  ", " ")
	return line


func _strip_detail_icon_prefix(line: String) -> String:
	var cleaned := line
	while cleaned.length() > 0:
		var first := cleaned.unicode_at(0)
		var keep_character := (
			(first >= 48 and first <= 57)
			or (first >= 65 and first <= 90)
			or (first >= 97 and first <= 122)
		)
		if keep_character:
			break
		cleaned = cleaned.substr(1).strip_edges()

	return cleaned


func _format_archetype_dyk(text: String) -> String:
	var cleaned := text.strip_edges()
	if cleaned == "":
		return ""

	return cleaned


func apply_playtest_text_layout(data: Dictionary) -> void:
	var card_type := str(data.get("type", ""))

	art_card_detail_tab.visible = true
	art_card_title.visible = true
	art_card_description.visible = true
	art_detail_text_1.visible = art_detail_text_1.text.strip_edges() != ""
	art_detail_text_2.visible = false
	art_dyk_bar_text.visible = card_type == "archetype" and art_dyk_bar_text.text.strip_edges() != ""

	if card_type == "archetype":
		_place_card_control(art_card_detail_tab, Rect2(108, 37, 252, 38))
		_place_card_control(art_card_title, Rect2(112, 396, 236, 28))
		_place_card_control(art_card_description, Rect2(112, 428, 236, 28))
		_place_card_control(art_detail_text_1, Rect2(112, 460, 236, 28))
		_place_card_control(art_detail_text_2, Rect2(0, 0, 1, 1))
		_place_card_control(art_dyk_bar_text, Rect2(60, 518, 276, 38))
		art_card_detail_tab.add_theme_font_size_override("font_size", _get_heading_font_size(data))
		art_card_detail_tab.add_theme_color_override("font_color", Color("#6A4AA0"))
		art_card_detail_tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		art_card_title.add_theme_font_size_override("font_size", 12)
		art_card_description.add_theme_font_size_override("font_size", 12)
		art_detail_text_1.add_theme_font_size_override("font_size", 12)
		art_detail_text_2.add_theme_font_size_override("font_size", 1)
		art_dyk_bar_text.add_theme_font_size_override("font_size", 12)
	elif card_type == "defining_moment":
		_place_card_control(art_card_detail_tab, Rect2(116, 34, 244, 36))
		_place_card_control(art_card_title, Rect2(116, 474, 232, 28))
		_place_card_control(art_card_description, Rect2(116, 512, 232, 28))
		_place_card_control(art_detail_text_1, Rect2(0, 0, 1, 1))
		_place_card_control(art_detail_text_2, Rect2(0, 0, 1, 1))
		_place_card_control(art_dyk_bar_text, Rect2(0, 0, 1, 1))
		art_card_detail_tab.add_theme_font_size_override("font_size", 20)
		art_card_detail_tab.add_theme_color_override("font_color", Color("#F5F2ED"))
		art_card_detail_tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		art_card_title.add_theme_font_size_override("font_size", 12)
		art_card_description.add_theme_font_size_override("font_size", 12)
		art_detail_text_1.add_theme_font_size_override("font_size", 1)
		art_detail_text_2.add_theme_font_size_override("font_size", 1)
		art_dyk_bar_text.add_theme_font_size_override("font_size", 1)
	else:
		_place_card_control(art_card_detail_tab, Rect2(116, 34, 244, 36))
		_place_card_control(art_card_title, Rect2(104, 451, 244, 28))
		_place_card_control(art_card_description, Rect2(104, 483, 244, 28))
		_place_card_control(art_detail_text_1, Rect2(104, 516, 244, 28))
		_place_card_control(art_detail_text_2, Rect2(0, 0, 1, 1))
		_place_card_control(art_dyk_bar_text, Rect2(0, 0, 1, 1))
		art_card_detail_tab.add_theme_font_size_override("font_size", 20)
		art_card_detail_tab.add_theme_color_override("font_color", Color("#F5F2ED"))
		art_card_detail_tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		art_card_title.add_theme_font_size_override("font_size", 12)
		art_card_description.add_theme_font_size_override("font_size", 12)
		art_detail_text_1.add_theme_font_size_override("font_size", 12)
		art_detail_text_2.add_theme_font_size_override("font_size", 1)
		art_dyk_bar_text.add_theme_font_size_override("font_size", 1)

	art_card_title.add_theme_color_override("font_color", Color("#29252B"))
	art_card_description.add_theme_color_override("font_color", Color("#29252B"))
	art_detail_text_1.add_theme_color_override("font_color", Color("#29252B"))
	art_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	art_card_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	art_detail_text_1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	art_card_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_card_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_detail_text_1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _setup_dyk_scratch_overlay(data: Dictionary) -> void:
	_clear_dyk_scratch_overlay()

	if str(data.get("type", "")) != "archetype":
		return
	if art_dyk_bar_text.text.strip_edges() == "":
		return

	dyk_scratch_overlay = Control.new()
	dyk_scratch_overlay.name = "DYKScratchOverlay"
	dyk_scratch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dyk_scratch_overlay.z_index = 80
	_place_card_control(dyk_scratch_overlay, DYK_SCRATCH_OVERLAY_RECT)
	card_art_root.add_child(dyk_scratch_overlay)

	var scratch_label := RichTextLabel.new()
	scratch_label.bbcode_enabled = true
	scratch_label.text = "[center][b]SCRATCH![/b][/center]"
	scratch_label.fit_content = true
	scratch_label.scroll_active = false
	scratch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scratch_label.z_index = 10
	scratch_label.add_theme_color_override("default_color", Color("#8B6F2A"))
	scratch_label.add_theme_font_size_override("normal_font_size", 16)
	scratch_label.add_theme_font_size_override("bold_font_size", 16)
	_place_card_control(
		scratch_label,
		Rect2(
			DYK_SCRATCH_LABEL_RECT.position - dyk_scratch_overlay.position,
			DYK_SCRATCH_LABEL_RECT.size
		)
	)
	dyk_scratch_overlay.add_child(scratch_label)

	dyk_scratch_tiles.clear()
	dyk_scratch_revealed_tiles = 0
	dyk_scratch_active = false

	var columns := int(ceil(DYK_SCRATCH_RECT.size.x / DYK_SCRATCH_TILE_SIZE.x))
	var rows := int(ceil(DYK_SCRATCH_RECT.size.y / DYK_SCRATCH_TILE_SIZE.y))
	for row in range(rows):
		for column in range(columns):
			var tile := ColorRect.new()
			var tile_position: Vector2 = DYK_SCRATCH_RECT.position - dyk_scratch_overlay.position + Vector2(
				column * DYK_SCRATCH_TILE_SIZE.x,
				row * DYK_SCRATCH_TILE_SIZE.y
			)
			var tile_size: Vector2 = Vector2(
				minf(DYK_SCRATCH_TILE_SIZE.x, DYK_SCRATCH_RECT.size.x - column * DYK_SCRATCH_TILE_SIZE.x),
				minf(DYK_SCRATCH_TILE_SIZE.y, DYK_SCRATCH_RECT.size.y - row * DYK_SCRATCH_TILE_SIZE.y)
			)
			tile.color = GOLD_LIGHT
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_place_card_control(tile, Rect2(tile_position, tile_size))
			dyk_scratch_overlay.add_child(tile)
			dyk_scratch_tiles.append(tile)

	scratch_label.move_to_front()


func _clear_dyk_scratch_overlay() -> void:
	dyk_scratch_active = false
	dyk_scratch_tiles.clear()
	dyk_scratch_revealed_tiles = 0

	if dyk_scratch_overlay != null and is_instance_valid(dyk_scratch_overlay):
		dyk_scratch_overlay.queue_free()

	dyk_scratch_overlay = null


func _handle_dyk_scratch_input(event: InputEvent) -> bool:
	if dyk_scratch_overlay == null or not is_instance_valid(dyk_scratch_overlay):
		return false
	if not dyk_scratch_overlay.visible:
		return false
	if not card_container.visible:
		return false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_position := _event_position_to_card_local(event.position)
		var over_scratch := DYK_SCRATCH_RECT.has_point(mouse_position)
		if event.pressed and over_scratch:
			dyk_scratch_active = true
			_scratch_dyk_at(mouse_position)
			return true
		if not event.pressed and dyk_scratch_active:
			dyk_scratch_active = false
			return true

	if event is InputEventMouseMotion and dyk_scratch_active:
		_scratch_dyk_at(_event_position_to_card_local(event.position))
		return true

	if event is InputEventScreenTouch:
		var touch_position := _event_position_to_card_local(event.position)
		var over_touch_scratch := DYK_SCRATCH_RECT.has_point(touch_position)
		if event.pressed and over_touch_scratch:
			dyk_scratch_active = true
			_scratch_dyk_at(touch_position)
			return true
		if not event.pressed and dyk_scratch_active:
			dyk_scratch_active = false
			return true

	if event is InputEventScreenDrag and dyk_scratch_active:
		_scratch_dyk_at(_event_position_to_card_local(event.position))
		return true

	return false


func _event_position_to_card_local(position: Vector2) -> Vector2:
	return card_art_root.get_global_transform_with_canvas().affine_inverse() * position


func _scratch_dyk_at(card_position: Vector2) -> void:
	if dyk_scratch_overlay == null or not is_instance_valid(dyk_scratch_overlay):
		return

	var scratch_position: Vector2 = card_position - dyk_scratch_overlay.position
	var brush_radius_squared: float = DYK_SCRATCH_BRUSH_RADIUS * DYK_SCRATCH_BRUSH_RADIUS

	for tile_node in dyk_scratch_tiles:
		var tile := tile_node as Control
		if tile == null:
			continue
		if not is_instance_valid(tile) or not tile.visible:
			continue

		var tile_center: Vector2 = tile.position + tile.size * 0.5
		if tile_center.distance_squared_to(scratch_position) <= brush_radius_squared:
			tile.visible = false
			dyk_scratch_revealed_tiles += 1

	if dyk_scratch_tiles.size() > 0:
		var revealed_ratio: float = float(dyk_scratch_revealed_tiles) / float(dyk_scratch_tiles.size())
		if revealed_ratio >= DYK_SCRATCH_REVEAL_RATIO:
			dyk_scratch_overlay.visible = false
			dyk_scratch_active = false


func start_cards() -> void:
	current_card = 0

	if intro_tween != null and intro_tween.is_running():
		intro_tween.kill()

	intro_container.visible = false
	card_container.visible = false
	reveal_container.visible = false
	deck_container.visible = false
	progress_container.visible = true
	progress_container.move_to_front()

	background.color = BG_LIGHT

	card_container.modulate.a = 1.0
	reveal_container.modulate.a = 1.0
	update_continue_hint_visibility()

	if cards.is_empty():
		show_empty_deck()
		return

	show_reveal(current_card)


func show_card(index: int) -> void:
	if cards.is_empty():
		show_empty_deck()
		return

	_clear_dyk_scratch_overlay()

	index = clamp(index, 0, cards.size() - 1)
	current_card = index

	var data: Dictionary = cards[index]

	if data.get("type", "") == "archetype":
		apply_archetype_card_style()
	else:
		apply_normal_card_style()

	card_art_root.visible = true

	_apply_playtest_card_assets(data)

	_apply_playtest_card_text(data)

	force_card_size()
	apply_art_text_style()
	apply_playtest_text_layout(data)
	_setup_dyk_scratch_overlay(data)
	update_progress()
	update_continue_hint_visibility()
	animate_card_in()


func _get_card_center_position() -> Vector2:
	return (get_viewport_rect().size - card_panel.size) / 2.0


func _stop_card_motion() -> void:
	if card_entry_tween != null and card_entry_tween.is_running():
		card_entry_tween.kill()
	if card_float_tween != null and card_float_tween.is_running():
		card_float_tween.kill()


func _start_card_float() -> void:
	if not card_container.visible:
		return

	if card_float_tween != null and card_float_tween.is_running():
		card_float_tween.kill()

	var center_position := _get_card_center_position()
	card_panel.position = center_position
	card_float_tween = create_tween()
	card_float_tween.set_loops()
	card_float_tween.set_trans(Tween.TRANS_SINE)
	card_float_tween.set_ease(Tween.EASE_IN_OUT)
	card_float_tween.tween_property(card_panel, "position", center_position + Vector2(0, -7), 1.75)
	card_float_tween.tween_property(card_panel, "position", center_position, 1.75)


func show_reveal(index: int) -> void:
	if cards.is_empty():
		show_empty_deck()
		return

	_stop_card_motion()
	index = clamp(index, 0, cards.size() - 1)
	current_card = index
	showing_reveal = true

	background.color = BG_LIGHT
	reveal_container.visible = true
	card_container.visible = false
	update_continue_hint_visibility()

	var card: Dictionary = cards[index]
	reveal_lines = _get_reveal_copy(card)
	reveal_step = 0

	reveal_title.text = ""
	reveal_body.text = ""

	reveal_title.add_theme_color_override("font_color", Color("#0A0A0A"))
	reveal_body.add_theme_color_override("font_color", Color("#0A0A0A"))
	reveal_title.add_theme_font_size_override("font_size", 36)
	reveal_body.add_theme_font_size_override("font_size", 24)
	reveal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	reveal_container.modulate.a = 1.0
	reveal_container.scale = Vector2.ONE
	show_reveal_line(0)


func show_reveal_line(index: int) -> void:
	if reveal_tween != null and reveal_tween.is_running():
		reveal_tween.kill()

	if reveal_lines.is_empty():
		reveal_to_card()
		return

	reveal_step = clampi(index, 0, reveal_lines.size() - 1)
	reveal_title.text = reveal_lines[reveal_step]
	reveal_body.text = ""
	reveal_title.modulate.a = 0.0
	reveal_title.scale = Vector2(0.92, 0.92)

	reveal_tween = create_tween()
	reveal_tween.set_trans(Tween.TRANS_CUBIC)
	reveal_tween.set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(reveal_title, "modulate:a", 1.0, 1.65)
	reveal_tween.parallel().tween_property(reveal_title, "scale", Vector2.ONE, 1.65)


func advance_reveal_line() -> void:
	if reveal_tween != null and reveal_tween.is_running():
		reveal_tween.kill()
		reveal_title.modulate.a = 1.0
		reveal_title.scale = Vector2.ONE
		return

	if reveal_step < reveal_lines.size() - 1:
		show_reveal_line(reveal_step + 1)
		return

	reveal_to_card()


func reveal_to_card() -> void:
	showing_reveal = false

	if reveal_tween != null and reveal_tween.is_running():
		reveal_tween.kill()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(reveal_container, "modulate:a", 0.0, 0.52)
	tween.tween_property(reveal_container, "scale", Vector2(0.985, 0.985), 0.52)
	await tween.finished

	reveal_container.visible = false
	reveal_container.scale = Vector2.ONE
	card_container.visible = true
	update_continue_hint_visibility()

	show_card(current_card)


func animate_card_in() -> void:
	_stop_card_motion()
	var center_position := _get_card_center_position()

	card_panel.position = center_position + Vector2(0, 115)
	card_panel.modulate.a = 0.0
	card_panel.scale = Vector2(0.96, 0.96)

	card_entry_tween = create_tween()
	card_entry_tween.set_parallel(true)
	card_entry_tween.set_trans(Tween.TRANS_CUBIC)
	card_entry_tween.set_ease(Tween.EASE_OUT)
	card_entry_tween.tween_property(card_panel, "modulate:a", 1.0, 0.9)
	card_entry_tween.tween_property(card_panel, "position", center_position, 1.15)
	card_entry_tween.tween_property(card_panel, "scale", Vector2.ONE, 1.15)
	await card_entry_tween.finished

	if card_container.visible:
		_start_card_float()


func next_card() -> void:
	if cards.is_empty():
		show_empty_deck()
		return

	_stop_card_motion()
	var center_position := _get_card_center_position()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(card_panel, "modulate:a", 0.0, 0.42)
	tween.tween_property(card_panel, "position", center_position + Vector2(0, -90), 0.42)
	tween.tween_property(card_panel, "scale", Vector2(0.94, 0.94), 0.42)
	await tween.finished

	current_card += 1

	if current_card >= cards.size():
		show_deck()
	else:
		card_panel.modulate.a = 1.0
		card_panel.scale = Vector2.ONE
		card_panel.position = center_position
		show_reveal(current_card)


func apply_deck_screen_layout() -> void:
	if deck_button_spacer == null or not is_instance_valid(deck_button_spacer):
		deck_button_spacer = Control.new()
		deck_button_spacer.name = "DeckButtonSpacer"
		deck_button_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck_vbox.add_child(deck_button_spacer)
	elif deck_button_spacer.get_parent() != deck_vbox:
		var previous_parent: Node = deck_button_spacer.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(deck_button_spacer)
		deck_vbox.add_child(deck_button_spacer)

	var target_index: int = share_button.get_index()
	if deck_button_spacer.get_index() < target_index:
		target_index -= 1
	deck_vbox.move_child(deck_button_spacer, target_index)

	deck_vbox.add_theme_constant_override("separation", 14)
	cards_row.add_theme_constant_override("separation", MINI_CARD_GAP)
	cards_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	deck_title.custom_minimum_size = Vector2(0, 38)
	cards_row.custom_minimum_size = Vector2(0, MINI_CARD_SIZE.y)
	deck_button_spacer.custom_minimum_size = Vector2(1, 52)
	share_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	share_button.custom_minimum_size = Vector2(220, 42)
	replay_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	replay_button.custom_minimum_size = Vector2(220, 42)


func show_deck() -> void:
	_clear_dyk_scratch_overlay()
	card_container.visible = false
	reveal_container.visible = false
	deck_container.visible = true
	progress_container.visible = false
	background.color = BG_DARK
	update_continue_hint_visibility()

	deck_title.text = final_deck_title
	deck_title.add_theme_color_override("font_color", Color("#F5F2ED"))
	deck_title.add_theme_font_size_override("font_size", 28)
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_deck_screen_layout()

	for child in cards_row.get_children():
		child.queue_free()

	for i in range(cards.size()):
		var mini_card := build_mini_card(cards[i], i)
		cards_row.add_child(mini_card)


func build_mini_card(data: Dictionary, index: int) -> PanelContainer:
	var mini := PanelContainer.new()
	mini.custom_minimum_size = MINI_CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)

	mini.add_theme_stylebox_override("panel", style)

	var root := Control.new()
	root.custom_minimum_size = MINI_CARD_SIZE
	root.size = MINI_CARD_SIZE
	mini.add_child(root)

	_add_playtest_layers(root, data, MINI_CARD_SIZE)

	var playtest_text := _get_playtest_text_bundle(data)

	var tab := _make_mini_label(
		str(playtest_text.get("heading", "")),
		_get_heading_font_size(data, true),
		_get_heading_color(data),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)
	root.add_child(tab)

	var title := _make_mini_label(
		str(playtest_text.get("row_1", "")),
		6,
		Color("#29252B"),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)
	root.add_child(title)

	var description := _make_mini_label(
		str(playtest_text.get("row_2", "")),
		6,
		Color("#29252B"),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)
	root.add_child(description)

	var detail_1 := _make_mini_label(
		str(playtest_text.get("row_3", "")),
		6,
		Color("#29252B"),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)
	root.add_child(detail_1)

	var detail_2 := _make_mini_label(
		"",
		1,
		Color("#1A1A1A"),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_TOP
	)
	root.add_child(detail_2)

	var dyk_text := _make_mini_label(
		str(playtest_text.get("dyk", "")),
		7,
		Color("#1A1A1A"),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)
	root.add_child(dyk_text)

	_place_mini_text_controls(data, tab, title, description, detail_1, detail_2, dyk_text)

	return mini


func _place_mini_control(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
	control.custom_minimum_size = rect.size


func _add_playtest_layers(root: Control, data: Dictionary, target_size: Vector2) -> void:
	var assets := _get_playtest_asset_set(data)
	var layer_keys := ["background", "front", "image", "body", "icons", "dyk", "banner", "logo"]

	for key in layer_keys:
		if not assets.has(key):
			continue

		var texture := _load_playtest_texture(str(assets.get(key, "")))
		if texture == null:
			continue

		var layer := TextureRect.new()
		layer.texture = texture
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		_place_mini_control(layer, Rect2(Vector2.ZERO, target_size))
		root.add_child(layer)


func _place_mini_text_controls(
	data: Dictionary,
	tab: Label,
	title: Label,
	description: Label,
	detail_1: Label,
	detail_2: Label,
	dyk_text: Label
) -> void:
	var card_type := str(data.get("type", ""))

	if card_type == "archetype":
		_place_mini_control(tab, _scale_mini_rect(Rect2(108, 37, 252, 38)))
		_place_mini_control(title, _scale_mini_rect(Rect2(112, 396, 236, 28)))
		_place_mini_control(description, _scale_mini_rect(Rect2(112, 428, 236, 28)))
		_place_mini_control(detail_1, _scale_mini_rect(Rect2(112, 460, 236, 28)))
		_place_mini_control(detail_2, _scale_mini_rect(Rect2(0, 0, 1, 1)))
		_place_mini_control(dyk_text, _scale_mini_rect(Rect2(60, 518, 276, 38)))
	elif card_type == "defining_moment":
		_place_mini_control(tab, _scale_mini_rect(Rect2(116, 34, 244, 36)))
		_place_mini_control(title, _scale_mini_rect(Rect2(116, 474, 232, 28)))
		_place_mini_control(description, _scale_mini_rect(Rect2(116, 512, 232, 28)))
		_place_mini_control(detail_1, _scale_mini_rect(Rect2(0, 0, 1, 1)))
		_place_mini_control(detail_2, _scale_mini_rect(Rect2(0, 0, 1, 1)))
		_place_mini_control(dyk_text, _scale_mini_rect(Rect2(0, 0, 1, 1)))
	else:
		_place_mini_control(tab, _scale_mini_rect(Rect2(116, 34, 244, 36)))
		_place_mini_control(title, _scale_mini_rect(Rect2(104, 451, 244, 28)))
		_place_mini_control(description, _scale_mini_rect(Rect2(104, 483, 244, 28)))
		_place_mini_control(detail_1, _scale_mini_rect(Rect2(104, 516, 244, 28)))
		_place_mini_control(detail_2, _scale_mini_rect(Rect2(0, 0, 1, 1)))
		_place_mini_control(dyk_text, _scale_mini_rect(Rect2(0, 0, 1, 1)))

	detail_1.visible = detail_1.text.strip_edges() != ""
	detail_2.visible = false
	dyk_text.visible = card_type == "archetype" and dyk_text.text.strip_edges() != ""


func _scale_mini_rect(rect: Rect2) -> Rect2:
	var scale := Vector2(MINI_CARD_SIZE.x / CARD_SIZE.x, MINI_CARD_SIZE.y / CARD_SIZE.y)
	return Rect2(rect.position * scale, rect.size * scale)


func _make_mini_label(
	text: String,
	font_size: int,
	font_color: Color,
	horizontal_alignment: HorizontalAlignment,
	vertical_alignment: VerticalAlignment
) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = horizontal_alignment
	label.vertical_alignment = vertical_alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func replay() -> void:
	current_card = 0
	showing_reveal = false
	_stop_card_motion()

	for child in cards_row.get_children():
		child.queue_free()

	card_panel.scale = Vector2.ONE
	card_panel.modulate.a = 1.0
	card_container.modulate.a = 1.0
	reveal_container.modulate.a = 1.0
	deck_container.modulate.a = 1.0

	setup_initial_state()


func share_deck() -> void:
	await export_all_keepsake_images()


func export_all_keepsake_images() -> void:
	var folder := "user://keepsake_exports/"
	var absolute_folder := ProjectSettings.globalize_path(folder)
	var original_card_position := card_panel.position

	DirAccess.make_dir_recursive_absolute(absolute_folder)

	# Exportar deck completo
	show_deck()
	await export_deck_cards_as_png(folder + "full_deck.png")

	# Exportar cartas individuales
	for i in range(cards.size()):
		card_container.visible = true
		deck_container.visible = false
		reveal_container.visible = false

		show_card_for_export(i)
		card_panel.position = Vector2(CARD_EXPORT_PADDING, CARD_EXPORT_PADDING)

		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw

		await export_viewport_region_as_png(
			Rect2i(
				Vector2i.ZERO,
				Vector2i(
					int(CARD_SIZE.x) + CARD_EXPORT_PADDING * 2,
					int(CARD_SIZE.y) + CARD_EXPORT_PADDING * 2
				)
			),
			folder + "card_%d.png" % (i + 1)
		)

	card_panel.position = original_card_position
	show_deck()

	OS.shell_open(absolute_folder)

	print("Keepsake exports saved to: ", absolute_folder)

func export_control_as_png(control: Control, path: String, padding := 0) -> void:
	await RenderingServer.frame_post_draw

	var viewport_image := get_viewport().get_texture().get_image()
	var rect := control.get_global_rect()
	rect = rect.grow(float(padding))

	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_image.get_size()))
	rect = rect.intersection(viewport_rect)

	var crop_rect := Rect2i(
		Vector2i(rect.position),
		Vector2i(rect.size)
	)

	var cropped := viewport_image.get_region(crop_rect)
	var error := cropped.save_png(path)

	if error != OK:
		print("Could not save image: ", path, " Error: ", error)
	else:
		print("Saved: ", ProjectSettings.globalize_path(path))


func export_viewport_region_as_png(region: Rect2i, path: String) -> void:
	await RenderingServer.frame_post_draw

	var viewport_image := get_viewport().get_texture().get_image()
	var viewport_rect := Rect2i(Vector2i.ZERO, viewport_image.get_size())
	var crop_rect := region.intersection(viewport_rect)
	var cropped := viewport_image.get_region(crop_rect)
	var error := cropped.save_png(path)

	if error != OK:
		print("Could not save image: ", path, " Error: ", error)
	else:
		print("Saved: ", ProjectSettings.globalize_path(path))


func export_deck_cards_as_png(path: String) -> void:
	var card_count: int = cards.size()
	var gap_count: int = maxi(0, card_count - 1)
	var export_width: int = int(MINI_CARD_SIZE.x) * card_count + MINI_CARD_GAP * gap_count + DECK_EXPORT_PADDING * 2
	var export_height: int = int(MINI_CARD_SIZE.y) + DECK_EXPORT_PADDING * 2

	var previous_deck_visible := deck_container.visible
	var previous_card_visible := card_container.visible
	var previous_reveal_visible := reveal_container.visible
	var previous_progress_visible := progress_container.visible

	deck_container.visible = false
	card_container.visible = false
	reveal_container.visible = false
	progress_container.visible = false

	var export_root := Control.new()
	export_root.name = "DeckExportRoot"
	export_root.position = Vector2.ZERO
	export_root.size = Vector2(export_width, export_height)
	export_root.custom_minimum_size = export_root.size
	export_root.z_index = 1000
	add_child(export_root)

	var export_background := ColorRect.new()
	export_background.color = BG_DARK
	export_background.position = Vector2.ZERO
	export_background.size = export_root.size
	export_root.add_child(export_background)

	for i in range(cards.size()):
		var mini_card := build_mini_card(cards[i], i)
		mini_card.custom_minimum_size = MINI_CARD_SIZE
		mini_card.position = Vector2(
			DECK_EXPORT_PADDING + i * (MINI_CARD_SIZE.x + MINI_CARD_GAP),
			DECK_EXPORT_PADDING
		)
		mini_card.size = MINI_CARD_SIZE
		export_root.add_child(mini_card)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	await export_viewport_region_as_png(
		Rect2i(Vector2i.ZERO, Vector2i(export_width, export_height)),
		path
	)

	export_root.queue_free()
	deck_container.visible = previous_deck_visible
	card_container.visible = previous_card_visible
	reveal_container.visible = previous_reveal_visible
	progress_container.visible = previous_progress_visible


func export_control_children_as_png(container: Control, path: String, padding := 0) -> void:
	await RenderingServer.frame_post_draw

	var bounds := Rect2()
	var has_bounds := false

	for child in container.get_children():
		if not child is Control:
			continue

		var child_control := child as Control
		if not child_control.visible:
			continue

		var child_rect := child_control.get_global_rect()
		if not has_bounds:
			bounds = child_rect
			has_bounds = true
		else:
			bounds = bounds.merge(child_rect)

	if not has_bounds:
		await export_control_as_png(container, path, padding)
		return

	bounds = bounds.grow(float(padding))

	var viewport_image := get_viewport().get_texture().get_image()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_image.get_size()))
	bounds = bounds.intersection(viewport_rect)

	var crop_rect := Rect2i(
		Vector2i(bounds.position),
		Vector2i(bounds.size)
	)

	var cropped := viewport_image.get_region(crop_rect)
	var error := cropped.save_png(path)

	if error != OK:
		print("Could not save image: ", path, " Error: ", error)
	else:
		print("Saved: ", ProjectSettings.globalize_path(path))


func _input(event: InputEvent) -> void:
	if _handle_dyk_scratch_input(event):
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or _is_scroll_button(event.button_index):
			if _continue_from_input():
				get_viewport().set_input_as_handled()
				return

	if event is InputEventScreenTouch and event.pressed:
		if _continue_from_input():
			get_viewport().set_input_as_handled()
			return

	if event is InputEventPanGesture:
		if absf(event.delta.y) > 0.2 and _continue_from_input():
			get_viewport().set_input_as_handled()
			return


func _is_scroll_button(button_index: int) -> bool:
	return button_index == MOUSE_BUTTON_WHEEL_UP or button_index == MOUSE_BUTTON_WHEEL_DOWN


func _continue_from_input() -> bool:
	if continue_input_locked:
		return false

	if intro_container.visible:
		if not open_button.visible:
			_lock_continue_input()
			advance_intro_line()
			return true
		return false

	if showing_reveal:
		_lock_continue_input()
		advance_reveal_line()
		return true

	if card_container.visible:
		_lock_continue_input()
		next_card()
		return true

	return false


func _lock_continue_input() -> void:
	continue_input_locked = true
	get_tree().create_timer(0.28).timeout.connect(_unlock_continue_input)


func _unlock_continue_input() -> void:
	continue_input_locked = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if is_inside_tree() and is_instance_valid(card_panel):
			card_panel.position = (get_viewport_rect().size - card_panel.size) / 2.0

		if is_inside_tree() and is_instance_valid(progress_container):
			progress_container.position = Vector2(24, (get_viewport_rect().size.y - 100) / 2.0)

		_position_continue_hint()


func load_keepsake_data(data: Dictionary) -> void:
	intro_time_text = str(data.get("session_duration_text", "some time")).strip_edges()
	if intro_time_text.is_empty():
		intro_time_text = "some time"

	final_deck_title = str(data.get("deck_title", "Your collection is ready.")).strip_edges()
	if final_deck_title.is_empty():
		final_deck_title = "Your collection is ready."

	_reset_intro_lines()
	var incoming_intro_lines = data.get("intro_lines", [])
	if typeof(incoming_intro_lines) == TYPE_ARRAY and not incoming_intro_lines.is_empty():
		intro_lines.clear()
		for line in incoming_intro_lines:
			intro_lines.append(str(line))

	if not data.has("cards"):
		print("Keepsake data has no cards.")
		cards = []
		current_card = 0
		return

	var incoming_cards = data["cards"]
	if typeof(incoming_cards) != TYPE_ARRAY:
		print("Keepsake data cards field is not an array.")
		cards = []
		current_card = 0
		return

	cards = incoming_cards
	current_card = 0


func _reset_intro_lines() -> void:
	intro_lines.clear()
	for line in DEFAULT_INTRO_LINES:
		intro_lines.append(line)


func update_progress() -> void:
	for child in progress_container.get_children():
		child.queue_free()

	for i in range(cards.size()):
		var pip := Panel.new()
		var active := i == current_card

		pip.custom_minimum_size = Vector2(14, 14) if active else Vector2(10, 10)

		var style := StyleBoxFlat.new()
		style.bg_color = Color("#C9A84C") if active else Color("#8A8680")
		style.corner_radius_top_left = 100
		style.corner_radius_top_right = 100
		style.corner_radius_bottom_left = 100
		style.corner_radius_bottom_right = 100

		pip.add_theme_stylebox_override("panel", style)
		progress_container.add_child(pip)

	progress_container.move_to_front()


func show_empty_deck() -> void:
	intro_container.visible = false
	reveal_container.visible = false
	card_container.visible = false
	deck_container.visible = true
	progress_container.visible = false
	update_continue_hint_visibility()

	background.color = BG_DARK

	deck_title.text = "No keepsake cards were generated."
	deck_title.add_theme_color_override("font_color", Color("#F5F2ED"))
	deck_title.add_theme_font_size_override("font_size", 24)
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for child in cards_row.get_children():
		child.queue_free()

func show_card_for_export(index: int) -> void:
	_clear_dyk_scratch_overlay()
	if continue_hint_label != null and is_instance_valid(continue_hint_label):
		continue_hint_label.visible = false

	index = clamp(index, 0, cards.size() - 1)
	current_card = index

	var data: Dictionary = cards[index]

	if data.get("type", "") == "archetype":
		apply_archetype_card_style()
	else:
		apply_normal_card_style()

	card_container.visible = true
	card_panel.visible = true
	card_art_root.visible = true

	card_panel.modulate.a = 1.0
	card_panel.scale = Vector2.ONE
	card_container.modulate.a = 1.0

	_apply_playtest_card_assets(data)

	_apply_playtest_card_text(data)

	force_card_size()
	apply_art_text_style()
	apply_playtest_text_layout(data)
	_clear_dyk_scratch_overlay()
