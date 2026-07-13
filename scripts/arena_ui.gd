class_name ArenaUI
extends CanvasLayer

signal atacar
signal usar_habilidade(h)
signal usar_item
signal parry

var _player: PlayerCombatant
var _enemies: Array = []

var _menu: Control
var _btn_atacar: Button
var _btn_habs: Button
var _btn_itens: Button
var _parry_btn: Button
var _hab_panel: VBoxContainer
var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _log: Label
var _tel := {}       # lane -> ColorRect
var _enemy_bars := []

func _ready() -> void:
	_montar()

func _montar() -> void:
	# telegrafo por lane (fundo)
	for lane in [CombatEnums.Lane.LEFT, CombatEnums.Lane.CENTER, CombatEnums.Lane.RIGHT]:
		var r := ColorRect.new()
		r.color = Color(1, 0.15, 0.15, 0.30)
		r.anchor_left = (lane + 1) / 3.0
		r.anchor_right = (lane + 2) / 3.0
		r.anchor_top = 0.0
		r.anchor_bottom = 1.0
		r.visible = false
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		_tel[lane] = r

	# HUD do player
	_hp_bar = ProgressBar.new(); _hp_bar.position = Vector2(20, 20); _hp_bar.size = Vector2(200, 24)
	_mp_bar = ProgressBar.new(); _mp_bar.position = Vector2(20, 50); _mp_bar.size = Vector2(200, 18)
	add_child(_hp_bar); add_child(_mp_bar)

	# log
	_log = Label.new(); _log.position = Vector2(20, 80)
	add_child(_log)

	# menu de acao — canto inferior direito
	_menu = VBoxContainer.new()
	_menu.anchor_left = 1.0; _menu.anchor_top = 1.0
	_menu.anchor_right = 1.0; _menu.anchor_bottom = 1.0
	_menu.offset_left = -200; _menu.offset_top = -230
	_menu.offset_right = -16; _menu.offset_bottom = -16
	add_child(_menu)
	_btn_atacar = _make_btn("Atacar", func(): atacar.emit())
	_btn_habs = _make_btn("Habilidades", func(): _hab_panel.visible = not _hab_panel.visible)
	_btn_itens = _make_btn("Itens", func(): usar_item.emit())
	_menu.add_child(_btn_atacar); _menu.add_child(_btn_habs); _menu.add_child(_btn_itens)

	# painel de habilidades — acima do menu, no canto direito
	_hab_panel = VBoxContainer.new()
	_hab_panel.anchor_left = 1.0; _hab_panel.anchor_top = 1.0
	_hab_panel.anchor_right = 1.0; _hab_panel.anchor_bottom = 1.0
	_hab_panel.offset_left = -420; _hab_panel.offset_top = -230
	_hab_panel.offset_right = -210; _hab_panel.offset_bottom = -16
	_hab_panel.visible = false
	add_child(_hab_panel)

	# botao parry — centro-baixo, escondido (so aparece no ataque inimigo)
	_parry_btn = _make_btn("PARRY", func(): parry.emit())
	_parry_btn.anchor_left = 0.5; _parry_btn.anchor_top = 1.0
	_parry_btn.anchor_right = 0.5; _parry_btn.anchor_bottom = 1.0
	_parry_btn.offset_left = -110; _parry_btn.offset_top = -110
	_parry_btn.offset_right = 110; _parry_btn.offset_bottom = -30
	_parry_btn.add_theme_font_size_override("font_size", 30)
	_parry_btn.visible = false
	add_child(_parry_btn)

func _make_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(160, 44)
	b.pressed.connect(cb)
	return b

func bind_player(p: PlayerCombatant) -> void:
	_player = p

func set_enemies(arr: Array) -> void:
	_enemies = arr
	for b in _enemy_bars:
		b.queue_free()
	_enemy_bars.clear()
	var i := 0
	for e in arr:
		var bar := ProgressBar.new()
		bar.position = Vector2(20 + i * 210, 120)
		bar.size = Vector2(200, 18)
		add_child(bar)
		_enemy_bars.append(bar)
		i += 1

func popular_habilidades(habs: Array) -> void:
	for c in _hab_panel.get_children():
		c.queue_free()
	for h in habs:
		var hb = h
		var b := _make_btn(h.nome, func(): usar_habilidade.emit(hb))
		_hab_panel.add_child(b)

func set_menu_visivel(v: bool) -> void:
	if _menu: _menu.visible = v
	if not v and _hab_panel: _hab_panel.visible = false

func set_menu_interativo(v: bool) -> void:
	for b in [_btn_atacar, _btn_habs, _btn_itens]:
		if b: b.disabled = not v

func mostrar_parry(v: bool) -> void:
	if _parry_btn: _parry_btn.visible = v

func set_log(txt: String) -> void:
	if _log: _log.text = txt

func mostrar_telegrafo(lanes: Array) -> void:
	for lane in _tel:
		_tel[lane].visible = lanes.has(lane)

func esconder_telegrafo() -> void:
	for lane in _tel:
		_tel[lane].visible = false

func _process(_dt: float) -> void:
	if _player != null and _player.vitals != null:
		_hp_bar.max_value = _player.vitals.max_hp
		_hp_bar.value = _player.vitals.hp
		_mp_bar.max_value = max(1, _player.vitals.max_mana)
		_mp_bar.value = _player.vitals.mana
	for i in range(min(_enemy_bars.size(), _enemies.size())):
		var e = _enemies[i]
		if e != null and e.vitals != null:
			_enemy_bars[i].max_value = e.vitals.max_hp
			_enemy_bars[i].value = e.vitals.hp
			_enemy_bars[i].visible = e.esta_vivo()
