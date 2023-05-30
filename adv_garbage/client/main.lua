ESX = exports["es_extended"]:getSharedObject()
local currentstop = 0
local HasAlreadyEnteredArea, clockedin, vehiclespawned, albetogetbags, truckdeposit = false, false, false, false, false
local work_truck, NewDrop, LastDrop, binpos, truckpos, garbagebag, truckplate, mainblip, AreaType, AreaInfo, currentZone, AreaMarker, gbag, gbag2
local Blips, CollectionJobs, depositlist = {}, {}, {}
local baginhand = false



Citizen.CreateThread(function()		
		mainblip = AddBlipForCoord(Config.Zones[2].pos)

		SetBlipSprite (mainblip, 318)
		SetBlipDisplay(mainblip, 4)
		SetBlipScale  (mainblip, 1.2)
		SetBlipColour (mainblip, 5)
		SetBlipAsShortRange(mainblip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('blip_job'))
		EndTextCommandSetBlipName(mainblip)
	
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
	TriggerServerEvent('esx_garbagecrew:setconfig')
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName or not ESX.PlayerLoaded then return end
    PlayerData = ESX.GetPlayerData()
    PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	--PlayerData.job = job
	TriggerEvent('esx_garbagecrew:checkjob')
end)

RegisterNetEvent('esx_garbagecrew:movetruckcount')
AddEventHandler('esx_garbagecrew:movetruckcount', function(count)
	Config.TruckPlateNumb = count
end)

RegisterNetEvent('esx_garbagecrew:updatejobs')
AddEventHandler('esx_garbagecrew:updatejobs', function(newjobtable)
	CollectionJobs = newjobtable
end)


RegisterNetEvent('esx_garbagecrew:selectnextjob')
AddEventHandler('esx_garbagecrew:selectnextjob', function()
	if currentstop < Config.MaxStops then
		SetVehicleDoorShut(work_truck, 5, false)
		SetBlipRoute(Blips['delivery'], false)
		FindDeliveryLoc()
		albetogetbags = false
	else
		NewDrop = nil
		oncollection = false
		SetVehicleDoorShut(work_truck, 5, false)
		RemoveBlip(Blips['delivery'])
		SetBlipRoute(Blips['endmission'], true)
		albetogetbags = false
		--exports['mythic_notify']:SendAlert('inform', _U('return_depot'))
	end
end)


AddEventHandler('esx_garbagecrew:checkjob', function()
	if mainblip == nil then
		mainblip = AddBlipForCoord(Config.Zones[2].pos)

		SetBlipSprite (mainblip, 318)
		SetBlipDisplay(mainblip, 4)
		SetBlipScale  (mainblip, 1.2)
		SetBlipColour (mainblip, 5)
		SetBlipAsShortRange(mainblip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('blip_job'))
		EndTextCommandSetBlipName(mainblip)
	end
end)


exports["qtarget"]:AddBoxZone("garbagejob",vector3(-321.75, -1545.88, 31.02), 2.0, 2.2, {
	name="garbagejob",
	heading=0,
	--debugPoly=true,
	minZ=29.87,
	maxZ=32.27
}, {
options = {
	{
		event = "xp8-garbagejob:signon",
		icon = "far fa-clipboard",
		label = "Sign On",
		--job = "garbage",
	},
	{
		event = "xp8-garbagejob:signoff",
		icon = "far fa-clipboard",
		label = "Sign Off",
		--job = "garbage",
	},
	{
		event = "xp8-garbagejob:SpawnTruck",
		icon = "fas fa-truck",
		label = "Spawn Truck",
		--job = "garbage",
		canInteract = function()
			if clockedin == true then 
				return true
			else
				return false
			end
		end, 
	},
},
distance = 1.5


})

RegisterNetEvent('xp8-garbagejob:signon')
AddEventHandler('xp8-garbagejob:signon',function(data)
	clockedin = true
	WorkClothesData = {}

	TriggerEvent('skinchanger:getSkin', function(skin, jobSkin)
		if skin.sex == 0 then
			WorkClothesData = Config.Uniforms.Male
		else
			WorkClothesData = Config.Uniforms.FeMale
		end

		if WorkClothesData ~= {} then
			TriggerEvent('skinchanger:loadClothes', skin, WorkClothesData)
		end
	end)

	--exports['mythic_notify']:SendAlert('Inform', 'You are now signed on')
end)


