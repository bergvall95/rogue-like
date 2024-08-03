extends Area3D

var target = null
var speed = -1   # created bounce away effect before coin comes to player

@onready var speed_juice: Node3D = $SpeedJuice
@onready var collision = $CollisionShape3D
@onready var sound = $snd_collected


func _ready():
	pass

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2*delta   # increases movement speed towards player

func collect():
	collision.call_deferred("set", "disabled",true)
	speed_juice.visible = false   # removes gem visually only so sound can fully play out.
	


func _on_snd_collected_finished():
	queue_free()   # actually deletes coin
