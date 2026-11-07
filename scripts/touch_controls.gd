extends Node2D
## Finger ownership allows moving, blocking and attacking simultaneously.
const CENTER=Vector2(116,640)
const BUTTONS=[
	["jump",Vector2(267,616),36.0,"ПРЫЖОК"],
	["block",Vector2(865,663),34.0,"БЛОК"],
	["attack0",Vector2(979,616),39.0,"УДАР"],
	["attack1",Vector2(1085,616),37.0,"ДАЛЬНИЙ"],
	["attack2",Vector2(1191,616),37.0,"ОСОБЫЙ"],
	["attack3",Vector2(1090,686),29.0,"УЛЬТА"]
]
var game:Node
var fingers:Dictionary={}
var owned_actions:Dictionary={}
var stick_up:bool=false

func _ready() -> void:
	game=get_parent()

func clear() -> void:
	fingers.clear()
	stick_up=false
	for action in owned_actions: Input.action_release(action)
	owned_actions.clear()

func _process(_dt:float) -> void:
	if game.screen!="battle" or game.intro>0 or game.outro>0: clear()
	queue_redraw()

func menu_tap(at:Vector2) -> void:
	var best:Dictionary={}
	var distance=INF
	for button in game.buttons:
		var r:Rect2=button.rect
		var size=r.size.max(Vector2(48,48))
		if Rect2(r.get_center()-size*0.5,size).has_point(at):
			var d=at.distance_squared_to(r.get_center())
			if d<distance:
				best=button
				distance=d
	if not best.is_empty(): game.activate(best.id)

func _input(event:InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			fingers.erase(event.index)
			sync_actions()
		elif game.screen!="battle": menu_tap(event.position)
		elif Rect2(606,132,68,39).has_point(event.position):
			game.screen="pause"
			clear()
		elif Rect2(685,132,68,39).has_point(event.position):
			game.back_screen="pause"
			game.guide_page=game.selected
			game.screen="guide"
			clear()
		elif game.intro<=0 and game.outro<=0:
			var control=""
			if event.position.distance_to(CENTER)<91 and not fingers.values().any(func(f): return f.id=="stick"):
				control="stick"
			for b in BUTTONS:
				if event.position.distance_to(b[1])<=b[2]+8: control=b[0]
			if control!="":
				fingers[event.index]={"id":control,"p":event.position}
				if control.begins_with("attack"):
					game.pending_attacks[0]=int(control.trim_prefix("attack"))
					game.pending_until[0]=game.time+0.25
				if control=="jump": game.pending_jumps[0]=true
				sync_actions()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		fingers[event.index].p=event.position
		sync_actions()
		get_viewport().set_input_as_handled()

func sync_actions() -> void:
	var wanted:Dictionary={}
	var up=false
	for f in fingers.values():
		if f.id=="stick":
			var delta:Vector2=(f.p-CENTER)/58.0
			if delta.x < -0.18: wanted.p1_left=clampf(-delta.x,0,1)
			if delta.x > 0.18: wanted.p1_right=clampf(delta.x,0,1)
			if delta.y>0.60: wanted.p1_crouch=1.0
			up=delta.y < -0.65
		elif f.id=="block": wanted.p1_block=1.0
		elif f.id=="attack0": wanted.p1_0=1.0
	if up and not stick_up: game.pending_jumps[0]=true
	stick_up=up
	for action in owned_actions:
		if not wanted.has(action): Input.action_release(action)
	for action in wanted: Input.action_press(action,wanted[action])
	owned_actions=wanted

func label(s:String,at:Vector2,size:int,col:Color) -> void:
	var width=game.font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(game.font,at-Vector2(width/2,0),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)

func _draw() -> void:
	if not is_instance_valid(game) or game.screen!="battle": return
	var white=Color("eee9dd")
	var gold=Color("e5bf76")
	var bg=Color(0.035,0.065,0.09,0.82)
	for b in [[Rect2(606,132,68,39),"Ⅱ"],[Rect2(685,132,68,39),"?"]]:
		draw_rect(b[0],bg)
		draw_rect(b[0],Color(0.8,0.8,0.7,0.4),false,1)
		label(b[1],b[0].get_center()+Vector2(0,8),24,white)
	draw_circle(CENTER,65,bg)
	draw_arc(CENTER,65,0,TAU,48,Color(0.8,0.85,0.9,0.4),2,true)
	for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		draw_line(CENTER+d*38,CENTER+d*48,white,3,true)
	var knob=CENTER
	for f in fingers.values():
		if f.id=="stick": knob+=(f.p-CENTER).limit_length(46)
	draw_circle(knob,23,Color(0.78,0.83,0.85,0.65))
	label("ДВИЖЕНИЕ",Vector2(116,718),11,white)
	for b in BUTTONS:
		var pressed=fingers.values().any(func(f): return f.id==b[0])
		var ready=b[0]!="attack3" or (not game.fighters.is_empty() and game.fighters[0].energy>=100)
		var col=gold if ready else Color("788894")
		draw_circle(b[1],b[2],bg if not pressed else Color(0.5,0.4,0.2,0.8))
		draw_arc(b[1],b[2],0,TAU,36,col,2 if pressed else 1,true)
		label(b[3],b[1]+Vector2(0,5),11 if b[0]=="attack3" else 12,col)
		if b[0]=="attack3": label("100",b[1]+Vector2(0,19),9,col)

func _exit_tree() -> void:
	clear()
