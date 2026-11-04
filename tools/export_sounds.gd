extends SceneTree
## Yer tutucu sesleri dinlemek için .wav olarak dışa aktarır (M9-B).
## Çalıştırma: godot --headless --script res://tools/export_sounds.gd -- --out=art/sound_previews


func _init() -> void:
	var out: String = "res://art/sound_previews"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
			if not out.begins_with("res://") and not out.is_absolute_path():
				out = "res://" + out
	var data: GameData = GameData.load_from()
	var dir: String = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(dir)
	var n: int = 0
	for name: String in data.sounds["sfx"]:
		var def: Dictionary = data.sounds["sfx"][name]
		var wav: AudioStreamWAV = SfxSynth.build(def["synth"], int(data.sounds["sample_rate"]), name.hash(), false)
		wav.save_to_wav(dir.path_join(name + ".wav"))
		n += 1
	print("%d ses → %s" % [n, dir])
	quit(0)
