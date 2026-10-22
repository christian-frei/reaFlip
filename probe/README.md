# Slab Probe — file loading test

Throwaway test for the "Verify first" list in `AGENTS.md`. Delete this folder
once the answers are folded into `AGENTS.md`.

## Setup

1. Copy (or symlink) `SlabProbe.jsfx` into REAPER's `Effects/` folder
   (*Options → Show REAPER resource path*).
2. *Actions → New action → Load ReaScript…* → `SlabProbe_Send.lua`.
3. Add **JS: Slab Probe (file loading test)** to any track and open its window.
4. Select an item, run the script. The ReaScript console shows what REAPER
   reports; the plugin window shows what the JSFX read.

## Test matrix

For each case note: plugin message, ch/Hz, values loaded, time, and whether
the "first frames" lines match between console and plugin.

| # | Item | Checks |
|---|---|---|
| 1 | Untrimmed 44.1 kHz stereo WAV, short | absolute path works, gmem handover, values match |
| 2 | Same WAV, item start trimmed by a few seconds | section offset: first frames match, waveform starts at the trim |
| 3 | 48 kHz mono WAV, 24-bit | ch/Hz correct, audition pitch correct, 1 channel |
| 4 | AIFF (16- or 24-bit) | does `file_riff` read it at all? (key question) |
| 5 | Long stem (several minutes), item trimmed to ~10 s near the end | skip time acceptable? any audio dropout while loading? |
| 6 | Section > 18 s at 44.1 kHz stereo | "OVER 18 s BUDGET" shown |
| 7 | Path with spaces and non-ASCII characters (ä, é) | path rebuilt correctly |
| 8 | Item made with "Reverse" / a section source (glued or "Item properties → Section") | console wrapper levels; offset still right? |
| 9 | MP3 or FLAC (for information only) | does `file_riff` read it? |

Audition (slider) plays the loaded section in a loop to check it by ear.

Paste the console output and a description (or screenshot) of the plugin
window for each case back into the conversation.