RegisterNetEvent('xp8-garbagejob:signoff')
AddEventHandler('xp8-garbagejob:signoff',function(data)
	clockedin = false
	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:loadSkin', skin)
	end)
	
	DeleteVehicle(NetToVeh(truckid))
	if Blips['delivery'] ~= nil then
		RemoveBlip(Blips['delivery'])
		Blips['delivery'] = nil
	end
	
	if Blips['endmission'] ~= nil then
		RemoveBlip(Blips['endmission'])
		Blips['endmission'] = nil
	end
	SetBlipRoute(Blips['delivery'], false)
	SetBlipRoute(Blips['endmission'], false)
	vehiclespawned = false
	albetogetbags = false
	CurrentAction = nil
	CurrentActionMsg = nil


	--exports['mythic_notify']:SendAlert('Inform', 'You are now signed off')
end)


RegisterNetEvent('xp8-garbagejob:SpawnTruck')
AddEventHandler('xp8-garbagejob:SpawnTruck',function(data)
	ESX.Game.SpawnVehicle('trash', Config.VehicleSpawn.pos, 270.0, function(vehicle)
		local playerPed = PlayerPedId()
		local trucknumber = Config.TruckPlateNumb + 1
		if trucknumber <=9 then
			SetVehicleNumberPlateText(vehicle, 'GCREW00'..trucknumber)
			worktruckplate =   'GCREW00'..trucknumber 
		elseif trucknumber <=99 then
			SetVehicleNumberPlateText(vehicle, 'GCREW0'..trucknumber)
			worktruckplate =   'GCREW0'..trucknumber 
		else
			SetVehicleNumberPlateText(vehicle, 'GCREW'..trucknumber)
			worktruckplate =   'GCREW'..trucknumber 
		end
		TriggerServerEvent('esx_garbagecrew:movetruckcount')   
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1) 
		work_truck = vehicle
		SetEntityAsMissionEntity(work_truck,true, true)
		NetworkRegisterEntityAsNetworked(work_truck)
		local vehnet = VehToNet(work_truck)
		NetworkSetNetworkIdDynamic(vehnet, true)
		SetNetworkIdCanMigrate(vehnet, true)
		SetNetworkIdExistsOnAllMachines(vehnet, true)
		truckid = vehnet
		vehiclespawned = true 
		albetogetbags = false
		currentstop = 0
		FindDeliveryLoc()
	end)
end)

exports.ox_target:addModel(Config.DumpstersAvaialbe, {
	{
	name = "open dumpsters",
	icon = "fas fa-dumpster",
	label = "Collect Trash",
	canInteract = function(entity, distance, coords, name)
		if clockedin == true then 
			if bin ~= 0 then
				currentZone = NewDrop
				if IsInArea and baginhand == false then
						return true
				end
			end
		else
			return false
		end
	end, 
	onSelect = function(data)
		CollectBagFromBin(currentZone)
	end
	},
})

exports.ox_target:addGlobalVehicle({
    {
        name = 'Dump Bag',
        icon = 'fa-solid fa-car-rear',
        label = 'Dump Trash',
        bones = 'boot',
        canInteract = function(entity, distance, coords, name, boneId)
            if clockedin == true and baginhand == true then
				return true
			else
				return false
			end
        end,
        onSelect = function(data)
            PlaceBagInTruck(currentZone)
        end
    }
})


