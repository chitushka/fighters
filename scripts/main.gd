extends Node2D

const Data = preload("res://scripts/data.gd")
const Art = preload("res://scripts/art.gd")
const Fighter = preload("res://scripts/fighter.gd")
const Sound = preload("res://scripts/sound.gd")
const GOLD = Color("e5bf76")
const WHITE = Color("f3eee2")
const MUTED = Color("9aa8ae")
const ORANGE = Color("ef7950")
var font: Font
var bold: Font
var audio: Node
var screen: String = "menu"
var back_screen: String = "menu"
var selected: int = 0
var opponent: int = 1
var stage: int = 0
var mode: int = 0
var difficulty: int = 1
var guide_page: int = 0
var time: float = 0.0
var fighters: Array = []
var projectiles: Array = []
var particles: Array = []
var labels: Array = []
var slashes: Array = []
var buttons: Array = []
var mouse: Vector2
var scores: Array = [0,0]
var round_number: int = 1
var timer: float = 75.0
var intro: float = 3.0
var outro: float = 0.0
var winner: int = -1
var match_over: bool = false
var hitstop: float = 0.0
var shake: float = 0.0
var ai_time: float = 0.0
var ai_cmd: Dictionary = {}
var training_reset: float = 0.0
var capture_frames: int = 0
var rng = RandomNumberGenerator.new()
var config = ConfigFile.new()
var pending_attacks: Array = [-1,-1]
var pending_until: Array = [0.0,0.0]
var pending_jumps: Array = [false,false]
var roster_page: int = 0

func _ready() -> void:
	font=ThemeDB.fallback_font
	var custom=SystemFont.new()
	custom.font_names=PackedStringArray(["Bahnschrift","Arial"])
	custom.font_weight=700
	bold=custom
	rng.randomize()
	audio=Sound.new()
	add_child(audio)
	setup_input()
	load_settings()
	roster_page=selected/3 as int
	get_window().title="ДИКИЙ ИНСТИНКТ • WILD INSTINCT"
	if "--smoke" in OS.get_cmdline_user_args():
		start_match()
		intro=0
	if "--capture-battle" in OS.get_cmdline_user_args():
		start_match()
		intro=0
		fighters[0].energy=100
		fighters[1].energy=78
		fighters[0].x=435
		fighters[1].x=845
	queue_redraw()

func setup_input() -> void:
	var mapping={
		"p1_left":[KEY_A],"p1_right":[KEY_D],"p1_jump":[KEY_W],"p1_crouch":[KEY_S],
		"p1_block":[KEY_SPACE],"p1_0":[KEY_J],"p1_1":[KEY_K],"p1_2":[KEY_L],"p1_3":[KEY_I],
		"p2_left":[KEY_LEFT],"p2_right":[KEY_RIGHT],"p2_jump":[KEY_UP],"p2_crouch":[KEY_DOWN],
		"p2_block":[KEY_0,KEY_KP_0],"p2_0":[KEY_1,KEY_KP_1],"p2_1":[KEY_2,KEY_KP_2],"p2_2":[KEY_3,KEY_KP_3],"p2_3":[KEY_4,KEY_KP_4]
	}
	for action in mapping:
		InputMap.add_action(action)
		for key in mapping[action]:
			var event=InputEventKey.new()
			event.physical_keycode=key
			InputMap.action_add_event(action,event)

func load_settings() -> void:
	if "--script" in OS.get_cmdline_args(): return
	if config.load("user://settings.cfg")==OK:
		selected=clampi(config.get_value("game","fighter",0),0,Data.NAMES.size()-1)
		opponent=clampi(config.get_value("game","opponent",1),0,Data.NAMES.size()-1)
		stage=clampi(config.get_value("game","stage",0),0,Data.STAGES.size()-1)
		difficulty=clampi(config.get_value("game","difficulty",1),0,2)
		audio.muted=config.get_value("game","muted",false)

func save_settings() -> void:
	if "--script" in OS.get_cmdline_args(): return
	config.set_value("game","fighter",selected)
	config.set_value("game","opponent",opponent)
	config.set_value("game","stage",stage)
	config.set_value("game","difficulty",difficulty)
	config.set_value("game","muted",audio.muted)
	config.save("user://settings.cfg")

