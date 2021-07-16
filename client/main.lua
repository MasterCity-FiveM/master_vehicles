local HasAlreadyEnteredMarker, IsInShopMenu = false, false
local CurrentAction, CurrentActionMsg, LastZone, currentDisplayVehicle, CurrentVehicleData
local CurrentActionData, Vehicles, Categories = {}, {}, {}
ESX = nil
-- LUX


local count_bcast_timer = 0
local delay_bcast_timer = 200

local count_sndclean_timer = 0
local delay_sndclean_timer = 400

local actv_ind_timer = false
local count_ind_timer = 0
local delay_ind_timer = 180

local actv_lxsrnmute_temp = false
local srntone_temp = 0
local dsrn_mute = true

local state_indic = {}
local state_lxsiren = {}
local state_pwrcall = {}
local state_airmanu = {}

local ind_state_o = 0
local ind_state_l = 1
local ind_state_r = 2
local ind_state_h = 3

local snd_lxsiren = {}
local snd_pwrcall = {}
local snd_airmanu = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Citizen.Wait(10000)

	ESX.TriggerServerCallback('esx_vehicleshop:getCategories', function(categories)
		Categories = categories
	end)

	ESX.TriggerServerCallback('esx_vehicleshop:getVehicles', function(vehicles)
		Vehicles = vehicles
	end)
	
end)

function getVehicleLabelFromModel(model)
	for k,v in ipairs(Vehicles) do
		if v.model == model then
			return v.name
		end
	end

	return
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx_vehicleshop:sendCategories')
AddEventHandler('esx_vehicleshop:sendCategories', function(categories)
	Categories = categories
end)

RegisterNetEvent('esx_vehicleshop:sendVehicles')
AddEventHandler('esx_vehicleshop:sendVehicles', function(vehicles)
	Vehicles = vehicles
end)

Citizen.CreateThread(function()
	RequestIpl('shr_int') -- Load walls and floor

	local interiorID = 7170
	LoadInterior(interiorID)
	EnableInteriorProp(interiorID, 'csr_beforeMission') -- Load large window
	RefreshInterior(interiorID)
end)

-- Create Blips
Citizen.CreateThread(function()
	local blip = AddBlipForCoord(Config.Zones.ShopEntering.Pos)

	SetBlipSprite (blip, 595)
	SetBlipDisplay(blip, 4)
	SetBlipColour(blip, 26)
	SetBlipScale  (blip, 1.0)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(_U('car_dealer'))
	EndTextCommandSetBlipName(blip)
	
	for k,v in pairs(Config.RentLocations) do
		local blip = AddBlipForCoord(v.BlipPos)

		SetBlipSprite (blip, 198)
		SetBlipDisplay(blip, 4)
		SetBlipColour(blip, 60)
		SetBlipScale  (blip, 0.8)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName('Keraye Mashin')
		EndTextCommandSetBlipName(blip)
	end
	
	for k,v in pairs(Config.GarageLocations) do
		if v.ShowBlipOnMap then
			local blip = AddBlipForCoord(v.BlipPos)

			SetBlipSprite (blip, 357)
			SetBlipDisplay(blip, 4)
			SetBlipColour(blip, 2)
			SetBlipScale  (blip, 1.1)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName('Garage')
			EndTextCommandSetBlipName(blip)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		if IsInShopMenu then
			ESX.UI.Menu.CloseAll()

			local playerPed = PlayerPedId()

			FreezeEntityPosition(playerPed, false)
			SetEntityVisible(playerPed, true)
			SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)
		end

		DeleteDisplayVehicleInsideShop()
	end
end)

AddEventHandler('esx_vehicleshop:hasExitedMarker', function(zone)
	ESX.UI.Menu.CloseAll()
	IsInShopMenu = false
	CurrentAction = nil
end)

