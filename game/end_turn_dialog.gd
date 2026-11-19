extends Window

signal confirmed
signal village_requested(cap: Vector2i)

var village: Vector2i
var summary: Label
var show_button: Button
var keep_button: Button
var end_button: Button
var sheet: PanelContainer

func _init():
	title = "End your turn?"
	visible = false
	borderless = true
	unresizable = true
	transient = true
	exclusive = true

func _ready():
	var ui = get_parent()
	sheet = ui.panel(self,ui.PAPER)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content = ui.column(ui.margin(sheet,14,12),8)
	ui.label(content,title,28,ui.INK,true)
	summary = ui.label(content,"",16,ui.INK)
	ui.rule(content)
	var actions = ui.row(content,6)
	show_button = ui.button(actions,"Show village",func(): hide(); village_requested.emit(village),ui.NIGHT,ui.LIGHT,ui.MUTED,44)
	ui.spacer(actions)
	keep_button = ui.button(actions,"Keep playing",hide,ui.PAPER,ui.INK,ui.MUTED,44)
	keep_button.add_theme_color_override("font_focus_color",ui.INK)
	end_button = ui.button(actions,"End turn",func(): hide(); confirmed.emit(),ui.GOLD,ui.INK,ui.MUTED,44)
	end_button.add_theme_color_override("font_focus_color",ui.INK)
	close_requested.connect(hide)
	window_input.connect(func(event):
		if event.is_action_pressed("ui_cancel"):
			set_input_as_handled()
			hide())
	ui.get_viewport().size_changed.connect(fit_dialog.call_deferred)

func offer(message: String, cap: Vector2i):
	summary.text = message
	village = cap
	show_button.visible = cap != preload("res://game/rules.gd").NONE
	popup()
	fit_dialog()
	keep_button.grab_focus()

func fit_dialog():
	if visible:
		var screen = Vector2i(get_parent().get_viewport_rect().size)
		size = Vector2i(mini(440,screen.x - 16),ceili(sheet.get_combined_minimum_size().y))
		position = (screen - size) / 2
