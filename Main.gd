extends Spatial


var current_world = null
var world_node = null
var player_node = null
var worlds = {
        1: preload("res://World1.tscn"),
        2: preload("res://World2.tscn"),
        3: preload("res://World3.tscn"),
    }
const MAX_WORLD = 3


func _ready():
    change_world(1)


func _input(event):
    if event is InputEventKey and event.is_pressed():
        if event.scancode == KEY_1: change_world(1)
        if event.scancode == KEY_2: change_world(2)
        if event.scancode == KEY_3: change_world(3)


func _process(delta):
    $FPS.text = "FPS: " + str(Engine.get_frames_per_second())  # TEMP!
    if Input.is_action_just_pressed("escape"): get_tree().quit()  # TEMP?
    
    $Title.text = "WORLD " + str(current_world) + "/" + str(MAX_WORLD)
    
    if Input.is_action_just_pressed("restart"): 
        change_world(current_world)
        
    if Input.is_action_just_pressed("previous") and current_world > 1:
        change_world(current_world - 1)
    
    if Input.is_action_just_pressed("next") and current_world < MAX_WORLD:
        change_world(current_world + 1)
        

func change_world(number):
    
    var wh = $WorldHolder
    var current = wh.get_child(0)
    if current != null:
        wh.remove_child(current)
        current.queue_free()
    world_node = worlds[number].instance()
    wh.add_child(world_node)
    current_world = number
    
    # Find player and set items.
    var items = []
    player_node = world_node.get_node("Player")
    for child in world_node.get_children():
        if child.get_script() and child.get_script().get_path().get_file() == "Item.gd":  # TODO: Is this the best way to do this?
            items.append(child.which)
    player_node.set_collectable_items(items)

