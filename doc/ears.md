---
feature: slab-sampler
title: ReaFlip — pad slicer for REAPER, played from an AlphaTheta SLAB
author: Christian Frei, producer and owner
contact: christian.frei@gmail.com
date: 2026-10-23
revision: 9
status: ready
---

# ReaFlip
> Let a producer chop one audio file into 16 cues inside REAPER, play and shape them from an AlphaTheta SLAB the way Serato Sample does, and record the result into an MPC2500.

## Context
The workflow is modelled on Serato Sample (help centre: Overview, Loading a file, Source Player,
Beatgrids, Cues, Cue parameters, Autoset, Miscellaneous, Keyboard shortcuts, SLAB Quickstart)
and the AlphaTheta SLAB operating instructions.
Serato Sample is installed and used as the behavioural reference; where this document differs
from it, this document wins.

Stems are separated beforehand in REAPER with STEMwerk; the chosen stem or loop is the source
file for this feature. Finished chops are played from SLAB and recorded as audio into the
MPC2500's inputs.

With Serato Sample, SLAB uses a dedicated "Take Control" link; here SLAB is used in its plain
general MIDI mode, so every SLAB function below works only once its control has been learned.

The instrument is called ReaFlip. It is meant to be published for the REAPER community and,
in the long run, offered to Cockos for inclusion in REAPER.

## Operations
- `load-source` — load the source file of the media item selected in REAPER
- `swap-source` — replace the loaded source with another, keeping all cues
- `eject-source` — unload the source and discard all cues
- `analyse-source` — detect tempo and beatgrid of a newly loaded source
- `reopen-project` — restore the instance's state when the REAPER project is opened
- `play-source` — play, pause, scrub and seek through the source
- `view-waveform` — see, zoom and freeze the waveform with cues and playhead
- `edit-beatgrid` — correct the detected tempo and grid
- `create-cue` — create a cue by pressing a pad (lazy chop or plain)
- `edit-cue-range` — move a cue's start point and set or move its end point
- `delete-cue` — remove one or all cues
- `arrange-cues` — move, swap, copy and rename cues between pads
- `autoset-slicer` — fill the pads with consecutive equal-length slices
- `autoset-find-samples` — fill the pads with cues on the strongest transients
- `play-cue` — trigger a cue from a pad, in Hold or Trigger mode, Mono or Poly
- `shape-cue` — set level, attack, release, filter, reverse and key shift per cue
- `select-cues` — select one, several or all cues, and mark favourites
- `undo-redo` — step back and forward through cue edits
- `learn-controls` — learn which SLAB controls send which MIDI messages
- `control-from-slab` — operate the instrument from SLAB's dial, arrows, encoders, buttons and touch strip
- `stretch-time` — follow the project tempo, and change a cue's length or key without the other

## Requirements

### R1: Load a source
- R1.1 — When the producer loads the selected media item, the system shall load that item's source audio file into the instrument.
- R1.2 — When the producer loads the selected media item, the system shall show the file name and length.
- R1.3 — When a source is loaded into an instance that has no source, the system shall start with no cues set.
- R1.4 — If no media item is selected, then the system shall refuse the load with a message saying so.
- R1.5 — If more than one media item is selected, then the system shall refuse the load with a message saying so.
- R1.6 — If the selected item has no audio file behind it, then the system shall refuse the load with a message saying so.
- R1.7 — When the selected item plays only a section of its file, the system shall load just that section, read from the original file.
- R1.8 — If the section to load is longer than the maximum length for its format, then the system shall refuse the load with a message naming that maximum.
- R1.9 — If the source file is neither WAV nor AIFF, then the system shall refuse the load with a message naming the file's format.
- R1.10 — When the producer loads the selected media item and no instrument exists yet in the project, the system shall create one on a track named after the instrument, placed below the item's track.
- R1.11 — When the producer loads the selected media item, the system shall make the instrument's track live-ready.
- R1.12 — The system shall accept WAV and AIFF files of any sample rate, bit depth and channel count of one or two.
- R1.13 — The system shall set the maximum length as 18 seconds at 44.1 kHz stereo, scaled in proportion to the file's sample rate and channel count (for example 36 seconds for 44.1 kHz mono or 22.05 kHz stereo).
- R1.14 — If the selected item plays its file reversed, then the system shall load the section in the file's original direction.
- R1.15 — If the file has more than two channels, then the system shall refuse the load with a message saying so.
- R1.16 — When the producer loads the selected media item and the project has more than one instrument, the system shall load into the instrument whose window was used last if it is still open, else into one with an open window, else into the first. _(why: a second instance added by hand must be reachable without removing the first)_