function DeleteDisplayVehicleInsideShop()
	local attempt = 0

	if currentDisplayVehicle and DoesEntityExist(currentDisplayVehicle) then
		while DoesEntityExist(currentDisplayVehicle) and not NetworkHasControlOfEntity(currentDisplayVehicle) and attempt < 100 do
			Citizen.Wait(100)
			NetworkRequestControlOfEntity(currentDisplayVehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(currentDisplayVehicle) and NetworkHasControlOfEntity(currentDisplayVehicle) then
			ESX.Game.DeleteVehicle(currentDisplayVehicle)
		end
	end
end

-- Enter / Exit marker events & Draw Markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsInShopMenu == false then
			local playerCoords = GetEntityCoords(PlayerPedId())
			local isInMarker, letSleep = false, true
			local currentZone
			local ActionType = false

			for k,v in pairs(Config.Zones) do
				local distance = #(playerCoords - v.Pos)

				if distance < Config.DrawDistance then
					letSleep = false

					if v.Type ~= -1 then
						DrawMarker(v.Type, v.Pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < v.Size.x then
						isInMarker, currentZone = true, k
					end
				end
			end
			
			--if letSleep then
			for k,v in pairs(Config.RentLocations) do
				local distance = #(playerCoords - v.BlipPos)

				if distance < Config.DrawDistance then
					letSleep = false

					DrawMarker(Config.RentType, v.BlipPos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.RentSize.x, Config.RentSize.y, Config.RentSize.z, Config.RentMarkerColor.r, Config.RentMarkerColor.g, Config.RentMarkerColor.b, 100, false, true, 2, false, nil, nil, false)

					if distance < Config.RentSize.x then
						isInMarker, currentZone = true, k
						ActionType = 1
					end
				end
			end
			--end
			
			--if letSleep then
			for k,v in pairs(Config.GarageLocations) do
				local distance = #(playerCoords - v.BlipPos)

				if distance < Config.DrawDistance then
					letSleep = false

					DrawMarker(Config.GarageType, v.BlipPos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.GarageSize.x, Config.GarageSize.y, Config.GarageSize.z, Config.GarageMarkerColor.r, Config.GarageMarkerColor.g, Config.GarageMarkerColor.b, 100, false, true, 2, false, nil, nil, false)

					if distance < Config.RentSize.x then
						isInMarker, currentZone = true, k
						ActionType = 2
					end
				end
			end
			--end

			if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
				HasAlreadyEnteredMarker, LastZone = true, currentZone
				LastZone = currentZone
				TriggerEvent('esx_vehicleshop:hasEnteredMarker', currentZone, ActionType)
			end

			if not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_vehicleshop:hasExitedMarker', LastZone)
			end

			if letSleep then
				Citizen.Wait(7000)
			end
		end
	end
end)

AddEventHandler('esx_vehicleshop:hasEnteredMarker', function(zone, ActionType)
	if ActionType == false then
		CurrentIsRent = nil
		if zone == 'ShopEntering' then
			CurrentAction     = 'shop_menu'
			CurrentActionMsg  = _U('shop_menu')
			CurrentActionData = {}
		elseif zone == 'ResellVehicle' then
			CurrentAction     = 'changeowner_menu'
			CurrentActionMsg  =  'جهت انتقال مالکیت خودرو لطفا E بزنید.'
			CurrentActionData = {}
		end
	elseif ActionType == 1 then
		CurrentAction     = 'rent_menu'
		CurrentActionMsg  = 'جهت اجاره خودرو لطفا E بزنید.'
		CurrentActionData = {zoneid = zone}
	elseif ActionType == 2 then
		CurrentAction     = 'garage_menu'
		CurrentActionMsg  = 'جهت دسترسی به گاراژ لطفا E بزنید.'
		CurrentActionData = {zoneid = zone}
	end
	
	if CurrentActionMsg ~= nil and IsInShopMenu == false then
		exports.pNotify:SendNotification({text = CurrentActionMsg, type = "info", timeout = 4000})
	end
end)

RegisterNetEvent('master_keymap:e')
AddEventHandler('master_keymap:e', function()
	if CurrentAction then
		if CurrentAction == 'shop_menu' then
			if Config.LicenseEnable then
				ESX.TriggerServerCallback('esx_license:checkLicense', function(hasDriversLicense)
					if hasDriversLicense then
						OpenShopMenu()
					else
						exports.pNotify:SendNotification({text = _U('license_missing'), type = "error", timeout = 4000})
					end
				end, GetPlayerServerId(PlayerId()), 'drive')
			else
				OpenShopMenu()
			end
		elseif CurrentAction == 'rent_menu' then
			OpenRentMenu(CurrentActionData.zoneid)
		elseif CurrentAction == 'garage_menu' then
			OpenGarageMenu(CurrentActionData.zoneid)
		elseif CurrentAction == 'changeowner_menu' then
			ChangeCarOwner()
		end	
	end
end)

function GetAvailableVehicleSpawnPoint(Zone)
	local spawnPoints = Config.RentLocations[Zone].SpawnPos
	local spawnLocation = nil
	local found, foundSpawnPoint = false, nil
	
	for k,v in pairs(spawnPoints) do
		if ESX.Game.IsSpawnPointClear(v.coords, v.radius) then
			spawnLocation = v
			break
		end
	end
	
	if spawnLocation == nil then
		exports.pNotify:SendNotification({text = 'محل تحویل خودرو خالی نمی باشد!', type = "error", timeout = 4000})
		return false
	end
	
	return spawnLocation
end

function OpenGarageMenu(Zone)
	ESX.TriggerServerCallback('master_vehicles:getOwnedVehicles', function(cars)
		if cars ~= nil then
			local menuElements = {{label = 'انتقال خودرو به پارکینگ',  value = 'toGarage'}}
			for k,v in pairs(cars) do
				if v.vehicle.model ~= nil then 
					if v.data.stored == 1 then
						table.insert(menuElements, {label = 'تحویل خودرو: <span style="color: #ff96ef">' .. GetDisplayNameFromVehicleModel(v.vehicle.model) .. '</span> - <span style="color: #85fffb">' .. v.vehicle.plate .. '</span> <span style="color: #8cff7a">(' .. Config.GetCarPrice .. '$)</span>',  value = v.vehicle.plate})
					else
				
						price = Config.FindCarPrice
						for k2,v2 in ipairs(Vehicles) do
							if GetHashKey(v2.model) == v.vehicle.model then
								price = math.ceil(v2.price / 10)
							end
						end
						
						table.insert(menuElements, {label = 'تحویل خودرو: <span style="color: #ff96ef">' .. GetDisplayNameFromVehicleModel(v.vehicle.model) .. '</span> - <span style="color: #85fffb">' .. v.vehicle.plate .. '</span> <span style="color: #8cff7a">(' .. price .. '$)</span>',  value = v.vehicle.plate})
					end
				end
			end
			ESX.UI.Menu.CloseAll()
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'car_list', {
				title = 'گاراژ',
				align = 'top-right',
				elements = menuElements
			}, function(data, menu)
				if data.current.value == 'toGarage' then
					StoreVehicleToGarage()
					menu.close()
				else
					GetCarFromGarage(Zone, data.current.value)
					menu.close()
				end
			end, function(menu, menu)
				menu.close()
			end)
			
		else
			exports.pNotify:SendNotification({text = 'شما ماشینی در پارکینگ ندارید!', type = "error", timeout = 4000})
		end
	end, 'cars', false)
end

function GetCarFromGarage(Zone, plate)
	local spawnPoints = Config.GarageLocations[Zone].SpawnPos
	local found, foundSpawnPoint = false, nil
	local spawnLocation = nil
	
	for k,v in pairs(spawnPoints) do
		if ESX.Game.IsSpawnPointClear(v.coords, v.radius) then
			spawnLocation = v
			break
		end
	end
	
	if spawnLocation == nil then
		exports.pNotify:SendNotification({text = 'محل تحویل خودرو خالی نمی باشد!', type = "error", timeout = 4000})
		return
	end
	
	ESX.TriggerServerCallback('master_vehicles:SpawnGarageCar', function(status, carData)
		if status == 1 then
			SpawnVehicle(carData, spawnLocation)
		elseif status == 2 then
			exports.pNotify:SendNotification({text = 'شما امکان تحویل گرفتن این خودرو را ندارید!', type = "error", timeout = 4000})
		elseif status == 3 then
			exports.pNotify:SendNotification({text = 'این خودرو به زودی به گاراژ منتقل میشود.', type = "error", timeout = 4000})
		elseif status == 4 then
			exports.pNotify:SendNotification({text = 'خودرو شما در حال انتقال به پارکینگ می باشد، لطفا صبور باشید.', type = "info", timeout = 4000})
		elseif status == 5 then
			exports.pNotify:SendNotification({text = 'شما پول کافی ندارید.', type = "info", timeout = 4000})
		end
	end, plate, false)
end

function SpawnVehicle(vehicle, spawnLocation)
	ESX.Game.SpawnVehicle(vehicle.model, spawnLocation.coords, spawnLocation.heading, function(callback_vehicle)
		SetVehicleProperties(callback_vehicle, vehicle)
		TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
		local vehNet = NetworkGetNetworkIdFromEntity(callback_vehicle)
		local plate = GetVehicleNumberPlateText(callback_vehicle)
		TriggerServerEvent("car_lock:GiveKeys", vehNet, plate)
	end)
end

