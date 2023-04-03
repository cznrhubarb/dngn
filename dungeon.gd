extends Node3D

@onready var viewpoint := $Viewpoint
var input_locked := false
var input_tween_duration := 0.25
var collision_data: Array
var queued_input = null


func _ready():
	var dummy_data = []
	var file = FileAccess.open("res://testdata.txt", FileAccess.READ)
	while !file.eof_reached():
		var csv = file.get_csv_line()
		dummy_data.append(csv)
	file.close()
	build(dummy_data)


func build(data: Array):
	collision_data = data
	var wall_scene: PackedScene = load("res://wall.tscn")
	var empty_scene: PackedScene = load("res://empty.tscn")
	
	for y in data.size():
		var row = data[y]
		for x in row.size():
			var cell = row[x]
			if cell == 'w':
				var wall: Node3D = wall_scene.instantiate()
				wall.position = Vector3(x, 0, y)
				$Walls.add_child(wall)
			else:
				var empty: Node3D = empty_scene.instantiate()
				empty.position = Vector3(x, -0.5, y)
				$Walls.add_child(empty)
					
			if cell.begins_with('p'):
				viewpoint.position = Vector3(x, 0, y)
				viewpoint.look_at(viewpoint.position + get_orientation_for_direction(cell[1]))


func get_orientation_for_direction(dir: String):
	match dir:
		's':
			return Vector3(0, 0, 1)
		'n':
			return Vector3(0, 0, -1)
		'e':
			return Vector3(1, 0, 0)
		'w':
			return Vector3(-1, 0, 0)


func _physics_process(delta):
	process_input()


func get_input():
	if Input.is_action_just_pressed("move_forward"):
		return "move_forward"
	if Input.is_action_just_pressed("move_back"):
		return "move_back"
	if Input.is_action_just_pressed("turn_left"):
		return "turn_left"
	if Input.is_action_just_pressed("turn_right"):
		return "turn_right"
	if Input.is_action_just_pressed("move_left"):
		return "move_left"
	if Input.is_action_just_pressed("move_right"):
		return "move_right"
	return null


func process_input():
	var input = get_input()
	
	if input_locked:
		if input != null:
			queued_input = input
		return
	
	if input == null:
		input = queued_input
	queued_input = null
	
	var desired_pos = null
	var desired_rot = null
	var forward = viewpoint.global_transform.basis.z
	if input == "move_forward":
		desired_pos = viewpoint.position - forward
	if input == "move_back":
		desired_pos = viewpoint.position + forward
	if input == "turn_left":
		tween_viewpoint_rotation_by(PI/2)
	if input == "turn_right":
		tween_viewpoint_rotation_by(-PI/2)
	if input == "move_left":
		desired_pos = viewpoint.position - forward.rotated(Vector3.UP, PI/2)
	if input == "move_right":
		desired_pos = viewpoint.position + forward.rotated(Vector3.UP, PI/2)
	
	if desired_pos != null:
		var is_blocked = collision_data[int(round(desired_pos.z))][int(round(desired_pos.x))].begins_with('w')
		if not is_blocked:
			tween_viewpoint_position_to(desired_pos)
		else:
			tween_viewpoint_bump_to(desired_pos)


func tween_viewpoint_position_to(pos: Vector3):
	input_locked = true
	var tween = get_tree().create_tween()
	tween.tween_property(viewpoint, "position", pos, input_tween_duration)
	tween.tween_callback(func(): input_locked = false)


func tween_viewpoint_bump_to(pos: Vector3):
	input_locked = true
	var tween = get_tree().create_tween()
	var delta = (pos - viewpoint.position) / 4
	tween.tween_property(viewpoint, "position", viewpoint.position + delta, input_tween_duration/2)
	tween.tween_property(viewpoint, "position", viewpoint.position, input_tween_duration/2)
	tween.tween_callback(func(): input_locked = false)


func tween_viewpoint_rotation_by(delta: float):
	input_locked = true
	var tween = get_tree().create_tween()
	tween.tween_property(viewpoint, "rotation:y", viewpoint.rotation.y + delta, input_tween_duration)
	tween.tween_callback(func(): input_locked = false)
