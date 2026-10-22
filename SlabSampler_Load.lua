-- Slab Sampler (working title): load the selected item's audio section into
-- the Slab Sampler JSFX. The plugin does all slicing; this script only finds
-- the file and section, and makes the instrument track ready to play live.

local NAME = "Slab Sampler" -- working title (Q13): also the JSFX desc and track name
local GMEM = "SlabSampler"
local FX_NAMES = { "JS:" .. NAME, "JS:SlabSampler.jsfx", "JS:SlabSampler" }
local BUDGET = 18 * 44100 * 2 -- sample values: 18 s of 44.1 kHz stereo (C5, R1.13)
local PATH_MAX = 4000

-- gmem layout shared with SlabSampler.jsfx
local G_REQ, G_TOKEN, G_START, G_LEN, G_PATHLEN, G_PATH = 0, 1, 2, 3, 4, 16

local function fail(text)
  reaper.ShowMessageBox(text, NAME, 0)
end

local function describe(sr, ch)
  return ("%g kHz %s"):format(sr / 1000, ch == 1 and "mono" or "stereo")
end

-- Section and reversed sources wrap the real file. Map the take's window
-- down through every wrapper into the file's own time, so the plugin reads
-- the same audio the item plays, in the file's direction (R1.7, R1.14).
local function resolve(item, take)
  local src = reaper.GetMediaItemTake_Source(take)
  local start = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    * reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  while true do
    local parent = reaper.GetMediaSourceParent(src)
    if not parent then break end
    local is_section, offs, sec_len, rev = reaper.PCM_Source_GetSectionInfo(src)
    if is_section then
      if rev then start = sec_len - (start + len) end
      start = start + offs
    end
    src = parent
  end
  return src, start, len
end

local function find_fx(track)
  for _, name in ipairs(FX_NAMES) do
    local fx = reaper.TrackFX_AddByName(track, name, false, 0)
    if fx >= 0 then return fx end
  end
end

-- Reuse the instrument wherever it is (the track may have been renamed);
-- otherwise create it right below the item's track (R1.10).
local function find_or_create(item)
  for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    local fx = find_fx(track)
    if fx then return track, fx end
  end
  -- IP_TRACKNUMBER is 1-based, so inserting at it lands directly below
  local idx = math.floor(reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(item), "IP_TRACKNUMBER"))
  reaper.InsertTrackAtIndex(idx, true)
  local track = reaper.GetTrack(0, idx)
  reaper.GetSetMediaTrackInfo_String(track, "P_NAME", NAME, true)
  for _, name in ipairs(FX_NAMES) do
    local fx = reaper.TrackFX_AddByName(track, name, false, -1)
    if fx >= 0 then return track, fx end
  end
  reaper.DeleteTrack(track)
end

-- Armed, all MIDI inputs on all channels, monitoring on: pads sound as
-- they are hit (R1.11, Terms: live-ready).
local function make_live_ready(track)
  reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 4096 + 63 * 32)
  reaper.SetMediaTrackInfo_Value(track, "I_RECMON", 1)
  reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
  reaper.SetOnlyTrackSelected(track)
end

-- gmem is shared by every instance in REAPER, so the request carries a token
-- that only the target instance holds in its hidden slider. The counter is
-- written last so the plugin never acts on a half-written request.
local function send(track, fx, path, start, len)
  local token = math.random(1, 999999)
  reaper.TrackFX_SetParam(track, fx, 0, token)
  reaper.gmem_attach(GMEM)
  reaper.gmem_write(G_TOKEN, token)
  reaper.gmem_write(G_START, start)
  reaper.gmem_write(G_LEN, len)
  reaper.gmem_write(G_PATHLEN, #path)
  for i = 1, #path do
    reaper.gmem_write(G_PATH + i - 1, path:byte(i))
  end
  reaper.gmem_write(G_REQ, reaper.gmem_read(G_REQ) + 1)
end

local function main()
  local count = reaper.CountSelectedMediaItems(0)
  if count == 0 then return fail("Select the audio item you want to load.") end -- R1.4
  if count > 1 then return fail("Select only one item to load.") end -- R1.5

  local item = reaper.GetSelectedMediaItem(0, 0)
  local take = reaper.GetActiveTake(item)
  if not take or reaper.TakeIsMIDI(take) then
    return fail("The selected item has no audio file behind it.") -- R1.6
  end
  local src, start, len = resolve(item, take)
  local path = reaper.GetMediaSourceFileName(src)
  if not path or path == "" then
    return fail("The selected item has no audio file behind it.") -- R1.6
  end

  -- REAPER reports AIFF sources as type WAVE, so the extension decides (R1.9)
  local ext = (path:match("%.([^%./\\]+)$") or ""):lower()
  if ext ~= "wav" and ext ~= "aif" and ext ~= "aiff" then
    local kind = ext == "" and "This file type" or (ext:upper() .. " files")
    return fail(kind .. " can't be loaded. Use a WAV or AIFF file.")
  end
  local ch = reaper.GetMediaSourceNumChannels(src)
  if ch > 2 then
    return fail(("The file has %d channels. Only mono and stereo files can be loaded."):format(ch)) -- R1.15
  end
  if #path > PATH_MAX then
    return fail("The file's path is too long to hand over to the plugin.")
  end

  -- an item can extend past its file (looped source); load only real audio
  local file_len = reaper.GetMediaSourceLength(src)
  start = math.max(0, start)
  len = math.min(len, file_len - start)
  if len <= 0 then return fail("The selected item plays no part of its file.") end

  -- same rounding as the plugin, so both agree on what fits (R1.8, R1.13)
  local sr = reaper.GetMediaSourceSampleRate(src)
  if math.floor(len * sr + 0.5) * ch > BUDGET then
    return fail(("The item is %.1f s long. The maximum for a %s file is %.1f s.\n\nShorten the item and try again.")
      :format(len, describe(sr, ch), BUDGET / (sr * ch)))
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local track, fx = find_or_create(item)
  if track then
    make_live_ready(track)
    send(track, fx, path, start, len)
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock(NAME .. ": load selected item", -1)
  if not track then
    fail("The " .. NAME .. " plugin was not found. Copy SlabSampler.jsfx into REAPER's Effects folder.")
  end
end

main()