### R2: Swap the source
- R2.1 — When the producer loads a source into an instance that already has one, the system shall replace the source and keep every cue with its start, end and parameters.
- R2.2 — If a kept cue's start lies beyond the end of the new source, then the system shall move that cue to the last possible position in the new source.
- R2.3 — If a kept cue's end lies beyond the end of the new source, then the system shall move that end to the end of the new source.

### R3: Eject the source
- R3.1 — When the producer ejects the source, the system shall unload it.
- R3.2 — When the producer ejects the source, the system shall discard all cues.
- R3.3 — While no source is loaded, the system shall show that a source is needed and how to load one.

### R4: Analyse a newly loaded source
- R4.1 — When a source is loaded, the system shall detect its tempo in BPM.
- R4.2 — When a source is loaded, the system shall place a beatgrid of bars and beats at the detected tempo, aligned to the first detected downbeat.
- R4.3 — While analysis is running, the system shall show its progress.
- R4.4 — While analysis is running, when the producer cancels it, the system shall stop the analysis.
- R4.6 — When a source is swapped, the system shall discard the previous beatgrid and analyse the new source.
- R4.7 — When analysis is cancelled, the system shall keep the source loaded with no beatgrid and the BPM shown as unknown.

### R5: Reopen a project
- R5.1 — When a REAPER project containing the instrument is opened, the system shall reload the source from its saved location.
- R5.2 — When a REAPER project containing the instrument is opened, the system shall restore all cues, cue parameters, pad names, beatgrid, modes and learned controls as they were saved.
- R5.3 — If the saved source file is missing, then the system shall show a message naming the missing file.
- R5.4 — If the saved source file is missing, then the system shall keep all cues and settings.
- R5.5 — While the source file is missing, when the producer loads a selected media item, the system shall use it as the source and keep all cues, as in R2.

### R6: Play the source
- R6.1 — When the producer presses play, the system shall play the source from the playhead.
- R6.2 — While the source is playing, when the producer presses pause, the system shall stop playback and leave the playhead where it stopped.
- R6.3 — When the producer drags across the main waveform, the system shall move the playhead with the drag (scrub).
- R6.4 — When the producer clicks the waveform overview, the system shall move the playhead to the clicked position.
- R6.5 — The system shall show the current tempo of the source in BPM.
- R6.6 — When the producer chooses double or half tempo, the system shall double or halve the BPM, with the beatgrid following it.
- R6.7 — If no source is loaded, then the system shall ignore play, scrub and seek.

### R7: View the waveform
- R7.1 — The system shall show an overview of the whole source with all cues and the playhead.
- R7.2 — The system shall show a main waveform of a part of the source with the cues in that part and the playhead.
- R7.3 — The system shall show each cue in its own colour, with that colour also used on its pad.
- R7.4 — The system shall show each cue's start as a handle at the top of the waveform.
- R7.8 — While a cue has an end point, the system shall show that end as a handle at the bottom of the waveform.
- R7.9 — While a cue has an end point, the system shall shade the region between its start and end in the cue's colour.
- R7.5 — When the producer zooms in or out, the system shall show a shorter or longer part of the source in the main waveform.
- R7.6 — While the source is playing and Freeze is off, the system shall keep the playhead in view in the main waveform.
- R7.7 — While Freeze is on, the system shall keep the main waveform still while the playhead moves.
- R7.10 — While Freeze is off, when the producer plays a pad, the system shall show that pad's cue start one tenth of the main waveform's width from its left edge.
- R7.11 — While Freeze is off, when a played pad stops sounding, the system shall show that pad's cue start one tenth of the main waveform's width from its left edge again.
- R7.12 — When the producer drags the current-view box in the overview, the system shall move the main waveform's view with it, keeping the zoom.

