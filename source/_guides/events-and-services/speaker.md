---
# Copyright 2026 Core Devices LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

title: Speaker
description: |
  How to play tones, melodies, polyphonic tracks, and PCM streams through the
  speaker.
guide_group: events-and-services
order: 11
related_examples:
  - title: Note Player Thing
    url: https://github.com/coredevices/example-apps/tree/main/speaker/note-player-thing
  - title: Note Sample Thing
    url: https://github.com/coredevices/example-apps/tree/main/speaker/note-sample-thing
  - title: Polyphonic Thing
    url: https://github.com/coredevices/example-apps/tree/main/speaker/polyphonic-thing
  - title: PCM Resource Thing
    url: https://github.com/coredevices/example-apps/tree/main/speaker/pcm-resource-thing
---

On hardware platforms with a built-in speaker (`flint` and `emery`, see the
{% guide_link tools-and-resources/hardware-information#platform-support "platform support table" %}), the Speaker API gives apps
four different ways to make sound:

* A **one-shot tone**, for short beeps and confirmation sounds.
* A **note sequence**, for monophonic melodies that the system synthesizes
  from a chosen waveform.
* **Polyphonic tracks**, where up to four voices are mixed together, each
  optionally backed by a pitch-shifted PCM sample.
* **PCM streaming**, for arbitrary audio that the app generates or decodes on
  the fly.

All four paths share the same volume control, status reporting, and
finished-callback mechanism, so an app can mix and match them as it needs to.


## Volume

Every speaker call takes a volume argument in the range `0`–`100`. The global
volume can also be changed at any time, including while audio is playing:

```c
speaker_set_volume(60);
```

For note sequences, individual notes can override the global volume by setting
their `velocity` field (`1`–`127`); a velocity of `0` means "use the global
volume."


## Playing a One-Shot Tone

The simplest path is `speaker_play_tone()`, which plays a single frequency
with a chosen waveform for up to ten seconds. It's well suited to UI beeps,
alarms, and confirmation sounds:

```c
// Play a 440 Hz sine wave for 250 ms at 80% volume
speaker_play_tone(440, 250, 80, SpeakerWaveformSine);
```

The available waveforms are:

| Waveform | Description |
|----------|-------------|
| ``SpeakerWaveformSine`` | Smooth sine wave; the gentlest option. |
| ``SpeakerWaveformSquare`` | Hollow, retro square wave. |
| ``SpeakerWaveformTriangle`` | Brighter than a sine, softer than a square. |
| ``SpeakerWaveformSawtooth`` | Buzzy, harmonically rich sawtooth. |

`speaker_play_tone()` returns `true` if playback started, or `false` if the
duration is out of range or the speaker is busy with a different request.


## Playing a Note Sequence

For monophonic melodies, build an array of ``SpeakerNote`` values and hand it
to `speaker_play_notes()`. Each note carries a MIDI note number, a waveform,
a duration in milliseconds (capped at 10000), and an optional per-note
velocity:

```c
// A short C-major arpeggio
static const SpeakerNote s_arpeggio[] = {
  { .midi_note = 60, .waveform = SpeakerWaveformSine,     .duration_ms = 200 }, // C4
  { .midi_note = 64, .waveform = SpeakerWaveformSine,     .duration_ms = 200 }, // E4
  { .midi_note = 67, .waveform = SpeakerWaveformSine,     .duration_ms = 200 }, // G4
  { .midi_note = 72, .waveform = SpeakerWaveformTriangle, .duration_ms = 400 }, // C5
};

speaker_play_notes(s_arpeggio, ARRAY_LENGTH(s_arpeggio), 80);
```

A `midi_note` of `0` is treated as a rest of the given duration. MIDI note
`60` is middle C (C4), and the standard MIDI note numbering applies.


## Playing Polyphonic Tracks

`speaker_play_tracks()` mixes up to four ``SpeakerTrack`` voices together.
Each track is its own monophonic note sequence, so four tracks together can
play a four-voice harmony. Each track may also point at a ``SpeakerSample``,
which causes the synthesizer to pitch-shift that PCM sample to the requested
note instead of generating a waveform:

```c
static const SpeakerNote s_melody[] = {
  { .midi_note = 72, .waveform = SpeakerWaveformSine, .duration_ms = 250 },
  { .midi_note = 74, .waveform = SpeakerWaveformSine, .duration_ms = 250 },
  { .midi_note = 76, .waveform = SpeakerWaveformSine, .duration_ms = 500 },
};

static const SpeakerNote s_bass[] = {
  { .midi_note = 48, .waveform = SpeakerWaveformTriangle, .duration_ms = 500 },
  { .midi_note = 50, .waveform = SpeakerWaveformTriangle, .duration_ms = 500 },
};

static const SpeakerTrack s_tracks[] = {
  { .notes = s_melody, .num_notes = ARRAY_LENGTH(s_melody) },
  { .notes = s_bass,   .num_notes = ARRAY_LENGTH(s_bass)   },
};

speaker_play_tracks(s_tracks, ARRAY_LENGTH(s_tracks), 80);
```

To use a sample instead of a synthesized waveform, fill in a
``SpeakerSample`` and point the track at it. The sample's `base_midi_note`
specifies which note plays the sample at its original pitch; other notes in
the track are produced by pitch-shifting the same sample. Setting `loop` to
`true` lets a short sample sustain through longer notes:

```c
static const SpeakerSample s_kick = {
  .data           = kick_pcm_data,
  .num_bytes      = sizeof(kick_pcm_data),
  .format         = SpeakerPcmFormat_16kHz_16bit,
  .base_midi_note = 36,    // C2
  .loop           = false,
};

static const SpeakerTrack s_drum_track = {
  .notes     = s_drum_notes,
  .num_notes = ARRAY_LENGTH(s_drum_notes),
  .sample    = &s_kick,
};
```

Pass between 1 and 4 tracks to `speaker_play_tracks()`. Tracks beyond the
fourth are not supported.


## Streaming PCM

For arbitrary audio - synthesised on the fly, decoded from a downloaded file,
or generated procedurally - open a PCM stream, push bytes into it, and close
it when done.

Open a stream by choosing one of the supported PCM formats and a starting
volume:

```c
if (!speaker_stream_open(SpeakerPcmFormat_16kHz_16bit, 80)) {
  // Speaker was busy or unavailable
  return;
}
```

The supported formats are all mono, signed PCM:

| Format | Bytes / sample | Sample rate |
|--------|----------------|-------------|
| ``SpeakerPcmFormat_8kHz_8bit`` | 1 | 8 kHz |
| ``SpeakerPcmFormat_16kHz_8bit`` | 1 | 16 kHz |
| ``SpeakerPcmFormat_8kHz_16bit`` | 2 (little-endian) | 8 kHz |
| ``SpeakerPcmFormat_16kHz_16bit`` | 2 (little-endian) | 16 kHz |

Then push samples into the stream. `speaker_stream_write()` returns the number
of bytes it actually accepted, which may be less than the amount requested if
the internal buffer is full. Loop and retry the remainder:

```c
const uint8_t *cursor = buffer;
uint32_t remaining = buffer_size;
while (remaining > 0) {
  uint32_t written = speaker_stream_write(cursor, remaining);
  cursor    += written;
  remaining -= written;

  if (written == 0) {
    // Buffer is full - yield briefly and try again
    psleep(5);
  }
}
```

When all of the audio has been written, close the stream. `speaker_stream_close()` drains anything still buffered before it stops the
speaker, so it's safe to call as soon as the last byte has been written:

```c
speaker_stream_close();
```


## Stopping Playback Early

Any playback path can be stopped immediately with:

```c
speaker_stop();
```

This applies equally to tones, note sequences, polyphonic tracks, and PCM
streams. If a finish callback is registered, it will fire with the
``SpeakerFinishReasonStopped`` reason.


## Knowing When Playback Ends

To find out when playback finishes - naturally or otherwise - register a
finish callback before starting playback:

```c
static void speaker_finished(SpeakerFinishReason reason, void *ctx) {
  switch (reason) {
    case SpeakerFinishReasonDone:
      APP_LOG(APP_LOG_LEVEL_INFO, "Playback completed");
      break;
    case SpeakerFinishReasonStopped:
      APP_LOG(APP_LOG_LEVEL_INFO, "Stopped by the app");
      break;
    case SpeakerFinishReasonPreempted:
      APP_LOG(APP_LOG_LEVEL_INFO, "Preempted by the system");
      break;
    case SpeakerFinishReasonError:
      APP_LOG(APP_LOG_LEVEL_ERROR, "Playback error");
      break;
  }
}

speaker_set_finish_callback(speaker_finished, NULL);
speaker_play_notes(s_arpeggio, ARRAY_LENGTH(s_arpeggio), 80);
```

The callback runs on the app task, so it's safe to update UI or kick off
follow-up playback from inside it.

The current state can also be polled at any time with `speaker_get_status()`,
which returns one of:

| Status | Meaning |
|--------|---------|
| ``SpeakerStatusIdle`` | Nothing is playing. |
| ``SpeakerStatusPlaying`` | A tone, sequence, track set, or stream is actively playing. |
| ``SpeakerStatusDraining`` | Playback has stopped accepting new input and is finishing the buffered audio. |


## Detecting Speaker Support

Not every platform has a built-in speaker. There are two ways to handle this:

At compile time, the `PBL_SPEAKER` preprocessor define is present on platforms
that have a speaker, so speaker-specific code can be excluded entirely from
builds for platforms that don't:

```c
#if defined(PBL_SPEAKER)
  speaker_play_tone(440, 250, 80, SpeakerWaveformSine);
#else
  vibes_short_pulse();
#endif
```

At runtime, `speaker_play_tone()`, `speaker_play_notes()`,
`speaker_play_tracks()`, and `speaker_stream_open()` all return `false` on
platforms without a speaker (or when the speaker is busy with another
request), so apps that always call through the API can just check the return
value and fall back to vibration or a visual cue.


## Battery Considerations

Driving the speaker is one of the most power-hungry things an app can do.
Long PCM streams in particular keep the audio hardware powered and the CPU
busy moving samples into the buffer. Use the speaker for short, intentional
sounds - confirmations, alarms, brief melodies - and prefer
`speaker_play_tone()` or `speaker_play_notes()` over PCM streaming whenever a
synthesized sound would do the job.