function StoreVehicleToGarage()
	local ped = GetPlayerPed(-1)
	local playerCoords = GetEntityCoords(PlayerPedId())
    if (DoesEntityExist(ped) and not IsEntityDead(ped)) then 
        local pos = GetEntityCoords(ped)

        if (IsPedSittingInAnyVehicle(ped)) then 
            local vehicle = GetVehiclePedIsIn(ped, false)
			local vehicleProps = GetVehicleProperties(vehicle)
			if vehicleProps and vehicleProps.plate ~= nil then
				if (GetPedInVehicleSeat( vehicle, -1 ) == ped) then 
					ESX.TriggerServerCallback('master_vehicles:storeVehicle', function(success)
						if success then
							local entity = vehicle
							local attempt = 0

							exports.pNotify:SendNotification({text = "خودرو شما به گاراژ منتقل شد.", type = "success", timeout = 4000})
							while not NetworkHasControlOfEntity(entity) and attempt < 30.0 and DoesEntityExist(entity) do
								Wait(100)
								NetworkRequestControlOfEntity(entity)
								attempt = attempt + 1
							end

							if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
								ESX.Game.DeleteVehicle(entity)
								return
							end
						else
							exports.pNotify:SendNotification({text = "شما امکان تحویل این خودرو به گاراژ را ندارید.", type = "error", timeout = 4000})
						end
					end, vehicleProps, false)
				else 
					exports.pNotify:SendNotification({text = "شما باید پشت فرمان باشید.", type = "error", timeout = 4000})
				end
			else
				exports.pNotify:SendNotification({text = "شما امکان تحویل این خودرو را ندارید.", type = "error", timeout = 4000})
				return
			end
        else
            exports.pNotify:SendNotification({text = "شما باید در خودرو باشید.", type = "error", timeout = 4000})
        end 
    end
end

function SetVehicleProperties(vehicle, vehicleProps)
    ESX.Game.SetVehicleProperties(vehicle, vehicleProps)

    if vehicleProps["windows"] then
        for windowId = 1, 9, 1 do
            if vehicleProps["windows"][windowId] == false then
                SmashVehicleWindow(vehicle, windowId)
            end
        end
    end

    if vehicleProps["tyres"] then
        for tyreId = 1, 7, 1 do
            if vehicleProps["tyres"][tyreId] ~= false then
                SetVehicleTyreBurst(vehicle, tyreId, true, 1000)
            end
        end
    end

    if vehicleProps["doors"] then
        for doorId = 0, 5, 1 do
            if vehicleProps["doors"][doorId] ~= false then
                SetVehicleDoorBroken(vehicle, doorId - 1, true)
            end
        end
    end
	if vehicleProps.vehicleHeadLight then SetVehicleHeadlightsColour(vehicle, vehicleProps.vehicleHeadLight) end
end

function GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)

        vehicleProps["tyres"] = {}
        vehicleProps["windows"] = {}
        vehicleProps["doors"] = {}

        for id = 1, 7 do
            local tyreId = IsVehicleTyreBurst(vehicle, id, false)
        
            if tyreId then
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = tyreId
        
                if tyreId == false then
                    tyreId = IsVehicleTyreBurst(vehicle, id, true)
                    vehicleProps["tyres"][ #vehicleProps["tyres"]] = tyreId
                end
            else
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = false
            end
        end

        for id = 1, 7 do
            local windowId = IsVehicleWindowIntact(vehicle, id)

            if windowId ~= nil then
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = windowId
            else
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = true
            end
        end
        
        for id = 0, 5 do
            local doorId = IsVehicleDoorDamaged(vehicle, id)
        
            if doorId then
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = doorId
            else
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = false
            end
        end
		vehicleProps["vehicleHeadLight"]  = GetVehicleHeadlightsColour(vehicle)

        return vehicleProps
	else
		return nil
    end
end

function OpenRentMenu(Zone)
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'rent_car', {
		title = 'اجاره خودرو',
		align = 'top-right',
		elements = {
			{label = 'اجاره خودرو - [هزینه: ' .. Config.RentPrice .. '$]',  value = 'rent'},
			{label = 'تحویل خودرو', value = 'deliver'}
	}}, function(data, menu)
		if data.current.value == 'rent' then
			local SpawnPoint = GetAvailableVehicleSpawnPoint(Zone)
			if SpawnPoint ~= false then
				ESX.TriggerServerCallback('esx_vehicleshop:RentCar', function(success, plate)
					if success then
						ESX.Game.SpawnVehicle(Config.RentCar, SpawnPoint.coords, SpawnPoint.heading, function(vehicle)
							local allVehicleProps = {}
							allVehicleProps.plate = plate
							
							ESX.Game.SetVehicleProperties(vehicle, allVehicleProps)
							TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
							local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
							local plate = GetVehicleNumberPlateText(vehicle)
							TriggerServerEvent("car_lock:GiveKeys", vehNet, plate)
							exports.pNotify:SendNotification({text = 'خودرو تحویل داده شد، بخشی از هزینه شما، در هنگام تحویل خودرو برگردانده می شود.', type = "success", timeout = 5000})
						end)
					end
				end)
			end
			menu.close()
		else
			local playerCoords = GetEntityCoords(PlayerPedId())
			StoreRentNearbyVehicle(playerCoords)
			menu.close()
		end
	end, function(menu, menu)
		menu.close()
	end)
end

