extends RefCounted
## Entirely original, resolution-independent character and arena artwork.

static func poly(c: CanvasItem, pts: Array, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(pts), color)

static func oval(c: CanvasItem, p: Vector2, r: Vector2, color: Color, n: int = 32) -> void:
	var pts: Array = []
	for i in n:
		var a = TAU * i / n
		pts.append(p + Vector2(cos(a) * r.x, sin(a) * r.y))
	poly(c, pts, color)

static func stroke(c: CanvasItem, pts: Array, color: Color, width: float = 2.0) -> void:
	c.draw_polyline(PackedVector2Array(pts), color, width, true)

static func curve(c: CanvasItem, a: Vector2, b: Vector2, d: Vector2, e: Vector2, color: Color, width: float) -> void:
	var pts: Array = []
	for i in 25:
		var t = float(i) / 24.0
		pts.append(a.bezier_interpolate(b, d, e, t))
	stroke(c, pts, color, width)

static func character(c: CanvasItem, kind: int, p: Vector2, size: float, facing: float, t: float, action: int = -1, phase: float = 0.0, hurt: float = 0.0, blocking: bool = false, dead: bool = false) -> void:
	var bob = sin(t * 2.8) * 3.0
	var tilt = 0.0
	if dead:
		tilt = -0.95
		bob = 24.0
	c.draw_set_transform(p + Vector2(0, bob), tilt * facing, Vector2(size * facing, size))
	if hurt > 0:
		c.draw_set_transform(p + Vector2(-hurt * 12 * facing, bob), -0.09 * facing, Vector2(size * facing, size))
	var reach = sin(clampf(phase, 0, 1) * PI) if action >= 0 else 0.0
	match kind:
		0: cobra(c, t, action, reach, blocking)
		1: cactus(c, t, action, reach, blocking)
		2:
			if action == 1 or action == 3:
				leopard(c, t, reach)
			else:
				squirrel(c, t, action, reach, blocking)
	if hurt > 0:
		for i in 6:
			var a = i * TAU / 6 + t
			c.draw_line(Vector2(20, -130), Vector2(20, -130) + Vector2.from_angle(a) * (30 + 15 * hurt), Color(1, 0.9, 0.65, hurt), 3, true)
	c.draw_set_transform(Vector2.ZERO)

