# AGENTS.md — ReaFlip

A JSFX instrument for REAPER modelled on the Serato Sample workflow: one
loaded sample section, 16 cues on 16 pads, waveform view, played and edited
from an AlphaTheta SLAB in general MIDI mode. Chops are recorded out to an
MPC2500. Stem separation is done beforehand by STEMwerk and is not part of
this project.

**What the instrument does is specified in `doc/ears.md`** — EARS
requirements with stable ids `Rn.m`. That file is the source of truth for
behaviour; this file covers *how* to build it. If the two disagree,
`doc/ears.md` wins and this file gets fixed. Never change behaviour without a
matching revision of `doc/ears.md` (`/ears-spec revise`, ids stay stable).

## Principles

- **Zero dependencies.** Plain JSFX (EEL2) plus one small Lua ReaScript
  helper. No SWS, js_ReaScriptAPI, ReaImGui, ReaPack packages or external
  libraries (C1).
- **As simple as possible.** Few files, no frameworks, no abstraction layers
  that aren't needed. Prefer one clear function over a clever one.
- **Non-destructive.** Never modify, move, copy, convert or render the source
  file. The plugin only reads it into memory (R22).
- **Workflow, not branding.** Copy Serato Sample's layout and behaviour, not
  its name, logos, artwork or assets. Never decompile or inspect the Serato
  binary (C6). The final name must not use or imitate Serato or AlphaTheta
  trademarks, including "SLAB" (C7).
- **Public release.** The project will be published for the REAPER
  community: keep code readable, the README self-contained, and nothing
  user- or machine-specific in the repo.

## Name

**ReaFlip** ("flipping" a sample = chopping and rearranging it). Decided
2026-10-22 (Q13 closed). Chosen to fit REAPER's own naming next to
ReaSamplOmatic5000 and to stay clear of Serato/AlphaTheta trademarks —
AlphaTheta has a pending trademark application for "SLAB", so the name and
UI never use "Slab". SLAB is presented as one supported controller, not as
part of the product. A web search (2026-10-22) found no existing "ReaFlip"
plugin or script; that is not a trademark clearance.

Long-term goal: offer ReaFlip to Cockos for inclusion in REAPER's stock
JSFX. That favours a licence Cockos can ship (MIT or LGPL), clean
self-contained code, and nothing tied to one controller.

Keep the name in one place per file (JSFX `desc:`, `NAME` in Lua, README
title).

## Repository layout

```
/
├── AGENTS.md
├── .gitignore                   # keeps test audio, REAPER projects/peaks, personal scripts out
├── README.md                    # user-facing install + usage
├── doc/ears.md                  # EARS requirements (source of truth for behaviour)
├── ReaFlip.jsfx             # the instrument: DSP, MIDI, UI, state
├── ReaFlip_Load.lua         # action: send the selected item's section to the JSFX
└── probe/                       # temporary: file-loading test, delete once "Verify first" is answered
```

Keep it flat. Install = copy or symlink `ReaFlip.jsfx` into REAPER's
`Effects/` and `ReaFlip_Load.lua` into `Scripts/`; the README explains
this. Split the JSFX with `import` only if one file becomes hard to read.

## Lua helper — `ReaFlip_Load.lua` (R1, R2)

1. Exactly one selected media item with an audio take, else one
   `ShowMessageBox` naming the problem (R1.4–R1.6).
2. Resolve file and section, in source time:
   - `GetActiveTake` → `GetMediaItemTake_Source`. If it is a section or
     reversed source, read `PCM_Source_GetSectionInfo` and walk to the parent
     with `GetMediaSourceParent`; combine offsets.
   - Section start = take `D_STARTOFFS` (+ section offset), length = item
     `D_LENGTH` × take `D_PLAYRATE` (R1.7). Reversed items load in the file's
     original direction (R1.14).
   - `GetMediaSourceFileName` for the path; abort if empty.
   - Extension must be WAV or AIFF (R1.9). Channels 1 or 2 (R1.15).
   - Length budget check (R1.8, R1.13), see Memory below — refuse here with
     the maximum for this file's rate/channels, before touching the project.
3. Find the instance (R1.16: last-used open window, else any open window,
   else the first; matched by `fx_ident`, not by name); create a track below
   the item's track if there is none, add the JSFX (`TrackFX_AddByName(track, "JS:<desc name>", false, 1)`)
   (R1.10).
4. Make it live-ready: arm, input = all MIDI inputs / all channels,
   monitoring on, select it (R1.11).
5. Hand over via gmem (below). One undo block around all project changes.

## Loading in the JSFX

