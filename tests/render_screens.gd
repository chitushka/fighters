extends SceneTree

var game: Node

func _initialize() -> void:
	run.call_deferred()

func shot(file: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+file+".png")

func run() -> void:
	game=load("res://scripts/main.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.audio.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://test-results")
	for i in game.Data.NAMES.size():
		game.guide_page=i
		game.screen="guide"
		await shot("guide_"+str(i))
	for page in 4:
		game.roster_page=page
		game.screen="menu"
		await shot("roster_"+str(page))
	for i in game.Data.STAGES.size():
		game.stage=i
		game.screen="menu"
		await shot("menu_"+str(i))
		game.guide_page=i
		game.screen="guide"
		await shot("guide_"+str(i))
		game.selected=(i+3)%game.Data.NAMES.size()
		game.opponent=(i+4)%game.Data.NAMES.size()
		game.mode=2
		game.start_match()
		game.intro=0
		game.fighters[0].x=450
		game.fighters[1].x=820
		await shot("arena_"+str(i))
	game.selected=2
	game.opponent=0
	game.start_match()
	game.intro=0
	game.fighters[0].x=450
	game.fighters[1].x=820
	game.fighters[0].energy=100
	game.fighters[0].attack(1)
	for j in 20: game.battle(1.0/60)
	await shot("leopard")
	game.screen="pause"
	await shot("pause")
	game.winner=0
	game.scores=[2,1]
	game.screen="result"
	await shot("result")
	print("RENDER OK: 12 fighters, 4 roster pages, 8 arenas, pause and result")
	game.queue_free()
	await process_frame
	quit()