static func cobra(c: CanvasItem, t: float, action: int, reach: float, blocking: bool) -> void:
	var ink = Color("080e13")
	var dark = Color("17232a")
	var gold = Color("d9ad55")
	var light = Color("ffe5a0")
	var lunge = reach * (85.0 if action >= 2 else 45.0)
	curve(c, Vector2(-94, -15), Vector2(-167, -65), Vector2(13, -79), Vector2(43, -21), ink, 37)
	curve(c, Vector2(-94, -19), Vector2(-157, -62), Vector2(13, -72), Vector2(43, -25), dark, 25)
	curve(c, Vector2(-100, -23), Vector2(-139, -52), Vector2(4, -69), Vector2(39, -27), gold.darkened(0.3), 3)
	for i in 12:
		var a = float(i)/11.0*PI
		var p = Vector2(-25-cos(a)*72,-24-sin(a)*25)
		poly(c,[p+Vector2(-4,0),p+Vector2(0,-3),p+Vector2(4,0),p+Vector2(0,3)],gold.darkened(0.2))
	oval(c, Vector2(-7, -24), Vector2(82, 27), ink)
	oval(c, Vector2(-10, -31), Vector2(72, 23), dark)
	curve(c, Vector2(-67, -37), Vector2(-20, -63), Vector2(60, -24), Vector2(0, -17), gold, 2)
	curve(c, Vector2(-20, -34), Vector2(48, -64), Vector2(-56, -105), Vector2(lunge, -165), ink, 58)
	curve(c, Vector2(-20, -36), Vector2(41, -68), Vector2(-47, -105), Vector2(lunge, -165), dark, 45)
	curve(c, Vector2(-11, -43), Vector2(40, -72), Vector2(-27, -120), Vector2(14 + lunge, -165), Color("b48b48"), 17)
	for i in 8:
		var y = -50 - i * 12
		c.draw_line(Vector2(-5 + lunge * i / 12, y), Vector2(17 + lunge * i / 9, y - 3), ink, 2, true)
	var h = Vector2(lunge, -174)
	# Expanded king cobra hood, with gold inlay and a crown motif.
	var hood: Array = [h+Vector2(6,-43),h+Vector2(-31,-54),h+Vector2(-68,-28),h+Vector2(-75,13),h+Vector2(-50,55),h+Vector2(-14,79),h+Vector2(15,37),h+Vector2(30,-4)]
	poly(c, hood, ink)
	stroke(c, hood + [hood[0]], gold.darkened(0.4), 2)
	poly(c, [h+Vector2(-31,-43),h+Vector2(-60,-22),h+Vector2(-62,10),h+Vector2(-36,49),h+Vector2(-17,59),h+Vector2(-29,14)], Color("233039"))
	stroke(c, [h+Vector2(-32,-40),h+Vector2(-56,-18),h+Vector2(-55,12),h+Vector2(-31,44),h+Vector2(-19,55)], gold, 4)
	stroke(c, [h+Vector2(-23,-28),h+Vector2(-39,-10),h+Vector2(-37,10),h+Vector2(-19,29)], gold, 3)
	poly(c, [h+Vector2(-37,-6),h+Vector2(-29,2),h+Vector2(-37,12),h+Vector2(-45,2)], light)
	for i in 5:
		var y = -18 + i * 12
		c.draw_line(h+Vector2(-65+i*4,y), h+Vector2(-58+i*4,y+3), gold, 2, true)
	var head = h + Vector2(26, -24)
	oval(c, head, Vector2(43, 26), ink)
	poly(c, [head+Vector2(-24,-18),head+Vector2(13,-24),head+Vector2(57,-6),head+Vector2(58,9),head+Vector2(16,19),head+Vector2(-14,13)], dark)
	stroke(c, [head+Vector2(-21,-18),head+Vector2(12,-22),head+Vector2(52,-6)], gold, 2)
	poly(c, [head+Vector2(0,-5),head+Vector2(19,-9),head+Vector2(11,2),head+Vector2(2,3)], light)
	c.draw_line(head+Vector2(9,-7),head+Vector2(9,2),ink,3)
	var mouth = reach * 20 if action == 0 or action == 1 or action == 3 else 0.0
	poly(c, [head+Vector2(14,12),head+Vector2(58,7),head+Vector2(48,19+mouth),head+Vector2(18,19+mouth)], Color("3c1725"))
	poly(c, [head+Vector2(40,10),head+Vector2(48,10),head+Vector2(42,26+mouth)], Color("fff0cf"))
	stroke(c, [head+Vector2(17,21+mouth),head+Vector2(49,22+mouth),head+Vector2(60,13+mouth)], gold.darkened(0.3), 3)
	if action == -1 and sin(t * 2) > 0.7:
		stroke(c,[head+Vector2(57,15),head+Vector2(80,18),head+Vector2(88,12)],Color("fa5b62"),2)
		c.draw_line(head+Vector2(80,18),head+Vector2(87,23),Color("fa5b62"),2)
	if blocking:
		c.draw_arc(Vector2(20,-145),88,-1.5,1.4,32,Color("e5bf76"),4,true)

