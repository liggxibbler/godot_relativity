extends Node

var sim : Global.Sim
var view : Global.View
var gameplay : Global.Gameplay

var maxBoostSize = 1.5

var lookSpeed = 1.0

var time_scale = 1.0
var speedOfLight = 1.0
var retardation = true

func gamma_operator(beta) -> float:
		return pow(1 - beta * beta, -.5)
	
func lorentz(v : Vector4, c) -> Projection:
	var speed = v.length()
	var beta = speed / c
	var gamma = gamma_operator(beta)

	var v2 = speed * speed
	
	var row1 = Vector4(1 + (gamma - 1) * v[0] * v[0] / v2, (gamma - 1) * v[0] * v[1] / v2, (gamma - 1) * v[0] * v[2] / v2, -gamma * v[0] / c)
	var row2 = Vector4((gamma - 1) * v[1] * v[1] / v2, 1 + (gamma - 1) * v[1] * v[1] / v2, (gamma - 1) * v[1] * v[2] / v2, -gamma * v[1] / c)
	var row3 = Vector4((gamma - 1) * v[2] * v[0] / v2, (gamma - 1) * v[2] * v[1] / v2, 1 + (gamma - 1) * v[2] * v[2] / v2, -gamma * v[2] / c)
	var row4 = Vector4(-gamma * v[0] / c, -gamma * v[1] / c, -gamma * v[2] / c, gamma)
	
	return Projection(row1, row2, row3, row4)

func handle_physics(dt: float, input_boost : Vector4, c : float) -> void:
	if input_boost != Vector4.ZERO:
		input_boost = input_boost / sim.fourvel.w
		var boost = lorentz(-input_boost * dt, c)
		sim.transform_matrix = sim.transform_matrix * boost
		sim.fourvel = sim.transform_matrix * Vector4(0,0,0,1)

	gameplay.enemyPosition.y = 5*cos(sim.uposition.w)
	gameplay.enemyPosition.z = 5*sin(sim.uposition.w)

	sim.uposition += sim.fourvel * dt

func _ready() -> void:
	sim = Global.Sim.new()
	view = Global.View.new()
	gameplay = Global.Gameplay.new()	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("Exit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("ToggleRetardation"):
		toggle_retardation()
	
	view.projectionDistance += Input.get_axis("DecreaseZoom", "IncreaseZoom") * delta
		
	$"../Camera2D".update_resolution(retardation)
	
	if is_instant_braking:
		instant_brake(delta)
	
	var delta_scaled = delta
	
	if Input.is_action_pressed("SlowDown"):
		slow_down(delta)
	else:
		speed_up(delta)
	
	delta_scaled /= time_scale
	
	var boostBackForward = Input.get_axis("BoostBack", "BoostForward")
	var boostLeftRight = Input.get_axis("BoostLeft", "BoostRight")
	var boostUpDown = Input.get_axis("BoostDown", "BoostUp")
	var boostVector = boostBackForward * view.Forward + boostLeftRight * view.Right + boostUpDown * view.Up
	boostVector *= maxBoostSize
	
	if Input.is_action_just_pressed("InstantBrake"):
		instant_brake(delta_scaled);
	
	handle_physics(
		delta_scaled,
		Vector4(boostVector.x, boostVector.y, boostVector.z, 0.0),
		speedOfLight
	)
	
	view.Forward += delta * lookSpeed * Input.get_axis("LookLeft", "LookRight") * view.Right
	view.Forward += delta * lookSpeed * Input.get_axis("LookDown", "LookUp") * view.Up
	
	view.Forward = view.Forward.normalized()	
	
	view.Up = view.Right.cross(view.Forward)
	view.Up = view.Up.normalized()
	view.Right = view.Forward.cross(view.Up)
	
	var dutchAmount = delta * lookSpeed * Input.get_axis("DutchLeft", "DutchRight")
	var newRight = cos(dutchAmount) * view.Right - sin(dutchAmount) * view.Up
	var newUp = sin(dutchAmount) * view.Right + cos(dutchAmount) * view.Up
	view.Right = newRight
	view.Up = newUp
	
	$"../Camera2D".update_shader_values(sim, view, gameplay)

func slow_down(delta : float):
	if time_scale < 10.0:
		time_scale *= (1 + delta * 5.0)
	else:
		time_scale = 10.0

func speed_up(delta : float):
	if (time_scale > 1.0):
		time_scale *= (1 - delta * 5.0)
	else:
		time_scale = 1.0

func toggle_retardation():
	retardation = not retardation

func Rotate2D(vec : Vector2, angle : float) -> Vector2:
	var T = Transform2D(
		Vector2(cos(angle),sin(angle)),
		Vector2(-sin(angle), cos(angle)),
		Vector2.ZERO
	)
	return T * vec

var is_instant_braking = false
var instant_brake_duration = 2.0
var instant_brake_timer = -1.0
var starting_matrix : Projection
var starting_fourvel : Vector4

func instant_brake(delta_time : float):
	if not is_instant_braking:
		is_instant_braking = true
		instant_brake_timer = instant_brake_duration
		starting_matrix = sim.transform_matrix
		starting_fourvel = sim.fourvel
	if is_instant_braking:
		instant_brake_timer -= delta_time
		if instant_brake_timer < 0:
			instant_brake_timer = 0.0
			is_instant_braking = false
		var alpha = 1 - instant_brake_timer / instant_brake_duration
		var x = starting_matrix.x
		var y = starting_matrix.y
		var z = starting_matrix.z
		var w = starting_matrix.w
		#print ("braking", alpha, x, y, z, w)
		x=x.lerp(Vector4(1.0,0.0,0.0,0.0), alpha)
		y=y.lerp(Vector4(0.0,1.0,0.0,0.0), alpha)
		z=z.lerp(Vector4(0.0,0.0,1.0,0.0), alpha)
		w=w.lerp(Vector4(0.0,0.0,0.0,1.0), alpha)
		sim.transform_matrix = Projection(x,y,z,w)
		sim.fourvel = starting_fourvel.lerp(Vector4(0,0,0,1), alpha)