function OpenShopMenu()
	if #Vehicles == 0 then
		return
	end
	TriggerEvent('master_weapons:stopguns')
	IsInShopMenu = true

	StartShopRestriction()
	ESX.UI.Menu.CloseAll()

	local playerPed = PlayerPedId()

	FreezeEntityPosition(playerPed, true)
	SetEntityVisible(playerPed, false)
	SetEntityCoords(playerPed, Config.Zones.ShopInside.Pos)

	local vehiclesByCategory = {}
	local elements           = {}
	local firstVehicleData   = nil

	for i=1, #Categories, 1 do
		vehiclesByCategory[Categories[i].name] = {}
	end

	for i=1, #Vehicles, 1 do
		if IsModelInCdimage(GetHashKey(Vehicles[i].model)) then
			table.insert(vehiclesByCategory[Vehicles[i].category], Vehicles[i])
		else
			print(('[esx_vehicleshop] [^3ERROR^7] Vehicle "%s" does not exist'):format(Vehicles[i].model))
		end
	end

	for k,v in pairs(vehiclesByCategory) do
		table.sort(v, function(a, b)
			return a.name < b.name
		end)
	end

	for i=1, #Categories, 1 do
		local category         = Categories[i]
		local categoryVehicles = vehiclesByCategory[category.name]
		local options          = {}

		for j=1, #categoryVehicles, 1 do
			local vehicle = categoryVehicles[j]

			if i == 1 and j == 1 then
				firstVehicleData = vehicle
			end

			table.insert(options, ('%s <span style="color:green;">%s</span>'):format(vehicle.name, _U('generic_shopitem', ESX.Math.GroupDigits(vehicle.price))))
		end

		table.sort(options)

		table.insert(elements, {
			name    = category.name,
			label   = category.label_fa,
			value   = 0,
			type    = 'slider',
			max     = #Categories[i],
			options = options
		})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
		title    = _U('car_dealer'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_confirm', {
			title = _U('buy_vehicle_shop', vehicleData.name, ESX.Math.GroupDigits(vehicleData.price)),
			align = 'top-left',
			elements = {
				{label = _U('no'),  value = 'no'},
				{label = _U('yes'), value = 'yes'}
		}}, function(data2, menu2)
			if data2.current.value == 'yes' then
				local generatedPlate = GeneratePlate()
				ESX.TriggerServerCallback('master_gang:isInGang', function(isInGang)
					if isInGang == true then
						ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gang_confirm', {
							title = "آیا میخواهید این خودرو را برای گنگ بخرید؟",
							align = 'top-left',
							elements = {
								{label = _U('no'),  value = 'no'},
								{label = _U('yes'), value = 'yes'},
								{label = 'خروج', value = 'exit'},
						}}, function(data3, menu3)
							if data3.current.value == 'yes' then
								ESX.TriggerServerCallback('esx_vehicleshop:buyVehicle', function(success)
									if success then
										IsInShopMenu = false
										menu3.close()
										menu2.close()
										menu.close()
										DeleteDisplayVehicleInsideShop()

										ESX.Game.SpawnVehicle(vehicleData.model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function(vehicle)
											TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
											SetVehicleNumberPlateText(vehicle, generatedPlate)

											FreezeEntityPosition(playerPed, false)
											SetEntityVisible(playerPed, true)
											local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
											local plate = GetVehicleNumberPlateText(vehicle)
											TriggerServerEvent("car_lock:GiveKeys", vehNet, plate)
										end)
									else
										menu3.close()
										menu2.close()
										menu.close()
										exports.pNotify:SendNotification({text = _U('not_enough_money'), type = "error", timeout = 4000})
										DeleteDisplayVehicleInsideShop()
										local playerPed = PlayerPedId()

										CurrentAction     = 'shop_menu'
										CurrentActionMsg  = _U('shop_menu')
										CurrentActionData = {}

										FreezeEntityPosition(playerPed, false)
										SetEntityVisible(playerPed, true)
										SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

										IsInShopMenu = false
									end
								end,  vehicleData.model, generatedPlate, true)
							elseif data3.current.value == 'exit' then
								menu3.close()
								menu2.close()
								menu.close()
								DeleteDisplayVehicleInsideShop()
								local playerPed = PlayerPedId()

								CurrentAction     = 'shop_menu'
								CurrentActionMsg  = _U('shop_menu')
								CurrentActionData = {}

								FreezeEntityPosition(playerPed, false)
								SetEntityVisible(playerPed, true)
								SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

								IsInShopMenu = false
							else
								ESX.TriggerServerCallback('esx_vehicleshop:buyVehicle', function(success)
									if success then
										IsInShopMenu = false
										menu3.close()
										menu2.close()
										menu.close()
										DeleteDisplayVehicleInsideShop()

										ESX.Game.SpawnVehicle(vehicleData.model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function(vehicle)
											TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
											SetVehicleNumberPlateText(vehicle, generatedPlate)

											FreezeEntityPosition(playerPed, false)
											SetEntityVisible(playerPed, true)
											local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
											local plate = GetVehicleNumberPlateText(vehicle)
											TriggerServerEvent("car_lock:GiveKeys", vehNet, plate)
										end)
									else
										menu3.close()
										menu2.close()
										menu.close()
										exports.pNotify:SendNotification({text = _U('not_enough_money'), type = "error", timeout = 4000})
										DeleteDisplayVehicleInsideShop()
										local playerPed = PlayerPedId()

										CurrentAction     = 'shop_menu'
										CurrentActionMsg  = _U('shop_menu')
										CurrentActionData = {}

										FreezeEntityPosition(playerPed, false)
										SetEntityVisible(playerPed, true)
										SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

										IsInShopMenu = false
									end
								end,  vehicleData.model, generatedPlate, false)
							end
						end)
					else
						ESX.TriggerServerCallback('esx_vehicleshop:buyVehicle', function(success)
							if success then
								IsInShopMenu = false
								menu2.close()
								menu.close()
								DeleteDisplayVehicleInsideShop()

								ESX.Game.SpawnVehicle(vehicleData.model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function(vehicle)
									TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
									SetVehicleNumberPlateText(vehicle, generatedPlate)

									FreezeEntityPosition(playerPed, false)
									SetEntityVisible(playerPed, true)
									local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
									local plate = GetVehicleNumberPlateText(vehicle)
									TriggerServerEvent("car_lock:GiveKeys", vehNet, plate)
								end)
							else
								menu2.close()
								menu.close()
								exports.pNotify:SendNotification({text = _U('not_enough_money'), type = "error", timeout = 4000})
								DeleteDisplayVehicleInsideShop()
								local playerPed = PlayerPedId()

								CurrentAction     = 'shop_menu'
								CurrentActionMsg  = _U('shop_menu')
								CurrentActionData = {}

								FreezeEntityPosition(playerPed, false)
								SetEntityVisible(playerPed, true)
								SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

								IsInShopMenu = false
							end
						end,  vehicleData.model, generatedPlate, false)
					end
				end)
			else
				menu2.close()
			end
		end, function(data2, menu2)
			menu2.close()
		end)
	end, function(data, menu)
		menu.close()
		DeleteDisplayVehicleInsideShop()
		local playerPed = PlayerPedId()

		CurrentAction     = 'shop_menu'
		CurrentActionMsg  = _U('shop_menu')
		CurrentActionData = {}

		FreezeEntityPosition(playerPed, false)
		SetEntityVisible(playerPed, true)
		SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

		IsInShopMenu = false
	end, function(data, menu)
		local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]
		local playerPed   = PlayerPedId()

		DeleteDisplayVehicleInsideShop()
		WaitForVehicleToLoad(vehicleData.model)

		ESX.Game.SpawnLocalVehicle(vehicleData.model, Config.Zones.ShopInside.Pos, Config.Zones.ShopInside.Heading, function(vehicle)
			currentDisplayVehicle = vehicle
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			FreezeEntityPosition(vehicle, true)
			SetModelAsNoLongerNeeded(vehicleData.model)
		end)
	end)

	DeleteDisplayVehicleInsideShop()
	WaitForVehicleToLoad(firstVehicleData.model)

	ESX.Game.SpawnLocalVehicle(firstVehicleData.model, Config.Zones.ShopInside.Pos, Config.Zones.ShopInside.Heading, function(vehicle)
		currentDisplayVehicle = vehicle
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		FreezeEntityPosition(vehicle, true)
		SetModelAsNoLongerNeeded(firstVehicleData.model)
	end)
end

function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyspinnerOn('STRING')
		AddTextComponentSubstringPlayerName(_U('shop_awaiting_model'))
		EndTextCommandBusyspinnerOn(4)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(0)
			DisableAllControlActions(0)
		end

		BusyspinnerOff()
	end
end

function StartShopRestriction()
	Citizen.CreateThread(function()
		while IsInShopMenu do
			Citizen.Wait(0)

			DisableControlAction(0, 75,  true) -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		end
	end)
end

