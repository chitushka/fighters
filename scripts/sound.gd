extends Node
## Small procedural soundtrack and synthesized combat foley; no external assets.
var muted: bool = false
var voices: Array[AudioStreamPlayer] = []
var samples: Dictionary = {}
var beat_time: float = 0.0
var beat: int = 0
var in_battle: bool = false

func _ready() -> void:
	for i in 12:
		var p=AudioStreamPlayer.new()
		p.volume_db=-12
		add_child(p)
		voices.append(p)
	for id in ["hit","block","fire","spike","jump","select","gong","ko","bass","hat"]:
		samples[id]=synth(id)

func synth(id: String) -> AudioStreamWAV:
	var rate=22050
	var duration=0.18
	if id=="gong" or id=="ko": duration=1.3
	if id=="bass": duration=0.40
	var count=int(rate*duration)
	var bytes=PackedByteArray()
	bytes.resize(count*2)
	var rng=RandomNumberGenerator.new()
	rng.seed=456
	var filtered=0.0
	for i in count:
		var t=float(i)/rate
		var env=pow(maxf(0,1-t/duration),2)
		var v=0.0
		var noise=rng.randf_range(-1,1)
		filtered=lerpf(filtered,noise,0.18)
		match id:
			"hit": v=sin(TAU*(90*t+6*(1-exp(-t*45))))*0.6+filtered*0.8
			"block": v=sin(TAU*740*t)*0.25+noise*0.22
			"fire": v=filtered*1.5+sin(TAU*(180*t-190*t*t))*0.2
			"spike": v=sin(TAU*(1600*t-1800*t*t))*0.3+noise*0.17
			"jump": v=sin(TAU*(180*t+400*t*t))*0.28
			"select": v=sin(TAU*660*t)*0.22+sin(TAU*990*t)*0.12
			"gong": v=sin(TAU*110*t)*0.4+sin(TAU*167*t)*0.25+sin(TAU*233*t)*0.15
			"ko": v=sin(TAU*(95*t-15*t*t))*0.6+filtered*0.2
			"bass": v=(sin(TAU*55*t)+sin(TAU*82.4*t)*0.3)*0.28
			"hat": v=noise*exp(-t*80)*0.18
		v=clampf(v*env,-1,1)
		bytes.encode_s16(i*2,int(v*24000))
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=rate
	stream.data=bytes
	return stream

func play(id: String, pitch: float = 1.0) -> void:
	if muted or not samples.has(id): return
	for v in voices:
		if not v.playing:
			v.stream=samples[id]
			v.pitch_scale=pitch
			v.play()
			return

func _process(dt: float) -> void:
	beat_time-=dt
	if beat_time<=0:
		beat_time=0.46
		beat+=1
		if beat%2==0: play("bass",[1.0,1.0,0.89,1.12][(beat/8 as int)%4])
		if in_battle: play("hat",1.0 if beat%2==0 else 0.8)

func toggle() -> void:
	muted=not muted
	if muted:
		for p in voices: p.stop()

func _exit_tree() -> void:
	for p in voices:
		p.stop()
		p.stream=null
	voices.clear()
	samples.clear()