static func cactus(c: CanvasItem, t: float, action: int, reach: float, blocking: bool) -> void:
	var edge = Color("142b26")
	var green = Color("a4cb83")
	var shade = Color("527e57")
	var hi = Color("d0e3a0")
	for i in 6:
		var x = -40 + i * 15
		var sway = sin(t * 7 + i) * 5
		curve(c,Vector2(x,-24),Vector2(x-16,-9),Vector2(x+20+sway,2),Vector2(x-17+sway,7),edge,12)
		curve(c,Vector2(x,-24),Vector2(x-16,-9),Vector2(x+20+sway,2),Vector2(x-17+sway,7),Color("bda276"),5)
	var arm = reach * 60
	# Far arm rises behind the body.
	var far_hand=Vector2(-86+reach*180,-181+reach*25)
	curve(c,Vector2(-29,-112),Vector2(-103,-85),Vector2(-96+reach*150,-155),far_hand,edge,42)
	curve(c,Vector2(-29,-112),Vector2(-103,-85),Vector2(-96+reach*150,-155),far_hand,shade,32)
	oval(c,far_hand,Vector2(16,18),shade)
	oval(c,Vector2(0,-110),Vector2(51,109),edge)
	oval(c,Vector2(0,-114),Vector2(45,102),green)
	oval(c,Vector2(-20,-114),Vector2(19,92),shade)
	curve(c,Vector2(2,-209),Vector2(-17,-161),Vector2(13,-72),Vector2(0,-23),hi,4)
	curve(c,Vector2(23,-201),Vector2(13,-153),Vector2(31,-77),Vector2(21,-28),Color("83ad6c"),3)
	for i in 8:
		for j in 3:
			var p = Vector2(-27+j*25,-185+i*21)
			c.draw_line(p,p+Vector2(4,-9),Color("e9e5b6"),1.6,true)
			c.draw_line(p,p+Vector2(-5,-6),Color("e9e5b6"),1.3,true)
	var hand = Vector2(84 + arm * 0.5, -156 + reach * 30)
	if blocking: hand = Vector2(54,-181)
	curve(c,Vector2(30,-98),Vector2(107+arm,-69),Vector2(hand.x+12,-128),hand,edge,45)
	curve(c,Vector2(30,-98),Vector2(107+arm,-69),Vector2(hand.x+12,-128),hand,green,35)
	curve(c,Vector2(34,-104),Vector2(100+arm,-78),Vector2(hand.x+6,-130),hand+Vector2(-3,-4),hi,4)
	oval(c,hand,Vector2(19,22),green)
	for i in 5:
		var p = Vector2(61+sin(i)*19+arm*0.3,-102-i*13)
		c.draw_line(p,p+Vector2(10,-4),Color("fff0be"),2,true)
	# Small, stern face, carved into the tall trunk.
	poly(c,[Vector2(-17,-165),Vector2(-2,-161),Vector2(-4,-153),Vector2(-15,-155)],edge)
	poly(c,[Vector2(10,-161),Vector2(29,-168),Vector2(25,-155),Vector2(13,-153)],edge)
	c.draw_line(Vector2(-13,-159),Vector2(-8,-157),Color("ffdd80"),2)
	c.draw_line(Vector2(16,-158),Vector2(23,-161),Color("ffdd80"),2)
	stroke(c,[Vector2(-3,-137),Vector2(8,-132),Vector2(20,-139)],edge,3)
	# Flower crest.
	for i in 6:
		oval(c,Vector2(-9,-216)+Vector2.from_angle(i*TAU/6)*9,Vector2(9,6),Color("e7867a"))
	c.draw_circle(Vector2(-9,-216),5,Color("ffda8b"))
	if action == 3:
		c.draw_arc(Vector2(0,-90),140*reach,-PI,0,30,Color(0.7,1,0.5,reach),5,true)

static func spots(c: CanvasItem, center: Vector2, rx: float, ry: float, count: int, seed_val: int = 0) -> void:
	for i in count:
		var a = i * 2.399 + seed_val
		var r = sqrt(float(i+1)/count) * 0.85
		var p = center + Vector2(cos(a)*rx*r,sin(a)*ry*r)
		oval(c,p,Vector2(5.0+(i%3),3.6+(i%2)),Color("50362b"),10)
		if i % 3 == 0: oval(c,p,Vector2(2.3,1.6),Color("d49b56"),8)