### R8: Edit the beatgrid
- R8.1 — When the producer enters grid edit, the system shall show the bar and beat markers on the main waveform.
- R8.2 — While in grid edit, when the producer drags a bar or beat marker, the system shall stretch or compress the grid around the grid start, showing the resulting BPM.
- R8.3 — While in grid edit, when the producer drags the grid with the slip modifier held, the system shall move the whole grid without changing the BPM.
- R8.4 — While in grid edit, when the producer changes the BPM value, the system shall redraw the grid at the new tempo from the grid start.
- R8.5 — While in grid edit, when the producer sets the grid start, the system shall place the first downbeat at the playhead and rebuild the grid from there.
- R8.6 — While in grid edit and the source is playing, when the producer taps the tempo, the system shall set the BPM from the tapped interval.
- R8.7 — While in grid edit with the metronome on and the source playing, the system shall sound a click on every beat of the grid.
- R8.8 — While in grid edit, when the producer saves, the system shall keep the edited grid.
- R8.9 — While in grid edit, when the producer cancels, the system shall restore the grid as it was on entering grid edit.
- R8.10 — When the producer clears the grid, the system shall remove the grid and show the BPM as unknown.
- R8.11 — The system shall hold a single tempo for the whole source.
- R8.12 — If the producer enters a BPM below 20 or above 220, then the system shall keep the previous BPM.
- R8.13 — If a BPM change by dragging, tapping, doubling or halving would leave the range 20 to 220, then the system shall hold the BPM at the range limit.

### R9: Create a cue from a pad
- R9.1 — The system shall have lazy chop switched on in a new instance.
- R9.2 — While lazy chop is on and the source is stopped, when the producer presses an empty pad, the system shall set a cue on that pad at the playhead.
- R9.3 — While lazy chop is on and the source is stopped, when the producer presses an empty pad, the system shall start playing the source from that cue (starting a lazy chop pass).
- R9.4 — While a lazy chop pass runs, when the producer presses another empty pad, the system shall set a cue on that pad at the current playhead.
- R9.5 — While a lazy chop pass runs, when the producer presses a pad, the system shall keep the source playing without interruption.
- R9.6 — While a lazy chop pass runs, when the producer releases a pad, the system shall keep the source playing regardless of Hold mode.
- R9.7 — While a lazy chop pass runs, when the producer presses a pad that already holds a cue, the system shall move the playhead to that cue's start.
- R9.8 — When the source is stopped during a lazy chop pass, the system shall end the pass.
- R9.9 — When all 16 pads hold a cue, the system shall end the lazy chop pass.
- R9.10 — While lazy chop is off, when the producer presses an empty pad, the system shall set a cue on that pad at the playhead without changing whether the source plays.
- R9.11 — When a cue is created, the system shall give it the default parameters: level 0 dB, attack 0, release 0, filter off, not reversed, key shift 0, no end point.
- R9.12 — If no source is loaded, then the system shall ignore presses on empty pads.

### R10: Edit a cue's start and end
- R10.1 — When the producer drags a cue's start handle, the system shall move the cue's start to the dragged position.
- R10.2 — When the producer drags a cue's end handle, the system shall move the cue's end to the dragged position.
- R10.3 — When the producer turns the SLAB dial, the system shall move the selected cue's start by one step per dial tick in the turned direction.
- R10.4 — While SLAB's Shift is held, when the producer turns the dial, the system shall move the selected cue's end by one step per dial tick in the turned direction.
- R10.5 — When the producer presses SLAB's right arrow, the system shall move the selected cue's end one beat later.
- R10.6 — When the producer presses SLAB's left arrow, the system shall move the selected cue's end one beat earlier.
- R10.7 — If an edit would move a cue's start before the beginning of the source, then the system shall hold the start at the beginning.
- R10.8 — If an edit would move a cue's end past the end of the source, then the system shall hold the end at the end of the source.
- R10.9 — If an edit would bring a cue's start and end closer than the minimum cue length, then the system shall stop the edit at the minimum cue length.
- R10.10 — While Quantize is on, when a cue's start or end is created or moved, the system shall snap it to the nearest 1/8 beat of the grid.
- R10.11 — While Quantize is off, the system shall place a cue's start and end exactly where set.
- R10.12 — If Quantize is on and the source has no beatgrid, then the system shall place cue points exactly where set.
- R10.14 — While a cue has no end point set, the system shall treat the start of the next cue in the source as its end, or the end of the source if no cue follows.
- R10.15 — When the producer first edits the end of a cue that has none set, the system shall start the end at the start of the next cue in the source, or at the end of the source if no cue follows.
- R10.16 — The system shall allow a cue's end to be set beyond the start of the next cue.
- R10.17 — The system shall have Quantize off in a new instance.

