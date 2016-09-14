require "Sound"
require "Unit"

local MoOooo = {}

local ktSaveDefault = {
  bEnabled      = true,
  nMoooTimeout  = 3,
  eRankMin      = Unit.CodeEnumRank.Champion,
  bTargetOnly   = false,
}

local knMoooFiles = 13
local kstrIndent  = "     "

local ktCommands = {
  {
    strCmd = "on",
    strDescription = "release the herd!",
    funcCmd = function(ref, strParam)
      ref.tSave.bEnabled = true
      Print("MoOoooing enabled!")
    end,
  },
  {
    strCmd = "off",
    strDescription = "sleepy cattle",
    funcCmd = function(ref, strParam)
      ref.tSave.bEnabled = false
      Print("MoOoooing disabled")
    end,
  },
  {
    strCmd = "timeout",
    strDescription = "time cows need to catch breath (in seconds)",
    funcCmd = function(ref, strParam)
      local nTimeout = tonumber(strParam)
      if nTimeout then
        ref.tSave.nMoooTimeout = nTimeout
        Print("Updated timeout to "..tostring(nTimeout).." seconds")
      else
        Print("Bessie no likey number \""..strParam.."\"")
      end
    end,
  },
  {
    strCmd = "minrank",
    strDescription = "minimun mob rank to bother moooing at",
    funcCmd = function(ref, strParam)
      if strParam == "" then
        Print("Available Ranks:")
        for strRank, nRank in pairs(Unit.CodeEnumRank) do
          Print(kstrIndent.."["..tostring(nRank).."] "..strRank)
        end
      else
        local eRank = Unit.CodeEnumRank[strParam]
        eRank = eRank or Unit.CodeEnumRank[ref:GetStrRank(tonumber(strParam))]
        if eRank then
          ref.tSave.eRankMin = eRank
          Print("Set minrank to ["..tostring(eRank).."] "..ref:GetStrRank(eRank))
        else
          Print("Angus asks what a \""..strParam.."\" is")
        end
      end
    end,
  },
  {
    strCmd = "targetonly",
    strDescription = "only mooo for target/focus",
    funcCmd = function(ref, strParam)
      Print("TODO")
    end,
  },
}

local bPlayedMooo = false

function MoOooo:GetStrRank(eRank)
  for strRank, nRank in pairs(Unit.CodeEnumRank) do
    if nRank == eRank then return strRank end
  end
  return "Unknown"
end

function MoOooo:OnMoooingTimeout()
  bPlayedMooo = false
end

function MoOooo:PlayMoooSound()
  if bPlayedMooo then return else bPlayedMooo = true end
  self.timer = ApolloTimer.Create(self.tSave.nMoooTimeout, false, "OnMoooingTimeout", self)
  local strSound = string.format("Mooos\\mooo%02d.wav", math.random(knMoooFiles))
  Sound.PlayFile(strSound)
  --@debug@
  Print("MoOoooing with "..strSound)
  --@end-debug@
end

function MoOooo:OnCombatLogInterrupted(tData)
  if not self.tSave.bEnabled then return end
  local bPlayMooo = tData.unitTarget and tData.unitTarget:GetRank() >= self.tSave.eRankMin
  if self.tSave.bTargetOnly then
    bPlayMooo = bPlayMooo and GameLib.GetPlayerUnit():GetTargetUnit() == tData.unitTarget
    bPlayMooo = bPlayMooo and GameLib.GetPlayerUnit():GetAlternateTarget() == tData.unitTarget
  end
  if bPlayMooo then self:PlayMoooSound() end
end

--@debug@
function MoOooo:OnTargetUnitChanged(unitTarget)
  if unitTarget and unitTarget:GetRank() >= self.tSave.eRankMin then
    Print("MoOooo: target rank = "..tostring(unitTarget:GetRank()))
  end
end
--@end-debug@

function MoOooo:PrintHelp()
  Print("MoOooo by Aramunn - v@project-version@")
  for _, tCmdData in pairs(ktCommands) do
    Print(kstrIndent..tCmdData.strCmd.." - "..tCmdData.strDescription)
  end
  Print("Current Settings:")
  Print(kstrIndent..(self.tSave.bEnabled and "Enabled" or "Disabled"))
  Print(kstrIndent.."Timeout = "..(tostring(self.tSave.nMoooTimeout)))
  Print(kstrIndent.."Min Rank = ["..tostring(self.tSave.eRankMin).."] "..(self:GetStrRank(self.tSave.eRankMin)))
  if self.tSave.bTargetOnly then Print(kstrIndent.."Target/Focus Only") end
end

function MoOooo:OnSlashCommand(strCmd, strParam)
  strParam = strParam and string.lower(strParam) or ""
  local strOptions = ""
  local nSplitIndex = string.find(strParam, " ") or 0
  if nSplitIndex > 2 then
    strOptions = string.sub(strParam, nSplitIndex + 1)
    strParam = string.sub(strParam, 1, nSplitIndex - 1)
  end
  --@debug@
  Print("MoOooo: Got strParam = "..strParam.." and strOptions = "..strOptions)
  --@end-debug@
  local funcCmd
  for _, tCmdData in pairs(ktCommands) do
    if strParam == tCmdData.strCmd then funcCmd = tCmdData.funcCmd end
  end
  if funcCmd then funcCmd(self, strOptions) else self:PrintHelp() end
end

function MoOooo:OnSave(eLevel)
  if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
    return self.tSave
  end
end

function MoOooo:OnRestore(eLevel, tSave)
  for strName, tData in pairs(ktSaveDefault) do
    self.tSave[strName] = tSave[strName] or tData
  end
end

function MoOooo:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function MoOooo:Init()
  self.tSave = ktSaveDefault
  Apollo.RegisterAddon(self)
end

function MoOooo:OnLoad()
  Apollo.RegisterSlashCommand("mooo", "OnSlashCommand", self)
  Apollo.RegisterEventHandler("CombatLogInterrupted", "OnCombatLogInterrupted", self)
  --@debug@
  Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
  --@end-debug@
end

local MoOoooInst = MoOooo:new()
MoOoooInst:Init()
