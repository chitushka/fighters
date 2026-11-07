extends RefCounted

const Data = preload("res://scripts/data.gd")
var kind: int = 0
var x: float = 360.0
var y: float = 0.0
var vy: float = 0.0
var facing: float = 1.0
var hp: float = 1000.0
var energy: float = 35.0
var action: int = -1
var elapsed: float = 0.0
var move: Dictionary = {}
var did_hit: bool = false
var emitted: bool = false
var block: bool = false
var crouch: bool = false
var stun: float = 0.0
var invincible: float = 0.0
var poison: float = 0.0
var flash: float = 0.0
var combo: int = 0
var combo_damage: float = 0.0
var combo_time: float = 0.0
var last_name: String = ""
var name_time: float = 0.0
var walk: float = 0.0
var buffer: int = -1
var buffer_time: float = 0.0
var slow_time: float = 0.0
var feedback: String = ""
var feedback_time: float = 0.0

func _init(character: int = 0, start_x: float = 360.0) -> void:
	kind = character
	x = start_x
	hp = Data.HP[kind]

func active() -> bool:
	return action >= 0 and elapsed >= move.startup and elapsed < move.startup + move.active

func progress() -> float:
	if action < 0: return 0.0
	return elapsed / (move.startup + move.active + move.recovery)

func attack(which: int) -> bool:
	if hp <= 0: return false
	if stun > 0:
		buffer=which
		buffer_time=0.28
		return false
	if action >= 0:
		# On-hit special cancel: a confirmed normal may flow into a special.
		if not (action == 0 and did_hit and which > 0 and elapsed >= move.startup):
			buffer = which
			buffer_time = 0.20
			return false
	var spec: Dictionary = Data.MOVES[kind][which]
	if energy < spec.cost:
		feedback="НУЖНО "+str(int(spec.cost))+" ЭНЕРГИИ • J БЕСПЛАТНО"
		feedback_time=1.2
		return false
	buffer=-1
	buffer_time=0
	energy -= spec.cost
	action = which
	elapsed = 0
	move = spec
	did_hit = false
	emitted = false
	block = false
	last_name = spec.name
	name_time = 1.7
	if which == 2 and y >= -1:
		if kind==0: vy=-350
		elif kind==2: vy=-440
		elif move.has("jump"): vy=move.jump
	if which == 3: invincible = 0.25
	return true

func step(dt: float, cmd: Dictionary, enemy_x: float, gravity: float) -> void:
	flash = maxf(0, flash-dt*5)
	stun = maxf(0,stun-dt)
	invincible = maxf(0,invincible-dt)
	name_time = maxf(0,name_time-dt)
	combo_time = maxf(0,combo_time-dt)
	buffer_time = maxf(0,buffer_time-dt)
	slow_time=maxf(0,slow_time-dt)
	feedback_time=maxf(0,feedback_time-dt)
	if combo_time <= 0:
		combo=0
		combo_damage=0
	if hp <= 0:
		block=false
		action=-1
	else:
		energy=minf(100,energy+dt*8)
		if poison>0:
			var tick=minf(dt,poison)
			poison=maxf(0,poison-dt)
			hp=maxf(0,hp-tick*8)
		if action < 0 and stun <= 0:
			facing = 1.0 if enemy_x > x else -1.0
			block=cmd.get("block",false) and y >= -1
			crouch=cmd.get("crouch",false) and y >= -1
			walk=float(cmd.get("axis",0)) if not block and not crouch else 0.0
			x += walk*Data.SPEED[kind]*dt*(0.55 if slow_time>0 else 1.0)
			if cmd.get("jump",false) and y>=-1 and not block:
				vy=-610
		else:
			block=false
			walk=0.0
		var request: int=cmd.get("attack",-1)
		if request<0 and action<0 and stun<=0 and buffer_time>0:
			request=buffer
			buffer=-1
		if request>=0: attack(request)
		if action>=0:
			elapsed+=dt
			if active() and move.has("dash"):
				x+=facing*move.dash*dt
			if elapsed>=move.startup+move.active+move.recovery:
				action=-1
				if buffer_time>0 and buffer>=0:
					var queued=buffer
					buffer=-1
					attack(queued)
	if y<0 or vy<0:
		vy+=gravity*dt
		y+=vy*dt
		if y>=0:
			y=0
			vy=0
	x=clampf(x,100,1180)

func hurtbox() -> Rect2:
	if crouch or (kind==2 and (action==1 or action==3)):
		return Rect2(x-43,448+y,86,116)
	return Rect2(x-39,354+y,78,210)

func receive(damage: float, dir: float, grab: bool = false, toxic: bool = false, radial: bool = false, slow: float = 0.0) -> Dictionary:
	if hp<=0 or (invincible>0 and not radial): return {"hit":false}
	var guarded=block and not grab
	var broken=false
	if guarded:
		energy-=14
		if energy<0:
			energy=0
			guarded=false
			broken=true
	var dealt=damage*(0.18 if guarded else 1.0)
	hp=maxf(0,hp-dealt)
	flash=0.4 if guarded else 1.0
	energy=minf(100,energy+(3 if guarded else 7))
	var armor=action>=0 and active() and ((kind==1 and action==2) or move.get("armor",false))
	stun=0.10 if guarded else (0.65 if broken else 0.24)
	if armor: stun=0
	invincible=0.13
	x=clampf(x+dir*(12 if guarded else 25),100,1180)
	if not guarded:
		if not armor: action=-1
		if toxic: poison=3.0
		if slow>0: slow_time=slow
	return {"hit":true,"guarded":guarded,"damage":dealt,"broken":broken}