func _input(event: InputEvent) -> void:
	if screen=="battle" and intro<=0 and outro<=0:
		for player in 2:
			var prefix="p"+str(player+1)+"_"
			for i in 4:
				if event.is_action_pressed(prefix+str(i)):
					pending_attacks[player]=i
					pending_until[player]=time+0.25
			if event.is_action_pressed(prefix+"jump"): pending_jumps[player]=true
	if event is InputEventMouseMotion:
		mouse=get_global_mouse_position()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		mouse=get_global_mouse_position()
		for b in buttons:
			if b.rect.has_point(mouse):
				activate(b.id)
				break
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F11:
				var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_M:
				audio.toggle()
				save_settings()
			KEY_F1:
				if screen=="guide": screen=back_screen
				else:
					back_screen="pause" if screen=="battle" else screen
					guide_page=selected
					screen="guide"
			KEY_ESCAPE:
				if screen=="battle": screen="pause"
				elif screen=="pause": screen="battle"
				elif screen=="guide": screen=back_screen
				elif screen=="result": screen="menu"
			KEY_ENTER:
				if screen=="menu": start_match()
				elif screen=="pause": screen="battle"
				elif screen=="result": start_match()
			KEY_R:
				if screen=="battle" and mode==2: new_round()
			KEY_LEFT:
				if screen=="menu":
					selected=posmod(selected-1,Data.NAMES.size())
					roster_page=selected/3 as int
			KEY_RIGHT:
				if screen=="menu":
					selected=(selected+1)%Data.NAMES.size()
					roster_page=selected/3 as int
	queue_redraw()

func activate(id: String) -> void:
	audio.play("select")
	if id.begins_with("fighter_"): selected=int(id.trim_prefix("fighter_"))
	elif id.begins_with("mode_"): mode=int(id.trim_prefix("mode_"))
	elif id.begins_with("guide_"): guide_page=int(id.trim_prefix("guide_"))
	else:
		match id:
			"roster_prev":
				roster_page=posmod(roster_page-1,ceili(Data.NAMES.size()/3.0))
				selected=roster_page*3
			"roster_next":
				roster_page=(roster_page+1)%ceili(Data.NAMES.size()/3.0)
				selected=roster_page*3
			"guide_prev": guide_page=posmod(guide_page-1,Data.NAMES.size())
			"guide_next": guide_page=(guide_page+1)%Data.NAMES.size()
			"stage_prev": stage=posmod(stage-1,Data.STAGES.size())
			"stage_next": stage=(stage+1)%Data.STAGES.size()
			"enemy": opponent=(opponent+1)%Data.NAMES.size()
			"enemy_prev": opponent=posmod(opponent-1,Data.NAMES.size())
			"difficulty": difficulty=(difficulty+1)%3
			"start","rematch": start_match()
			"guide":
				back_screen=screen
				guide_page=selected
				screen="guide"
			"back": screen=back_screen
			"menu":
				screen="menu"
				audio.in_battle=false
			"resume": screen="battle"
			"sound":
				audio.toggle()
				save_settings()

func start_match() -> void:
	scores=[0,0]
	round_number=1
	match_over=false
	winner=-1
	screen="battle"
	audio.in_battle=true
	save_settings()
	new_round()

func new_round() -> void:
	fighters=[Fighter.new(selected,350),Fighter.new(opponent,930)]
	fighters[1].facing=-1
	projectiles.clear()
	particles.clear()
	labels.clear()
	slashes.clear()
	timer=75
	intro=2.8
	outro=0
	winner=-1
	ai_time=0
	ai_cmd={}
	hitstop=0
	training_reset=0
	pending_attacks=[-1,-1]
	pending_until=[0.0,0.0]
	pending_jumps=[false,false]
	audio.play("gong")

func human(prefix: String) -> Dictionary:
	var player=0 if prefix=="p1_" else 1
	var cmd={"axis":Input.get_axis(prefix+"left",prefix+"right"),"jump":Input.is_action_just_pressed(prefix+"jump"),"crouch":Input.is_action_pressed(prefix+"crouch"),"block":Input.is_action_pressed(prefix+"block"),"attack":-1}
	for i in 4:
		if Input.is_action_just_pressed(prefix+str(i)): cmd.attack=i
	if pending_attacks[player]>=0 and pending_until[player]>=time:
		cmd.attack=pending_attacks[player]
	elif cmd.attack<0 and Input.is_action_pressed(prefix+"0"):
		cmd.attack=0
	pending_attacks[player]=-1
	cmd.jump=cmd.jump or pending_jumps[player]
	pending_jumps[player]=false
	return cmd

func cpu(dt: float) -> Dictionary:
	if mode==2: return {"axis":0,"attack":-1}
	ai_time-=dt
	var a=fighters[1]
	var b=fighters[0]
	var dist=absf(a.x-b.x)
	if ai_time<=0:
		ai_time=[0.42,0.25,0.14][difficulty]+rng.randf_range(0,0.14)
		ai_cmd={"axis":0,"block":false,"attack":-1,"jump":false}
		var danger=b.action>=0 or projectiles.any(func(p): return p.owner==0)
		if danger and rng.randf()<[0.22,0.49,0.72][difficulty]:
			ai_cmd.block=true
			if dist>230 and rng.randf()<0.35: ai_cmd.jump=true
		elif dist>190:
			ai_cmd.axis=signf(b.x-a.x)
			if dist<650 and rng.randf()<0.45: ai_cmd.attack=1 if rng.randf()<0.65 else 2
			if rng.randf()<0.08: ai_cmd.jump=true
		else:
			ai_cmd.axis=signf(b.x-a.x) if dist>126 else 0
			ai_cmd.attack=0 if rng.randf()<0.65 else 2
			if a.energy>=100 and rng.randf()<0.55: ai_cmd.attack=3
			if rng.randf()<0.14: ai_cmd.axis=-signf(b.x-a.x)
	var cmd=ai_cmd.duplicate()
	ai_cmd.attack=-1
	ai_cmd.jump=false
	return cmd