static func squirrel(c: CanvasItem, t: float, action: int, reach: float, blocking: bool) -> void:
	var edge = Color("29212a")
	var fur = Color("d99a55")
	var light = Color("ffcf88")
	var sw = sin(t * 2.5)*7
	# Large curved squirrel tail, distinctly different from leopard form.
	curve(c,Vector2(-21,-35),Vector2(-148,-61),Vector2(-151,-245+sw),Vector2(-84,-203+sw),edge,70)
	curve(c,Vector2(-21,-38),Vector2(-140,-64),Vector2(-146,-237+sw),Vector2(-84,-203+sw),fur,59)
	curve(c,Vector2(-34,-42),Vector2(-128,-74),Vector2(-132,-221+sw),Vector2(-87,-204+sw),light,13)
	for i in 11:
		var yy = -65-i*12
		var xx = -85-sin(float(i)/11*PI)*36
		oval(c,Vector2(xx,yy),Vector2(7,5),edge,10)
	curve(c,Vector2(-28,-58),Vector2(-46,-27),Vector2(-44,-13),Vector2(-60,-9),edge,24)
	curve(c,Vector2(-28,-58),Vector2(-46,-27),Vector2(-44,-13),Vector2(-60,-9),fur,17)
	curve(c,Vector2(17,-59),Vector2(35,-35),Vector2(24,-17),Vector2(49,-9),edge,24)
	curve(c,Vector2(17,-59),Vector2(35,-35),Vector2(24,-17),Vector2(49,-9),fur,17)
	oval(c,Vector2(-6,-95),Vector2(43,62),edge)
	oval(c,Vector2(-6,-97),Vector2(37,57),fur)
	spots(c,Vector2(-12,-101),34,52,13)
	oval(c,Vector2(11,-98),Vector2(18,43),light)
	var hand = Vector2(65+reach*76,-117-reach*23)
	if blocking: hand=Vector2(48,-171)
	curve(c,Vector2(-15,-133),Vector2(-45,-112),Vector2(18,-104),Vector2(37,-135),edge,18)
	curve(c,Vector2(-15,-133),Vector2(-45,-112),Vector2(18,-104),Vector2(37,-135),fur,12)
	curve(c,Vector2(15,-137),Vector2(48,-119),Vector2(35+reach*50,-100),hand,edge,22)
	curve(c,Vector2(15,-137),Vector2(48,-119),Vector2(35+reach*50,-100),hand,fur,15)
	oval(c,hand,Vector2(13,10),fur)
	for i in 3:
		stroke(c,[hand+Vector2(7,-7+i*6),hand+Vector2(22,-9+i*6),hand+Vector2(27,-4+i*6)],Color("fff2ce"),2)
	poly(c,[Vector2(-32,-176),Vector2(-39,-224),Vector2(-10,-206),Vector2(9,-202),Vector2(27,-222),Vector2(33,-178)],edge)
	poly(c,[Vector2(-26,-182),Vector2(-31,-213),Vector2(-12,-200),Vector2(11,-196),Vector2(25,-213),Vector2(26,-180)],fur)
	poly(c,[Vector2(-29,-208),Vector2(-23,-184),Vector2(-13,-193)],Color("ab6e64"))
	oval(c,Vector2(5,-170),Vector2(37,32),edge)
	oval(c,Vector2(5,-173),Vector2(32,28),fur)
	spots(c,Vector2(-2,-186),25,14,6,4)
	oval(c,Vector2(30,-162),Vector2(20,15),light)
	poly(c,[Vector2(41,-170),Vector2(53,-166),Vector2(44,-159)],edge)
	poly(c,[Vector2(2,-180),Vector2(22,-181),Vector2(16,-170),Vector2(8,-170)],edge)
	c.draw_circle(Vector2(15,-176),3,Color("c8efbc"))
	c.draw_line(Vector2(16,-179),Vector2(16,-173),edge,2)
	c.draw_line(Vector2(31,-151),Vector2(43,-153),edge,2,true)
	for i in 3:
		c.draw_line(Vector2(33,-158+i*4),Vector2(64,-166+i*10),Color("e4ceaa"),1,true)

