require "Sound"
require "Unit"

local MoOooo = {}

local ktSaveDefault = {
  bEnabled      = true,
  nMoooTimeout  = 2,
  eRankMin      = Unit.CodeEnumRank.Champion,
  bBlinders     = false,
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
    strCmd = "minrank",
    strDescription = "minimun mob rank to bother moooing at",
    funcCmd = function(ref, strParam)
      if strParam == "" then
        Print("Available Ranks:")
        for _, tRank in ipairs(ref.arrRanks) do
          Print(kstrIndent.."["..tostring(tRank.nRank).."] "..tRank.strName)
        end
      else
        for _, tRank in ipairs(ref.arrRanks) do
          if strParam == tostring(tRank.nRank) or strParam == string.lower(tRank.strName) then
            ref.tSave.eRankMin = tRank.nRank
            Print("Set minrank to ["..tostring(tRank.nRank).."] "..tRank.strName)
            return
          end
        end
        Print("Angus asks what a \""..strParam.."\" is")
      end
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
    strCmd = "blinders",
    strDescription = "only mooo for target/focus",
    funcCmd = function(ref, strParam)
      if strParam == "on" then
        ref.tSave.bBlinders = true
        Print("Blinders on!")
      elseif strParam == "off" then
        ref.tSave.bBlinders = false
        Print("Blinders off")
      else
        Print("Use \"blinders on\" or \"blinders off\"")
      end
    end,
  },
}

local bPlayedMooo = false

function MoOooo:FillRanks()
  self.arrRanks = {}
  for strName, nRank in pairs(Unit.CodeEnumRank) do
    table.insert(self.arrRanks, {
      nRank   = nRank,
      strName = strName,
    })
  end
  table.sort(self.arrRanks, function(a, b) return a.nRank > b.nRank end)
end

function MoOooo:OnMoooingTimeout()
  bPlayedMooo = false
end

function MoOooo:PlayMoooSound()
  if bPlayedMooo then return else bPlayedMooo = true end
  self.timer = ApolloTimer.Create(self.tSave.nMoooTimeout, false, "OnMoooingTimeout", self)
  local strSound = string.format("Mooos\\mooo%02d.wav", math.random(knMoooFiles))
  Sound.PlayFile(strSound)
end

function MoOooo:OnCombatLogInterrupted(tData)
  if not self.tSave.bEnabled then return end
  local bPlayMooo = tData.unitTarget and tData.unitTarget:GetRank() >= self.tSave.eRankMin
  local unitPlayer = GameLib.GetPlayerUnit()
  if tData.unitTarget == unitPlayer then return end
  if bPlayMooo and self.tSave.bBlinders then
    bPlayMooo = tData.unitTarget == unitPlayer:GetAlternateTarget()
    bPlayMooo = bPlayMooo or tData.unitTarget == unitPlayer:GetTarget()
  end
  if bPlayMooo then self:PlayMoooSound() end
end

function MoOooo:PrintHelp()
  Print("MoOooo by Aramunn - v@project-version@")
  for _, tCmdData in pairs(ktCommands) do
    Print(kstrIndent..tCmdData.strCmd.." - "..tCmdData.strDescription)
  end
  local strCurrent = self.tSave.bEnabled and "Enabled" or "Disabled"
  strCurrent = strCurrent..", ".."timeout = "..tostring(self.tSave.nMoooTimeout)
  strCurrent = strCurrent..", ".."minrank = "..tostring(self.tSave.eRankMin)
  if self.tSave.bBlinders then strCurrent = strCurrent..", Blinders" end
  Print("Current Settings: "..strCurrent)
end

function MoOooo:OnSlashCommand(strCmd, strParam)
  strParam = strParam and string.lower(strParam) or ""
  local strOptions = ""
  local nSplitIndex = string.find(strParam, " ") or 0
  if nSplitIndex > 2 then
    strOptions = string.sub(strParam, nSplitIndex + 1)
    strParam = string.sub(strParam, 1, nSplitIndex - 1)
  end
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
  self:FillRanks()
  Apollo.RegisterAddon(self)
end

function MoOooo:OnLoad()
  Apollo.RegisterSlashCommand("mooo", "OnSlashCommand", self)
  Apollo.RegisterEventHandler("CombatLogInterrupted", "OnCombatLogInterrupted", self)
end

local MoOoooInst = MoOooo:new()
MoOoooInst:Init()