func _process(dt: float) -> void:
	time+=dt
	if screen=="battle":
		battle(minf(dt,0.033))
	if screen!="pause" and screen!="guide":
		for p in particles:
			p.life-=dt
			p.p+=p.v*dt
			p.v.y+=240*dt
		particles=particles.filter(func(p): return p.life>0)
		for l in labels:
			l.life-=dt
			l.p.y-=dt*30
		labels=labels.filter(func(l): return l.life>0)
		for s in slashes: s.life-=dt
		slashes=slashes.filter(func(s): return s.life>0)
	shake=maxf(0,shake-dt*18)
	queue_redraw()
	if "--smoke" in OS.get_cmdline_user_args():
		capture_frames+=1
		if capture_frames>180:
			print("SMOKE OK: scene, rendering, physics, CPU, projectiles")
			get_tree().quit()
	if "--capture" in OS.get_cmdline_user_args() or "--capture-battle" in OS.get_cmdline_user_args():
		capture_frames+=1
		if capture_frames==10: capture.call_deferred()

func capture() -> void:
	await RenderingServer.frame_post_draw
	var file="res://test-results/battle.png" if screen=="battle" else "res://test-results/menu.png"
	DirAccess.make_dir_recursive_absolute("res://test-results")
	get_viewport().get_texture().get_image().save_png(file)
	print("Saved ",file)
	get_tree().quit()

func battle(dt: float) -> void:
	if intro>0:
		intro-=dt
		if intro<=0: audio.play("gong",1.5)
		return
	if outro>0:
		outro-=dt
		if outro<=0:
			if match_over:
				screen="result"
				audio.in_battle=false
			else:
				round_number+=1
				new_round()
		return
	if hitstop>0:
		hitstop-=dt
		return
	if mode!=2: timer=maxf(0,timer-dt)
	var cmd1=human("p1_")
	var cmd2=human("p2_") if mode==1 else cpu(dt)
	var commands=[cmd1,cmd2]
	for i in 2:
		var f=fighters[i]
		var old_action=f.action
		var old_y=f.y
		f.step(dt,commands[i],fighters[1-i].x,1100.0 if stage==2 else 1550.0)
		if old_y==0 and f.y<0: audio.play("jump")
		if f.action!=old_action and f.action==3:
			shake=8
			burst(Vector2(f.x,440+f.y),Data.COLORS[f.kind],36)
			audio.play("gong",1.4)
	# Pushboxes keep the fighters on opposite sides without teleporting.
	var gap=fighters[1].x-fighters[0].x
	if absf(gap)<92:
		var correction=(92-absf(gap))*0.5
		var direction=1.0 if gap>=0 else -1.0
		fighters[0].x=clampf(fighters[0].x-correction*direction,100,1180)
		fighters[1].x=clampf(fighters[1].x+correction*direction,100,1180)
	for i in 2:
		var a=fighters[i]
		var b=fighters[1-i]
		if not a.active(): continue
		if a.move.get("projectile",false) and not a.emitted:
			a.emitted=true
			shoot(i)
		if a.move.range<=0 or a.did_hit: continue
		var dist=(b.x-a.x)*a.facing
		var height_ok=absf(a.y-b.y)<138
		if a.move.get("grab",false): height_ok=absf(b.y)<25 and absf(a.y)<25
		if dist>0 and dist<a.move.range and height_ok:
			var scale_damage=pow(0.86,mini(a.combo,4))
			var result=b.receive(a.move.damage*scale_damage,a.facing,a.move.get("grab",false),a.move.get("poison",false),false,a.move.get("slow",0.0))
			if result.hit:
				a.did_hit=true
				register_hit(i,result,Vector2(b.x,430+b.y))
	for p in projectiles:
		p.life-=dt
		p.p+=p.v*dt
		var enemy=fighters[1-p.owner]
		var h:Rect2=enemy.hurtbox()
		if h.grow(10).has_point(p.p) and p.life>0:
			var result=enemy.receive(p.damage,signf(p.v.x),false,p.get("poison",false),p.type==1,p.get("slow",0.0))
			if result.hit:
				register_hit(p.owner,result,p.p)
				p.life=0
		if p.p.x < -40 or p.p.x>1320 or p.p.y>566 or p.p.y<80: p.life=0
	projectiles=projectiles.filter(func(p): return p.life>0)
	if mode==2:
		training_reset+=dt
		if training_reset>2.0 and fighters[0].action<0:
			for f in fighters:
				f.hp=Data.HP[f.kind]
				f.energy=100
				f.poison=0
				f.slow_time=0
			training_reset=0
	elif fighters[0].hp<=0 or fighters[1].hp<=0 or timer<=0:
		finish_round()