static func leopard(c: CanvasItem, t: float, reach: float) -> void:
	var edge=Color("29212a")
	var fur=Color("e2a45c")
	curve(c,Vector2(-64,-83),Vector2(-164,-127),Vector2(-119,-150),Vector2(-172,-148),edge,13)
	curve(c,Vector2(-64,-83),Vector2(-164,-127),Vector2(-119,-150),Vector2(-172,-148),fur,8)
	for i in 4:
		var x=-57+i*37
		var run=sin(t*23+i*2)*24
		curve(c,Vector2(x,-76),Vector2(x+run,-49),Vector2(x-run,-29),Vector2(x+run,-9),edge,18)
		curve(c,Vector2(x,-76),Vector2(x+run,-49),Vector2(x-run,-29),Vector2(x+run,-9),fur,12)
	oval(c,Vector2(-1,-87),Vector2(86,31),edge)
	oval(c,Vector2(-1,-89),Vector2(82,26),fur)
	spots(c,Vector2(-6,-90),76,25,24)
	oval(c,Vector2(79,-100),Vector2(29,27),edge)
	oval(c,Vector2(80,-103),Vector2(26,23),fur)
	poly(c,[Vector2(59,-117),Vector2(63,-138),Vector2(77,-122)],edge)
	oval(c,Vector2(99,-91),Vector2(22,12),Color("ffda9c"))
	c.draw_line(Vector2(81,-108),Vector2(96,-108),edge,5)
	c.draw_circle(Vector2(90,-108),2,Color("d7ffba"))
	poly(c,[Vector2(112,-99),Vector2(122,-94),Vector2(111,-88)],edge)
	if reach>0.3:
		for i in 3:
			c.draw_line(Vector2(108,-70+i*10),Vector2(154,-59+i*13),Color(1,0.87,0.6,reach),3,true)

static func arena(c: CanvasItem, stage: int, t: float, font: Font) -> void:
	match stage:
		0: island(c,t)
		1: city(c,t,font)
		2: moon(c,t)
	# Foreground fighting platform.
	c.draw_rect(Rect2(0,566,1280,154),Color("101820") if stage!=2 else Color("242b36"))
	poly(c,[Vector2(0,566),Vector2(1280,566),Vector2(1280,583),Vector2(0,583)],Color("334044"))
	c.draw_line(Vector2(0,567),Vector2(1280,567),Color("96917b"),2)
	for i in 16:
		var x=i*97
		stroke(c,[Vector2(x,584),Vector2(x+18,620),Vector2(x-4,665),Vector2(x+30,720)],Color("0b121c") if stage!=2 else Color("343e4a"),2)
	for i in 9:
		c.draw_line(Vector2(i*163,583),Vector2(i*178-70,720),Color(0.5,0.55,0.59,0.06),1)
	if stage==1:
		for i in 20:
			var x=fmod(i*173.3,1280)
			c.draw_line(Vector2(x,600+i%4*21),Vector2(x+65,600+i%4*21),Color(0.8,0.3,0.55,0.10),3)
	# Dark frame and atmospheric vignette.
	for i in 12:
		c.draw_rect(Rect2(i*3,i*2,1280-i*6,720-i*4),Color(0.015,0.02,0.03,0.018),false,5)

static func island(c: CanvasItem,t: float) -> void:
	c.draw_rect(Rect2(0,0,1280,570),Color("25333b"))
	for i in 22:
		c.draw_rect(Rect2(0,i*24,1280,25),Color("513e40").lerp(Color("283f45"),i/22.0))
	oval(c,Vector2(917,169),Vector2(65,65),Color("eab176"),64)
	oval(c,Vector2(917,169),Vector2(89,89),Color(1,0.65,0.35,0.04),64)
	# Smoke billows above the active caldera.
	for i in 15:
		var p=Vector2(661+sin(i*2.8+t*0.2)*i*6,232-i*17)
		oval(c,p,Vector2(28+i*4,25+i*2),Color(0.12,0.15,0.18,0.45))
	poly(c,[Vector2(243,436),Vector2(545,278),Vector2(614,230),Vector2(674,235),Vector2(734,287),Vector2(1010,437)],Color("243038"))
	poly(c,[Vector2(614,232),Vector2(646,254),Vector2(673,236),Vector2(706,280),Vector2(785,378),Vector2(729,346),Vector2(682,294),Vector2(655,282),Vector2(623,337),Vector2(581,350)],Color("9c4c39"))
	stroke(c,[Vector2(641,249),Vector2(656,280),Vector2(636,311),Vector2(655,348),Vector2(629,388),Vector2(647,425)],Color("f3a45d"),6)
	stroke(c,[Vector2(668,254),Vector2(685,283),Vector2(705,303),Vector2(709,331)],Color("ed7946"),5)
	oval(c,Vector2(644,237),Vector2(33,7),Color("ffbf6e"))
	c.draw_rect(Rect2(0,421,1280,133),Color("294950"))
	for i in 21:
		var y=428+i*6
		var x=fmod(i*173.0+t*(8+i),1260)
		c.draw_line(Vector2(x,y),Vector2(x+80+i*4,y),Color(0.64,0.73,0.66,0.15),1.5,true)
	poly(c,[Vector2(0,485),Vector2(193,467),Vector2(295,506),Vector2(438,499),Vector2(631,542),Vector2(931,493),Vector2(1150,478),Vector2(1280,499),Vector2(1280,568),Vector2(0,568)],Color("182a2d"))
	for side in 2:
		var x=100+side*1100
		var top=Vector2(x+(35 if side==0 else -35),199)
		curve(c,Vector2(x-12,565),Vector2(x+24,411),Vector2(x+8,309),top,Color("14282b"),22)
		for j in 7:
			var a=-PI+j*PI/6
			var end=top+Vector2(cos(a)*175,sin(a)*65+48)
			poly(c,[top,top+Vector2(cos(a)*105,sin(a)*96-28),end],Color("11282b"))
	for i in 36:
		var x=fmod(i*79.7+sin(i)*30+t*(12+i%4*4),1280)
		var y=fposmod(i*51.7-t*(15+i%6*3),550)
		c.draw_circle(Vector2(x,y),1+i%2,Color(1,0.55,0.25,0.3+0.2*sin(t+i)))

