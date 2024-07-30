extends PanelContainer

@onready var property_container: VBoxContainer = %VBoxContainer

var property
var frames_per_second : String
#Called when node enters scene tree for first time.
func _ready():
	# Hide Debug Panel on load
	visible = false
	add_debug_property("FPS",frames_per_second)
	
func _process(delta: float) -> void:
	if visible:
		frames_per_second = "%.2f" % (1.0/delta) # gets fps every frame
		property.text = property.name + ": " + frames_per_second

func _input(event):
	#Toggle debug panel
	if event.is_action_pressed("debug"):
		visible = !visible

#Callable function to add new debug property
func add_debug_property(title : String,value):
	property = Label.new() #Create new label node
	property_container.add_child(property) # Add new node as child to VBox container
	property.name = title #Set name to title
	property.text = property.name + value
