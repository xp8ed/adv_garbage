ESX = exports["es_extended"]:getSharedObject()
local currentJobs = {}
local resourceName = "Garbage Crew"

RegisterServerEvent('esx_garbagecrew:bagdumped')
AddEventHandler('esx_garbagecrew:bagdumped', function(location, truckPlate)
    local _source = source
    local updated = false

    if currentJobs[location] ~= nil and currentJobs[location].trucknumber == truckPlate then
        if currentJobs[location].workers[_source] ~= nil then
            currentJobs[location].workers[_source] = currentJobs[location].workers[_source] + 1
            currentJobs[location].bagsdropped = currentJobs[location].bagsdropped + 1
            updated = true
        end

        if not updated then
            if currentJobs[location].workers[_source] == nil then
                currentJobs[location].workers[_source] = 1
            end
            currentJobs[location].bagsdropped = currentJobs[location].bagsdropped + 1
        end

        if currentJobs[location].bagsremaining <= 0 and currentJobs[location].bagsdropped == currentJobs[location].totalbags then
            TriggerEvent('esx_garbagecrew:paycrew', currentJobs[location].pos)
        end
    end
end)

RegisterServerEvent('esx_garbagecrew:setworkers')
AddEventHandler('esx_garbagecrew:setworkers', function(location, truckNumber, truckId)
    local _source = source
    local bagTotal = math.random(Config.MinBags, Config.MaxBags)

    if currentJobs[location] == nil then
        currentJobs[location] = {}
    end

    currentJobs[location] = {
        name = 'bagcollection',
        jobboss = _source,
        pos = location,
        totalbags = bagTotal,
        bagsdropped = 0,
        bagsremaining = bagTotal,
        trucknumber = truckNumber,
        truckid = truckId,
        workers = {}
    }

    TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentJobs)
end)

RegisterServerEvent('esx_garbagecrew:unknownlocation')
AddEventHandler('esx_garbagecrew:unknownlocation', function(location)
    if currentJobs[location] ~= nil then
        if next(currentJobs[location].workers) ~= nil then
            TriggerEvent('esx_garbagecrew:paycrew', currentJobs[location].pos)
        end
        currentJobs[location] = nil
        TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentJobs)
    end
end)

RegisterServerEvent('esx_garbagecrew:bagremoval')
AddEventHandler('esx_garbagecrew:bagremoval', function(location)
    if currentJobs[location] ~= nil then
        currentJobs[location].bagsremaining = currentJobs[location].bagsremaining - 1
        TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentJobs)
    end
end)

RegisterServerEvent('esx_garbagecrew:movetruckcount')
AddEventHandler('esx_garbagecrew:movetruckcount', function()
    Config.TruckPlateNumb = Config.TruckPlateNumb + 1
    if Config.TruckPlateNumb == 1000 then
        Config.TruckPlateNumb = 1
    end
    TriggerClientEvent('esx_garbagecrew:movetruckcount', -1, Config.TruckPlateNumb)
end)

RegisterServerEvent('esx_garbagecrew:setconfig')
AddEventHandler('esx_garbagecrew:setconfig', function()
    TriggerClientEvent('esx_garbagecrew:movetruckcount', -1, Config.TruckPlateNumb)
    TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentJobs)
end)

AddEventHandler('playerDropped', function()
    _source = source
    local removeNumber = nil

    for i, v in pairs(currentJobs) do
        if v.jobboss == _source then
            TriggerEvent('esx_garbagecrew:paycrew', v.pos)
            removeNumber = i
        end
        if v.workers[_source] ~= nil then
            v.workers[_source] = nil
        end
    end

    if removeNumber ~= nil then
        currentJobs[removeNumber] = nil
        TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentJobs)
    end
end)

AddEventHandler('esx_garbagecrew:paycrew', function(number)
    print('Request received to payout for stop: ' .. tostring(number))
    local currentCrew = currentJobs[number].workers
    local payAmount = (Config.StopPay / currentJobs[number].totalbags) + Config.BagPay

    for i, v in pairs(currentCrew) do
        local xPlayer = ESX.GetPlayerFromId(i)
        if xPlayer ~= nil then
            local amount = math.ceil(payAmount * v)
            xPlayer.addMoney(amount)
            TriggerClientEvent('esx:showNotification', i, 'Received ' .. tostring(amount) .. ' from this stop!')
        end
    end

    local currentBoss = currentJobs[number].jobboss
    currentJobs[number] = nil
    TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentJobs)
    TriggerClientEvent('esx_garbagecrew:selectnextjob', currentBoss)
end)