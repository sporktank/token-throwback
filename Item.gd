tool
extends Area


const ALL = ["Turkey", "Soup", "Pizza", "Steak", "Noodles", "Milk"]
export(String, "Turkey", "Soup", "Pizza", "Steak", "Noodles", "Milk") var which = "Turkey"

var picked_up = false


func _ready():
    # Editor only stuff..
    if Engine.is_editor_hint():
        return
    # .
    
    for np in ALL:
        get_node(np).visible = np == which


func _process(delta):
    # Editor only stuff..
    if Engine.is_editor_hint():
        for np in ALL:
            get_node(np).visible = np == which
        return
    # .    

    rotation_degrees.y += 90.0 * delta
        

func _on_Item_body_entered(body):
    if picked_up:
        return
    picked_up = body.try_pickup_item(self)
