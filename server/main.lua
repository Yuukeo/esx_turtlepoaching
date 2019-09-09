ESX                      = nil
local PlayersHarvesting  = {}
local PlayersCutting     = {}
local PlayersSelling     = {}
local CopsConnected      = 0
local turtle             = 1

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_turtlepoaching:GetUserJob')
AddEventHandler('esx_turtlepoaching:GetUserJob', function(currentZone)
  local _source = source
    local xPlayer  = ESX.GetPlayerFromId(_source)
    TriggerClientEvent('esx_turtlepoaching:ReturnJob', 
      _source,
    xPlayer.job.name, 
    currentZone
    )
end)

function CountCops()
	local xPlayers = ESX.GetPlayers()
	CopsConnected = 0
	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if xPlayer.job.name == 'police' then
			CopsConnected = CopsConnected + 1
		end
	end
	SetTimeout(10000, CountCops)
end
CountCops()

--------------------- Recolte Tortue
local function Harvest(source)
  if CopsConnected < Config.RequiredCopsTurtle then
    TriggerClientEvent('esx:showNotification', source, _U('act_imp_police') .. CopsConnected .. '~s~/' .. Config.RequiredCopsTurtle)
	  return
  end
  SetTimeout(2000, function()
    if PlayersHarvesting[source] == true then
      local xPlayer  = ESX.GetPlayerFromId(source)
      local TurtleQuantity = xPlayer.getInventoryItem('turtle').count
      if TurtleQuantity > 49 then
         TriggerClientEvent('esx:showNotification', source, _U('too_many_turtle'))
      else
        xPlayer.addInventoryItem('turtle', 1)
        Harvest(source)
      end
    end
  end)
end

RegisterServerEvent('esx_turtlepoaching:startHarvest')
AddEventHandler('esx_turtlepoaching:startHarvest', function()
  local _source = source
  PlayersHarvesting[_source] = true
  TriggerClientEvent('esx:showNotification', _source, _U('harvest_in_progress'))
  Harvest(_source)
end)

RegisterServerEvent('esx_turtlepoaching:stopHarvest')
AddEventHandler('esx_turtlepoaching:stopHarvest', function()
  local _source = source
  PlayersHarvesting[_source] = false
end)

------------ Découpe Tortue --------------
local function Cutting(source)
  if CopsConnected < Config.RequiredCopsTurtle then
    TriggerClientEvent('esx:showNotification', source, _U('act_imp_police') .. CopsConnected .. '~s~/' .. Config.RequiredCopsTurtle)
	  return
  end
  SetTimeout(2500, function()
    if PlayersCutting[source] == true then
      local xPlayer  = ESX.GetPlayerFromId(source)
      local TurtleQuantity = xPlayer.getInventoryItem('turtle').count
      local TurtleMeatQuantity = xPlayer.getInventoryItem('turtle_meat').count
      if TurtleMeatQuantity > 49 then
        TriggerClientEvent('esx:showNotification', source, _U('too_many_meat'))
      elseif TurtleQuantity  < 1 then
        TriggerClientEvent('esx:showNotification', source, _U('not_enough_turtle'))
      else
        xPlayer.removeInventoryItem('turtle', 1)
        xPlayer.addInventoryItem('turtle_meat', 1)
        Cutting(source)
      end
    end
  end)
end

RegisterServerEvent('esx_turtlepoaching:startCutting')
AddEventHandler('esx_turtlepoaching:startCutting', function()
  local _source = source
  PlayersCutting[_source] = true
  TriggerClientEvent('esx:showNotification', _source, _U('cutting_in_progress'))
  Cutting(_source)
end)

RegisterServerEvent('esx_turtlepoaching:stopCutting')
AddEventHandler('esx_turtlepoaching:stopCutting', function()
  local _source = source
  PlayersCutting[_source] = false
end)

---------------- vente Tortue
local function Selling(source, zone)
  if CopsConnected < Config.RequiredCopsTurtle then
    TriggerClientEvent('esx:showNotification', source, _U('act_imp_police') .. CopsConnected .. '~s~/' .. Config.RequiredCopsTurtle)
    return
  end
  if PlayersSelling[source] == true then
    local xPlayer  = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem('turtle_meat').count < 10 then
      turtle = 0
    else
      turtle = 1
    end    
    if turtle == 0 then
      TriggerClientEvent('esx:showNotification', source, _U('no_product_sale'))
      return
    elseif xPlayer.getInventoryItem('turtle_meat').count < 10 then
      TriggerClientEvent('esx:showNotification', source, _U('no_meat_sale'))
      turtle = 0
    else
      if (turtle == 1) then
        SetTimeout(5000, function()
          local argent = math.random(150,200)
          xPlayer.removeInventoryItem('turtle_meat', 10)
          xPlayer.addAccountMoney('black_money',argent)
          TriggerClientEvent('esx:showNotification', xPlayer.source, _U('have_earned') .. argent .. _U('black_money'))
          Selling(source)
        end)
      end        
    end
  end
end

RegisterServerEvent('esx_turtlepoaching:startSell')
AddEventHandler('esx_turtlepoaching:startSell', function()
  local _source = source
  PlayersSelling[_source] = true
  TriggerClientEvent('esx:showNotification', _source, _U('sale_in_prog'))
  Selling(_source)
end)

RegisterServerEvent('esx_turtlepoaching:stopSell')
AddEventHandler('esx_turtlepoaching:stopSell', function()
  local _source = source
  PlayersSelling[_source] = false
end)