func shoot(owner: int) -> void:
	var f=fighters[owner]
	var at=Vector2(f.x+f.facing*77,375+f.y)
	if f.kind==0:
		projectiles.append({"p":at,"v":Vector2(f.facing*620,0),"owner":owner,"damage":92.0,"life":2.4,"type":0})
		audio.play("fire")
	elif f.kind==1:
		# A full radial burst; three lanes can reach an upright opponent.
		for i in 12:
			var angle=TAU*i/12.0
			projectiles.append({"p":Vector2(f.x,443+f.y),"v":Vector2.from_angle(angle)*590,"owner":owner,"damage":32.0,"life":1.8,"type":1})
		audio.play("spike")
	else:
		var spec:Dictionary=f.move
		projectiles.append({"p":Vector2(f.x+f.facing*70,421+f.y),"v":Vector2(f.facing*660,0),"owner":owner,"damage":spec.damage,"life":2.2,"type":2,"color":Data.COLORS[f.kind],"poison":spec.get("poison",false),"slow":spec.get("slow",0.0)})
		audio.play("fire",1.25)

func register_hit(owner: int,result: Dictionary,at: Vector2) -> void:
	var a=fighters[owner]
	var guarded: bool=result.guarded
	var col=Color("a7d7ef") if guarded else Data.COLORS[a.kind]
	burst(at,col,12 if guarded else 21)
	audio.play("block" if guarded else "hit",rng.randf_range(0.9,1.15))
	hitstop=0.035 if guarded else 0.065
	shake=2 if guarded else (9 if a.action==3 else 5)
	a.energy=minf(100,a.energy+(3 if guarded else 10))
	if not guarded:
		a.combo+=1
		a.combo_damage+=result.damage
		a.combo_time=1.1
		training_reset=0
		if a.kind==2:
			for j in (5 if a.action==1 or a.action==3 else 2):
				slashes.append({"p":at+Vector2(0,-55+j*34),"life":0.38,"color":col})
	labels.append({"p":at+Vector2(0,-35),"text":"БЛОК СЛОМАН" if result.broken else ("БЛОК" if guarded else str(int(result.damage))),"life":0.85,"color":col})

func burst(p: Vector2,col: Color,count: int) -> void:
	for i in count:
		var angle=rng.randf()*TAU
		var vel=Vector2.from_angle(angle)*rng.randf_range(70,330)
		particles.append({"p":p,"v":vel,"life":rng.randf_range(0.2,0.65),"color":col,"size":rng.randf_range(1.4,4)})

func finish_round() -> void:
	var h0=fighters[0].hp/Data.HP[fighters[0].kind]
	var h1=fighters[1].hp/Data.HP[fighters[1].kind]
	winner=0 if h0>h1 else 1
	if is_equal_approx(h0,h1): winner=-1
	if winner>=0: scores[winner]+=1
	match_over=scores[0]>=2 or scores[1]>=2
	outro=3.5
	projectiles.clear()
	audio.play("ko")
	shake=10

func _draw() -> void:
	buttons.clear()
	if screen=="menu":
		draw_menu()
	elif screen=="guide":
		draw_guide()
	else:
		draw_battle()
		if screen=="pause": draw_pause()
		elif screen=="result": draw_result()
	var hovered=false
	for b in buttons:
		if b.rect.has_point(mouse): hovered=true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered else Input.CURSOR_ARROW)

func txt(s: String,p: Vector2,size: int = 18,col: Color = WHITE,heavy: bool = false) -> void:
	draw_string(bold if heavy else font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)

func center(s: String,p: Vector2,size: int = 18,col: Color = WHITE,heavy: bool = false) -> void:
	var f=bold if heavy else font
	txt(s,p-Vector2(f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),size,col,heavy)

func panel(r: Rect2, color: Color = Color("111c25"),border: Color = Color("2c3a43")) -> void:
	draw_style_box(box(color,border),r)

