local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local GUI                     = {}
ESX                           = nil
local myJob                   = nil
local PlayerData              = {}
local HasAlreadyEnteredMarker = false
local LastZone                = nil
local LastPart                = nil
local LastData                = {}
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local TargetCoords            = nil
local borsa                   = nil
GUI.Time                      = 0

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(1)
  end
end)

Citizen.CreateThread(function()
	while true do
	  Citizen.Wait(1000)
	  TriggerEvent('skinchanger:getSkin', function(skin)
		borsa = skin['bags_1']
	  end)
	  Citizen.Wait(1000)
	end
end)

function animsAction(animObj)
  Citizen.CreateThread(function()
    if not playAnim then
      local playerPed = GetPlayerPed(-1);
      if DoesEntityExist(playerPed) then -- Ckeck if ped exist
        dataAnim = animObj

        -- Play Animation
        RequestAnimDict(dataAnim.lib)
        while not HasAnimDictLoaded(dataAnim.lib) do
          Citizen.Wait(0)
        end
        if HasAnimDictLoaded(dataAnim.lib) then
          local flag = 0
          if dataAnim.loop ~= nil and dataAnim.loop then
            flag = 1
          elseif dataAnim.move ~= nil and dataAnim.move then
            flag = 49
          end
          TaskPlayAnim(playerPed, dataAnim.lib, dataAnim.anim, 8.0, -8.0, -1, flag, 0, 0, 0, 0)
          playAnimation = true
        end

        -- Wait end annimation
        while true do
          Citizen.Wait(0)
          if not IsEntityPlayingAnim(playerPed, dataAnim.lib, dataAnim.anim, 3) then
            playAnim = false
            TriggerEvent('ft_animation:ClFinish')
            break
          end
        end
      end -- end ped exist
    end
  end) 
end

function animsActionScenario(animObj)
  Citizen.CreateThread(function()
    if not playAnim then
      local playerPed = GetPlayerPed(-1);
      if DoesEntityExist(playerPed) then
        dataAnim = animObj
        TaskStartScenarioInPlace(playerPed, dataAnim.anim, 0, false)
        playAnimation = true
      end
    end
  end)
end

AddEventHandler('esx_turtlepoaching:hasEnteredMarker', function(zone)
  if zone == 'TurtleSell' then
    if myJob ~= "police" then
      CurrentAction     = 'turtle_resell'
      CurrentActionMsg  = _U('press_sell_turtle')
      CurrentActionData = {zone = zone}
      ESX.ShowNotification(_U('exit_marker'))
    end
  end
  if zone == 'TurtleHarvest' then
    if myJob ~= "police" then
      CurrentAction     = 'turtle_harvest_menu'
      CurrentActionMsg  = _U('harvest_turtle_menu')
      CurrentActionData = {}
      ESX.ShowNotification(_U('exit_marker'))
    end
  end
  if zone == 'TurtleCutting' then
    if myJob ~= "police" then
      CurrentAction     = 'turtle_cutting'
      CurrentActionMsg  = _U('cutting_menu')
      CurrentActionData = {}
      ESX.ShowNotification(_U('exit_marker'))
    end
  end
end)

RegisterNetEvent('esx_turtlepoaching:ReturnJob')
AddEventHandler('esx_turtlepoaching:ReturnJob', function(jobName, currentZone)
  myJob = jobName
  TriggerEvent('esx_turtlepoaching:hasEnteredMarker', currentZone)
end)

AddEventHandler('esx_turtlepoaching:hasExitedMarker', function(zone)
  if zone == 'TurtleSell' then
    TriggerServerEvent('esx_turtlepoaching:stopSell')
  end
  CurrentAction = nil
  ESX.UI.Menu.CloseAll()
end)