static func city(c: CanvasItem,t: float,font: Font) -> void:
	c.draw_rect(Rect2(0,0,1280,570),Color("121b30"))
	for i in 13:
		var x=i*109-40
		var h=160+fmod(i*137,230)
		c.draw_rect(Rect2(x,420-h,94,h+140),Color("1d2b40"))
		for j in 11:
			for k in 4:
				if (i+j+k)%3!=0:
					c.draw_rect(Rect2(x+10+k*21,427-h+j*24,5,9),Color(0.7,0.76,0.7,0.18))
	# Perspective street, converging into the heart of the square.
	poly(c,[Vector2(535,410),Vector2(736,410),Vector2(1140,567),Vector2(143,567)],Color("293144"))
	for i in 8:
		var yy=439+i*i*2
		c.draw_line(Vector2(631-i*15,yy),Vector2(649+i*15,yy),Color("9d938e"),3+i)
	var panels=[Rect2(66,91,174,236),Rect2(266,181,152,150),Rect2(889,97,182,220),Rect2(1092,193,143,160),Rect2(433,231,101,118),Rect2(751,208,100,148)]
	var colors=[Color("bb4e69"),Color("3b8e9b"),Color("d39658"),Color("656ec0"),Color("448f7d"),Color("bd5266")]
	var words=["WILD", "AFTER", "FURY", "24 / 7", "GO", "夜"]
	for i in panels.size():
		var r:Rect2=panels[i]
		c.draw_rect(r.grow(7),Color("0a1321"))
		c.draw_rect(r,colors[i].darkened(0.55))
		c.draw_rect(r,colors[i],false,2)
		for j in 6:
			c.draw_line(r.position+Vector2(8,j*29+15),r.position+Vector2(r.size.x-8,j*29+15),Color(1,1,1,0.05),1)
		c.draw_string(font,r.position+Vector2(10,r.size.y*0.5),words[i],HORIZONTAL_ALIGNMENT_LEFT,-1,32 if i<4 else 24,colors[i].lightened(0.4))
		c.draw_string(font,r.position+Vector2(10,r.size.y*0.5+25),"INSTINCT" if i%2==0 else "MIDNIGHT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,colors[i])
		c.draw_rect(Rect2(r.position+Vector2(11,r.size.y-35),Vector2(r.size.x-22,5)),colors[i])
	for x in [38,456,823,1250]:
		c.draw_line(Vector2(x,355),Vector2(x,566),Color("0c1523"),6)
		c.draw_line(Vector2(x,355),Vector2(x+34,355),Color("0c1523"),5)
		oval(c,Vector2(x+34,358),Vector2(22,7),Color("ffe4aa"))
		poly(c,[Vector2(x+21,362),Vector2(x+47,362),Vector2(x+95,565),Vector2(x-25,565)],Color(1,0.8,0.45,0.025))
	for i in 5:
		var x=80+i*270
		c.draw_rect(Rect2(x,516,65,24),Color("d3a04c"))
		poly(c,[Vector2(x+9,516),Vector2(x+19,503),Vector2(x+43,503),Vector2(x+55,516)],Color("222e3d"))
		c.draw_circle(Vector2(x+13,541),7,Color("0e1520"))
		c.draw_circle(Vector2(x+51,541),7,Color("0e1520"))
	for i in 95:
		var x=fposmod(i*173.7-t*115,1320)-20
		var y=fposmod(i*53.3+t*540,580)
		c.draw_line(Vector2(x,y),Vector2(x-4,y+17),Color(0.65,0.77,0.88,0.13),1,true)

static func moon(c: CanvasItem,t: float) -> void:
	c.draw_rect(Rect2(0,0,1280,570),Color("080e1d"))
	for i in 145:
		var p=Vector2(fmod(i*179.37,1280),fmod(i*73.73,470))
		c.draw_circle(p,0.6+i%3*0.4,Color(0.8,0.86,1,0.28+0.3*abs(sin(t*0.3+i))))
	var earth=Vector2(930,191)
	for i in 6:
		c.draw_circle(earth,84+i*3,Color(0.3,0.58,0.9,0.025))
	c.draw_circle(earth,81,Color("5c9db5"))
	poly(c,[earth+Vector2(-53,-54),earth+Vector2(-22,-69),earth+Vector2(13,-52),earth+Vector2(6,-28),earth+Vector2(32,-11),earth+Vector2(16,16),earth+Vector2(-8,11),earth+Vector2(-16,45),earth+Vector2(-29,54),earth+Vector2(-42,12),earth+Vector2(-62,-7)],Color("a2b79b"))
	curve(c,earth+Vector2(-68,-20),earth+Vector2(-12,-52),earth+Vector2(37,11),earth+Vector2(67,-16),Color("dae9df"),9)
	curve(c,earth+Vector2(-48,40),earth+Vector2(2,15),earth+Vector2(36,56),earth+Vector2(54,39),Color("dae9df"),6)
	oval(c,earth+Vector2(40,4),Vector2(40,70),Color(0.025,0.05,0.10,0.25))
	poly(c,[Vector2(0,444),Vector2(181,335),Vector2(331,423),Vector2(491,342),Vector2(666,430),Vector2(797,391),Vector2(974,443),Vector2(1149,341),Vector2(1280,391),Vector2(1280,570),Vector2(0,570)],Color("30394c"))
	poly(c,[Vector2(0,491),Vector2(180,464),Vector2(302,498),Vector2(518,448),Vector2(727,499),Vector2(998,467),Vector2(1280,509),Vector2(1280,570),Vector2(0,570)],Color("4d5768"))
	for i in 23:
		var x=fmod(i*197.7,1280)
		var y=480+fmod(i*29,79)
		oval(c,Vector2(x,y),Vector2(18+i%4*11,4+i%3*3),Color("303b4d"))
		var rim: Array=[]
		for j in 18:
			var a=float(j)/17*PI
			rim.append(Vector2(x+cos(a)*(18+i%4*11),y+sin(a)*(4+i%3*3)))
		stroke(c,rim,Color(0.6,0.65,0.73,0.2),2)
	# Distant lander and flag, with a rigid horizontal support.
	c.draw_rect(Rect2(206,440,42,30),Color("b5a67b"))
	poly(c,[Vector2(202,438),Vector2(220,419),Vector2(240,424),Vector2(251,440)],Color("8b96a6"))
	for s in [-1,1]:
		stroke(c,[Vector2(227+s*16,460),Vector2(227+s*34,491),Vector2(227+s*44,491)],Color("b8bac4"),3)
	c.draw_line(Vector2(307,488),Vector2(307,411),Color("b8bac4"),2)
	poly(c,[Vector2(308,412),Vector2(353,416),Vector2(353,440),Vector2(308,436)],Color("d0bf91"))
	c.draw_circle(Vector2(328,426),6,Color("5b6a80"))