### R11: Delete cues
- R11.1 — When the producer deletes the selected cue, the system shall remove the cue and its parameters from its pad.
- R11.2 — When the producer clicks a pad with the delete modifier held, the system shall remove that pad's cue.
- R11.3 — While SLAB's Delete is held, when the producer presses a pad, the system shall remove that pad's cue.
- R11.4 — While all cues are selected, when the producer deletes, the system shall remove every cue.
- R11.5 — When a pad's cue is removed, the system shall show that pad as empty.
- R11.6 — When a favourite cue is deleted explicitly, the system shall remove it like any other cue.
- R11.7 — If the producer deletes on an empty pad, then the system shall leave every pad unchanged.

### R12: Move, swap, copy and rename cues
- R12.1 — When the producer drags a cue's pad onto an empty pad, the system shall move the cue with all its parameters to that pad.
- R12.2 — When the producer drags a cue's pad onto a pad that holds a cue, the system shall swap the two cues.
- R12.3 — When the producer drags a cue's pad onto another pad with the copy modifier held, the system shall place a copy of the cue with all its parameters and colour on the target pad.
- R12.4 — If the copy target already holds a cue, then the system shall overwrite that cue with the copy.
- R12.5 — While a pad is dragged, the system shall outline the pad it would land on.
- R12.6 — When the producer renames a pad, the system shall show the new name on that pad.
- R12.7 — If the producer drops a pad onto itself, then the system shall leave its cue unchanged.
- R12.8 — If the producer drags an empty pad, then the system shall leave every pad unchanged.

### R13: Autoset — Slicer
- R13.1 — When the producer runs Slicer, the system shall set 16 consecutive cues of equal length on pads 1–16, the first starting at the playhead.
- R13.2 — The system shall offer slice lengths of 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8 and 16 beats for Slicer.
- R13.3 — When the producer changes the slice length after running Slicer, the system shall reset all 16 slicer cues to the new length from the same first start.
- R13.4 — When the producer shifts the slice region left or right, the system shall move all 16 slicer cues together by one step.
- R13.5 — If a slice would extend beyond the end of the source, then the system shall leave that pad and every later one empty.
- R13.6 — If the source has no beatgrid, then the system shall refuse Slicer with a message that a tempo is needed.
- R13.7 — When Slicer runs, the system shall leave favourite cues and their pads unchanged.
- R13.8 — The system shall use a slice length of 1 beat in a new instance.

### R14: Autoset — Find samples
- R14.1 — The system shall offer a transient count from 4 to 16 for Find samples.
- R14.2 — When the producer runs Find samples with count N, the system shall place cues exactly on the N strongest transients of the source.
- R14.3 — When the producer runs Find samples, the system shall assign the found cues to pads in the order they occur in the source, starting at pad 1.
- R14.4 — When the producer runs Find samples with count N, the system shall leave the pads after the last found cue empty.
- R14.5 — When the producer runs Find samples twice on the same source with the same count, the system shall produce the same cues.
- R14.6 — When Find samples runs, the system shall leave favourite cues and their pads unchanged.
- R14.8 — While favourite cues exist, when Find samples runs, the system shall assign the found cues to the non-favourite pads only, in order from the lowest pad.
- R14.9 — The system shall use a transient count of 16 in a new instance.
- R14.7 — If the source holds fewer than N detectable transients, then the system shall place a cue on each one found and leave the rest of the pads empty.