function StoreRentNearbyVehicle(playerCoords)
	local ped = GetPlayerPed(-1)

    if (DoesEntityExist(ped) and not IsEntityDead(ped)) then 
        local pos = GetEntityCoords(ped)

        if (IsPedSittingInAnyVehicle(ped)) then 
            local vehicle = GetVehiclePedIsIn(ped, false)
			local vehicleData = ESX.Game.GetVehicleProperties(vehicle)
			if vehicleData and vehicleData.plate ~= nil then
				if (GetPedInVehicleSeat( vehicle, -1 ) == ped) then 
					ESX.TriggerServerCallback('esx_vehicleshop:returnRentCar', function(success)
						if success then
							local entity = vehicle
							local attempt = 0

							while not NetworkHasControlOfEntity(entity) and attempt < 30.0 and DoesEntityExist(entity) do
								Wait(100)
								NetworkRequestControlOfEntity(entity)
								attempt = attempt + 1
							end

							if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
								ESX.Game.DeleteVehicle(entity)
								return
							end
						end
					end, vehicleData.plate, vehicle)
				else 
					exports.pNotify:SendNotification({text = "شما باید پشت فرمان باشید.", type = "error", timeout = 4000})
				end
			else
				exports.pNotify:SendNotification({text = "شما امکان تحویل این خودرو را ندارید.", type = "error", timeout = 4000})
				return
			end
        else
            exports.pNotify:SendNotification({text = "شما باید در خودرو باشید.", type = "error", timeout = 4000})
        end 
    end
end

function ChangeCarOwner()
	local ped = GetPlayerPed(-1)

    if (DoesEntityExist(ped) and not IsEntityDead(ped)) then 
        if (IsPedSittingInAnyVehicle(ped)) then 
            local vehicle = GetVehiclePedIsIn( ped, false )

            if (GetPedInVehicleSeat(vehicle, -1) == ped) then 
                local vehicleData = ESX.Game.GetVehicleProperties(vehicle)
				if vehicleData and vehicleData.plate ~= nil then
					local carPlate = vehicleData.plate
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer ~= -1 and closestDistance <= 2.0 then
						ESX.UI.Menu.CloseAll()
						ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'chco_car', {
							title = 'انتقال مالکیت خودرو',
							align = 'top-right',
							elements = {
								{label = 'انصراف', value = 'cancel'},
								{label = 'آیا میخواهید مالکیت خودرو را به (' .. GetPlayerServerId(closestPlayer) .. ') منتقل کنید؟ (هزینه: ' .. Config.ChangeOwnerPrice .. '$)',  value = 'changeowner'}
						}}, function(data, menu)
							if data.current.value == 'changeowner' then
								ESX.TriggerServerCallback('esx_vehicleshop:ChangeCarOwner', function(status)
									if status == 1 then
										exports.pNotify:SendNotification({text = "انتقال خودرو انجام شد.", type = "success", timeout = 4000})
									elseif status == 2 then
										exports.pNotify:SendNotification({text = "شما مالک این خودرو نیستید.", type = "error", timeout = 4000})
									end
								end,  carPlate, GetPlayerServerId(closestPlayer))
								menu.close()
							else
								menu.close()
							end
						end, function(menu, menu)
							menu.close()
						end)

					else
						exports.pNotify:SendNotification({text = "بازیکنی در نزدیکی شما نیست.", type = "error", timeout = 4000})
						return
					end
				else
					exports.pNotify:SendNotification({text = "شما امکان تغییر مالکیت این خودرو را ندارید.", type = "error", timeout = 4000})
					return
				end
            else
                exports.pNotify:SendNotification({text = "شما باید پشت فرمان خودرو باشید.", type = "error", timeout = 4000})
				return
            end
		else
			exports.pNotify:SendNotification({text = "شما باید پشت فرمان خودرو باشید.", type = "error", timeout = 4000})
			return
        end 
    end
end

Citizen.CreateThread(function()
	RequestIpl('shr_int') -- Load walls and floor

	local interiorID = 7170
	LoadInterior(interiorID)
	EnableInteriorProp(interiorID, 'csr_beforeMission') -- Load large window
	RefreshInterior(interiorID)
end)

function lockAnimation()
    local ply = PlayerPedId()
    RequestAnimDict("anim@heists@keycard@")
    while not HasAnimDictLoaded("anim@heists@keycard@") do
        Wait(0)
    end
    TaskPlayAnim(ply, "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
    Wait(800)
    ClearPedTasks(ply)
end

function GetClosestPlayer()
	local players = GetPlayers()
	local closestDistance = -1
	local closestPlayer = -1
	local ply = PlayerPedId()
	local plyCoords = GetEntityCoords(ply, 0)

	for index,value in ipairs(players) do
		local target = GetPlayerPed(value)
		if(target ~= ply) then
			local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
			local distance = Vdist(targetCoords["x"], targetCoords["y"], targetCoords["z"], plyCoords["x"], plyCoords["y"], plyCoords["z"])
			if(closestDistance == -1 or closestDistance > distance) then
				closestPlayer = value
				closestDistance = distance
			end
		end
	end

	return closestPlayer, closestDistance
end

function GetPlayers()
    local players = {}

    for i = 0, 256 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end

function GetVehicleInFront()
	local plyCoords = GetEntityCoords(GetPlayerPed(PlayerId()), false)
	local plyOffset = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 5.0, 0.0)
	local rayHandle = StartShapeTestCapsule(plyCoords.x, plyCoords.y, plyCoords.z, plyOffset.x, plyOffset.y, plyOffset.z, 1.0, 10, GetPlayerPed(PlayerId()), 7)
	local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
	return vehicle
end

function GetClosestVeh()
	local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)
    local entityWorld = GetOffsetFromEntityInWorldCoords(ply, 0.0, 20.0, 0.0)
    local rayHandle = CastRayPointToPoint(plyCoords["x"], plyCoords["y"], plyCoords["z"], entityWorld.x, entityWorld.y, entityWorld.z, 10, ply, 0)
    local a, b, c, d, targetVehicle = GetRaycastResult(rayHandle)

    return targetVehicle
end

RegisterNetEvent("car_lock:ToggleOutsideLock")
AddEventHandler("car_lock:ToggleOutsideLock", function(vehNet, hasKeys)
    if hasKeys then
        local veh = NetworkGetEntityFromNetworkId(vehNet)
        local isLocked = GetVehicleDoorLockStatus(veh)
        if isLocked == 0 then		
			exports.pNotify:SendNotification({text = "خودرو قفل شد.", type = "error", timeout = 4000})
            lockAnimation()
			TriggerServerEvent('InteractSound_SV:PlayOnSource', 'lock', 0.3)
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleLights(veh, 2)
            Wait(200)
            SetVehicleLights(veh, 0)
        elseif isLocked == 1 then
			exports.pNotify:SendNotification({text = "خودرو قفل شد.", type = "error", timeout = 4000})
            lockAnimation()
			TriggerServerEvent('InteractSound_SV:PlayOnSource', 'lock', 0.3)
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleLights(veh, 2)
            Wait(200)
            SetVehicleLights(veh, 0)
        elseif isLocked == 5 then
			exports.pNotify:SendNotification({text = "خودرو قفل شد.", type = "error", timeout = 4000})
            lockAnimation()
			TriggerServerEvent('InteractSound_SV:PlayOnSource', 'lock', 0.3)
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleLights(veh, 2)
            Wait(200)
            SetVehicleLights(veh, 0)
        else
			exports.pNotify:SendNotification({text = "قفل خودرو باز شد.", type = "success", timeout = 4000})
            lockAnimation()
			TriggerServerEvent('InteractSound_SV:PlayOnSource', 'unlock', 0.3)
            SetVehicleDoorsLocked(veh, 0)
            SetVehicleLights(veh, 2)
            Wait(200)
            SetVehicleLights(veh, 0)
        end
    end
end)

