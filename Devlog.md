# Can you make a rhythm game in Godot? (March of the Ants devlog)

(Cross-post from https://itch.io/jam/acerola-jam-0/topic/3591445/can-you-make-a-rhythm-game-in-godot-march-of-the-ants-devlog)

Hey everyone! ​I wanted to share my experience working with Godot to make a rhythm game and the challenges I encountered with it. Hopefully this devlog passes some useful information and implementation in case you want to make your own rhythm game in Godot.

## Why rhythm games are difficult (to make)

Besides being difficult to play, rhythm games are also difficult to make. For most game engines, there are two important [computing threads](https://en.wikipedia.org/wiki/Thread_(computing))​​ for rhythm games: the **main thread** and the **audio thread**. The main thread contains all of the game logic like inputs, physics, animations, etc., but most importantly it signals to the audio thread what sounds to play. Unfortunately this communication has some few milliseconds of delay, which for rhythm games can be problematic.

To make matters worse, the internal clocks between the main thread and the audio thread are not synced with each other. For shorter durations, this is not a problem. However, if you start two stopwatches in both threads at the same time, they will eventually go out of sync with each other.

Godot has [a great writeup](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html)​ on how you can address these issues as well as going into more detail on Godot's specific audio implementations. This was instrumental knowledge that I needed to program my game.

## ​Goals for my game

​With the above in mind, what did I actually need for my game?

1. Infinite gameplay
2. Obstacles (ants) that move one square forward/backward on the beat
3. Sounds that play on the beat

Once I came up with these ideas, it was time to get to work!

## Determining when a beat happens

The 1st goal actually dictated which method of syncing I used. While not completely accurate, you can get the approximate timestamp of where you are in a song and use that to get what beat you're on:

```gdscript
# First, get the playback position
var time_seconds = $Player.get_playback_position()
# Playback position only updates when an audio mix happens, so we can
# add the time that has passsed since then
time_seconds += AudioServer.get_time_since_last_mix()
# The he audio thread is slightly ahead of the actual sound coming out
# of the speakers/headphones because of latency, so subtract that
time_seconds -= AudioServer.get_output_latency()

# Finally, just a bit of math to get the beat
var beat = time_seconds / 60 * bpm
```

Now that I had the beat value, I could tell when the next beat happens by keeping track of the previous time and comparing it to the current time after truncating the decimal. Once the values changed, I could then signal that a beat happened. All this was centralized in a Conductor class:

```gdscript
class_name Conductor

var _prev_time_seconds: float

# Other scripts can connect to this signal to know when the beat happens
# and what beat it was
signal quarter_passed(beat: int)

func _process(delta: float) -> void:
	var time_seconds = $Player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()

	# Validation
	if not _is_valid_update(time_seconds):
		return

	var beat = time_seconds / 60 * bpm
	var prev_beat = _prev_time_seconds / 60 * bpm

	if floor(beat) > floor(prev_beat):
		# Beat happened this frame!
		quarter_passed.emit(floor(beat))

	# Keep track of the previous frame's time
	_prev_time_seconds = time_seconds
```

With this done, I could connect my ant movement logic to the quarter_passed signal!

You may be asking, why do you need to check if an update is valid? Due to how threading works, the current time can sometimes go backwards, so you need to account for this. There was also some weird bug on web builds that caused time_seconds to be extremely big. So, I didn't process frames where these oddities occurred:

```gdscript
func _is_valid_update(time_seconds: float) -> bool:
	return (
		# No weird web issue
		time_seconds < 1000 and
		# Time moved forward
		time_seconds > _prev_time_seconds)
```

It's important to note that the quarter_passed signal doesn't happen exactly on the beat. Signals can only be emitted on frame updates, so some amount of deviation is expected. Having a high framerate makes this better. For my game, this deviation was ok, but if you are writing a game where even this deviation needs to be known, you can adjust the quarter_passed signal to take the non-truncated beat.

## Dealing with song loops

With infinite gameplay, I had no choice but to have a looping song. This is actually a valid reason for why the current time goes backwards, so I added some logic to account for this properly.

```gdscript
var _loops: int = 0
var _num_beats_in_song: int = round($Player.stream.get_length() / 60 * bpm)

func _process(delta: float) -> void:
	# ...calculate/validate time_seconds

	if time_seconds - _prev_time_seconds < -5:
		# Loop happened!
		_loops += 1
		# Make prev time on the same "loop" as the curr time. It's not
		# recommended to use song length directly as there can be small
		# inaccuracies with audio looping and the song itself
		_prev_time_seconds -= num_beats_in_song / bpm * 60

	var beat = time_seconds / 60 * bpm
	var prev_beat = _prev_time_seconds / 60 * bpm

	# Now add additional beats from previous loops
	beat += _loops * num_beats_in_song
	prev_beat += _loops * num_beats_in_song

	# And do the rest as usual...


# Validation needs to change as well
func _is_valid_update(time_seconds: float) -> bool:
	return (
		# No weird web issue
		time_seconds < 1000 and (
			# Time moved forward
			time_seconds > _prev_time_seconds or
			# Loop happened
			time_seconds - _prev_time_seconds < -5))
```

## "Scheduling" sounds

Unfortunately, [Godot does not support scheduling sounds](https://github.com/godotengine/godot-proposals/issues/1151), so this needs to be done in a more manual way.

Instead of checking if a beat happens *now*, I checked if a beat happens in the *near future*. This can be done by re-adding the output latency back to the current time.

```gdscript
# Similar to quarter_passed, but with audio latency accounted for. Use
# this to schedule sounds on the beat.
signal quarter_will_pass(beat: int)

func _process(delta: float) -> void:
	# ...calculate/validate time_seconds

	# ...emit quarter_passed signal

	# Now adjust the time to be in the future
	var latency_in_beats = AudioServer.get_output_latency() / 60 * bpm
	beat += latency_in_beats
	prev_beat += latency_in_beats
	
	if floor(beat) > floor(prev_beat):
		# Beat will happen soon!
		quarter_will_pass.emit(floor(beat))
	
	# Keep track of the previous frame's time
	_prev_time_seconds = time_seconds
```

I used this to schedule both the backing metronome as well as the other tick sounds indicating how the ants will move/are moving. Here's a small snippet of the backing metronome:

```gdscript
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var hi_tick_player: AudioStreamPlayer = $HiTick
@onready var lo_tick_player: AudioStreamPlayer = $LoTick


func _ready() -> void:
	conductor.quarter_will_pass.connect(_on_beat_passed)


func _on_beat_passed(beat: int) -> void:
	if beat % 4 == 0:
		hi_tick_player.play()
	else:
		lo_tick_player.play()
```

Again, having a higher framerate will result in more accurate sounds, but 100% accuracy will always be impossible. Due to the nature of Godot's audio chunking, sounds can only be played at 15ms intervals (by default), and calling Player.play() schedules the sound to be played at the next mix. My approach schedules the sound to be played on the mix just after the true beat time. However, you can technically look further into the future with [AudioServer.get_time_to_next_mix()](https://docs.godotengine.org/en/stable/classes/class_audioserver.html#class-audioserver-method-get-time-to-next-mix) to ensure sounds start on the mix just before the true beat time.

## Summary

So, can you make a rhythm game in Godot? Yes! With some limitations:

* Framerate matters! Higher framerates result in more accurate beat signals, so game performance needs to be top notch.
* Scheduling sounds is not yet possible, but this can be somewhat worked around using Godot's audio APIs. Some amount of variance is unavoidable due to audio chunking and a [lack of a DSP time/scheduling implementation](https://github.com/godotengine/godot-proposals/issues/1151).

## That's all!

If you're curious, the full source code for my Conductor code can be found [here on my GitHub](https://github.com/PizzaLovers007/Acerola-Jam-0/blob/main/Scripts/Core/Conductor.gd).

Also, check out my game [here](https://pizzalovers007.itch.io/march-of-the-ants)​! I'll be happy to check out yours as well :)