### R15: Play a cue
- R15.1 — When the producer presses a pad that holds a cue, the system shall play the source from that cue's start.
- R15.2 — When the producer presses a pad that holds a cue, the system shall light that pad while the cue sounds.
- R15.3 — When the producer presses a pad that holds a cue, the system shall make that cue the selected cue.
- R15.4 — The system shall use Hold mode in a new instance.
- R15.5 — While Hold mode is on, when the producer releases the pad, the system shall begin the cue's release.
- R15.6 — While Hold mode is on, when the cue's release has ended, the system shall return the playhead to the cue's start.
- R15.7 — While Hold mode is on and the pad is held, when playback reaches the cue's end, the system shall pause there until the pad is released.
- R15.8 — While Trigger mode is on, the system shall play the cue to its end regardless of how long the pad is held.
- R15.9 — While Trigger mode is on and the cue's release is above 0, when the cue's attack has ended, the system shall begin the cue's release.
- R15.10 — While Trigger mode is on, when the cue's release ends or playback reaches the cue's end, the system shall pause playback.
- R15.11 — When the producer presses a pad whose cue is already sounding, the system shall restart that cue from its start.
- R15.12 — When a cue starts or stops, the system shall ramp its level rather than cut it, so no click is heard.
- R15.13 — When the producer switches between Hold and Trigger, the system shall apply the new mode to all cues.
- R15.14 — If the source is missing, then the system shall stay silent when a pad holding a cue is pressed.
- R15.15 — While the source is mono, the system shall play it equally on both output channels.
- R15.16 — While a cue's loop mode is not off and its pad is held in Hold mode, the system shall loop the cue between its start and end.
- R15.17 — While Trigger mode is on and a cue's loop mode is not off, the system shall loop the cue until its pad is pressed again.
- R15.18 — While Trigger mode is on and a looping cue sounds, when the producer presses its pad again, the system shall begin the cue's release.

### R16: Voice mode
- R16.1 — The system shall use Mono voice mode in a new instance.
- R16.2 — While Mono is on, when the producer presses a pad, the system shall stop any other sounding cue.
- R16.3 — While Poly is on, the system shall let all 16 cues sound at the same time.

### R17: Shape a cue
- R17.1 — When the producer sets a cue's level, the system shall play that cue louder or quieter within −12 dB to +12 dB.
- R17.2 — When the producer sets a cue's attack, the system shall fade the cue in over that time, from 0 to 10 s.
- R17.3 — When the producer sets a cue's release, the system shall fade the cue out over that time, from 0 to 10 s.
- R17.4 — When the producer turns a cue's filter left of centre, the system shall apply a low-pass filter whose cutoff falls from 17 kHz towards 80 Hz.
- R17.5 — When the producer turns a cue's filter right of centre, the system shall apply a high-pass filter whose cutoff rises from 80 Hz towards 17 kHz.
- R17.6 — While a cue's filter is at centre, the system shall play the cue unfiltered.
- R17.7 — While a cue is set to reverse, the system shall play it backwards from its end to its start.
- R17.8 — When the producer sets a cue's key shift, the system shall play that cue higher or lower in semitone steps within −24 to +24, changing its speed and length together with its pitch unless the cue keeps its tempo (R23.6).
- R17.9 — When the producer clicks a parameter with the reset modifier held, the system shall return it to its default value.
- R17.10 — When the producer adjusts a parameter with the fine modifier held, the system shall change it in smaller increments.
- R17.11 — While Velocity is on, the system shall play a cue triggered at velocity 127 at its set level, and lower velocities proportionally quieter.
- R17.12 — While Velocity is off, the system shall play every cue at its set level regardless of velocity.
- R17.13 — While one cue is selected, the system shall show the parameter controls in that cue's colour.
- R17.14 — While several cues are selected, when the producer changes a parameter, the system shall apply the change to every selected cue.
- R17.15 — While several cues are selected and all share a parameter's value, the system shall show that value.
- R17.16 — While several cues are selected and their values for a parameter differ, the system shall show that parameter's default value.
- R17.17 — If an adjustment would take a parameter beyond its range, then the system shall hold it at the range limit.
- R17.18 — The system shall have Velocity on in a new instance.
- R17.19 — The system shall offer the loop modes off, forward, backward and alternate for each cue, with off as the default.
- R17.20 — While a cue's loop mode is forward, the system shall repeat the cue in its playing direction.
- R17.21 — While a cue's loop mode is backward, the system shall repeat the cue against its playing direction.
- R17.22 — While a cue's loop mode is alternate, the system shall play the cue in its playing direction and then against it, in turn.
- R17.23 — While a cue loops, the system shall crossfade over the cue's loop crossfade length at every loop seam.
- R17.24 — The system shall set the loop crossfade length of a new cue to 0.
- R17.25 — The system shall offer a loop crossfade length from 0 up to the cue's length from start to end.
- R17.26 — While a cue is set to reverse, the system shall treat end to start as that cue's playing direction.
- R17.27 — When a cue's start or end is moved so that its loop crossfade exceeds the cue's length, the system shall shorten the crossfade to the cue's length.

