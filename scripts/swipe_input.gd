class_name SwipeInput
extends Node

signal swipe(dir: int)
signal parry

@export var min_swipe_px := 40.0

var _ativo := false
var _acc_x := 0.0

func set_ativo(v: bool) -> void:
	_ativo = v
	_acc_x = 0.0

func pressionar_parry() -> void:
	parry.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not _ativo:
		return
	if event is InputEventScreenDrag:
		_acumular(event.relative.x)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_acumular(event.relative.x)

func _acumular(dx: float) -> void:
	_acc_x += dx
	if absf(_acc_x) >= min_swipe_px:
		swipe.emit(1 if _acc_x > 0 else -1)
		_acc_x = 0.0
