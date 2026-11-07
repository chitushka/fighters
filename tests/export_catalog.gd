extends SceneTree
const Data=preload("res://scripts/data.gd")

func _initialize() -> void:
	var file=FileAccess.open("res://docs/Все бойцы и арены.md",FileAccess.WRITE)
	file.store_string("# Все бойцы и арены\n\n12 бойцов, 48 приёмов, 8 локаций. Новые страницы бойцов переключаются стрелками над карточками. Соперник и арена выбираются независимо.\n\n")
	for kind in Data.NAMES.size():
		file.store_string("## "+Data.NAMES[kind]+" — "+Data.TITLES[kind]+"\n\n"+Data.LORE[kind]+"\n\nЗдоровье: **"+str(int(Data.HP[kind]))+"**. Скорость: **"+str(int(Data.SPEED[kind]))+" px/с**.\n\n")
		file.store_string("| Клавиша | Приём | Урон | Энергия | Подготовка / активность / восстановление |\n|---|---|---:|---:|---|\n")
		for i in 4:
			var m:Dictionary=Data.MOVES[kind][i]
			file.store_string("| "+["J","K","L","I"][i]+" | "+m.name+" | "+str(int(m.damage))+" | "+str(int(m.cost))+" | "+str(int(m.startup*1000))+" / "+str(int(m.active*1000))+" / "+str(int(m.recovery*1000))+" мс |\n")
		file.store_string("\n")
		for i in 4: file.store_string("- "+Data.HELP[kind][i*2]+": "+Data.HELP[kind][i*2+1]+"\n")
		file.store_string("\n")
	file.store_string("## Арены\n\n")
	for i in Data.STAGES.size(): file.store_string(str(i+1)+". **"+Data.STAGES[i]+"** — "+Data.STAGE_TAGS[i]+".\n")
	file.store_string("\nВсе арены имеют отдельный рисунок и анимированные детали. На Луне снижена гравитация; остальные фоны не меняют баланс случайным уроном.\n\n## Новые эффекты\n\n- Яд Скорпиона: 24 урона за 3 секунды; блок предотвращает наложение.\n- Мороз Ледоволка и Ледоголема, чернила Кракена: ходьба замедляется на 45%, срок показан в описании приёма. Блок защищает от эффекта.\n- Захват Кракена пробивает блок, но не достаёт в прыжке.\n- Таран Громоноса и Ледоголема имеет броню в активной фазе: урон проходит, оглушение не прерывает таран.\n- Прыжки Феникса, Ледоволка, Богомола и Неонолиса имеют разные вертикальные импульсы.\n\n## Исправления управления и запуска\n\nСкрипты Windows сохранены с CRLF; запуск работает и из другой рабочей папки. Короткие нажатия не теряются при остановке удара. Ввод во время оглушения ставится в очередь. J можно удерживать для повторных бесплатных ударов. При нехватке энергии появляется подсказка; ближняя атака остаётся доступной.\n")
	file.close()
	print("Catalog saved: 12 fighters / 48 moves / 8 stages")
	quit()