func box(bg: Color,border: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=bg
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func button(id: String,r: Rect2,label: String,chosen: bool = false,primary: bool = false) -> void:
	var over=r.has_point(mouse)
	var bg=GOLD if primary else Color("1a2932") if over or chosen else Color("101a23")
	var border=GOLD if chosen or over or primary else Color("34414a")
	panel(r,bg,border)
	center(label,r.position+Vector2(r.size.x/2,r.size.y/2+6),16,Color("182027") if primary else GOLD if chosen else WHITE,true)
	buttons.append({"id":id,"rect":r})

func paragraph(s: String,p: Vector2,width: float,size: int = 16,col: Color = MUTED) -> float:
	var line=""
	var yy=p.y
	for word in s.split(" "):
		if font.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:
			txt(line,Vector2(p.x,yy),size,col)
			yy+=size*1.5
			line=""
		line+=word+" "
	if not line.is_empty():
		txt(line,Vector2(p.x,yy),size,col)
		yy+=size*1.5
	return yy

func draw_menu() -> void:
	Art.arena(self,stage,time,font)
	draw_rect(Rect2(0,0,1280,720),Color(0.023,0.04,0.055,0.90))
	draw_rect(Rect2(0,0,8,720),GOLD)
	txt("W / I",Vector2(52,49),25,GOLD,true)
	txt("WILD INSTINCT",Vector2(139,44),16,WHITE,true)
	txt("АРКАДНЫЙ ФАЙТИНГ  /  01",Vector2(139,64),10,MUTED)
	txt(str(Data.NAMES.size())+" БОЙЦОВ. "+str(Data.STAGES.size())+" МИРОВ.",Vector2(922,44),13,MUTED)
	draw_circle(Vector2(1209,39),4,ORANGE)
	txt("ДИКИЙ ИНСТИНКТ",Vector2(49,154),68,WHITE,true)
	txt("Выбери свою природу.",Vector2(53,193),19,MUTED)
	draw_line(Vector2(52,216),Vector2(1228,216),Color("34414a"),1)
	txt("01  /  ВЫБЕРИ БОЙЦА",Vector2(52,243),12,GOLD,true)
	button("roster_prev",Rect2(477,227,34,27),"←")
	center("БОЙЦЫ "+str(roster_page*3+1)+"–"+str(mini(roster_page*3+3,Data.NAMES.size()))+" / "+str(Data.NAMES.size()),Vector2(615,245),11,MUTED)
	button("roster_next",Rect2(720,227,34,27),"→")
	txt("02  /  ВЫБЕРИ АРЕНУ",Vector2(806,243),12,GOLD,true)
	for slot in 3:
		var i=roster_page*3+slot
		if i>=Data.NAMES.size(): break
		var r=Rect2(52+slot*240,261,222,284)
		var chosen=i==selected
		var col: Color=Data.COLORS[i]
		panel(r,Color("16232b") if chosen else Color("101a22"),col if chosen else Color("2d3b43"))
		draw_rect(Rect2(r.position,Vector2(r.size.x,3)),col if chosen else Color("34434a"))
		for j in 8:
			Art.oval(self,r.position+Vector2(111,154),Vector2(53+j*7,84+j*4),Color(col,0.007))
		Art.oval(self,r.position+Vector2(111,211),Vector2(77,11),Color(0,0,0,0.3))
		Art.character(self,i,r.position+Vector2(124 if i==2 else 113,214),0.73 if i==2 else 0.77,1,time+i)
		txt(str(i+1).pad_zeros(2),r.position+Vector2(15,27),13,col,true)
		if chosen:
			txt("ВЫБРАН",r.position+Vector2(139,27),10,col,true)
		draw_line(r.position+Vector2(14,229),r.position+Vector2(208,229),Color("34414a"),1)
		txt(Data.NAMES[i],r.position+Vector2(15,254),22,WHITE,true)
		txt(Data.TITLES[i],r.position+Vector2(15,273),10,col)
		buttons.append({"id":"fighter_"+str(i),"rect":r})
	# Live arena preview at 31.25% scale.
	draw_set_transform(Vector2(806,261),0,Vector2(0.3297,0.3297))
	Art.arena(self,stage,time,font)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(806,261,422,237),Color("52616a"),false,1)
	draw_rect(Rect2(806,450,422,48),Color(0.025,0.04,0.06,0.88))
	txt(Data.STAGES[stage],Vector2(821,473),20,WHITE,true)
	txt(Data.STAGE_TAGS[stage],Vector2(821,489),9,GOLD)
	button("stage_prev",Rect2(806,506,42,37),"←")
	button("stage_next",Rect2(1186,506,42,37),"→")
	center(str(stage+1).pad_zeros(2)+"  /  "+str(Data.STAGES.size()).pad_zeros(2),Vector2(1017,530),13,MUTED)
	for i in Data.STAGES.size():
		draw_circle(Vector2(1017+(i-(Data.STAGES.size()-1)*0.5)*18,540),2,GOLD if i==stage else Color("49565d"))
	txt("03  /  РЕЖИМ БОЯ",Vector2(52,574),12,GOLD,true)
	var modes=["ПРОТИВ КОМПЬЮТЕРА","ДВА ИГРОКА","ТРЕНИРОВКА"]
	for i in 3:
		button("mode_"+str(i),Rect2(52+i*240,587,222,40),modes[i],mode==i)
	button("enemy_prev",Rect2(806,558,34,34),"←")
	button("enemy",Rect2(847,558,381,34),"СОПЕРНИК: "+Data.NAMES[opponent]+"  →")
	if mode==0:
		button("difficulty",Rect2(806,599,422,29),"СЛОЖНОСТЬ: "+["НОВИЧОК","БОЕЦ","ХИЩНИК"][difficulty])
	else:
		center("СТРЕЛКИ + 1 / 2 / 3 / 4 / 0" if mode==1 else "БЕСКОНЕЧНЫЙ БОЙ • R — СБРОС",Vector2(1017,619),12,MUTED)
	button("guide",Rect2(52,653,222,39),"ПРИЁМЫ И ПРАВИЛА  ↗")
	txt("A D  ДВИЖЕНИЕ    W  ПРЫЖОК    J K L I  АТАКИ",Vector2(295,671),12,MUTED)
	txt("ПРОБЕЛ  БЛОК     F11  ПОЛНЫЙ ЭКРАН",Vector2(295,690),11,Color("6e808a"))
	button("start",Rect2(981,650,247,44),"НАЧАТЬ БОЙ    →",false,true)
	txt("ENTER",Vector2(927,679),10,MUTED)

