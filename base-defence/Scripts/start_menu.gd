extends Control

func _ready():
	_update_ui()

func _update_ui():
	var best = SaveManager.data["best_phase"]
	$BestPhaseLabel.text = "Best Phase: " + str(best)

	$WorkshopButton.disabled = false
	$WorkshopButton.text = "WORKSHOP"

	# Phase select hidden until boss beaten
	var unlock_phase = SaveManager.data["max_start_phase"] > 1
	if unlock_phase:
		$PhaseSelectButton.visible = true
		$PhaseDownButton.visible = true
		$PhaseUpButton.visible = true
		var start = SaveManager.data.get("start_phase", 1)
		$PhaseSelectButton.text = "PHASE " + str(start)
	else:
		$PhaseSelectButton.visible = false
		$PhaseDownButton.visible = false
		$PhaseUpButton.visible = false

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_workshop_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/workshop.tscn")

func _on_skill_tree_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/skilltree.tscn")

func _on_phase_select_button_pressed():
	var current = SaveManager.data.get("start_phase", 1)
	var max_phase = SaveManager.data["max_start_phase"]
	current += 1
	if current > max_phase:
		current = 1
	SaveManager.data["start_phase"] = current
	SaveManager.save_game()
	$PhaseSelectButton.text = "START FROM PHASE " + str(current)

func _on_work_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/workshop.tscn")

func _on_debug_reset_button_pressed():
	SaveManager.reset_save()
	_update_ui()

func _on_debug_unlock_button_pressed():
	SaveManager.data["legacy_points"] = 999999999
	SaveManager.data["max_start_phase"] = 20
	SaveManager.data["phase_tokens"] = 15
	SaveManager.data["phase_tokens_earned"] = 15
	SaveManager.data["unlock_atk_tier"] = 3
	SaveManager.data["unlock_def_tier"] = 3
	SaveManager.data["unlock_hp_tier"] = 3
	SaveManager.data["unlock_util_tier"] = 3
	SaveManager.save_game()
	_update_ui()

func _on_phase_down_button_pressed():
	var current = SaveManager.data.get("start_phase", 1)
	current -= 1
	if current < 1:
		current = 1
	SaveManager.data["start_phase"] = current
	SaveManager.save_game()
	$PhaseSelectButton.text = "START FROM PHASE " + str(current)

func _on_phase_up_button_pressed():
	var current = SaveManager.data.get("start_phase", 1)
	var max_phase = SaveManager.data["max_start_phase"]
	current += 1
	if current > max_phase:
		current = max_phase
	SaveManager.data["start_phase"] = current
	SaveManager.save_game()
	$PhaseSelectButton.text = "START FROM PHASE " + str(current)

func _on_mute_button_pressed():
	var muted = AudioManager.toggle_mute()
	$MuteButton.text = "🔇" if muted else "🔊"
