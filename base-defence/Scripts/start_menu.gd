extends Control

func _ready():
	_update_ui()

func _update_ui():
	var unlock = SaveManager.data["unlock_level"]
	var best = SaveManager.data["best_phase"]

	$BestPhaseLabel.text = "Best Phase: " + str(best)

	# Workshop locked until unlock_level 2
	if unlock < 2:
		$WorkshopButton.disabled = true
		$WorkshopButton.text = "WORKSHOP (Beat Boss First)"
	else:
		$WorkshopButton.disabled = false
		$WorkshopButton.text = "WORKSHOP"

	# Phase select hidden until boss beaten
	if unlock >= 2:
		$PhaseSelectButton.visible = true
		var start = SaveManager.data.get("start_phase", 1)
		$PhaseSelectButton.text = "START FROM PHASE " + str(start)
	else:
		$PhaseSelectButton.visible = false

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_workshop_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Workshop.tscn")

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
	pass # Replace with function body.