func draw_battle() -> void:
	var offset=Vector2(sin(time*83),cos(time*71))*shake
	draw_set_transform(offset)
	Art.arena(self,stage,time,font)
	draw_set_transform(Vector2.ZERO)
	for f in fighters:
		Art.oval(self,Vector2(f.x,566)+offset,Vector2(maxf(34,81+f.y*0.12),12),Color(0,0,0,0.30 if f.y<0 else 0.45))
	for f in fighters:
		var scale_y=0.66 if f.crouch and f.action<0 else 1.0
		var anim_time=time+f.x*0.001
		if f.walk!=0: anim_time+=time*2
		# Crouch compresses the whole silhouette and its hurtbox together.
		if scale_y<1:
			draw_set_transform(Vector2(0,566*(1-scale_y)),0,Vector2(1,scale_y))
			# Art.character owns its transform, so use a compact scale with foot alignment.
		Art.character(self,f.kind,Vector2(f.x,566+f.y)+offset,scale_y,f.facing,anim_time,f.action,f.progress(),f.flash,f.block,f.hp<=0)
		if f.poison>0:
			for i in 5:
				var p=Vector2(f.x+sin(i*5+time)*37,540+f.y-fposmod(time*38+i*31,140))
				draw_circle(p,3,Color(0.65,0.9,0.3,0.55))
		if f.block:
			draw_arc(Vector2(f.x+f.facing*20,444+f.y),105,-1.4 if f.facing>0 else 1.7,1.4 if f.facing>0 else 4.6,32,Color(0.6,0.82,0.95,0.45),3,true)
	for p in projectiles:
		if p.type==0:
			var dir=signf(p.v.x)
			for j in 7:
				draw_circle(p.p-Vector2(dir*j*8,0),18-j*1.7,Color(1,0.27+0.04*j,0.08,0.13+(7-j)*0.035))
			draw_circle(p.p,14,Color("fc9e46"))
			draw_circle(p.p+Vector2(dir*3,-2),8,Color("fff0ae"))
		elif p.type==1:
			var v=p.v.normalized()
			Art.poly(self,[p.p+v*17,p.p-v*12+v.orthogonal()*4,p.p-v*12-v.orthogonal()*4],Color("e2edb0"))
		else:
			var col:Color=p.color
			var v:Vector2=p.v.normalized()
			for j in 5:
				draw_circle(p.p-v*j*9,17-j*2,Color(col,0.18))
			Art.poly(self,[p.p+v*23,p.p+v.orthogonal()*12,p.p-v*14,p.p-v.orthogonal()*12],col)
			draw_circle(p.p,6,col.lightened(0.6))
	for p in particles:
		draw_line(p.p,p.p-p.v*0.025,Color(p.color,clampf(p.life*2,0,1)),p.size,true)
	for s in slashes:
		for j in 3:
			var p:Vector2=s.p+Vector2(j*8,0)
			draw_line(p+Vector2(-24,-25),p+Vector2(25,24),Color(s.color,clampf(s.life*3,0,1)),3,true)
	for l in labels:
		center(l.text,l.p,21,Color(l.color,minf(1,l.life*3)),true)
	draw_hud()
	if intro>0:
		var title="РАУНД "+str(round_number) if intro>0.9 else "В БОЙ!"
		draw_rect(Rect2(0,258,1280,151),Color(0.025,0.04,0.06,0.72))
		center(title,Vector2(640,350),65,GOLD,true)
		center(Data.STAGES[stage],Vector2(640,385),12,WHITE)
	elif outro>0:
		draw_rect(Rect2(0,251,1280,153),Color(0.025,0.04,0.06,0.76))
		center("НИЧЬЯ" if winner<0 else "K.O." if timer>0 else "ВРЕМЯ!",Vector2(640,327),70,GOLD,true)
		center("ЕЩЁ ОДИН РАУНД" if winner<0 else Data.NAMES[fighters[winner].kind]+" ПОБЕЖДАЕТ",Vector2(640,373),21,WHITE,true)