- **Handover:** shared memory. Lua `reaper.gmem_attach("ReaFlip")` and
  writes: path length, path as character codes, section start and length in
  seconds, then increments a request counter last. The JSFX
  (`options:gmem=ReaFlip`) sees the counter change in `@block`, rebuilds
  the path with `str_setchar`, and loads.
- **Reading:** `file_open(path)`, `file_riff` for rate/channels,
  `file_mem` into the sample buffer from the section start, spread over
  blocks so the audio thread never stalls; show progress (R4.3).
- **Swap vs. fresh load:** a load into an instance with a source keeps cues
  and clamps them (R2); a load into an empty instance starts with no cues
  (R1.3). Every load discards the beatgrid and re-analyses (R4.6).
- **Persistence:** path + section + all state in `@serialize`; reload from the
  path on project open (R5). Missing file → message in the UI, keep state,
  silent pads (R5.3–R5.5, R15.14).

**Verified (probe, 2026-10-21):** `file_open` with an absolute path
(spaces, `~`, iCloud Drive folder), gmem path handover, `file_riff` +
`file_mem` on a 44.1 kHz mono WAV — sample values match REAPER's own;
section offset (take start offset 5.5 s) by reading past the start —
first frames match REAPER's audio accessor, correct by ear. Exact counts
(skipped 242 550, loaded 102 282). `file_avail` right after `file_riff`
returns the whole file's value count, so length/budget checks can happen
before reading. Throughput ≈ 6 M values/s at 64 K values per block
(344 832 values in 53.5 ms) → a 3-minute stereo stem ≈ 3 s worst case.
AIFF 24-bit stereo: `file_riff` reads it (2 ch, 44 100 Hz, 204 564 values
interleaved L/R), first frames match REAPER, correct by ear. REAPER reports
AIFF sources as type `WAVE`, so the Lua helper checks the file extension,
not the source type, for R1.9.
Long skip (2026-10-22): 154.9 s mono WAV, section from 142.5 s — skipped
6 284 250 values, loaded 544 887, 1.11 s, first frames match, **no audible
dropout** with another track playing. 64 K values per block is safe.

**Still to verify (with the real loader, not the probe):** non-ASCII
paths; 48 kHz file (playback pitch); reversed and section sources (offset
maths in the Lua helper); MP3/FLAC refusal.

## Memory

Budget = 18 s × 44 100 Hz × 2 ch = **1 587 600 sample values** (C5, R1.13).
Max length for a file = 1 587 600 / (rate × channels) seconds. Reserve that
buffer plus waveform peaks and state as named regions at the top of
`@init`; set `options:maxmem=` accordingly. Mono sources are stored once and
played on both outputs (R15.15). Play at the file's own rate relative to the
project rate (resample on playback, linear interpolation is fine for v1).

## The JSFX — `ReaFlip.jsfx`

- `@init` — constants, memory regions, defaults. Set `ext_noinit = 1`:
  by default JSFX re-runs `@init` on every playback start (seen in the
  probe — it reset the load state). It still re-runs on samplerate change:
  never wipe a loaded sample or cues there.
- `@slider` — only what should be automatable (master gain, play mode,
  voice mode). Everything else is UI state in `@serialize`.
- `@block` — `midirecv` for pads, dial, encoders, buttons, touch strip,
  learn; `midisend` for everything unused (R20.12); gmem load requests;
  incremental load/analysis work.
- `@sample` — up to 16 voices (one per cue), each: position, direction,
  envelope (attack/release, R17.2–17.3), level, velocity, filter, key shift
  as playback speed (R17.8), loop mode with crossfade (R17.19–17.27). Ramp
  every start/stop (R15.12). Mono voice mode = one voice (R16).
- `@serialize` — leading format version, then path, section, beatgrid,
  16 × cue (start, end-or-unset, level, attack, release, filter, reverse,
  key shift, loop mode, crossfade, colour, name, favourite), modes, learned
  mapping.
- `@gfx` — overview + main waveform, cue handles and regions, playhead,
  zoom/freeze/grid controls, 4×4 pads, parameter row, learn flow. `gfx_*`
  only, no external bitmaps; one dark theme with colours defined once.
  Waveform draws from peaks computed once per load.

### Implementation notes per area

- **Positions** are stored in seconds of the loaded section. A cue without
  an end uses the next cue's start (or section end) as its end (R10.14).
- **Step** = 1/100 of the span shown in the main waveform; dial ticks,
  Slicer region shifts and the minimum cue length all use it (Terms).
  Constant in one place — the user may resize it later.