function CollectBagFromBin(currentZone)
	local playerPed = PlayerPedId()
	binpos = currentZone.pos
	truckplate = currentZone.trucknumber
	if not HasAnimDictLoaded("anim@heists@narcotics@trash") then
		RequestAnimDict("anim@heists@narcotics@trash") 
		while not HasAnimDictLoaded("anim@heists@narcotics@trash") do 
			Citizen.Wait(0)
		end
	end
	local worktruck = NetToVeh(truckid)
	NetworkRequestControlOfNetworkId(truckid)
	NetworkRequestControlOfEntity(worktruck)
	if DoesEntityExist(worktruck) and GetDistanceBetweenCoords(GetEntityCoords(worktruck), GetEntityCoords(playerPed), true) < 25.0 then
		truckpos = GetOffsetFromEntityInWorldCoords(worktruck, 0.0, -5.25, 0.0)
		if not Config.Debug then
			TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
		end
		TriggerServerEvent('esx_garbagecrew:bagremoval', currentZone.pos, currentZone.trucknumber) 
		trashcollection = false
		Citizen.Wait(4000)
		ClearPedTasks(playerPed)
		local randombag = math.random(0,2)

		if randombag == 0 then
			garbagebag = CreateObject(GetHashKey("prop_cs_street_binbag_01"), 0, 0, 0, true, true, true) -- creates object
			gbag = ObjToNet(garbagebag)
			gbag2 = NetToObj(gbag)
			AttachEntityToEntity(gbag2, playerPed, GetPedBoneIndex(playerPed, 57005), 0.4, 0, 0, 0, 270.0, 60.0, true, true, false, true, 1, true) -- object is attached to right hand    
		elseif randombag == 1 then
			garbagebag = CreateObject(GetHashKey("bkr_prop_fakeid_binbag_01"), 0, 0, 0, true, true, true) -- creates object
			gbag = ObjToNet(garbagebag)
			gbag2 = NetToObj(gbag)
			AttachEntityToEntity(gbag2, playerPed, GetPedBoneIndex(playerPed, 57005), .65, 0, -.1, 0, 270.0, 60.0, true, true, false, true, 1, true) -- object is attached to right hand    
		elseif randombag == 2 then
			garbagebag = CreateObject(GetHashKey("hei_prop_heist_binbag"), 0, 0, 0, true, true, true) -- creates object
			gbag = ObjToNet(garbagebag)
			gbag2 = NetToObj(gbag)
			AttachEntityToEntity(gbag2, playerPed, GetPedBoneIndex(playerPed, 57005), 0.12, 0.0, 0.00, 25.0, 270.0, 180.0, true, true, false, true, 1, true) -- object is attached to right hand    
		end
		if not NetworkGetEntityIsNetworked(gbag) then
			NetworkRegisterEntityAsNetworked(gbag)
		end
		SetNetworkIdExistsOnAllMachines(gbag, true)
		TaskPlayAnim(playerPed, 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0,-1,49,0,0, 0,0)
		CurrentAction = nil
		CurrentActionMsg = nil
		HasAlreadyEnteredArea = false
		baginhand = true
	else
		print("Cant find" ..worktruck)
		TriggerServerEvent('esx_garbagecrew:unknownlocation', currentZone.pos)
	end
end

AddEventHandler('xp8:dumpbag', function(data)
	PlaceBagInTruck()
end)

function PlaceBagInTruck(thiszone)
	local playerPed = PlayerPedId()
	if not HasAnimDictLoaded("anim@heists@narcotics@trash") then
		RequestAnimDict("anim@heists@narcotics@trash") 
		while not HasAnimDictLoaded("anim@heists@narcotics@trash") do 
			Citizen.Wait(0)
		end
	end
	ClearPedTasksImmediately(playerPed)
	TaskPlayAnim(playerPed, 'anim@heists@narcotics@trash', 'throw_b', 1.0, -1.0,-1,2,0,0, 0,0)
	Citizen.Wait(800)
	DeleteEntity(gbag2)
	Citizen.Wait(100)
	ClearPedTasksImmediately(playerPed)
	CurrentAction = nil
	CurrentActionMsg = nil
	depositlist = nil
	truckpos = nil
	TriggerServerEvent('esx_garbagecrew:bagdumped', binpos, truckplate)
	HasAlreadyEnteredArea = false
	baginhand = false
end


function SelectBinAndCrew(location)
	local bin = nil
	for i, v in pairs(Config.DumpstersAvaialbe) do
		bin = GetClosestObjectOfType(location, 20.0, v, false, false, false)
		if bin ~= 0 then
			if CollectionJobs[GetEntityCoords(bin)] == nil then
				break
			else
				bin = 0
			end
		end
	end
	if bin ~= 0 then
		truckplate = GetVehicleNumberPlateText(NetToVeh(truckid))
		if truckid ~= nil then 
			NetworkRequestControlOfNetworkId(truckid)
			NetworkRequestControlOfEntity(NetToVeh(truckid))
			if NetworkDoesNetworkIdExist(truckid) or DoesEntityExist(NetToVeh(truckid)) then
				local EntityCheck = NetToVeh(truckid)
				if DoesEntityExist(EntityCheck) then
					TriggerServerEvent('esx_garbagecrew:setworkers', GetEntityCoords(bin), truckplate, truckid)
					truckpos = nil
					albetogetbags = true
					SetBlipRoute(Blips['delivery'], false)
					currentstop = currentstop + 1
					SetVehicleDoorOpen(work_truck, 5, false, false)
				end
			else 
			print("Couldn't find network id: " ..truckid)
			end
		end
	else
		--exports['mythic_notify']:SendAlert('error', _U('no_trash_aviable'))
		SetBlipRoute(Blips['endmission'], true)
		FindDeliveryLoc()
	end