func draw_hud() -> void:
	draw_rect(Rect2(0,0,1280,127),Color(0.02,0.033,0.047,0.91))
	txt("W / I",Vector2(29,29),16,GOLD,true)
	center(Data.STAGES[stage]+"   /   "+["ПРОТИВ КОМПЬЮТЕРА","ЛОКАЛЬНЫЙ БОЙ","ТРЕНИРОВКА"][mode],Vector2(640,24),10,MUTED)
	for i in 2:
		var f=fighters[i]
		var col:Color=Data.COLORS[f.kind]
		var x=51 if i==0 else 731
		txt(Data.NAMES[f.kind],Vector2(x,56),25,WHITE,true)
		txt("ИГРОК 1" if i==0 else "ИГРОК 2" if mode==1 else "МАНЕКЕН" if mode==2 else ["НОВИЧОК","БОЕЦ","ХИЩНИК"][difficulty],Vector2(x+336,53),10,col)
		panel(Rect2(x,66,498,23),Color("26323a"),Color("536068"))
		var ratio=clampf(f.hp/Data.HP[f.kind],0,1)
		var w=490*ratio
		var start=x+4 if i==0 else x+494-w
		draw_rect(Rect2(start,70,w,15),col if ratio>0.25 else ORANGE)
		draw_rect(Rect2(start,70,w,3),col.lightened(0.4))
		for j in 9:
			draw_line(Vector2(x+50+j*49,70),Vector2(x+50+j*49,85),Color(0.03,0.06,0.08,0.3),1)
		var ew=280*f.energy/100
		draw_rect(Rect2(x,99,280,5),Color("283741"))
		draw_rect(Rect2(x if i==0 else x+280-ew,99,ew,5),GOLD if f.energy>=100 else Color("74adbd"))
		txt("УЛЬТА ГОТОВА" if f.energy>=100 else "ЭНЕРГИЯ  "+str(int(f.energy))+" / 100",Vector2(x,119),9,GOLD if f.energy>=100 else MUTED)
		txt(str(int(ceil(f.hp)))+" / "+str(int(Data.HP[f.kind])),Vector2(x+405,104),10,MUTED)
		for j in 2:
			draw_circle(Vector2(530-j*18 if i==0 else 750+j*18,115),5,GOLD if scores[i]>j else Color("34424d"))
		if f.poison>0:
			txt("ЯД  "+str(snappedf(f.poison,0.1))+" с",Vector2(x+320,119),10,Color("b6d775"))
		elif f.slow_time>0:
			txt("ЗАМЕДЛЕНИЕ",Vector2(x+320,119),10,Color("9ce5ff"))
		if f.feedback_time>0:
			txt(f.feedback,Vector2(x,190),12,ORANGE,true)
		if f.name_time>0:
			var where=Vector2(53,166) if i==0 else Vector2(1226,166)
			if i==0: txt(f.last_name.to_upper(),where,16,col,true)
			else:
				var width=bold.get_string_size(f.last_name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
				txt(f.last_name.to_upper(),where-Vector2(width,0),16,col,true)
		if f.combo>1:
			var cx=80 if i==0 else 1200
			center(str(f.combo)+" HITS",Vector2(cx,226),27,GOLD,true)
			center(str(int(f.combo_damage))+" УРОНА",Vector2(cx,249),12,WHITE)
	panel(Rect2(578,44,124,76),Color("101923"),GOLD.darkened(0.5))
	center("∞" if mode==2 else str(int(ceil(timer))).pad_zeros(2),Vector2(640,93),45,ORANGE if timer<15 else WHITE,true)
	center("РАУНД "+str(round_number),Vector2(640,112),9,GOLD)
	draw_rect(Rect2(0,675,1280,45),Color(0.025,0.04,0.06,0.94))
	txt("A D  ШАГ    W  ПРЫЖОК    S  ПРИСЕСТЬ",Vector2(30,694),11,MUTED)
	txt("J  УДАР / УДЕРЖИВАТЬ    K  ДАЛЬНИЙ    L  ОСОБЫЙ    I  УЛЬТА    ПРОБЕЛ  БЛОК",Vector2(341,694),11,WHITE)
	txt("ESC  ПАУЗА    F1  ПРИЁМЫ    M  ЗВУК",Vector2(30,712),10,Color("687c86"))
	if mode==1: txt("P2:  ← → ↑ ↓   /   1  2  3  4   /   0  БЛОК",Vector2(778,712),10,GOLD)
	elif mode==2: txt("R  СБРОС   •   ЗДОРОВЬЕ ВОССТАНАВЛИВАЕТСЯ ЧЕРЕЗ 2 СЕКУНДЫ",Vector2(630,712),10,GOLD)
	else: txt("ДО ДВУХ ПОБЕД  •  75 СЕКУНД  •  ПОДТВЕРЖДЁННЫЙ J → K / L",Vector2(700,712),10,Color("687c86"))

func draw_pause() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.015,0.025,0.04,0.83))
	panel(Rect2(423,164,434,402),Color("101b25"),Color("4a5557"))
	center("ПЕРЕВЕДИ ДУХ",Vector2(640,231),34,WHITE,true)
	center("БОЙ ПРИОСТАНОВЛЕН",Vector2(640,263),12,GOLD)
	button("resume",Rect2(473,301,334,47),"ПРОДОЛЖИТЬ",false,true)
	button("guide",Rect2(473,361,334,43),"ПРИЁМЫ И ПРАВИЛА")
	button("sound",Rect2(473,416,334,43),"ЗВУК: "+("ВЫКЛЮЧЕН" if audio.muted else "ВКЛЮЧЁН"))
	button("menu",Rect2(473,471,334,43),"К ВЫБОРУ БОЙЦА")
	center("ESC / ENTER — ПРОДОЛЖИТЬ",Vector2(640,545),10,MUTED)

