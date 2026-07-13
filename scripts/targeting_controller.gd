class_name TargetingController
extends Node

signal resolvido

enum Modo { SINGLE, AOE }

var ativo := false
var resultado_ok := false
var resultado_alvo = null

# enquadramento (setado pelo Level1)
var dist_single := 3.0
var altura_single := 1.6
var dist_aoe := 7.0
var altura_aoe := 3.0

var _cam: Camera3D
var _transform_normal: Transform3D
var _enemies: Array = []
var _modo := Modo.SINGLE
var _foco := 0
var _px_min := 60.0
var _inicio_toque := Vector2.ZERO
var _rastreando := false

func configurar(cam: Camera3D) -> void:
	_cam = cam

func iniciar(enemies: Array, modo: int) -> void:
	_enemies = enemies
	_modo = modo
	_transform_normal = _cam.global_transform
	_foco = _primeiro_vivo()
	if _foco == -1:
		cancelar()
		return
	ativo = true
	resultado_ok = false
	resultado_alvo = null
	_enquadrar()

func _primeiro_vivo() -> int:
	for i in _enemies.size():
		if _enemies[i] != null and _enemies[i].esta_vivo():
			return i
	return -1

func _vivos() -> Array:
	var r := []
	for e in _enemies:
		r.append(e != null and e.esta_vivo())
	return r

func trocar_foco(dir: int) -> void:
	if _modo != Modo.SINGLE:
		return
	_foco = TargetCycler.proximo(_vivos(), _foco, dir)
	_enquadrar()

func confirmar() -> void:
	if not ativo:
		return
	resultado_ok = true
	resultado_alvo = _enemies[_foco] if _modo == Modo.SINGLE else null
	_sair()

func confirmar_inimigo(inimigo) -> void:
	if not ativo:
		return
	resultado_ok = true
	resultado_alvo = inimigo if _modo == Modo.SINGLE else null
	_sair()

func cancelar() -> void:
	if not ativo:
		resolvido.emit()
		return
	resultado_ok = false
	resultado_alvo = null
	_sair()

func _sair() -> void:
	ativo = false
	_tween_cam(_transform_normal)
	resolvido.emit()

func _enquadrar() -> void:
	if _modo == Modo.AOE:
		_tween_cam(_pos_para(_centro_vivos(), dist_aoe, altura_aoe))
	else:
		_tween_cam(_pos_para(_enemies[_foco].global_position, dist_single, altura_single))

func _centro_vivos() -> Vector3:
	var c := Vector3.ZERO
	var n := 0
	for e in _enemies:
		if e != null and e.esta_vivo():
			c += e.global_position
			n += 1
	return c / max(1, n)

func _pos_para(alvo: Vector3, dist: float, altura: float) -> Transform3D:
	# camera do lado do player (z positivo em relacao ao alvo), olhando pro alvo
	var t := Transform3D()
	t.origin = alvo + Vector3(0, altura, dist)
	return t.looking_at(alvo + Vector3(0, 1.0, 0), Vector3.UP)

func _tween_cam(destino: Transform3D) -> void:
	var tw := create_tween()
	tw.tween_property(_cam, "global_transform", destino, 0.3).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if not ativo:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_inicio_toque = event.position; _rastreando = true
		else:
			_fim_gesto(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_inicio_toque = event.position; _rastreando = true
		else:
			_fim_gesto(event.position)

func _fim_gesto(pos: Vector2) -> void:
	if not _rastreando:
		return
	_rastreando = false
	var d := pos - _inicio_toque
	if d.length() < _px_min:
		var alvo = _raycast_inimigo(pos)
		if alvo != null:
			confirmar_inimigo(alvo)
		return
	if absf(d.x) > absf(d.y):
		trocar_foco(1 if d.x > 0 else -1)
	elif d.y > 0:
		cancelar() # swipe pra baixo = voltar

func _raycast_inimigo(pos: Vector2):
	if _cam == null:
		return null
	var origem := _cam.project_ray_origin(pos)
	var destino := origem + _cam.project_ray_normal(pos) * 100.0
	var q := PhysicsRayQueryParameters3D.create(origem, destino)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := _cam.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	var col = hit.collider
	if col != null and col.has_meta("inimigo"):
		return col.get_meta("inimigo")
	return null
