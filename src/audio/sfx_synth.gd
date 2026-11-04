class_name SfxSynth
extends RefCounted
## Yer tutucu ses üretici (M9-B): data/sounds.json'daki tariflerden (dalga, frekans, süre, ses, zarf) 16 bit mono
## AudioStreamWAV üretir. Gerçek ses dosyası (assets/audio/sfx/<ad>.ogg) varsa Audio onu kullanır, bunu değil.
## Dalgalar: sine, square, triangle, noise; crackle (alkış: rastgele çıtırtılar), typing (klavye: kısa tıkırtılar).
## Bölüm {"gap": sn} sessizliktir. f1 verilirse frekans f0'dan f1'e kayar.


static func build(segments: Array, sample_rate: int, seed_value: int = 1, loop: bool = false) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var samples: PackedFloat32Array = PackedFloat32Array()
	for seg: Dictionary in segments:
		if seg.has("gap"):
			for i: int in int(float(seg["gap"]) * sample_rate):
				samples.append(0.0)
			continue
		samples.append_array(_segment(seg, sample_rate, rng))
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


static func _segment(seg: Dictionary, sr: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n: int = maxi(1, int(float(seg["dur"]) * sr))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var wave: String = str(seg["wave"])
	var vol: float = float(seg.get("vol", 0.3))
	var f0: float = float(seg.get("f0", 440.0))
	var f1: float = float(seg.get("f1", f0))
	var attack: int = int(float(seg.get("attack", 0.005)) * sr)
	var release: int = int(float(seg.get("release", 0.02)) * sr)
	var phase: float = 0.0
	# crackle / typing: rastgele anlarda başlayan kısa patlamalar.
	var bursts: PackedFloat32Array = PackedFloat32Array()
	if wave == "crackle" or wave == "typing":
		bursts.resize(n)
		var count: int = int(float(seg.get("rate", 10)) * float(seg["dur"]))
		var burst_len: int = int(sr * (0.012 if wave == "typing" else 0.02))
		for b: int in count:
			var start: int = rng.randi_range(0, maxi(0, n - burst_len - 1))
			var amp: float = rng.randf_range(0.4, 1.0)
			for k: int in burst_len:
				bursts[start + k] += amp * (1.0 - float(k) / burst_len) * rng.randf_range(-1.0, 1.0)
	for i: int in n:
		var t: float = float(i) / n
		var f: float = lerpf(f0, f1, t)
		phase = fmod(phase + f / sr, 1.0)
		var v: float = 0.0
		match wave:
			"sine": v = sin(TAU * phase)
			"square": v = 1.0 if phase < 0.5 else -1.0
			"triangle": v = 4.0 * absf(phase - 0.5) - 1.0
			"noise": v = rng.randf_range(-1.0, 1.0)
			"crackle", "typing": v = bursts[i]
		var env: float = 1.0
		if i < attack:
			env = float(i) / maxf(1.0, attack)
		elif i > n - release:
			env = float(n - i) / maxf(1.0, release)
		out[i] = v * vol * env
	return out