- **Beatgrid** is one BPM (20–220) + grid start `gs` = first downbeat in
  seconds, kept within the first bar (`norm_gs`); 4/4 is assumed (R8).
  Analysis (`ana_step`, a slice per block, deterministic): onset strength
  per 256-sample frame = rises in log energy of the signal and of its first
  difference; autocorrelation over 20–220 BPM weighted towards 120 BPM
  (log-Gaussian, 0.9 octave) picks the period; a comb over the whole
  envelope refines period (±2 %) and phase (½ frame); the strongest of the
  four beat phases is the downbeat. Saved with the project (format v8), so
  a reopen does not re-analyse; a load or swap does (R4.6).
- **Quantize** is slider 6 (automatable like the other modes). `snap()` sits
  inside `new_cue`, `set_start` and `set_end`, so mouse, dial, arrows and
  lazy chop all snap; with Quantize on a dial tick is 1/8 beat.
- **Find samples** (R14): its own envelope (`tr_step`, after every load and
  reopen): linear rises in level plus first difference per 256-sample frame,
  so "strongest" means loudest. Peaks at least 50 ms apart and above 2 % of
  the strongest are candidates; take the N strongest (N = 4–16, default
  16), sort by time; the attack is where the waveform first reaches 30 %
  of the hit's peak, the cue goes 3 ms before it (longer than the start
  ramp) and back to the nearest zero crossing within 5 ms. Same input →
  same output, no randomness.
- **Auto set** (R13, R14): both modes fill the non-favourite pads from the
  lowest and empty the rest. Slicer starts at the playhead (snapped while
  Quantize is on); slice length is `sl_k`, a power of two of a beat. Shift
  and a new slice length lay the slices out again from `sl_t0` while
  `sl_on`; undo/redo, a load or Find samples end that. Mode, slice length
  and count are saved (format v9).
- **Undo** (R19): all cue state (numeric fields, favourite, colour, name)
  is one contiguous block (`CUE_SIZE`), so a snapshot is one `memcpy` into a
  ring of 128 (`HIST`). `@block` compares the cues with the current
  snapshot; once a change has rested 0.4 s and no mouse button is down, it
  becomes one step — a drag or a burst of dial ticks is one action. Not
  persisted; a load or project restore starts a fresh history.
- **Modifiers** (Terms: Modifier): Shift-click on a pad deletes (R11.2);
  in the parameter row Alt-click resets (R17.9) and Cmd/Ctrl-drag is fine
  (R17.10); Cmd/Ctrl-click on a pad adds or removes it from the selection
  (R18.1); Alt held when a dragged pad is dropped copies (R12.3).
- **Loops** (R17.19–17.27): at every seam the outgoing pass carries on past
  the boundary in a tail voice and fades out while the next pass fades in,
  over the cue's crossfade (at least the 2 ms ramp, so a crossfade of 0
  never clicks). Backward plays one pass in the playing direction, then
  repeats against it; alternate turns at every seam.
- **Filter** (R17.4–17.6): RBJ biquad per voice, Q 0.707, cutoff on a log
  scale 17 kHz → 80 Hz; recomputed in `@block` when the cue's value changes
  while it sounds (the touch strip moves it live).
- **Stretch** (R23, slice 5e): per voice a time rate `V_TSP` (source
  frames per output sample, relative to `step`) next to the pitch rate
  `V_SPD`. Only while they differ does a voice run an engine (`V_GON`);
  otherwise @sample takes the plain read and stretch costs nothing.
  Sync ratio = project `tempo` / source BPM, updated every block (R23.3).
  Slider 8 picks the engine (R23.11):
  - **Drums = WSOLA**: two grains, 25 ms hop, rising sin² crossfade; each
    new grain starts within ±8 ms of the voice's position at the offset with
    the best cross-correlation (every 8th sample of the L+R sum, coarse
    step 6, then fine). Grains are kept inside the cue's bounds. Inline in
    @sample, cheap.
  - **Melodic = phase vocoder**: 2048-point Hann frames, hop 512, one
    complex FFT per frame for both channels (L real, R imaginary), identity
    phase locking on the L+R sum with the same rotation for both channels
    (stereo image holds), phase reset when frame energy doubles (attacks).
    Frames are made in @block into a per-voice overlap-add ring
    (`PV_BASE + v * PVS`), @sample only reads; three silent pre-roll frames
    make the first sample complete, and the first 46 ms blend in from a
    plain read so the attack is untouched. Tails copy the ring.
  - Reads outside the voice's `LO..HI` are silence, so a stretched cue never
    plays past its bounds. EEL2 names are case-insensitive: never use `b`
    and `B` (or `d` and `D`) in one function.
- **Lazy chop** (R9): state machine — idle / pass running; pass ends on stop
  or when all 16 pads hold cues.

