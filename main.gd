extends Node3D
var player
var enemies=[]
var hp=100
var ammo=30
var kills=0
var zone_radius=280.0
var elapsed=0.0
var status_label
var hp_bar
var ammo_label
func _ready():
    _build_world(); _spawn_player()
    for i in range(10): _spawn_enemy(i)
    _build_ui(); status_label.text="MATCH STARTED — Eliminate all enemies"
func _process(delta):
    elapsed += delta; _update_player(delta); _update_enemies(delta); _update_zone(delta); _update_ui()
func _build_world():
    var ground=MeshInstance3D.new(); var mesh=PlaneMesh.new(); mesh.size=Vector2(900,900); ground.mesh=mesh
    var mat=StandardMaterial3D.new(); mat.albedo_color=Color(0.12,0.24,0.12); ground.material_override=mat; add_child(ground)
    for i in range(30):
        var tree=MeshInstance3D.new(); var cm=CylinderMesh.new(); cm.top_radius=0.35; cm.bottom_radius=0.55; cm.height=5.0; tree.mesh=cm
        tree.position=Vector3(randf_range(-400,400),2.5,randf_range(-400,400)); var tm=StandardMaterial3D.new(); tm.albedo_color=Color(0.18,0.09,0.03); tree.material_override=tm; add_child(tree)
func _spawn_player():
    player=CharacterBody3D.new(); player.position=Vector3(0,1,0)
    var body=MeshInstance3D.new(); var cap=CapsuleMesh.new(); cap.radius=0.55; cap.height=1.8; body.mesh=cap
    var mat=StandardMaterial3D.new(); mat.albedo_color=Color(0.1,0.45,0.9); body.material_override=mat; player.add_child(body); add_child(player)
    var cam=Camera3D.new(); cam.position=Vector3(0,4,7); cam.rotation_degrees=Vector3(-18,180,0); player.add_child(cam); cam.current=true
func _spawn_enemy(i):
    var e=CharacterBody3D.new(); e.position=Vector3(randf_range(-250,250),1,randf_range(-250,250))
    var body=MeshInstance3D.new(); var cap=CapsuleMesh.new(); cap.radius=0.5; cap.height=1.7; body.mesh=cap
    var mat=StandardMaterial3D.new(); mat.albedo_color=Color(0.8,0.12,0.12); body.material_override=mat; e.add_child(body); add_child(e)
    enemies.append({"node":e,"hp":100.0,"cooldown":randf_range(0,2)})
func _update_player(delta):
    var dir=Vector3.ZERO
    if Input.is_action_pressed("move_left"): dir.x-=1
    if Input.is_action_pressed("move_right"): dir.x+=1
    if Input.is_action_pressed("move_forward"): dir.z-=1
    if Input.is_action_pressed("move_back"): dir.z+=1
    if dir.length()>0:
        dir=dir.normalized(); var speed=10.0 if Input.is_action_pressed("sprint") else 6.0; player.velocity.x=dir.x*speed; player.velocity.z=dir.z*speed; player.move_and_slide()
    if Input.is_action_just_pressed("shoot") and ammo>0: _shoot()
func _shoot():
    ammo-=1; var origin=player.global_position+Vector3(0,1,0); var nearest=null; var best=9999.0
    for e in enemies:
        if is_instance_valid(e.node):
            var d=origin.distance_to(e.node.global_position)
            if d<best: best=d; nearest=e
    if nearest and best<45:
        nearest.hp-=35
        if nearest.hp<=0: nearest.node.queue_free(); kills+=1
func _update_enemies(delta):
    for e in enemies:
        if not is_instance_valid(e.node): continue
        var d=player.global_position-e.node.global_position
        if d.length()>3: e.node.velocity=d.normalized()*2.0; e.node.move_and_slide()
        e.cooldown-=delta
        if e.cooldown<=0 and d.length()<25: hp=max(0,hp-5); e.cooldown=1.2
func _update_zone(delta):
    zone_radius=max(45.0,280.0-elapsed*1.2)
    if player.global_position.length()>zone_radius: hp=max(0,hp-int(10*delta))
    var alive=0
    for e in enemies:
        if is_instance_valid(e.node): alive+=1
    if hp<=0: status_label.text="YOU ARE ELIMINATED"; set_process(false)
    elif alive==0: status_label.text="VICTORY! — All enemies eliminated"; set_process(false)
func _build_ui():
    var layer=CanvasLayer.new(); add_child(layer)
    status_label=Label.new(); status_label.position=Vector2(30,25); status_label.add_theme_font_size_override("font_size",26); layer.add_child(status_label)
    hp_bar=ProgressBar.new(); hp_bar.position=Vector2(30,70); hp_bar.size=Vector2(260,28); hp_bar.max_value=100; layer.add_child(hp_bar)
    ammo_label=Label.new(); ammo_label.position=Vector2(30,110); ammo_label.add_theme_font_size_override("font_size",22); layer.add_child(ammo_label)
    var help=Label.new(); help.text="WASD: Move   SHIFT: Sprint   Mouse: Shoot"; help.position=Vector2(30,650); help.add_theme_font_size_override("font_size",18); layer.add_child(help)
func _update_ui():
    hp_bar.value=hp; ammo_label.text="AMMO: %02d     KILLS: %02d     SAFE ZONE: %dm" % [ammo,kills,int(zone_radius)]
