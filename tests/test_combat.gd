extends SceneTree

const Fighter=preload("res://scripts/fighter.gd")
const Data=preload("res://scripts/data.gd")
var failures: Array[String]=[]
var checks: int=0
var game: Node

func check(condition: bool,description: String) -> void:
	checks+=1
	if not condition:
		failures.append(description)
		push_error("FAIL: "+description)

func _initialize() -> void:
	run.call_deferred()

func fixture(a: int,b: int = 1,distance: float = 112) -> void:
	game.selected=a
	game.opponent=b
	game.mode=2
	game.start_match()
	game.intro=0
	game.fighters[0].x=400
	game.fighters[1].x=400+distance
	game.fighters[0].energy=100
	game.fighters[1].energy=100
	Input.action_release("p1_block")
	Input.action_release("p2_block")

func tick(seconds: float) -> void:
	for i in int(ceil(seconds*60)):
		game.battle(1.0/60.0)

func run() -> void:
	game=load("res://scripts/main.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.audio.set_process(false)
	game.audio.muted=true
	# Test moves through the actual combat controller, including collision and hit stop.
	check(Data.NAMES.size()>10,"expanded roster has more than ten fighters")
	check(Data.STAGES.size()==8,"eight arenas available")
	for kind in Data.NAMES.size():
		for move in 4:
			fixture(kind,(kind+1)%Data.NAMES.size())
			var defender=game.fighters[1]
			var old_hp:float=defender.hp
			check(game.fighters[0].attack(move),"move starts: %s / %s"%[kind,move])
			tick(1.2)
			check(defender.hp<old_hp,"move connects: %s / %s"%[kind,move])
			check(defender.hp>=0,"HP never negative")
	fixture(0,1,600)
	game.fighters[0].attack(0)
	tick(0.8)
	check(game.fighters[1].hp==Data.HP[1],"out-of-range bite misses")
	fixture(0,1)
	game.mode=1
	Input.action_press("p2_block")
	game.fighters[0].attack(0)
	tick(0.6)
	check(is_equal_approx(game.fighters[1].hp,Data.HP[1]-58*0.18),"block absorbs 82%")
	check(game.fighters[1].poison==0,"blocked bite does not poison")
	Input.action_release("p2_block")
	fixture(1,0)
	game.mode=1
	Input.action_press("p2_block")
	game.fighters[0].attack(0)
	tick(0.8)
	check(is_equal_approx(game.fighters[1].hp,Data.HP[0]-94),"cactus grab bypasses block")
	Input.action_release("p2_block")
	fixture(1,0)
	game.fighters[1].y=-140
	game.fighters[1].vy=-300
	game.fighters[0].attack(0)
	tick(0.5)
	check(game.fighters[1].hp==Data.HP[0],"airborne opponent escapes grab")
	fixture(0,1)
	game.fighters[0].energy=23
	check(not game.fighters[0].attack(1),"insufficient energy rejects fireball")
	check(game.fighters[0].energy==23,"rejected move costs nothing")
	var poisoned=Fighter.new(0)
	poisoned.poison=3
	for i in 180: poisoned.step(1.0/60.0,{},900,1550)
	check(absf(poisoned.hp-(1000-24))<0.01,"poison is exactly 24 over 3 seconds")
	check(poisoned.poison<0.001,"poison expires")
	var normal=Fighter.new(0)
	var lunar=Fighter.new(0)
	normal.step(0.01,{"jump":true},900,1550)
	lunar.step(0.01,{"jump":true},900,1100)
	for i in 30:
		normal.step(0.01,{},900,1550)
		lunar.step(0.01,{},900,1100)
	check(lunar.y<normal.y,"lunar jumps are higher")
	fixture(0,1,400)
	game.mode=1
	Input.action_press("p2_crouch")
	game.fighters[0].attack(1)
	tick(1.2)
	check(game.fighters[1].hp==Data.HP[1],"crouch evades high fireball")
	Input.action_release("p2_crouch")
	var leopard=Fighter.new(2)
	leopard.energy=100
	leopard.attack(1)
	check(leopard.hurtbox().size.y<150,"leopard morph has low hurtbox")
	fixture(0,1)
	game.mode=0
	game.fighters[1].hp=0
	game.battle(0.016)
	check(game.scores==[1,0],"KO awards a round")
	game.outro=0.001
	game.battle(0.016)
	check(game.round_number==2 and game.fighters[1].hp==Data.HP[1],"next round resets fighters")
	game.intro=0
	game.fighters[1].hp=0
	game.battle(0.016)
	check(game.match_over,"two wins end match")
	game.outro=0.001
	game.battle(0.016)
	check(game.screen=="result","match shows result screen")
	fixture(0,1)
	game.mode=0
	game.timer=0
	game.fighters[0].hp=500
	game.fighters[1].hp=575
	game.battle(0.016)
	check(game.winner==-1 and game.scores==[0,0],"equal normalized HP gives draw")
	fixture(1,0)
	game.fighters[0].attack(1)
	tick(1.2)
	check(game.fighters[1].hp<=Data.HP[0]-64,"multiple radial spikes connect")
	var armored=Fighter.new(1)
	armored.energy=100
	armored.attack(2)
	armored.elapsed=0.4
	armored.receive(58,1)
	check(armored.action==2 and armored.stun==0,"cactus armor preserves active ram")
	check(armored.hp==Data.HP[1]-58,"armor does not prevent damage")
	var guarded=Fighter.new(0)
	guarded.block=true
	guarded.energy=0
	var break_result=guarded.receive(58,1)
	check(break_result.broken and guarded.hp==942,"empty guard breaks with full damage")
	check(guarded.stun==0.65,"guard break applies long stun")
	fixture(0,1)
	game.fighters[1].hp=500
	game.fighters[0].energy=0
	tick(2.1)
	check(game.fighters[1].hp==Data.HP[1] and game.fighters[0].energy==100,"training restores HP and energy")
	fixture(0,1)
	game.fighters[0].attack(0)
	tick(0.25)
	check(game.fighters[0].did_hit,"normal confirms hit")
	check(game.fighters[0].attack(2),"normal cancels into special")
	tick(0.8)
	check(game.fighters[0].combo>=2,"cancel creates visible combo")
	# Run an entire real CPU match with a simple automated sparring partner.
	fixture(2,1,420)
	game.mode=0
	game.difficulty=2
	game.rng.seed=9001
	var cpu_did_damage=false
	for i in 22000:
		if game.screen=="result": break
		var a=game.fighters[0]
		var b=game.fighters[1]
		var gap=absf(a.x-b.x)
		if gap>140: Input.action_press("p1_right")
		else: Input.action_release("p1_right")
		if i%22==0: a.attack(3 if a.energy>=100 else 0 if gap<150 else 1)
		game.battle(1.0/60)
		if a.hp<Data.HP[a.kind]: cpu_did_damage=true
	Input.action_release("p1_right")
	check(cpu_did_damage,"CPU attacks and damages player")
	check(game.screen=="result","full CPU match reaches winner screen")
	# Real human input can arrive and be released while the combat clock is frozen.
	fixture(0,1)
	game.hitstop=0.065
	var key=InputEventKey.new()
	key.physical_keycode=KEY_K
	key.pressed=true
	game._input(key)
	key.pressed=false
	game._input(key)
	tick(0.16)
	check(game.fighters[0].action==1,"cobra keeps a special pressed during hit stop")
	fixture(0,1)
	game.fighters[0].energy=0
	check(not game.fighters[0].attack(1),"exhausted cobra cannot spend energy")
	check(game.fighters[0].feedback_time>0,"insufficient energy has visible feedback")
	check(game.fighters[0].attack(0),"exhausted cobra can still bite")
	tick(0.8)
	check(game.fighters[0].action==-1,"cobra always exits attack recovery")
	fixture(0,1,400)
	game.fighters[0].stun=0.15
	game.fighters[0].attack(1)
	tick(0.3)
	check(game.fighters[0].action==1,"cobra keeps input buffered during stun")
	fixture(0,1,400)
	Input.action_press("p1_0")
	for i in 180: game.battle(1.0/60)
	Input.action_release("p1_0")
	check(game.fighters[0].name_time>0,"holding J continues normal attacks")
	var slowed=Fighter.new(4)
	slowed.receive(30,1,false,false,false,1.5)
	slowed.stun=0
	var before_x=slowed.x
	slowed.step(0.1,{"axis":1},900,1550)
	check(slowed.x-before_x<Data.SPEED[4]*0.1,"frost reduces movement speed")
	for i in 20: slowed.step(0.1,{},900,1550)
	check(slowed.slow_time==0,"slow effect expires")
	for page in ceili(Data.NAMES.size()/3.0):
		game.roster_page=page
		game.activate("roster_next")
		check(game.roster_page==(page+1)%4,"roster pages wrap")
	game.stage=Data.STAGES.size()-1
	game.activate("stage_next")
	check(game.stage==0,"all arenas wrap back to island")
	print("COMBAT TESTS: ",checks-failures.size(),"/",checks," passed")
	game.queue_free()
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
