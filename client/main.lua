local HasAlreadyEnteredMarker, IsInShopMenu = false, false
local CurrentAction, CurrentActionMsg, LastZone, currentDisplayVehicle, CurrentVehicleData
local CurrentActionData, Vehicles, Categories = {}, {}, {}
ESX = nil

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
	if not IsInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

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
		local playerCoords = GetEntityCoords(PlayerPedId())
		local isInMarker, letSleep, currentZone = false, true
		local isRent = false

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
		
		if letSleep then
			for k,v in pairs(Config.RentLocations) do
				local distance = #(playerCoords - v.BlipPos)

				if distance < Config.DrawDistance then
					letSleep = false

					DrawMarker(Config.RentType, v.BlipPos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.RentSize.x, Config.RentSize.y, Config.RentSize.z, Config.RentMarkerColor.r, Config.RentMarkerColor.g, Config.RentMarkerColor.b, 100, false, true, 2, false, nil, nil, false)

					if distance < Config.RentSize.x then
						isInMarker, currentZone = true, k
						isRent = true
					end
				end
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker, LastZone = true, currentZone
			LastZone = currentZone
			TriggerEvent('esx_vehicleshop:hasEnteredMarker', currentZone, isRent)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_vehicleshop:hasExitedMarker', LastZone)
		end

		if letSleep then
			Citizen.Wait(2000)
		end
	end
end)

AddEventHandler('esx_vehicleshop:hasEnteredMarker', function(zone, isRent)
	if isRent then
		CurrentAction     = 'rent_menu'
		CurrentActionMsg  = 'جهت اجاره خودرو لطفا E بزنید.'
		CurrentActionData = {zoneid = zone}
	else
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
		elseif CurrentAction == 'changeowner_menu' then
			ChangeCarOwner()
		end	
	end
end)


function GetAvailableVehicleSpawnPoint(Zone)
	local spawnPoints = Config.RentLocations[Zone].SpawnPos
	local found, foundSpawnPoint = false, nil

	if ESX.Game.IsSpawnPointClear(spawnPoints.coords, spawnPoints.radius) then
		return true
	else
		exports.pNotify:SendNotification({text = 'محل تحویل خودرو خالی نمیباشد.', type = "error", timeout = 4000})	
		return false
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
			if GetAvailableVehicleSpawnPoint(Zone) then
				ESX.TriggerServerCallback('esx_vehicleshop:RentCar', function(success, plate)
					if success then
						ESX.Game.SpawnVehicle(Config.RentCar, Config.RentLocations[Zone].SpawnPos.coords, Config.RentLocations[Zone].SpawnPos.heading, function(vehicle)
							local allVehicleProps = {}
							allVehicleProps.plate = plate
							
							ESX.Game.SetVehicleProperties(vehicle, allVehicleProps)
							TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
							local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
							local plate = GetVehicleNumberPlateText(vehicle)
							TriggerServerEvent("SOSAY_Locking:GiveKeys", vehNet, plate)
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
						end)
					else
						exports.pNotify:SendNotification({text = _U('not_enough_money'), type = "error", timeout = 4000})
					end
				end,  vehicleData.model, generatedPlate)
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