local speedLimited = false
Citizen.CreateThread(function()
	local resetSpeedOnEnter = true
    while true do
		CleanupSounds()
        local ply = PlayerPedId()
        if DoesEntityExist(GetVehiclePedIsTryingToEnter(ply)) then
            local veh = GetVehiclePedIsTryingToEnter(ply)
            local isLocked = GetVehicleDoorLockStatus(veh)
            if isLocked == 7 then
                SetVehicleDoorsLocked(veh, 2)
            end

            if isLocked == 4 then
                ClearPedTasks(ply)
            end

            local aiPed = GetPedInVehicleSeat(veh, -1)
            if aiPed then
                SetPedCanBeDraggedOut(aiPed, false)
            end
        end
		
        if IsControlJustPressed(0, 246) and GetLastInputMethod(0) then
            local insideVeh = IsPedInAnyVehicle(ply, false)

            if insideVeh == 1 then
                local veh = GetVehiclePedIsIn(ply, false)
                local isLocked = GetVehicleDoorLockStatus(veh)
                if isLocked == 0 then
                    SetVehicleDoorsLocked(veh, 2)
					exports.pNotify:SendNotification({text = "خودرو قفل شد.", type = "error", timeout = 4000})
                elseif isLocked == 1 then
                    SetVehicleDoorsLocked(veh, 2)
					exports.pNotify:SendNotification({text = "خودرو قفل شد.", type = "error", timeout = 4000})
                elseif isLocked == 5 then
                    SetVehicleDoorsLocked(veh, 2)
					exports.pNotify:SendNotification({text = "خودرو قفل شد.", type = "error", timeout = 4000})
                else
                    SetVehicleDoorsLocked(veh, 0)
					exports.pNotify:SendNotification({text = "قفل خودرو باز شد.", type = "success", timeout = 4000})
                end
            else
                local inFront = GetVehicleInFront()
                if inFront ~= 0 then
                    local vehNet = NetworkGetNetworkIdFromEntity(inFront)
                    local plate = GetVehicleNumberPlateText(inFront)
                    if vehNet ~= 0 then
                        TriggerServerEvent("car_lock:CheckOwnership", vehNet, plate)
                    end
                end
            end
        end
        Wait(0)
		
		local playerPed = GetPlayerPed(-1)
		local vehicle = GetVehiclePedIsIn(playerPed,false)
		if GetPedInVehicleSeat(vehicle, -1) == playerPed and IsPedInAnyVehicle(playerPed, false) then
			-- This should only happen on vehicle first entry to disable any old values
			if resetSpeedOnEnter then
				maxSpeed = GetVehicleHandlingFloat(vehicle,"CHandlingData","fInitialDriveMaxFlatVel")
				SetEntityMaxSpeed(vehicle, maxSpeed)
				resetSpeedOnEnter = false
				speedLimited = false
			end
			
			
			speed = math.ceil(GetEntitySpeed(vehicle) * 3.6)
			SetPlayerCanDoDriveBy(PlayerId(), false)
			--if speed >= 50 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
			
			-- Disable speed limiter
			if IsControlJustReleased(0,29) and speedLimited then
				speedLimited = false
				maxSpeed = GetVehicleHandlingFloat(vehicle,"CHandlingData","fInitialDriveMaxFlatVel")
				SetEntityMaxSpeed(vehicle, maxSpeed)
				exports.pNotify:SendNotification({text = 'کروز کنترل خاموش شد.', type = "info", timeout = 4000})
			-- Enable speed limiter
			elseif IsControlJustReleased(0,29) and not speedLimited and speed > 1 then
				speedLimited = true
				cruise = GetEntitySpeed(vehicle)
				SetEntityMaxSpeed(vehicle, cruise)
				cruise = math.floor(cruise * 3.6 + 0.5)					
				exports.pNotify:SendNotification({text = 'سرعت شما روی ' .. cruise .. ' KM، محدود شد.', type = "info", timeout = 4000})
			end
			
			-- LUX
			local playerped = GetPlayerPed(-1)
			local veh = GetVehiclePedIsUsing(playerped)
			
			DisableControlAction(0, 84, true) -- INPUT_VEH_PREV_RADIO_TRACK  
			DisableControlAction(0, 83, true) -- INPUT_VEH_NEXT_RADIO_TRACK 
			
			if state_indic[veh] ~= ind_state_o and state_indic[veh] ~= ind_state_l and state_indic[veh] ~= ind_state_r and state_indic[veh] ~= ind_state_h then
				state_indic[veh] = ind_state_o
			end
			
			-- INDIC AUTO CONTROL
			if actv_ind_timer == true then	
				if state_indic[veh] == ind_state_l or state_indic[veh] == ind_state_r then
					if GetEntitySpeed(veh) < 6 then
						count_ind_timer = 0
					else
						if count_ind_timer > delay_ind_timer then
							count_ind_timer = 0
							actv_ind_timer = false
							state_indic[veh] = ind_state_o
							PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
							TogIndicStateForVeh(veh, state_indic[veh])
							count_bcast_timer = delay_bcast_timer
						else
							count_ind_timer = count_ind_timer + 1
						end
					end
				end
			end
			
			--- IS EMERG VEHICLE ---
			if GetVehicleClass(veh) == 18 then
				
				local actv_manu = false
				local actv_horn = false
				
				DisableControlAction(0, 86, true) -- INPUT_VEH_HORN	
				DisableControlAction(0, 172, true) -- INPUT_CELLPHONE_UP 
				--DisableControlAction(0, 173, true) -- INPUT_CELLPHONE_DOWN
				--DisableControlAction(0, 174, true) -- INPUT_CELLPHONE_LEFT 
				--DisableControlAction(0, 175, true) -- INPUT_CELLPHONE_RIGHT 
				DisableControlAction(0, 81, true) -- INPUT_VEH_NEXT_RADIO
				DisableControlAction(0, 82, true) -- INPUT_VEH_PREV_RADIO
				DisableControlAction(0, 19, true) -- INPUT_CHARACTER_WHEEL 
				DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL 
				DisableControlAction(0, 80, true) -- INPUT_VEH_CIN_CAM 
			
				SetVehRadioStation(veh, "OFF")
				SetVehicleRadioEnabled(veh, false)
				
				if state_lxsiren[veh] ~= 1 and state_lxsiren[veh] ~= 2 and state_lxsiren[veh] ~= 3 then
					state_lxsiren[veh] = 0
				end
				if state_pwrcall[veh] ~= true then
					state_pwrcall[veh] = false
				end
				if state_airmanu[veh] ~= 1 and state_airmanu[veh] ~= 2 and state_airmanu[veh] ~= 3 then
					state_airmanu[veh] = 0
				end
				
				if useFiretruckSiren(veh) and state_lxsiren[veh] == 1 then
					TogMuteDfltSrnForVeh(veh, false)
					dsrn_mute = false
				else
					TogMuteDfltSrnForVeh(veh, true)
					dsrn_mute = true
				end
				
				if not IsVehicleSirenOn(veh) and state_lxsiren[veh] > 0 then
					PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
					SetLxSirenStateForVeh(veh, 0)
					count_bcast_timer = delay_bcast_timer
				end
				if not IsVehicleSirenOn(veh) and state_pwrcall[veh] == true then
					PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
					TogPowercallStateForVeh(veh, false)
					count_bcast_timer = delay_bcast_timer
				end
			
				----- CONTROLS -----
				if not IsPauseMenuActive() then
				
					-- TOG DFLT SRN LIGHTS
					if IsDisabledControlJustReleased(0, 85) or IsDisabledControlJustReleased(0, 246) then
						if IsVehicleSirenOn(veh) then
							PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
							SetVehicleSiren(veh, false)
						else
							PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
							SetVehicleSiren(veh, true)
							count_bcast_timer = delay_bcast_timer
						end		
					
					-- TOG LX SIREN
					elseif IsDisabledControlJustReleased(0, 19) or IsDisabledControlJustReleased(0, 82) then
						local cstate = state_lxsiren[veh]
						if cstate == 0 then
							if IsVehicleSirenOn(veh) then
								PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1) -- on
								SetLxSirenStateForVeh(veh, 1)
								count_bcast_timer = delay_bcast_timer
							end
						else
							PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1) -- off
							SetLxSirenStateForVeh(veh, 0)
							count_bcast_timer = delay_bcast_timer
						end
						
					-- POWERCALL
					elseif IsDisabledControlJustReleased(0, 172) then
						if state_pwrcall[veh] == true then
							PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
							TogPowercallStateForVeh(veh, false)
							count_bcast_timer = delay_bcast_timer
						else
							if IsVehicleSirenOn(veh) then
								PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
								TogPowercallStateForVeh(veh, true)
								count_bcast_timer = delay_bcast_timer
							end
						end
						
					end
					
					-- BROWSE LX SRN TONES
					if state_lxsiren[veh] > 0 then
						if IsDisabledControlJustReleased(0, 80) or IsDisabledControlJustReleased(0, 81) then
							if IsVehicleSirenOn(veh) then
								local cstate = state_lxsiren[veh]
								local nstate = 1
								PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1) -- on
								if cstate == 1 then
									nstate = 2
								elseif cstate == 2 then
									nstate = 3
								else	
									nstate = 1
								end
								SetLxSirenStateForVeh(veh, nstate)
								count_bcast_timer = delay_bcast_timer
							end
						end
					end
								
					-- MANU
					if state_lxsiren[veh] < 1 then
						if IsDisabledControlPressed(0, 80) or IsDisabledControlPressed(0, 81) then
							actv_manu = true
						else
							actv_manu = false
						end
					else
						actv_manu = false
					end
					
					-- HORN
					if IsDisabledControlPressed(0, 86) then
						actv_horn = true
					else
						actv_horn = false
					end
				
				end
				
				---- ADJUST HORN / MANU STATE ----
				local hmanu_state_new = 0
				if actv_horn == true and actv_manu == false then
					hmanu_state_new = 1
				elseif actv_horn == false and actv_manu == true then
					hmanu_state_new = 2
				elseif actv_horn == true and actv_manu == true then
					hmanu_state_new = 3
				end
				if hmanu_state_new == 1 then
					if not useFiretruckSiren(veh) then
						if state_lxsiren[veh] > 0 and actv_lxsrnmute_temp == false then
							srntone_temp = state_lxsiren[veh]
							SetLxSirenStateForVeh(veh, 0)
							actv_lxsrnmute_temp = true
						end
					end
				else
					if not useFiretruckSiren(veh) then
						if actv_lxsrnmute_temp == true then
							SetLxSirenStateForVeh(veh, srntone_temp)
							actv_lxsrnmute_temp = false
						end
					end
				end
				if state_airmanu[veh] ~= hmanu_state_new then
					SetAirManuStateForVeh(veh, hmanu_state_new)
					count_bcast_timer = delay_bcast_timer
				end	
			end
			
				
			--- IS ANY LAND VEHICLE ---	
			if GetVehicleClass(veh) ~= 14 and GetVehicleClass(veh) ~= 15 and GetVehicleClass(veh) ~= 16 and GetVehicleClass(veh) ~= 21 then
			
				----- CONTROLS -----
				if not IsPauseMenuActive() then
				
					-- IND L
					if IsDisabledControlJustReleased(0, 84) then -- INPUT_VEH_PREV_RADIO_TRACK
						local cstate = state_indic[veh]
						if cstate == ind_state_l then
							state_indic[veh] = ind_state_o
							actv_ind_timer = false
							PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
						else
							state_indic[veh] = ind_state_l
							actv_ind_timer = true
							PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
						end
						TogIndicStateForVeh(veh, state_indic[veh])
						count_ind_timer = 0
						count_bcast_timer = delay_bcast_timer			
					-- IND R
					elseif IsDisabledControlJustReleased(0, 83) then -- INPUT_VEH_NEXT_RADIO_TRACK
						local cstate = state_indic[veh]
						if cstate == ind_state_r then
							state_indic[veh] = ind_state_o
							actv_ind_timer = false
							PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
						else
							state_indic[veh] = ind_state_r
							actv_ind_timer = true
							PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
						end
						TogIndicStateForVeh(veh, state_indic[veh])
						count_ind_timer = 0
						count_bcast_timer = delay_bcast_timer
					-- IND H
					elseif IsControlJustReleased(0, 202) then -- INPUT_FRONTEND_CANCEL / Backspace
						if GetLastInputMethod(0) then -- last input was with kb
							local cstate = state_indic[veh]
							if cstate == ind_state_h then
								state_indic[veh] = ind_state_o
								PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
							else
								state_indic[veh] = ind_state_h
								PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
							end
							TogIndicStateForVeh(veh, state_indic[veh])
							actv_ind_timer = false
							count_ind_timer = 0
							count_bcast_timer = delay_bcast_timer
						end
					end
				
				end
				
				
				----- AUTO BROADCAST VEH STATES -----
				if count_bcast_timer > delay_bcast_timer then
					count_bcast_timer = 0
					--- IS EMERG VEHICLE ---
					if GetVehicleClass(veh) == 18 then
						TriggerServerEvent("lvc_TogDfltSrnMuted_s", dsrn_mute)
						TriggerServerEvent("lvc_SetLxSirenState_s", state_lxsiren[veh])
						TriggerServerEvent("lvc_TogPwrcallState_s", state_pwrcall[veh])
						TriggerServerEvent("lvc_SetAirManuState_s", state_airmanu[veh])
					end
					--- IS ANY OTHER VEHICLE ---
					TriggerServerEvent("lvc_TogIndicState_s", state_indic[veh])
				else
					count_bcast_timer = count_bcast_timer + 1
				end
			
			end
		elseif IsPedInAnyVehicle(playerPed, false) then
			resetSpeedOnEnter = true
            SetPlayerCanDoDriveBy(PlayerId(), true)
		else
			resetSpeedOnEnter = true
		end
    end
