extends SceneTree
var game:Node
var controls:Node
var checks:int=0
var failures:int=0

func check(ok:bool,name:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("FAIL: "+name)

func touch(index:int,at:Vector2,pressed:bool=true,canceled:bool=false) -> void:
	var event=InputEventScreenTouch.new()
	event.index=index
	event.position=at
	event.pressed=pressed
	event.canceled=canceled
	controls._input(event)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	game=load("res://scripts/main.gd").new()
	game.mobile=true
	root.add_child(game)
	game.set_process(false)
	game.audio.muted=true
	game.audio.set_process(false)
	controls=game.touch_controls
	controls.set_process(false)
	game.selected=0
	game.opponent=1
	game.mode=2
	game.start_match()
	game.intro=0
	touch(1,Vector2(172,640))
	check(Input.is_action_pressed("p1_right"),"joystick moves right")
	touch(2,Vector2(979,616))
	check(Input.is_action_pressed("p1_right") and Input.is_action_pressed("p1_0"),"movement and attack work simultaneously")
	game.battle(0.016)
	check(game.fighters[0].action==0,"touch starts cobra bite")
	touch(2,Vector2(979,616),false)
	check(Input.is_action_pressed("p1_right") and not Input.is_action_pressed("p1_0"),"releasing attack keeps movement")
	touch(1,Vector2(172,640),false)
	check(not Input.is_action_pressed("p1_right"),"releasing joystick stops movement")
	touch(3,Vector2(267,616))
	check(game.pending_jumps[0],"jump button queues jump")
	touch(3,Vector2(267,616),false)
	game.new_round()
	game.intro=0
	touch(1,Vector2(116,640))
	var drag=InputEventScreenDrag.new()
	drag.index=1
	drag.position=Vector2(116,687)
	controls._input(drag)
	check(Input.is_action_pressed("p1_crouch"),"dragging joystick down crouches")
	drag.position=Vector2(116,590)
	controls._input(drag)
	check(game.pending_jumps[0],"dragging joystick up jumps")
	touch(1,Vector2.ZERO,true,true)
	check(controls.fingers.is_empty() and controls.owned_actions.is_empty(),"canceled touch releases owned actions")
	touch(4,Vector2(865,663))
	check(Input.is_action_pressed("p1_block"),"block can be held")
	touch(5,Vector2(640,150))
	check(game.screen=="pause" and not Input.is_action_pressed("p1_block"),"pause releases held block")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.screen=="battle","Android back resumes pause")
	touch(6,Vector2(719,150))
	check(game.screen=="guide" and game.back_screen=="pause","touch opens move guide safely")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.screen=="pause","Android back leaves guide")
	game.screen="battle"
	touch(1,Vector2(62,640))
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.screen=="pause" and controls.fingers.is_empty(),"app backgrounding pauses and releases all touches")
	game.screen="menu"
	game.buttons=[{"id":"start","rect":Rect2(981,650,247,44)}]
	touch(8,Vector2(1090,670))
	check(game.screen=="battle","menu works with touch and no mouse emulation")
	print("TOUCH TESTS: ",checks-failures,"/",checks," passed")
	game.queue_free()
	await create_timer(0.15).timeout
	quit(0 if failures==0 else 1)
