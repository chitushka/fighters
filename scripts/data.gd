extends RefCounted

static var NAMES = ["КОБРА", "КАКТУС", "ЛЕОБЕЛКА"]
static var TITLES = ["ПЛАМЯ И ЯД", "ЖИВАЯ КРЕПОСТЬ", "ДВА ОБЛИЧЬЯ"]
static var COLORS = [Color("e5bf76"), Color("addd91"), Color("f6a15c")]
static var STAGES = ["ОГНЕННЫЙ ОСТРОВ", "ТАЙМС-СКВЕР", "ЛУННАЯ ПОВЕРХНОСТЬ"]
static var STAGE_TAGS = ["ЛАВА • ПЕПЕЛ • ОКЕАН", "НЕОН • ДОЖДЬ • ПОЛНОЧЬ", "ЗЕМЛЯ • ЗВЁЗДЫ • ТИШИНА"]
static var HP = [1000.0, 1150.0, 920.0]
static var SPEED = [260.0, 205.0, 310.0]
static var MOVES = [
	[
		{"name":"Ядовитый укус", "damage":58.0, "range":143.0, "startup":0.13, "active":0.12, "recovery":0.24, "cost":0.0, "poison":true},
		{"name":"Огненный шар", "damage":92.0, "range":0.0, "startup":0.30, "active":0.08, "recovery":0.40, "cost":24.0, "projectile":true},
		{"name":"Королевский бросок", "damage":124.0, "range":185.0, "startup":0.22, "active":0.26, "recovery":0.48, "cost":32.0, "dash":500.0},
		{"name":"Золотое затмение", "damage":235.0, "range":260.0, "startup":0.32, "active":0.32, "recovery":0.70, "cost":100.0, "dash":650.0, "poison":true}
	],
	[
		{"name":"Колючие объятия", "damage":94.0, "range":156.0, "startup":0.25, "active":0.16, "recovery":0.38, "cost":0.0, "grab":true},
		{"name":"Веер шипов", "damage":32.0, "range":0.0, "startup":0.27, "active":0.08, "recovery":0.42, "cost":26.0, "projectile":true},
		{"name":"Корневая осада", "damage":142.0, "range":167.0, "startup":0.31, "active":0.24, "recovery":0.49, "cost":34.0, "dash":385.0},
		{"name":"Пустынный шторм", "damage":255.0, "range":290.0, "startup":0.40, "active":0.30, "recovery":0.80, "cost":100.0}
	],
	[
		{"name":"Леопардовы когти", "damage":51.0, "range":147.0, "startup":0.10, "active":0.12, "recovery":0.20, "cost":0.0},
		{"name":"Пятнистая молния", "damage":118.0, "range":135.0, "startup":0.20, "active":0.38, "recovery":0.40, "cost":28.0, "dash":760.0},
		{"name":"Прыжок охотницы", "damage":105.0, "range":164.0, "startup":0.16, "active":0.28, "recovery":0.36, "cost":30.0, "dash":560.0},
		{"name":"Дикая охота", "damage":245.0, "range":205.0, "startup":0.25, "active":0.46, "recovery":0.62, "cost":100.0, "dash":820.0}
	]
]

static var LORE = [
	"Чёрная королева вулканического острова. Золотой узор предупреждает: одного укуса достаточно, чтобы яд начал действовать.",
	"Светло-зелёный исполин на живых корнях. Держит удар, сжимает врага могучими руками и превращает арену в дождь из шипов.",
	"Белка с леопардовыми пятнами и огромным хвостом. Быстро сближается, а в броске принимает облик настоящего леопарда."
]

static var HELP = [
	["J  /  УКУС", "58 урона + 24 ядом за 3 с. Повторный укус обновляет яд.", "K  /  ОГНЕННЫЙ ШАР", "92 урона • 24 энергии. Летит прямо; можно перепрыгнуть.", "L  /  КОРОЛЕВСКИЙ БРОСОК", "124 урона • 32 энергии. Прыжок с вытяжением к голове.", "I  /  ЗОЛОТОЕ ЗАТМЕНИЕ", "235 урона + яд • 100 энергии. Дальний огненный выпад."],
	["J  /  КОЛЮЧИЕ ОБЪЯТИЯ", "94 урона. Захват пробивает блок, но не достаёт в прыжке.", "K  /  ВЕЕР ШИПОВ", "До 96 урона • 26 энергии. 12 шипов по кругу, по 32 урона.", "L  /  КОРНЕВАЯ ОСАДА", "142 урона • 34 энергии. Таран; в активной фазе броня.", "I  /  ПУСТЫННЫЙ ШТОРМ", "255 урона • 100 энергии. Удар по площади и вспышка шипов."],
	["J  /  ЛЕОПАРДОВЫ КОГТИ", "51 урон. Быстрый удар; удобен для комбинаций.", "K  /  ПЯТНИСТАЯ МОЛНИЯ", "118 урона • 28 энергии. Обращение в леопарда и рывок.", "L  /  ПРЫЖОК ОХОТНИЦЫ", "105 урона • 30 энергии. Воздушный прыжок с когтями.", "I  /  ДИКАЯ ОХОТА", "245 урона • 100 энергии. Длинный стремительный наскок."]
]

static func _static_init() -> void:
	for entry in preload("res://scripts/roster.gd").ENTRIES:
		NAMES.append(entry[0])
		TITLES.append(entry[1])
		COLORS.append(Color(entry[2]))
		HP.append(float(entry[3]))
		SPEED.append(float(entry[4]))
		LORE.append(entry[5])
		var traits:Dictionary=entry[12]
		var moves:Array=[]
		var help:Array=[]
		for i in 4:
			var spec={"name":entry[6][i],"damage":float(entry[7][i]),"cost":float(entry[8][i]),"range":float(entry[10]+(36 if i>=2 else 0)),"startup":entry[9][i],"active":0.12 if i==0 else 0.10 if i==1 else 0.30,"recovery":0.23 if i==0 else 0.39 if i<3 else 0.68}
			if i==1:
				spec.range=0.0
				spec.projectile=true
			if i>=2: spec.dash=float(entry[11])*(1.18 if i==3 else 1.0)
			if i==2 and traits.has("jump"): spec.jump=float(traits.jump)
			if i==2 and traits.get("armor",false): spec.armor=true
			if traits.get("poison",false): spec.poison=true
			if i==1 and traits.has("slow"): spec.slow=traits.slow
			if i==0 and traits.get("grab",false): spec.grab=true
			moves.append(spec)
			help.append(["J","K","L","I"][i]+"  /  "+spec.name.to_upper())
			var description=str(int(spec.damage))+" урона • "+str(int(spec.cost))+" энергии. "
			description+="Захват сквозь блок." if spec.get("grab",false) else "Ближний удар." if i==0 else "Дальний снаряд." if i==1 else "Таран с бронёй." if spec.get("armor",false) else "Прыжок и рывок." if spec.has("jump") else "Рывок вперёд."
			if spec.get("poison",false): description+=" Яд: 24 за 3 с."
			if spec.has("slow"): description+=" Замедление "+str(spec.slow)+" с."
			help.append(description)
		MOVES.append(moves)
		HELP.append(help)
	for arena in preload("res://scripts/roster.gd").ARENAS:
		STAGES.append(arena[0])
		STAGE_TAGS.append(arena[1])
