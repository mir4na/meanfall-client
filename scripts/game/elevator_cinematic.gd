extends CanvasLayer

func _ready() -> void:
	layer = 200  # Above SceneTransition (which is 128)
	
	# Wait for SceneTransition to finish its fade_in, then take over
	await get_tree().create_timer(0.5).timeout
	_run()

func _run() -> void:
	var vp   := get_viewport().get_visible_rect().size
	var vp_w := vp.x
	var vp_h := vp.y
	var bar_h := vp_h * 0.10

	# ── Top bar ──────────────────────────────
	var bar_top := ColorRect.new()
	bar_top.color    = Color(0, 0, 0, 1)
	bar_top.size     = Vector2(vp_w, 0)
	bar_top.position = Vector2(0, 0)
	add_child(bar_top)

	# ── Bottom bar ───────────────────────────
	var bar_bot := ColorRect.new()
	bar_bot.color    = Color(0, 0, 0, 1)
	bar_bot.size     = Vector2(vp_w, 0)
	bar_bot.position = Vector2(0, vp_h)
	add_child(bar_bot)

	# ── Shaft overlay (simulates elevator interior) ──
	var shaft := ColorRect.new()
	shaft.color    = Color(0.05, 0.04, 0.14, 1.0)
	shaft.size     = Vector2(vp_w, vp_h)
	shaft.position = Vector2(0, 0)
	# Center pivot for vertical-scale gate-open effect
	shaft.pivot_offset = Vector2(vp_w * 0.5, vp_h * 0.5)
	add_child(shaft)

	# ── Glow strips on left/right edges of shaft ──
	for xi in [0.0, vp_w - 4.0]:
		var strip := ColorRect.new()
		strip.color    = Color(0.3, 0.5, 1.0, 0.7)
		strip.size     = Vector2(4, vp_h)
		strip.position = Vector2(xi, 0)
		add_child(strip)

	# ─── Phase 1: bars slide in (letterbox) ───────────
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(bar_top, "size:y",     bar_h, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t1.tween_property(bar_bot, "size:y",     bar_h, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t1.tween_property(bar_bot, "position:y", vp_h - bar_h, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t1.finished

	# ─── Phase 2: elevator shake (descending) ─────────
	var shake_duration := 3.0
	var elapsed        := 0.0
	while elapsed < shake_duration:
		var amt  := randf_range(-3.0, 3.0)
		shaft.position.y = amt
		elapsed += 0.04
		await get_tree().create_timer(0.04).timeout
	shaft.position.y = 0.0

	await get_tree().create_timer(0.3).timeout

	# ─── Phase 3: gate opens — shaft shrinks vertically ────
	var t3 := create_tween()
	t3.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t3.tween_property(shaft, "scale:y", 0.0, 1.0)
	await t3.finished

	await get_tree().create_timer(0.4).timeout

	# ─── Phase 4: bars retract ────────────────────────
	var t4 := create_tween().set_parallel(true)
	t4.tween_property(bar_top, "size:y",     0.0,  0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t4.tween_property(bar_bot, "size:y",     0.0,  0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t4.tween_property(bar_bot, "position:y", vp_h, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await t4.finished

	queue_free()
