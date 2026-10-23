# ReaFlip

A sample-chopping instrument for REAPER: load one audio section, set 16 cues
on 16 pads and play them from the window or a MIDI controller, with beatgrid,
auto-slicing, per-cue shaping and time stretch. One JSFX plus one Lua action,
no extensions.

Modelled on the workflow of Serato Sample and tested with the AlphaTheta SLAB
in General MIDI mode. Not affiliated with or endorsed by Serato or AlphaTheta.

## Prerequisites

REAPER 7.x (stock). No SWS, ReaPack, js_ReaScriptAPI or ReaImGui.

## Install

1. Download the zip from the [latest release](https://github.com/christian-frei/reaFlip/releases/latest).
2. In REAPER, open *Options → Show REAPER resource path*.
3. Copy `ReaFlip.jsfx` into `Effects/` and `ReaFlip_Load.lua` into `Scripts/`.
4. *Actions → New action → Load ReaScript…*, pick `ReaFlip_Load.lua`, and bind it
   to a key or toolbar button.

## Use

1. Select one audio item (WAV or AIFF, mono or stereo) and run
   **ReaFlip_Load**. Only the item's visible section loads. Without a ReaFlip
   instance, the action creates a track below the item's track, armed and
   monitoring all MIDI inputs. With several instances, the last-focused open
   window wins.
2. On load, ReaFlip detects tempo and downbeat. Cancel the analysis, halve or
   double the BPM, or fix it in **Grid** edit (drag markers, Alt-drag to slide,
   type a BPM, tap, set start, metronome).
3. Set cues:
   - **Lazy chop**: hit empty pads while the source plays; each hit drops a cue.
   - **Auto set**: **Slicer** lays equal slices (1/16–16 beats) from the
     playhead; **Find** places cues on the 4–16 loudest hits. Favourite pads
     are kept.
   - Drag start and end handles in the main waveform. **Quantize** snaps to
     1/8 beat.
4. Shape the selected cues in the parameter row: level, attack, release,
   filter, key, reverse, loop mode, crossfade, stretch (0.25–4×), keep tempo.
   Drag up/down, Cmd/Ctrl-drag for fine steps, Alt-click to reset.
5. **Sync** stretches everything to the project tempo. **Drums / Melodic**
   picks the stretch engine (WSOLA or phase vocoder). Without any stretch, no
   engine runs.

Pads: Shift-click deletes, Cmd/Ctrl-click adds to the selection, drag moves or
swaps, Alt-drag copies. **Undo / Redo** cover all cue edits.

The project saves the source path, section, cues, grid and MIDI map. The
source file is only read, never changed. A moved or renamed file shows a
message and keeps all cues.

## MIDI controller

Pads default to notes 0–15 on any channel. Assign the rest with **Learn**:
the window walks through each control (pads, dial, Shift, Delete, arrows,
encoders, buttons) and detects the dial and encoder encoding. Skip optional
steps, then confirm. The confirmed map becomes the default for new instances
and survives a restart once the load action has run.

For the SLAB:

1. Hold **ENCODER MODE** to switch it to General MIDI mode.
2. In *Preferences → Audio → MIDI Inputs*, right-click the SLAB and choose
   **Enable input**. "Control messages only" is not enough.
3. Run **Learn**.

Pad LEDs are not driven yet.

## Limits

- WAV and AIFF only; mono or stereo.
- At most 18 s of 44.1 kHz stereo per load (36 s mono; shorter at higher
  rates).
- One tempo per source, 4/4, 20–220 BPM.

## Licence

MIT, see [LICENSE](LICENSE).
