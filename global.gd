extends Node

class Sim:
	var uposition : Vector4 = Vector4(0,0,0,0)
	var fourvel : Vector4 = Vector4(0,0,0,1)
	var transform_matrix : Projection = Projection.IDENTITY

class View:
	var projectionDistance : float = 1.0
	var Forward : Vector3 = Vector3(1,0,0)
	var Up : Vector3 = Vector3(0,1,0)
	var Right : Vector3 = Vector3(0,0,1)

class Gameplay:
	var enemyPosition : Vector4 = Vector4.ZERO