end

function FindDeliveryLoc()
	if LastDrop ~= nil then
		lastregion = GetNameOfZone(LastDrop.pos)
	end
	local newdropregion = nil
	while newdropregion == nil or newdropregion == lastregion do
		randomloc = math.random(1, #Config.Collections)
		newdropregion = GetNameOfZone(Config.Collections[randomloc].pos)
	end
	NewDrop = Config.Collections[randomloc]
	LastDrop = NewDrop
	if Blips['delivery'] ~= nil then
		RemoveBlip(Blips['delivery'])
		Blips['delivery'] = nil
	end
	
	Blips['delivery'] = AddBlipForCoord(NewDrop.pos)
	SetBlipSprite (Blips['delivery'], 318)
	SetBlipAsShortRange(Blips['delivery'], true)
	SetBlipRoute(Blips['delivery'], true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('blip_delivery'))
	EndTextCommandSetBlipName(Blips['delivery'])

	oncollection = true
	--exports['mythic_notify']:SendAlert('inform', _U('drive_to_collection'))
end


-- thread so the script knows you have entered a markers area - 
Citizen.CreateThread( function()
	while true do 
		sleep = 1000
		ply = PlayerPedId()
		plyloc = GetEntityCoords(ply)
		IsInArea = false
		currentZone = nil
		
		for i,v in pairs(Config.Zones) do
			if GetDistanceBetweenCoords(plyloc, v.pos, false)  <  v.size then
				IsInArea = true
				currentZone = v
			end
		end

		if oncollection and not albetogetbags then
			if GetDistanceBetweenCoords(plyloc, NewDrop.pos, true)  <  NewDrop.size then
				IsInArea = true
				currentZone = NewDrop
			end
		end

		if truckpos ~= nil then
			if GetDistanceBetweenCoords(plyloc, truckpos, false)  <  2.0 then
				IsInArea = true
				currentZone = {type = 'Deposit', name = 'deposit', pos = truckpos,}
			end
		end

		for i,v in pairs(CollectionJobs) do
			if GetDistanceBetweenCoords(plyloc, v.pos, false)  <  2.0 and truckpos == nil then
				IsInArea = true
				currentZone = v
			end
		end

		if IsInArea and not HasAlreadyEnteredArea then
			HasAlreadyEnteredArea = true
			sleep = 0
			TriggerEvent('esx_garbagecrew:enteredarea', currentZone)
		end

		if not IsInArea and HasAlreadyEnteredArea then
			HasAlreadyEnteredArea = false
			sleep = 1000
			TriggerEvent('esx_garbagecrew:leftarea', currentZone)
		end

		Citizen.Wait(sleep)
	end
end)


	-- SelectBinAndCrew(GetEntityCoords(playerPed))



	Citizen.CreateThread( function()
		while true do 
			Citizen.Wait(0)
			while CurrentAction ~= nil and CurrentActionMsg ~= nil do
				local playerPed = PlayerPedId()
				Citizen.Wait(0)
				SetTextComponentFormat('STRING')
				AddTextComponentString(CurrentActionMsg)
				DisplayHelpTextFromStringLabel(0, 0, 1, -1)
	
				if IsControlJustReleased(0, 38) then
					
					if CurrentAction == 'collection' then
						if CurrentActionMsg == _U('collection') then
							SelectBinAndCrew(GetEntityCoords(playerPed))
							CurrentAction = nil
							CurrentActionMsg  = nil
							IsInArea = false
						end
					end
	
				end
			end
		end
	end)

RegisterNetEvent('esx_garbagecrew:enteredarea')
AddEventHandler('esx_garbagecrew:enteredarea', function(zone)
	local playerPed = PlayerPedId()
	CurrentAction = zone.name
	if CurrentAction == 'collection' and not albetogetbags then
		if IsPedInAnyVehicle(playerPed) and GetVehicleNumberPlateText(GetVehiclePedIsIn(playerPed, false)) == worktruckplate then
			CurrentActionMsg = _U('collection')
		else
			CurrentActionMsg = _U('need_work_truck')
		end
	end

end)

RegisterNetEvent('esx_garbagecrew:leftarea')
AddEventHandler('esx_garbagecrew:leftarea', function()  
    CurrentAction = nil
	CurrentActionMsg = ''
end)