## MIDI and SLAB

SLAB runs in **General** (standard MIDI) mode (C3). Defaults until learned:

| Setting | Default | Notes |
|---|---|---|
| `pad_notes` | 0..15 | pads 1–16 (R20.1) — what SLAB sends from its default bank (tested); other controllers use Learn |
| `midi_channel` | 0 = any | 1–16 filters (R20.11) |
| `dial` | unset | CC + encoding: `relative_center`, `relative_twos`, `relative_signbit`, `absolute` |
| `shift`, `delete`, arrows, buttons, encoders 1–4 + presses, touch strip, strip mode | unset | learned (R20.7); unlearned functions are ignored (R21.24) |

The actual SLAB messages are **unknown** (Q1). Never hard-code guesses beyond
the defaults above. Learn infers dial encoding from the value pattern:
near 64 ± n → `relative_center`; 1–3 / 125–127 → `relative_twos`;
1–3 / 65–67 → `relative_signbit`; monotonic 0–127 sweep → `absolute`.
Function assignments are in R21.

**Seen with Learn on the real SLAB (2026-10-23, General mode):** pads notes
0–15 on ch 8; dial CC 60 ch 1, encoders 1–4 CC 16–19 ch 1, all sign-bit
encoded; encoders are touch-sensitive (touch = note 24–27 ch 1, press = note
32–35 ch 1, then touch notes again until release); SHIFT note 70 ch 1;
touch strip CC 14 or 16 ch 7 (two runs differed). Buttons are spread over
ch 1 and ch 7 with shared note numbers (DELETE and PLAY are both note 94).
With SHIFT held the SLAB sends other messages (hence R20.15): dial CC 61,
AUTO SET / FAVORITE / SELECT ALL their note + 1 (81, 83, 97 ch 7).

**Where the map lives (R20.9, R20.14):** each instance keeps its own map in
`@serialize`. Confirming Learn also writes the map to gmem (`G_MAP` = 8192:
version written last, layout id, pad channel, 16 pads,
kind/number/encoding/channel per Learn step). Controls match their exact
channel, since controllers reuse note numbers across channels. Bump
`MAP_LAYOUT` in both files whenever the Learn step list changes, so stale
maps are ignored. New instances in the same REAPER session start with the
gmem map; an instance restoring a map from a project also publishes it when
gmem has none. JSFX can't write
files, so `ReaFlip_Load.lua` copies the gmem map into ExtState
(`ReaFlip/midi_map`, persisted) on each run, and after a restart puts it back
into gmem. After a restart a learned map is the default again once the load
action has run, or once a project with a learned instance is opened.

## Constraints & conventions

- REAPER 7.x, macOS Apple Silicon first; nothing platform-specific (C2).
- JSFX: keep `@sample` cheap; heavy work (peaks, analysis) once per load,
  spread over blocks. Memory regions named by constants.
- Lua 5.4 as embedded in REAPER; locals everywhere.
- Every user-facing failure = one clear message (UI text in the JSFX,
  `ShowMessageBox` in Lua), no stack traces.
- Comments explain *why*, not *what*. Reference requirement ids (`-- R10.9`)
  where a rule is non-obvious, so code traces back to `doc/ears.md`.
- No auto-formatting tools, no build step, no test frameworks.

## Verification (manual, in REAPER)

There are no automated tests. Before calling a change done, walk the
affected requirement groups of `doc/ears.md` by id in REAPER, and always:

1. Load a trimmed item: only its section loads; limits and refusals per
   R1.8–R1.15 (try a 48 kHz file, a mono file, an MP3, a 6-channel file).
2. Save, close, reopen: everything restored (R5); rename the file on disk →
   missing-file message, state kept.
3. All 16 pads in Poly with loops and filters: CPU low, no clicks, UI
   responsive.
4. Learn with the real SLAB; mapping survives a REAPER restart (R20).
5. Source file on disk unchanged (timestamp/size) (R22.1).

## Development workflow

Built in vertical slices, each testable in REAPER on its own. **One slice =
one or more commits on `main`; a slice is committed only after the user has
tested it in REAPER.** Commit messages name the slice and the requirement
groups it covers, e.g. `Slice 1: load section, waveform, persistence (R1–R5, R7.1)`.

