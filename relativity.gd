extends Camera2D

var surface_material

var orientation = Vector3(0.0, 0.0, 0.0)
var uposition = Vector4.ZERO
var fourvel = Vector4(0,0,0,1)
var boost = Vector4.ZERO
var transform_matrix = Projection.IDENTITY
var view2d = Vector2(0.5,0.5)
var viewForward = Vector3(1,0,0)
var viewUp = Vector3(0,1,0)
var viewRight = Vector3(0,0,1)

var enemyPosition = Vector4(0,0,0,1)

var maxBoostSize = 1.5

var lookSpeed = 1.0

var shader_transformMatrix
var shader_position
var shader_orientation
var shader_fourvel
var shader_boost
var shader_iResolution
var shader_view2d
var shader_viewForward
var shader_viewUp
var shader_viewRight
var shader_enemyPosition

var time_scale = 1.0
var speedOfLight = 1.0
var retardation = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	surface_material = $CanvasLayer/ColorRect.get_material()
	
	shader_transformMatrix = StringName("transformMatrix")
	shader_fourvel = StringName("fourvel")
	shader_position = StringName("uposition")
	shader_boost = StringName("boost")
	shader_orientation = StringName("orientation")
	shader_iResolution = StringName("iResolution")
	shader_view2d = StringName("view2d")
	shader_viewForward = StringName("viewForward")
	shader_viewUp = StringName("viewUp")
	shader_viewRight = StringName("viewRight")
	shader_enemyPosition = StringName("enemyPosition")
	
	update_resolution()
	
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
		input_boost = input_boost / fourvel.w
		boost = lorentz(-input_boost * dt, c)
		transform_matrix = transform_matrix * boost
		fourvel = transform_matrix * Vector4(0,0,0,1)

	enemyPosition.y = 5*cos(uposition.w)
	enemyPosition.z = 5*sin(uposition.w)

	uposition += fourvel * dt
	
func update_shader_values() -> void:
	surface_material.set_shader_parameter(shader_position, uposition)
	surface_material.set_shader_parameter(shader_fourvel, fourvel)
	surface_material.set_shader_parameter(shader_orientation, orientation)
	surface_material.set_shader_parameter(shader_boost, boost)
	surface_material.set_shader_parameter(shader_transformMatrix, transform_matrix)
	surface_material.set_shader_parameter(shader_view2d, view2d)
	surface_material.set_shader_parameter(shader_viewForward, viewForward)
	surface_material.set_shader_parameter(shader_viewUp, viewUp)
	surface_material.set_shader_parameter(shader_viewRight, viewRight)
	surface_material.set_shader_parameter(shader_enemyPosition, enemyPosition)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("ToggleRetardation"):
		toggle_retardation()
	
	update_resolution()
	
	if is_instant_braking:
		instant_brake(delta)
	
	var c = cos(.1*delta)
	var s = sin(.1*delta)	
	orientation = Vector3(c*orientation.x-s*orientation.y,
	s*orientation.x+c*orientation.y,0);	
	
	var delta_scaled = delta
	
	if Input.is_action_pressed("SlowDown"):
		slow_down(delta)
	else:
		speed_up(delta)
	
	delta_scaled /= time_scale
	
	var boostBackForward = Input.get_axis("BoostBack", "BoostForward")
	var boostLeftRight = Input.get_axis("BoostLeft", "BoostRight")
	var boostUpDown = Input.get_axis("BoostDown", "BoostUp")
	var boostVector = boostBackForward * viewForward + boostLeftRight * viewRight +	boostUpDown * viewUp
	boostVector *= maxBoostSize
	
	if Input.is_action_just_pressed("InstantBrake"):
		instant_brake(delta_scaled);
	
	handle_physics(
		delta_scaled,
		Vector4(boostVector.x, boostVector.y, boostVector.z, 0.0),
		speedOfLight
	)
	
	viewForward += delta * lookSpeed * Input.get_axis("LookLeft", "LookRight") * viewRight
	viewForward += delta * lookSpeed * Input.get_axis("LookDown", "LookUp") * viewUp
	
	viewForward = viewForward.normalized()	
	
	viewUp = viewRight.cross(viewForward)
	viewUp = viewUp.normalized()
	viewRight = viewForward.cross(viewUp)
	
	var dutchAmount = delta * lookSpeed * Input.get_axis("DutchLeft", "DutchRight")
	var newRight = cos(dutchAmount) * viewRight - sin(dutchAmount) * viewUp
	var newUp = sin(dutchAmount) * viewRight + cos(dutchAmount) * viewUp
	viewRight = newRight
	viewUp = newUp
	
	update_shader_values()

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
		starting_matrix = transform_matrix
		starting_fourvel = fourvel
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
		transform_matrix = Projection(x,y,z,w)
		fourvel = starting_fourvel.lerp(Vector4(0,0,0,1), alpha)
	
func update_resolution():
	var resolution = Vector3(get_viewport().size.x, get_viewport().size.y, retardation)
	surface_material.set_shader_parameter(shader_iResolution, resolution)
