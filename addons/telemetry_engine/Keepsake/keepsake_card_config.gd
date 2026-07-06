class_name KeepsakeCardConfig
extends Resource

@export_group("Fixed Visual Design")
@export var border_image: Texture2D
@export var background_texture: Texture2D
@export var logo: Texture2D
@export var main_image: Texture2D

@export_group("Dynamic Card Text")
@export var type := ""
@export var title := ""
@export var card_detail_tab := ""
@export_multiline var description := ""
@export var content_lines: Array[String] = []

@export_group("Matched Icons")
@export var icon_1: Texture2D
@export var icon_2: Texture2D

@export_group("Did You Know")
@export_multiline var dyk_bar_text := ""
@export_multiline var scratchable_dyk := ""

@export_group("Reveal")
@export var reveal_title := ""
@export_multiline var reveal_body := ""
