extends SceneTree
## The nights' music: it starts when the night does (not under the briefing), a death does not
## restart it, the Síndico's stages are mixes of one song of one length that go on from the same
## point, and it goes down when the night ends. A night without music is silent. Each file is a
## real loop of the length its bars say.
const Campaign = preload("res://scripts/campaign.gd")
const NIGHT_1 := "res://assets/audio/night_01.ogg"
const STAGES := ["res://assets/audio/night_12_comicio.ogg","res://assets/audio/night_12_apuracao.ogg","res://assets/audio/night_12_heliponto.ogg"]
const RALLY := 11
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(absf((load(NIGHT_1) as AudioStream).get_length()-32*4*60.0/124) < .05,"Night one: 32 bars at 124 BPM")
	for path in STAGES:
		check(absf((load(path) as AudioStream).get_length()-32*4*60.0/138) < .05,"%s: 32 bars at 138 BPM" % path)
	Campaign.state = Campaign.fresh()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.sim.layout.get("music","") == NIGHT_1 and not game.music.playing,"Silence under the first briefing")
	game.start_or_resume()
	check(game.music_path == NIGHT_1 and game.music.playing and game.music.stream.loop,"The night starts, the music with it, looping")
	var stream: AudioStream = game.music.stream
	game.music_fade.kill()
	game.music.volume_db = game.MUSIC_DB
	game.sim.state = "playing"
	game.sim.die()
	game.start_or_resume()
	check(game.music.stream == stream and game.music.playing and game.music.volume_db == game.MUSIC_DB,"A retry does not touch it")
	game.show_room()
	check(game.music_path == "" and game.music_fade.is_valid(),"The night over, it goes down")
	game.queue_free()
	await process_frame
	# Night twelve: the same point of the song from stage to stage.
	Campaign.state = Campaign.fresh()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(RALLY)
	game.start_or_resume()
	check(game.music_path == STAGES[0],"The rally has its mix")
	game.music.seek(20.0)
	for i in 2:
		game._next_stage()
		check(game.music_path == STAGES[i],"Until the next stage starts, this one's mix goes on")
		game.start_or_resume()
		check(game.music_path == STAGES[i+1] and game.music.playing and game.music.volume_db == game.MUSIC_DB,"The next stage has its own mix, at full volume")
	game.queue_free()
	await process_frame
	# A night without a file of its own is silent, even coming straight from one with music.
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.load_level(0)
	game.start_or_resume()
	game.load_level(1)
	game.start_or_resume()
	check(game.music_path == "","Night two has no music yet")
	game.queue_free()
	await process_frame
	print("MUSIC: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