-- Display markers
Citizen.CreateThread(function()
  while true do
    Wait(0)
    local coords = GetEntityCoords(GetPlayerPed(-1))
    for k,v in pairs(Config.Zones) do
      if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
        DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
      end
    end
  end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
  while true do
    Wait(0)
    local coords      = GetEntityCoords(GetPlayerPed(-1))
    local isInMarker  = false
    local currentZone = nil
    for k,v in pairs(Config.Zones) do
      if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
        isInMarker  = true
        currentZone = k
      end
    end
    if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
      HasAlreadyEnteredMarker = true
      LastZone                = currentZone
      TriggerServerEvent('esx_turtlepoaching:GetUserJob', currentZone)     
    end
    if not isInMarker and HasAlreadyEnteredMarker then
      HasAlreadyEnteredMarker = false
      TriggerEvent('esx_turtlepoaching:hasExitedMarker', LastZone)
    end
  end
end)

-- Key Controls
Citizen.CreateThread(function()
  while ESX == nil or not ESX.IsPlayerLoaded() do
    Citizen.Wait(1)
  end
    while true do
      Citizen.Wait(1)
      if CurrentAction ~= nil then
        SetTextComponentFormat('STRING')
        AddTextComponentString(CurrentActionMsg)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        if IsControlJustReleased(0, 38)  then
          if Config.NeedBag then
          	if borsa == 40 or borsa == 41 or borsa == 44 or borsa == 45 then
              if CurrentAction == 'turtle_harvest_menu' then
                animsAction({ lib = "amb@code_human_police_investigate@idle_b", anim = "idle_f" })
                Wait(2000)
                TaskStartScenarioInPlace(GetPlayerPed(-1), 'world_human_stand_fishing', 0, false)
                Wait(500)
                TriggerServerEvent('esx_turtlepoaching:startHarvest', CurrentActionData.zone)
              end
              if CurrentAction == 'turtle_cutting' then
                animsAction({ lib = "amb@code_human_police_investigate@idle_b", anim = "idle_f" })
                Wait(2000)
                ClearPedTasks(GetPlayerPed(-1))
                TriggerServerEvent('esx_turtlepoaching:startCutting', CurrentActionData.zone)
                FreezeEntityPosition(PlayerPedId(), true)
              end
              if CurrentAction == 'turtle_resell' then
                animsAction({ lib = "amb@code_human_police_investigate@idle_b", anim = "idle_f" })
                Wait(2000)
          	    TaskStartScenarioInPlace(GetPlayerPed(-1), 'WORLD_HUMAN_CLIPBOARD', 0, false)
          	    Wait(500)
                TriggerServerEvent('esx_turtlepoaching:startSell', CurrentActionData.zone)
              end
            else
              TriggerEvent('esx:showNotification', _U('need_bag'))
            end
          else
            if CurrentAction == 'turtle_harvest_menu' then
              animsAction({ lib = "amb@code_human_police_investigate@idle_b", anim = "idle_f" })
              Wait(2000)
              TaskStartScenarioInPlace(GetPlayerPed(-1), 'world_human_stand_fishing', 0, false)
              Wait(500)
              TriggerServerEvent('esx_turtlepoaching:startHarvest', CurrentActionData.zone)
            end
            if CurrentAction == 'turtle_cutting' then
              animsAction({ lib = "amb@code_human_police_investigate@idle_b", anim = "idle_f" })
              Wait(2000)
              ClearPedTasks(GetPlayerPed(-1))
              TriggerServerEvent('esx_turtlepoaching:startCutting', CurrentActionData.zone)
              FreezeEntityPosition(PlayerPedId(), true)
            end
            if CurrentAction == 'turtle_resell' then
              animsAction({ lib = "amb@code_human_police_investigate@idle_b", anim = "idle_f" })
              Wait(2000)
          	  TaskStartScenarioInPlace(GetPlayerPed(-1), 'WORLD_HUMAN_CLIPBOARD', 0, false)
          	  Wait(500)
              TriggerServerEvent('esx_turtlepoaching:startSell', CurrentActionData.zone)
            end
          end     
          CurrentAction = nil
        end        
      end
      if IsControlJustReleased(0, Keys['X']) and GetLastInputMethod(2) and not isDead then
        ClearPedTasks(GetPlayerPed(-1))
        TriggerServerEvent('esx_turtlepoaching:stopHarvest')
        TriggerServerEvent('esx_turtlepoaching:stopCutting')
        TriggerServerEvent('esx_turtlepoaching:stopSell')
        FreezeEntityPosition(PlayerPedId(), false)
      end
    end
end)