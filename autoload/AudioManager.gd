# ============================================================
# AudioManager.gd — Singleton
# Genera tonos PCM programáticamente (sin archivos de audio).
# Uso: AudioManager.tocar("xp") / AudioManager.tocar("nivel")
# ============================================================
extends Node

var _pool    : Array = []   # Array[AudioStreamPlayer]
const POOL   : int   = 5

func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)


# ── API pública ───────────────────────────────────────────────
func tocar(nombre: String) -> void:
	var p : AudioStreamPlayer = _libre()
	if not p: return
	match nombre:
		"xp":
			p.stream    = _tono(660.0, 0.12)
			p.volume_db = -10.0
		"xp_bonus":
			p.stream    = _tono(880.0, 0.18)
			p.volume_db = -8.0
		"nivel":
			p.stream    = _acorde([523.25, 659.25, 783.99], 0.55)
			p.volume_db = -5.0
		"mision":
			p.stream    = _acorde([440.0, 550.0, 660.0], 0.35)
			p.volume_db = -7.0
		"zona":
			p.stream    = _tono(440.0, 0.09)
			p.volume_db = -14.0
		"adoptar":
			p.stream    = _acorde([528.0, 660.0, 792.0], 0.28)
			p.volume_db = -6.0
		"error":
			p.stream    = _tono(200.0, 0.16)
			p.volume_db = -10.0
		"crisis":
			p.stream    = _tono(320.0, 0.22)
			p.volume_db = -8.0
		"resultados":
			p.stream    = _acorde([261.63, 329.63, 392.0, 523.25], 0.80)
			p.volume_db = -4.0
	p.play()


# ── Generadores PCM ──────────────────────────────────────────
func _libre() -> AudioStreamPlayer:
	for p in _pool:
		if not (p as AudioStreamPlayer).playing:
			return p
	return _pool[0]


func _tono(freq: float, dur: float, vol: float = 0.38) -> AudioStreamWAV:
	const SR : int = 22050
	var  n   : int = int(SR * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t   : float = float(i) / float(SR)
		var env : float = sin(PI * t / dur)
		var s   : float = sin(TAU * freq * t) * vol * env
		var s16 : int   = int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2]     = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format   = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo   = false
	wav.data     = data
	return wav


func _acorde(freqs: Array, dur: float, vol: float = 0.26) -> AudioStreamWAV:
	const SR : int = 22050
	var  n   : int = int(SR * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t   : float = float(i) / float(SR)
		var env : float = pow(1.0 - t / dur, 0.6)
		var s   : float = 0.0
		for f in freqs:
			s += sin(TAU * float(f) * t) * vol
		s = clampf(s, -1.0, 1.0) * env
		var s16 : int = int(s * 32767.0)
		data[i * 2]     = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format   = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo   = false
	wav.data     = data
	return wav
