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
3. Find the instrument track by name; create it below the item's track if
   missing, add the JSFX (`TrackFX_AddByName(track, "JS:<desc name>", false, 1)`)
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
- **Quantize** snaps to 1/8 beat of the grid; off by default (R10.10,
  R10.17).
- **Beatgrid** is one BPM (20–220) + grid start (R8). Tempo detection and
  downbeat on load (R4.1–4.2): onset envelope + autocorrelation is enough;
  keep it deterministic.
- **Find samples** (R14): onset strength from the same onset envelope; take
  the N strongest (N = 4–16, default 16), sort by time, skip favourite pads.
  Same input → same output, no randomness.
- **Undo** (R19): ring buffer of ≥ 100 cue-state snapshots in plugin memory;
  not persisted.
- **Lazy chop** (R9): state machine — idle / pass running; pass ends on stop
  or when all 16 pads hold cues.

## MIDI and SLAB

SLAB runs in **General** (standard MIDI) mode (C3). Defaults until learned:

| Setting | Default | Notes |
|---|---|---|
| `pad_notes` | 36..51 | pads 1–16 (R20.1); SLAB can change these via PAD CODE CHANGE |
| `midi_channel` | 0 = any | 1–16 filters (R20.11) |
| `dial` | unset | CC + encoding: `relative_center`, `relative_twos`, `relative_signbit`, `absolute` |
| `shift`, `delete`, arrows, buttons, encoders 1–4 + presses, touch strip, strip mode | unset | learned (R20.7); unlearned functions are ignored (R21.24) |

The actual SLAB messages are **unknown** (Q1). Never hard-code guesses beyond
the defaults above. Learn infers dial encoding from the value pattern:
near 64 ± n → `relative_center`; 1–3 / 125–127 → `relative_twos`;
1–3 / 65–67 → `relative_signbit`; monotonic 0–127 sweep → `absolute`.
Function assignments are in R21.

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
| 2 Play | 16 pads by mouse and MIDI notes 36–51, Hold/Trigger, Mono/Poly, click-free ramps, velocity | R15, R16, R17.11–17.12, R17.18 |
| 3 Chop | lazy chop, cue handles, main waveform with zoom/freeze, scrub, delete, Slicer, cues kept and clamped on swap | R2, R6, R7, R9, R10, R11, R13 |
| 4 SLAB | Learn, dial start / Shift+dial end, arrows, app buttons, encoders, touch strip | R20, R21 |
| 5 Rest | cue parameters, loops, beatgrid + analysis, Find samples, selection, favourites, undo, move/copy/rename | R4, R8, R12, R14, R17, R18, R19 |

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
5. Put SLAB into General MIDI mode (hold ENCODER MODE), enable it as a MIDI
   input in REAPER preferences, run Learn.

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