end)


-- LUX

-- these models will use their real wail siren, as determined by their assigned audio hash in vehicles.meta
local eModelsWithFireSrn =
{
	"FIRETRUK",
}

-- models listed below will use AMBULANCE_WARNING as auxiliary siren
-- unlisted models will instead use the default wail as the auxiliary siren
local eModelsWithPcall =
{	
	"AMBULANCE",
	"FIRETRUK",
	"LGUARD",
}


---------------------------------------------------------------------
function ShowDebug(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

---------------------------------------------------------------------
function useFiretruckSiren(veh)
	local model = GetEntityModel(veh)
	for i = 1, #eModelsWithFireSrn, 1 do
		if model == GetHashKey(eModelsWithFireSrn[i]) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
function usePowercallAuxSrn(veh)
	local model = GetEntityModel(veh)
	for i = 1, #eModelsWithPcall, 1 do
		if model == GetHashKey(eModelsWithPcall[i]) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
function CleanupSounds()
	if count_sndclean_timer > delay_sndclean_timer then
		count_sndclean_timer = 0
		for k, v in pairs(state_lxsiren) do
			if v > 0 then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_lxsiren[k] ~= nil then
						StopSound(snd_lxsiren[k])
						ReleaseSoundId(snd_lxsiren[k])
						snd_lxsiren[k] = nil
						state_lxsiren[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_pwrcall) do
			if v == true then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_pwrcall[k] ~= nil then
						StopSound(snd_pwrcall[k])
						ReleaseSoundId(snd_pwrcall[k])
						snd_pwrcall[k] = nil
						state_pwrcall[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_airmanu) do
			if v == true then
				if not DoesEntityExist(k) or IsEntityDead(k) or IsVehicleSeatFree(k, -1) then
					if snd_airmanu[k] ~= nil then
						StopSound(snd_airmanu[k])
						ReleaseSoundId(snd_airmanu[k])
						snd_airmanu[k] = nil
						state_airmanu[k] = nil
					end
				end
			end
		end
	else
		count_sndclean_timer = count_sndclean_timer + 1
	end
end

---------------------------------------------------------------------
function TogIndicStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate == ind_state_o then
			SetVehicleIndicatorLights(veh, 0, false) -- R
			SetVehicleIndicatorLights(veh, 1, false) -- L
		elseif newstate == ind_state_l then
			SetVehicleIndicatorLights(veh, 0, false) -- R
			SetVehicleIndicatorLights(veh, 1, true) -- L
		elseif newstate == ind_state_r then
			SetVehicleIndicatorLights(veh, 0, true) -- R
			SetVehicleIndicatorLights(veh, 1, false) -- L
		elseif newstate == ind_state_h then
			SetVehicleIndicatorLights(veh, 0, true) -- R
			SetVehicleIndicatorLights(veh, 1, true) -- L
		end
		state_indic[veh] = newstate
	end
end

---------------------------------------------------------------------
function TogMuteDfltSrnForVeh(veh, toggle)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		DisableVehicleImpactExplosionActivation(veh, toggle)
	end
end

---------------------------------------------------------------------
function SetLxSirenStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_lxsiren[veh] then
				
			if snd_lxsiren[veh] ~= nil then
				StopSound(snd_lxsiren[veh])
				ReleaseSoundId(snd_lxsiren[veh])
				snd_lxsiren[veh] = nil
			end
						
			if newstate == 1 then
				if useFiretruckSiren(veh) then
					TogMuteDfltSrnForVeh(veh, false)
				else
					snd_lxsiren[veh] = GetSoundId()	
					PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_SIREN_1", veh, 0, 0, 0)
					TogMuteDfltSrnForVeh(veh, true)
				end
				
			elseif newstate == 2 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_SIREN_2", veh, 0, 0, 0)
				TogMuteDfltSrnForVeh(veh, true)
			
			elseif newstate == 3 then
				snd_lxsiren[veh] = GetSoundId()
				if useFiretruckSiren(veh) then
					PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_AMBULANCE_WARNING", veh, 0, 0, 0)
				else
					PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_POLICE_WARNING", veh, 0, 0, 0)
				end
				TogMuteDfltSrnForVeh(veh, true)
				
			else
				TogMuteDfltSrnForVeh(veh, true)
				
			end				
				
			state_lxsiren[veh] = newstate
		end
	end
end

---------------------------------------------------------------------
function TogPowercallStateForVeh(veh, toggle)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if toggle == true then
			if snd_pwrcall[veh] == nil then
				snd_pwrcall[veh] = GetSoundId()
				if usePowercallAuxSrn(veh) then
					PlaySoundFromEntity(snd_pwrcall[veh], "VEHICLES_HORNS_AMBULANCE_WARNING", veh, 0, 0, 0)
				else
					PlaySoundFromEntity(snd_pwrcall[veh], "VEHICLES_HORNS_SIREN_1", veh, 0, 0, 0)
				end
			end
		else
			if snd_pwrcall[veh] ~= nil then
				StopSound(snd_pwrcall[veh])
				ReleaseSoundId(snd_pwrcall[veh])
				snd_pwrcall[veh] = nil
			end
		end
		state_pwrcall[veh] = toggle
	end
end

---------------------------------------------------------------------
function SetAirManuStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_airmanu[veh] then
				
			if snd_airmanu[veh] ~= nil then
				StopSound(snd_airmanu[veh])
				ReleaseSoundId(snd_airmanu[veh])
				snd_airmanu[veh] = nil
			end
						
			if newstate == 1 then
				snd_airmanu[veh] = GetSoundId()
				if useFiretruckSiren(veh) then
					PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_FIRETRUCK_WARNING", veh, 0, 0, 0)
				else
					PlaySoundFromEntity(snd_airmanu[veh], "SIRENS_AIRHORN", veh, 0, 0, 0)
				end
				
			elseif newstate == 2 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_SIREN_1", veh, 0, 0, 0)
			
			elseif newstate == 3 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_SIREN_2", veh, 0, 0, 0)
				
			end				
				
			state_airmanu[veh] = newstate
		end
	end
end


---------------------------------------------------------------------
RegisterNetEvent("lvc_TogIndicState_c")
AddEventHandler("lvc_TogIndicState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogIndicStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_TogDfltSrnMuted_c")
AddEventHandler("lvc_TogDfltSrnMuted_c", function(sender, toggle)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogMuteDfltSrnForVeh(veh, toggle)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_SetLxSirenState_c")
AddEventHandler("lvc_SetLxSirenState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetLxSirenStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_TogPwrcallState_c")
AddEventHandler("lvc_TogPwrcallState_c", function(sender, toggle)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogPowercallStateForVeh(veh, toggle)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_SetAirManuState_c")
AddEventHandler("lvc_SetAirManuState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetAirManuStateForVeh(veh, newstate)
			end
		end
	end
end)