| Slice | Scope | Requirement groups |
|---|---|---|
| 1 Load | Lua helper with all checks, track creation, live-ready; JSFX loading with progress, overview waveform, persistence and reload, missing file | R1, R3, R4.3, R5, R7.1, R22 |
| 2 Play | 16 pads by mouse and MIDI notes, Hold/Trigger, Mono/Poly, click-free ramps, velocity; **temporary** 16 even cues on a fresh load (`temp_even_cues`, breaks R1.3 — remove in slice 3) | R15, R16, R17.11–17.12, R17.18 |
| 3 Chop | source player (play/pause, seek, scrub), lazy chop, main waveform with zoom/freeze, cue handles, delete, cues kept and clamped on swap; removes the temporary even cues | R2, R6.1–6.4, R6.7, R7, R9, R10.1–10.2, R10.7–10.9, R10.14–10.16, R11.1–11.2, R11.5–11.7 |
| 4 SLAB | Learn, dial start / Shift+dial end, Delete+pad, app buttons, encoders 1–3, touch strip pad level; the rest shows "comes with slice 5" | R10.3–10.4, R11.3, R20, R21 |
| 5a Shape | per-cue filter, reverse, key shift, loop modes + crossfade; editable parameter row (mouse, reset and fine modifiers); SLAB encoder 4, strip filter/crossfade, Note Repeat = loop mode | R15.16–15.18, R17, R21.5, R21.17, R21.25–21.26 |
| 5b Organise | multi-select, Select All, favourites, delete all, undo/redo, move/swap/copy/rename; parameters on several cues | R11.4, R12, R17.14–17.16, R18, R19, R21.7–21.8, R21.11, R21.13 |
| 5c Beatgrid | tempo + downbeat analysis on load (cancellable), BPM display, double/half, grid edit, Quantize; SLAB arrows (one beat), Shift+Select All | R4, R6.5–6.6, R8, R10.5–10.6, R10.10–10.12, R10.17, R21.27 |
| 5d Autoset | Slicer, Find samples; SLAB Auto Set, Shift+Auto Set | R13, R14, R21.9–21.10 |
| 5e Stretch | stretch engine per voice; Sync to project tempo (needs 5c's BPM), per-cue stretch 0.25–4×, key shift that keeps tempo | R17.8, R23 |

5b comes before 5d because Auto Set overwrites cues and undo is its safety
net; 5c before 5d because Slicer needs the grid. Tempo detection (5c) is the
riskiest piece and gets its own slice.

**Later, not scheduled:** pad and button LEDs on the SLAB. In General mode
the SLAB did not light pad 1 when note 0 ch 8 was sent back to it at
various velocities (tested 2026-10-23). Revisit if AlphaTheta's MIDI
message list turns up. Serato mode's protocol is unpublished and not an
option.

The remote is on GitHub (repo URL supplied by the user); push after each
tested slice. The repo stays private until the distribution section below
is done.

## Installation & distribution — LATER (not before v0.1 works)

> **Flagged for later.** Do none of this until the instrument works in
> REAPER. Kept here so it isn't lost.

Requirements for users: stock REAPER 7.x. **No SWS, no ReaPack, no other
extensions** — JSFX and Lua ReaScript are built into REAPER, and every API
the project uses (gmem, `PCM_Source_GetSectionInfo`, `file_*`) is native.

Manual install (what the README must explain):
1. Download the release zip.
2. REAPER → *Options → Show REAPER resource path*.
3. Copy `ReaFlip.jsfx` into `Effects/`, `ReaFlip_Load.lua` into
   `Scripts/`.
4. *Actions → New action → Load ReaScript…* → pick the Lua file; optionally
   bind it to a key or toolbar button.
5. Put SLAB into General MIDI mode (hold ENCODER MODE). In *Preferences →
   Audio → MIDI Inputs*, right-click SLAB → **Enable input** ("control
   messages only" is not enough — seen in testing: the device is listed but
   nothing reaches the track). Then run Learn.

Publishing (GitHub or GitLab, host to be decided):
- Public repo with a licence file (MIT or LGPL, so Cockos could ship it — user decides).
- Tagged releases (`v0.1.0`, …) with a zip of exactly the two files plus
  README and licence; the download link points at a release, not at `main`.
- README: what it is, requirements, install, SLAB setup, Learn walkthrough,
  short usage, known limits (18 s budget, WAV/AIFF only), credits to the
  Serato Sample workflow as inspiration without using its name as the
  product name.
- Nothing machine-specific in the repo (no absolute paths, no personal
  project files, no test audio that isn't freely licensed).

Optional, also later: a ReaPack `index.xml` in the same repo so ReaPack users
can subscribe and get updates. This is a distribution channel only — the
project must never depend on ReaPack.

## Open questions

Behavioural questions live in `doc/ears.md` (`## Open questions`: Q1 SLAB
MIDI message list). Technical unknowns are listed under
"Verify first" above — resolve them in REAPER, and raise with the user
anything whose answer would change behaviour.
