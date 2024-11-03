extends MeshInstance3D

var material

var orientation = Vector3(1.0, 0.0, 0.0)
var uposition = Vector4.ZERO
var fourvel = Vector4(0,0,0,1)
var boost = Vector4.ZERO
var transform_matrix = Projection.IDENTITY

var shader_transformMatrix
var shader_position
var shader_orientation
var shader_fourvel
var shader_boost
var shader_iResolution
var shader_iMouse
var shader_iTimeDelta

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material = get_active_material(0)
	
	shader_transformMatrix = StringName("transformMatrix")
	shader_fourvel = StringName("fourvel")
	shader_position = StringName("uposition")
	shader_boost = StringName("boost")
	shader_orientation = StringName("orientation")
	shader_iResolution = StringName("iResolution")
	shader_iMouse = StringName("iMouse")
	shader_iTimeDelta = StringName("iTimeDelta")
	
	#var resolution = Vector3(get_viewport().size.x, get_viewport().size.y, 1.0)
	var resolution = Vector3(1000, 1000, 1.0)
	material.set_shader_parameter(shader_iResolution, resolution)
	
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
		boost = lorentz(-boost * dt, c)
		var new_transform_matrix = transform_matrix * boost
		fourvel = new_transform_matrix * Vector4(0,0,0,1)		
		transform_matrix = new_transform_matrix

	uposition += fourvel * dt
	
func update_shader_values() -> void:
	material.set_shader_parameter(shader_position, uposition)
	material.set_shader_parameter(shader_fourvel, fourvel)
	material.set_shader_parameter(shader_orientation, orientation)
	material.set_shader_parameter(shader_boost, boost)
	material.set_shader_parameter(shader_transformMatrix, transform_matrix)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	handle_physics(delta, Vector4.ZERO, 1.0)
	
	update_shader_values()
