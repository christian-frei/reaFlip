-- Slab Probe: send the selected item's file and section to the Slab Probe
-- JSFX, and print what REAPER itself reports, so both sides can be compared.
-- Throwaway test, not part of the instrument.

local GMEM = "SlabProbe"
local G_REQ, G_START, G_LEN, G_PATHLEN, G_PATH = 0, 1, 2, 3, 16

local function msg(s) reaper.ShowConsoleMsg(s .. "\n") end
local function fail(s) reaper.ShowMessageBox(s, "Slab Probe", 0) end

local function main()
  if reaper.CountSelectedMediaItems(0) ~= 1 then
    return fail("Select exactly one media item.")
  end
  local item = reaper.GetSelectedMediaItem(0, 0)
  local take = reaper.GetActiveTake(item)
  if not take or reaper.TakeIsMIDI(take) then
    return fail("The selected item has no audio take.")
  end

  local src = reaper.GetMediaItemTake_Source(take)
  local take_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  msg("---- Slab Probe ----")
  msg(("take D_STARTOFFS %.6f  D_PLAYRATE %.4f  item D_LENGTH %.6f"):format(take_offs, rate, item_len))

  -- Section and reversed sources wrap the real file; walk down to it and
  -- print every wrapper so the offset maths can be checked by hand.
  local sec_offs, reversed, depth = 0, false, 0
  while true do
    local is_sec, offs, len, rev = reaper.PCM_Source_GetSectionInfo(src)
    msg(("level %d: type %s  section %s  offs %.6f  len %.6f  rev %s"):format(
      depth, reaper.GetMediaSourceType(src, ""), tostring(is_sec), offs or 0, len or 0, tostring(rev)))
    local parent = reaper.GetMediaSourceParent(src)
    if not parent then break end
    if is_sec then
      sec_offs = sec_offs + offs
      reversed = reversed ~= rev
    end
    src = parent
    depth = depth + 1
  end

  local path = reaper.GetMediaSourceFileName(src)
  if not path or path == "" then
    return fail("The selected item's take has no file on disk.")
  end
  local start = sec_offs + take_offs
  local len = item_len * rate
  msg("file: " .. path)
  msg(("REAPER says: %d ch, %d Hz, file length %.6f s"):format(
    reaper.GetMediaSourceNumChannels(src), reaper.GetMediaSourceSampleRate(src),
    reaper.GetMediaSourceLength(src)))
  msg(("sending section start %.6f s, length %.6f s, reversed %s"):format(start, len, tostring(reversed)))

  -- Reference values for the JSFX's "first frames" line. Only comparable
  -- with take volume 0 dB, pan centre, no take FX, play rate 1.
  local nch = reaper.GetMediaSourceNumChannels(src)
  local sr = reaper.GetMediaSourceSampleRate(src)
  local acc = reaper.CreateTakeAudioAccessor(take)
  local buf = reaper.new_array(4 * nch)
  reaper.GetAudioAccessorSamples(acc, sr, nch, 0, 4, buf)
  reaper.DestroyAudioAccessor(acc)
  local t = buf.table()
  for ch = 1, math.min(nch, 2) do
    local v = {}
    for f = 0, 3 do v[#v + 1] = ("%.6f"):format(t[f * nch + ch]) end
    msg(("accessor first frames %s: %s"):format(ch == 1 and "L" or "R", table.concat(v, " ")))
  end

  reaper.gmem_attach(GMEM)
  reaper.gmem_write(G_PATHLEN, #path)
  for i = 1, #path do
    reaper.gmem_write(G_PATH + i - 1, path:byte(i))
  end
  reaper.gmem_write(G_START, start)
  reaper.gmem_write(G_LEN, len)
  -- counter last: the JSFX only acts when it changes
  reaper.gmem_write(G_REQ, reaper.gmem_read(G_REQ) + 1)
  msg("sent request #" .. math.floor(reaper.gmem_read(G_REQ)))
end

main()