### R18: Select cues and mark favourites
- R18.1 — When the producer clicks a pad with the multi-select modifier held, the system shall add that cue to the selection, or remove it if already selected.
- R18.2 — When the producer selects all, the system shall select every pad that holds a cue.
- R18.3 — While all cues are selected, when the producer selects all again, the system shall clear the selection.
- R18.4 — When the producer marks the selected cues as favourite, the system shall show a favourite indicator on their pads.
- R18.5 — When the producer marks a favourite cue as favourite again, the system shall remove the favourite mark.

### R19: Undo and redo
- R19.1 — When the producer undoes, the system shall reverse the most recent cue edit, autoset run, deletion, move, copy or parameter change.
- R19.2 — When the producer redoes, the system shall reapply the most recently undone action.
- R19.3 — The system shall remember at least the last 100 actions per instance.
- R19.4 — When a new action is made after undoing, the system shall discard the actions that could have been redone.
- R19.5 — If there is nothing to undo or redo, then the system shall leave everything unchanged.

### R20: Learn SLAB controls
- R20.1 — The system shall use MIDI notes 0 to 15 as pads 1 to 16 in a new instance, on any MIDI channel. _(why: what SLAB sends from its default pad bank in general MIDI mode)_
- R20.2 — When the producer starts learning, the system shall ask for pads 1 to 16 to be hit in order and show which pads have been captured.
- R20.3 — While learning pads, if the producer hits a note already captured for another pad, then the system shall reject it and ask again.
- R20.4 — When the producer turns the dial clockwise and then counter-clockwise during learning, the system shall record which control the dial is.
- R20.13 — When the producer turns the dial clockwise and then counter-clockwise during learning, the system shall recognise how the dial encodes direction and speed.
- R20.5 — When learning the dial completes, the system shall show the recognised control and encoding for confirmation.
- R20.6 — If the dial's encoding cannot be recognised, then the system shall say so and ask to turn the dial again.
- R20.7 — When the producer learns any other SLAB function listed in R21, the system shall record the control that sends it.
- R20.8 — When the producer skips an optional step, the system shall leave that function unassigned.
- R20.9 — When the producer confirms the learned result, the system shall use it in this instance.
- R20.14 — When the producer confirms the learned result, the system shall use it as the default for new instances.
- R20.15 — When the producer learns a Shift combination (Shift + dial, Auto Set, Favourite, Select All) and the controller sends the same message as without Shift, the system shall use the learned Shift control to tell the two apart. _(why: some controllers change what a control sends while Shift is held, others don't)_
- R20.10 — When the producer cancels learning, the system shall restore the previous assignment.
- R20.11 — While a MIDI channel is set, the system shall ignore SLAB messages on other channels.
- R20.12 — The system shall pass on every MIDI message it does not use, unchanged.

### R21: Control from SLAB
- R21.1 — When the producer presses the dial, the system shall toggle play and pause of the source.
- R21.2 — When the producer turns encoder 1, the system shall change the selected cues' level.
- R21.3 — When the producer turns encoder 2, the system shall change the selected cues' filter.
- R21.4 — When the producer turns encoder 3, the system shall change the selected cues' attack.
- R21.5 — When the producer turns encoder 4, the system shall change the selected cues' key shift.
- R21.6 — When the producer presses an encoder, the system shall reset its parameter to the default for the selected cues.
- R21.7 — When the producer presses Undo, the system shall undo as in R19.1.
- R21.8 — When the producer presses Redo, the system shall redo as in R19.2.
- R21.9 — When the producer presses Auto Set, the system shall run the current autoset mode.
- R21.10 — When the producer presses Shift + Auto Set, the system shall switch to the other autoset mode.
- R21.11 — When the producer presses Favourite, the system shall toggle favourite on the selected cues.
- R21.12 — When the producer presses Shift + Favourite, the system shall switch between Mono and Poly.
- R21.13 — When the producer presses Select All, the system shall select or clear all as in R18.2 and R18.3.
- R21.14 — When the producer presses Trigger Mode, the system shall switch between Hold and Trigger.
- R21.15 — When the producer presses Play, the system shall toggle play and pause of the source.
- R21.16 — When the producer presses Strip Mode, the system shall cycle the touch strip through Filter, Pad Level and Loop Crossfade.
- R21.17 — While the touch strip is in Filter mode, when the producer touches the strip, the system shall set the selected cues' filter from the touched position.
- R21.18 — While the touch strip is in Pad Level mode, when the producer touches the strip, the system shall set the selected cues' level from the touched position.
- R21.24 — If a SLAB function has not been learned, then the system shall ignore it.
- R21.25 — When the producer presses Note Repeat, the system shall move the selected cues to the next loop mode in the order off, forward, backward, alternate.
- R21.26 — While the touch strip is in Loop Crossfade mode, when the producer touches the strip, the system shall set the selected cues' loop crossfade length from the touched position.
- R21.27 — When the producer presses Shift + Select All, the system shall switch Quantize on or off.

### R22: Protect the source
- R22.1 — The system shall never change, move, copy or re-render the source file.
- R22.2 — The system shall keep all cues, parameters and settings with the REAPER project, not in or beside the source file.

### R23: Stretch time
- R23.1 — The system shall have Sync off in a new instance.
- R23.2 — While Sync is on and the source has a beatgrid, the system shall play the source and every cue at the REAPER project tempo without changing their pitch.
- R23.3 — While Sync is on, when the project tempo changes, the system shall follow the new tempo.
- R23.4 — If Sync is on and the source has no beatgrid, then the system shall play at the source's own speed and say that a tempo is needed.
- R23.5 — The system shall offer a stretch per cue from 0.25× to 4× its length, 1× in a new cue.
- R23.6 — The system shall offer per cue a choice to keep its tempo when its key is shifted, off in a new cue.
- R23.7 — While a cue's stretch is not 1×, the system shall play it longer or shorter by that factor without changing its pitch.
- R23.8 — While a cue keeps its tempo, when its key is shifted, the system shall change its pitch without changing its length.
- R23.9 — While Sync is on, the system shall apply each cue's stretch on top of the tempo change.
- R23.10 — The system shall keep cue positions, the waveform and the beatgrid in the source's own time, whatever the stretch.

## Terms
- Source — the one audio file loaded into an instance; a stem or loop chosen after STEMwerk separation.
- Instance — one ReaFlip on one REAPER track; each instance has its own source and cues.
- Cue — a start point in the source, with an optional end point and its own parameters, held on one pad.
- Pad — one of 16 slots, 1 to 16, each triggered by one SLAB pad or a mouse click.
- Selected cue — the cue last triggered or clicked; the target of dial, arrows, encoders and parameter edits.
- Playhead — the current position in the source.
- Beatgrid — bar and beat positions derived from one tempo and one grid start.
- Lazy chop — creating cues by hitting empty pads while the source plays through once.
- Lazy chop pass — the run from the first empty-pad press until playback stops or all pads hold cues.
- Hold mode — a cue plays while its pad is held. Trigger mode — a cue plays to its end once hit.
- Mono / Poly — one cue sounds at a time / several cues sound at once.
- Favourite — a cue protected from being replaced by autoset.
- Transient — the onset of a hit or note in the audio; its strength is how sharply loudness rises.
- Minimum cue length — the shortest a cue may become through an edit: one step at the current zoom. May be resized later.
- Step — one hundredth of the span currently shown in the main waveform; fully zoomed out, one hundredth of the whole source. Used for dial ticks and Slicer region shifts. No acceleration on fast turns.
- Modifier — a held computer key or SLAB Shift that changes what a click, drag or turn does.
- Live-ready — the track is armed for recording, takes MIDI from all inputs, and has input monitoring on, so pads sound as they are hit.
- Section — the part of a file that a REAPER media item plays, between its trimmed start and end.
- Playing direction — start to end for a normal cue, end to start for a reversed cue.
- Loop modes — off: play once; forward: repeat in the playing direction; backward: repeat against it; alternate: with, then against, repeat.
- Loop crossfade — a blend between the audio before and after the loop seam, to avoid a click or gap.

## Constraints
- C1 — Runs inside REAPER 7 as a built-in-scriptable plugin (JSFX), with at most a small Lua ReaScript helper. No SWS, js_ReaScriptAPI, ReaImGui, ReaPack packages or other third-party extensions.
- C2 — macOS on Apple Silicon first; nothing platform-specific.
- C3 — SLAB is used in its general MIDI mode (hold ENCODER MODE to switch from Serato mode to General mode). Serato's "Take Control" link is not available. Pad notes can be changed on the unit (Utility → PAD CODE CHANGE); with the unit's velocity set to DISABLE, pads always send 127.
- C4 — Stem separation is done beforehand by STEMwerk.
- C5 — Sample length is limited to the equivalent of 18 seconds of 44.1 kHz stereo, in the spirit of the MPC2500 workflow.
- C6 — Look and layout follow Serato Sample (waveform overview and main waveform on top, 4×4 pads, coloured cues, parameter row). Serato's name, logos, artwork and assets are not used; the Serato plug-in is not decompiled or inspected.
- C7 — The instrument will be published for the REAPER community. Its final name must not use or imitate Serato or AlphaTheta trademarks (including "Serato" and "SLAB").

## Out of scope
- Stem separation and stem mute/solo/level (done by STEMwerk).
- Stretch quality on a par with commercial engines (Serato's Pitch 'n Time); deck key/BPM changes.
- Key detection and key display.
- More than 16 cues and SLAB Octave −/+ bank switching.
- Autoset modes Set Random, Key Shift Pad and Serato DJ cue import.
- Keyboard (piano) mode and glide; SLAB Piano mode.
- Per-cue output routing to separate outputs.
- Beatgrids with more than one tempo (tempo markers).
- Loading by drag and drop from Finder; loading through a file dialog.
- SLAB's deck encoder layer, Focus mode and Deck Scrub dial mode. SLAB's Record button.
- Exporting slices as audio files.
- Undo history surviving a project reload.
- Note Repeat, Swing and Pitch Bend from SLAB's touch strip; SLAB aftertouch.
- Files with more than two channels; formats other than WAV and AIFF.
- SLAB Quantize size (Shift + Scene Size −/+); Quantize snaps to 1/8 beat only.

## Open questions
- Q1 — Pads are known: notes 0–15 for pads 1–16 in the default bank (tested 2026-10-22). Still unknown: what SLAB sends for the other controls in R20 and R21 (CC numbers, dial and encoder encoding, whether Shift, Delete and the arrows send anything)? The operating instructions refer to a separate MIDI message list at alphatheta.com/support, not found yet. Until then the learn step (R20) discovers it. _(Christian to supply the list, or confirm by learning on the unit)_

## Revisions
- r1 — initial version
- r2 — working title; source is the item's section, WAV/AIFF only, 18 s at 44.1 kHz stereo scaled by format (R1.7–R1.9 changed, R1.12–R1.15 added, R1.10 track name); swap resets the beatgrid, cancelled analysis keeps the source without grid (R4.6, R4.7); BPM range 20–220 (R8.12 changed, R8.13 added); default end = next cue's start, may pass it (R10.14 changed, R10.15–R10.16 added); Quantize off by default (R10.17); step = 1/100 of the visible span (Terms); Velocity on, 127 = set level (R17.11 changed, R17.18); per-cue loop modes and crossfade (R15.16–R15.18, R17.19–R17.24, R21.25, R21.26, R21.16 changed); Shift + Select All toggles Quantize (R21.27); mono plays on both sides (R15.15); Note Repeat removed (R21.19–R21.23 retired); C3, C5 changed, C7 added; Q2–Q6, Q8, Q11 resolved, Q1, Q7, Q9 narrowed, Q12, Q13 added.
- r3 — minimum cue length = one step at current zoom (Terms); defaults Slicer 1 beat, Find samples 16 (R13.8, R14.9); loop crossfade up to cue length (R17.25, R17.27); loop direction follows the playing direction, reverse flips it (R17.20–R17.22 changed, R17.26 added); export dropped; Q7, Q9, Q10, Q12 resolved; status ready.
- r4 — name decided: ReaFlip (title, Context, Terms: Instance); Q13 resolved.
- r5 — default pad notes 0–15, as SLAB sends them (R20.1 changed); Q1 narrowed to the non-pad controls.
- r6 — load target with several instances (R1.16 added); Shift combinations learned on their own (R20.15 added).
- r7 — encoders remapped to level, filter, attack, key shift (R21.2–R21.4 changed); release is set in the window only.
- r8 — time stretch moved into scope: Sync to the project tempo, per-cue stretch and key shift that keeps tempo (R23 added, R17.8 changed, `stretch-time` added, Out of scope narrowed).
- r9 — view follows pad hits: cue start at 10 % on a hit and again when it stops (R7.10, R7.11); overview view box can be dragged (R7.12).