func draw_result() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.015,0.025,0.04,0.90))
	center("ВЕРШИНА ПИЩЕВОЙ ЦЕПИ",Vector2(640,135),13,GOLD,true)
	center(Data.NAMES[fighters[winner].kind],Vector2(640,213),65,WHITE,true)
	center("ПОБЕДИТЕЛЬ МАТЧА  /  "+str(scores[0])+" : "+str(scores[1]),Vector2(640,251),18,MUTED)
	Art.oval(self,Vector2(640,526),Vector2(108,14),Color(0,0,0,0.35))
	Art.character(self,fighters[winner].kind,Vector2(640,531),1.1,1,time)
	button("rematch",Rect2(370,583,260,49),"РЕВАНШ    →",false,true)
	button("menu",Rect2(650,583,260,49),"ВЫБРАТЬ БОЙЦА")
	center("ENTER — РЕВАНШ",Vector2(640,664),11,MUTED)

func draw_guide() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("0b141e"))
	txt("ПОЛЕВОЙ СПРАВОЧНИК",Vector2(52,63),31,WHITE,true)
	txt("ИЗУЧИ ИНСТИНКТ. ВЫИГРАЙ БОЙ.",Vector2(53,90),11,GOLD)
	button("back",Rect2(1068,38,160,39),"←  НАЗАД")
	for slot in 3:
		var i=(guide_page/3 as int)*3+slot
		button("guide_"+str(i),Rect2(52+slot*240,115,222,42),Data.NAMES[i],guide_page==i)
	button("guide_prev",Rect2(766,115,34,42),"←")
	button("guide_next",Rect2(807,115,34,42),"→")
	var col: Color=Data.COLORS[guide_page]
	panel(Rect2(52,179,293,351),Color("15212a"),col.darkened(0.5))
	Art.character(self,guide_page,Vector2(219 if guide_page==2 else 203,452),0.94 if guide_page==2 else 1.03,1,time)
	center(Data.TITLES[guide_page],Vector2(199,490),12,col,true)
	center(str(int(Data.HP[guide_page]))+" HP   /   "+str(int(Data.SPEED[guide_page]))+" СКОРОСТЬ",Vector2(199,513),11,MUTED)
	paragraph(Data.LORE[guide_page],Vector2(53,556),292,14,MUTED)
	for i in 4:
		var y=204+i*101
		txt(Data.HELP[guide_page][i*2],Vector2(380,y),17,col,true)
		paragraph(Data.HELP[guide_page][i*2+1],Vector2(380,y+27),430,14,WHITE)
		var m:Dictionary=Data.MOVES[guide_page][i]
		txt("ПОДГОТОВКА "+str(int(m.startup*1000))+" мс  /  ВОССТАНОВЛЕНИЕ "+str(int(m.recovery*1000))+" мс",Vector2(380,y+66),10,MUTED)
	panel(Rect2(854,115,374,509),Color("131f29"),Color("34434b"))
	txt("ПРАВИЛА ВЫЖИВАНИЯ",Vector2(875,151),19,WHITE,true)
	var rules=[
		["ДВЕ ПОБЕДЫ", "Раунд длится 75 секунд. При равенстве здоровья — переигровка."],
		["БЛОК / ПРОБЕЛ", "Поглощает 82% урона и тратит 14 энергии. Захват кактуса проходит сквозь блок."],
		["ЭНЕРГИЯ", "Начало: 35. Восстановление: 8/с. Попадание: +10. Для ульты нужно 100."],
		["КОМБИНАЦИИ", "После попадания J сразу нажми K или L. Каждый удар цепи слабее на 14%."],
		["ВТОРОЙ ИГРОК", "Стрелки — движение. 1 / 2 / 3 / 4 — атаки. 0 — блок. Работает и NumPad."],
		["ЛУННАЯ ГРАВИТАЦИЯ", "На Луне прыжок выше и дольше. Арены не наносят случайного урона."]
	]
	for i in rules.size():
		var y=186+i*70
		txt(rules[i][0],Vector2(875,y),11,GOLD,true)
		paragraph(rules[i][1],Vector2(875,y+20),329,12,MUTED)
	draw_line(Vector2(52,650),Vector2(1228,650),Color("34414a"),1)
	txt("УПРАВЛЕНИЕ ПО ФИЗИЧЕСКИМ КЛАВИШАМ — РАБОТАЕТ С РУССКОЙ РАСКЛАДКОЙ",Vector2(52,679),11,MUTED)
	txt("F1 / ESC — НАЗАД",Vector2(1077,679),10,GOLD)
