ESX = nil
local categories, vehicles, job_cars = {}, {}, {}
local RentCars = {}
local LastRentID = 1
local CarsNeedToFind = {}
local vehicleOwners = {}
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

MySQL.ready(function()
	MySQL.Async.execute('UPDATE owned_vehicles SET stored = 1 WHERE stored = 0', {}, function (rowsChanged) end)
	
	MySQL.Async.fetchAll('SELECT * FROM vehicle_categories', {}, function(_categories)
		categories = _categories

		MySQL.Async.fetchAll('SELECT * FROM vehicles', {}, function(_vehicles)
			vehicles = _vehicles

			for k,v in ipairs(vehicles) do
				for k2,v2 in ipairs(categories) do
					if v2.name == v.category then
						vehicles[k].categoryLabel = v2.label
						break
					end
				end
			end

			-- send information after db has loaded, making sure everyone gets vehicle information
			TriggerClientEvent('esx_vehicleshop:sendCategories', -1, categories)
			TriggerClientEvent('esx_vehicleshop:sendVehicles', -1, vehicles)
		end)
	end)
end)

function getVehicleLabelFromModel(model)
	for k,v in ipairs(vehicles) do
		if v.model == model then
			return v.name
		end
	end

	return
end

ESX.RegisterServerCallback('esx_vehicleshop:getCategories', function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:getCategories', {})
	cb(categories)
end)

ESX.RegisterServerCallback('esx_vehicleshop:getVehicles', function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:getVehicles', {})
	cb(vehicles)
end)

ESX.RegisterServerCallback('esx_vehicleshop:buyVehicle', function(source, cb, model, plate, forGang)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:buyVehicle', {model = model, plate = plate, forGang = forGang})
	local xPlayer = ESX.GetPlayerFromId(source)
	local modelPrice

	for k,v in ipairs(vehicles) do
		if model == v.model then
			modelPrice = v.price
			break
		end
	end

	if modelPrice and xPlayer.getMoney() >= modelPrice then
		if forGang then
			ESX.TriggerServerCallback("master_gang:GetGang", source, function(data)
				DataRecived = true
				if data == false then
					TriggerClientEvent("pNotify:SendNotification", source, { text = "شما گنگ ندارید!", type = "error", timeout = 5000, layout = "bottomCenter"})
					cb(false)
				elseif data.gang ~= nil and data.grade ~= nil and data.grade >= 5 then
					xPlayer.removeMoney(modelPrice)
					MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
						['@owner']   = data.gang,
						['@plate']   = plate,
						['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate})
					}, function(rowsChanged)
						TriggerClientEvent("pNotify:SendNotification", source, { text = "خودرو مخصوص، گنگ خریداری شد!", type = "success", timeout = 5000, layout = "bottomCenter"})
						cb(true)
					end)
				else
					TriggerClientEvent("pNotify:SendNotification", source, { text = "شما اجازه خرید ماشین برای گنگ را ندارید!", type = "error", timeout = 5000, layout = "bottomCenter"})
					cb(false)
				end
			end, source)
		else
			xPlayer.removeMoney(modelPrice)

			MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
				['@owner']   = xPlayer.identifier,
				['@plate']   = plate,
				['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate})
			}, function(rowsChanged)
				TriggerClientEvent("pNotify:SendNotification", source, { text = _U('vehicle_belongs', plate), type = "success", timeout = 5000, layout = "bottomCenter"})
				cb(true)
			end)
		end
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:isPlateTaken', function(source, cb, plate)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:isPlateTaken', {plate = plate})
	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)

ESX.RegisterServerCallback('esx_vehicleshop:retrieveJobGradeVehicles', function(source, cb, vtype)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:retrieveJobGradeVehicles', {vtype = vtype})
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if xPlayer.job.name == nil or xPlayer.job.grade_name == nil then
		cb({})
		return
	end
	
	local cars_key = xPlayer.job.grade_name
	local hasSubJob = false
	
	if xPlayer.job.job_sub ~= nil and xPlayer.job.job_sub ~= ''  then
		cars_key = xPlayer.job.grade_name .. '_' .. xPlayer.job.job_sub
		hasSubJob = true
	end
	
	if job_cars[xPlayer.job.name] == nil then
		job_cars[xPlayer.job.name] = {}
	end
	
	if job_cars[xPlayer.job.name][cars_key] == nil  then
		job_cars[xPlayer.job.name][cars_key] = {}
	end
	
	if job_cars[xPlayer.job.name][cars_key][vtype] == nil  then
		job_cars[xPlayer.job.name][cars_key][vtype] = {}
	else
		cb(job_cars[xPlayer.job.name][cars_key][vtype])
		return
	end
	
	if hasSubJob then
		MySQL.Async.fetchAll('SELECT * FROM job_cars WHERE job = @job and type = @type and (grade = @grade OR grade = @job_sub)', {
			['@type'] = vtype,
			['@job'] = xPlayer.job.name,
			['@grade'] = xPlayer.job.grade_name,
			['@job_sub'] = xPlayer.job.job_sub
		}, function(result)
			job_cars[xPlayer.job.name][cars_key][vtype] = result
			cb(result)
			return
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM job_cars WHERE grade = @grade AND job = @job and type = @type', {
			['@type'] = vtype,
			['@job'] = xPlayer.job.name,
			['@grade'] = xPlayer.job.grade_name
		}, function(result)
			job_cars[xPlayer.job.name][cars_key][vtype] = result
			cb(result)
			return
		end)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:RentCar', function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:RentCar', {})
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if xPlayer.getMoney() >= Config.RentPrice then
		plate = 'R' .. LastRentID
		RentCars[plate] = source
		
		LastRentID = LastRentID + 1
		xPlayer.removeMoney(Config.RentPrice)
		cb(true, plate)
	else
		TriggerClientEvent("pNotify:SendNotification", source, { text = 'شما پول کافی برای اجاره خودرو را ندارید.', type = "error", timeout = 5000, layout = "bottomCenter"})
		cb(false, nil)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:returnRentCar', function(source, cb, plate, vehiclesTmp)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:returnRentCar', {plate = plate})
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if plate ~= nil and RentCars[plate] ~= nil and RentCars[plate] == source then
		RentCars[plate] = nil
		xPlayer.addMoney(Config.RentbackMoney)
		TriggerClientEvent("pNotify:SendNotification", source, { text = 'الباقی هزینه به شما تحویل داده شد، از شما سپاس گذاریم.', type = "success", timeout = 5000, layout = "bottomCenter"})
		cb(true)
	else
		TriggerClientEvent("pNotify:SendNotification", source, { text = 'شما امکان تحویل این خودرو را ندارید.', type = "error", timeout = 5000, layout = "bottomCenter"})
		cb(false)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:ChangeCarOwner', function(source, cb, plate, target)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_vehicleshop:ChangeCarOwner', {plate = plate, target = target})
	local xPlayer = ESX.GetPlayerFromId(source)
	local tPlayer = ESX.GetPlayerFromId(target)
	
	if xPlayer and tPlayer and plate ~= nil then
	
		if xPlayer.getMoney() < Config.ChangeOwnerPrice then
			TriggerClientEvent("pNotify:SendNotification", source, { text = 'شما پول کافی برای انتقال خودرو را ندارید.', type = "error", timeout = 5000, layout = "bottomCenter"})
			cb(false)
			return
		end
		
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = plate
		}, function(result)
			if result[1] then 
				MySQL.Async.execute('UPDATE owned_vehicles SET `owner` = @newowner WHERE plate = @plate AND owner = @owner', {
					['@owner'] = xPlayer.identifier,
					['@plate'] = plate,
					['@newowner'] = tPlayer.identifier
				}, function(rowsChanged)
					xPlayer.removeMoney(Config.ChangeOwnerPrice)
					cb(1)
				end)
			else
				cb(2)
			end
		end)
		
		return
	end
	
	TriggerClientEvent("pNotify:SendNotification", source, { text = 'شما امکان تغییر مالکیت ندارید.', type = "error", timeout = 5000, layout = "bottomCenter"})
	cb(false)
end)

ESX.RegisterServerCallback('master_vehicles:getOwnedVehicles', function(source, cb, type, isGang)
	ESX.RunCustomFunction("anti_ddos", source, 'master_vehicles:getOwnedVehicles', {type = type, isGang = isGang})
	local xPlayer = ESX.GetPlayerFromId(source)
	OwnedCars = {}
	if type == 'cars' then
		local ownedAmbulanceCars = {}
		if isGang then
			ESX.TriggerServerCallback("master_gang:GetGang", source, function(data)
				DataRecived = true
				if data == false then
					cb(OwnedCars)
				elseif data.gang ~= nil then
					MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type', {
						['@owner'] = data.gang,
						['@Type'] = 'car'
					}, function(data)
						for _,v in pairs(data) do
							local vehicle = json.decode(v.vehicle)
							table.insert(OwnedCars, {vehicle = vehicle, data = v})
						end
						
						cb(OwnedCars)
					end)
				else
					cb(OwnedCars)
				end
			end, source)
		else
			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type', {
				['@owner'] = xPlayer.identifier,
				['@Type'] = 'car'
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(OwnedCars, {vehicle = vehicle, data = v})
				end
				
				cb(OwnedCars)
			end)
		end
	elseif type == 'helis' then
		local ownedAmbulanceHelis = {}
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type', {
			['@owner'] = xPlayer.identifier,
			['@Type'] = 'helis'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(OwnedCars, {vehicle = vehicle, data = v})
			end
			
			cb(OwnedCars)
		end)
	end
end)

-- Store Vehicles
ESX.RegisterServerCallback('master_vehicles:storeVehicle', function (source, cb, vehicleProps, isGang)
	ESX.RunCustomFunction("anti_ddos", source, 'master_vehicles:storeVehicle', {isGang = isGang})
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match("^%s*(.-)%s*$")
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)

	if isGang then
		ESX.TriggerServerCallback("master_gang:GetGang", source, function(data)
			DataRecived = true
			if data == false then
				cb(false)
			elseif data.gang ~= nil then
				MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
					['@owner'] = data.gang,
					['@plate'] = vehicleProps.plate
				}, function (result)
					if result[1] ~= nil then
						local originalvehprops = json.decode(result[1].vehicle)
						if originalvehprops.model == vehicleProps.model and vehicleProps.plate == originalvehprops.plate then
							MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle, stored = 1 WHERE owner = @owner AND plate = @plate', {
								['@owner'] = data.gang,
								['@vehicle'] = json.encode(vehicleProps),
								['@plate'] = vehicleProps.plate
							}, function (rowsChanged)
								cb(true)
							end)
						else
							print(('master_vehicles: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
							cb(false)
						end
					else
						cb(false)
					end
				end)
			else
				cb(false)
			end
		end, source)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = vehicleProps.plate
		}, function (result)
			if result[1] ~= nil then
				local originalvehprops = json.decode(result[1].vehicle)
				if originalvehprops.model == vehicleProps.model and vehicleProps.plate == originalvehprops.plate then
					MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle, stored = 1 WHERE owner = @owner AND plate = @plate', {
						['@owner'] = xPlayer.identifier,
						['@vehicle'] = json.encode(vehicleProps),
						['@plate'] = vehicleProps.plate
					}, function (rowsChanged)
						cb(true)
					end)
				else
					print(('master_vehicles: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
					cb(false)
				end
			else
				cb(false)
			end
		end)
	end
end)

ESX.RegisterServerCallback('master_vehicles:SpawnGarageCar', function (source, cb, plate, isGang)
	ESX.RunCustomFunction("anti_ddos", source, 'master_vehicles:SpawnGarageCar', {plate = plate, isGang = isGang})
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if isGang == true then
		
		ESX.TriggerServerCallback("master_gang:GetGang", source, function(data)
			DataRecived = true
			if data == false then
				cb(2, nil)
			elseif data.gang ~= nil then
				MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
					['@owner'] = data.gang,
					['@plate'] = plate
				}, function (result)
					if result[1] ~= nil then
						if result[1].stored == 1 then
							MySQL.Async.execute('UPDATE owned_vehicles SET stored = 0 WHERE owner = @owner AND plate = @plate', {
								['@owner'] = data.gang,
								['@plate'] = plate
							}, function (rowsChanged)
								local vehicleData = json.decode(result[1].vehicle)
								cb(1, vehicleData)
							end)
						else
							FindCar(source, plate, data.gang)
							local plate_key = plate:gsub( " ", "_")
							if CarsNeedToFind[plate_key] ~= nil then
								cb(3, nil)
							elseif xPlayer.getMoney() < Config.FindGangCarPrice then
								cb(5, nil)
							else
								FindCar(source, plate, data.gang)
								cb(4, nil)
							end
						end
					else
						print(('master_vehicles: %s attempted to Cheat! Tried Getting: %s'):format(xPlayer.identifier, plate))
						cb(2, nil)
					end
				end)
			else
				cb(2, nil)
			end
		end, source)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = plate
		}, function (result)
			if result[1] ~= nil then
				if result[1].stored == 1 and xPlayer.getMoney() >= Config.GetCarPrice then
					MySQL.Async.execute('UPDATE owned_vehicles SET stored = 0 WHERE owner = @owner AND plate = @plate', {
						['@owner'] = xPlayer.identifier,
						['@plate'] = plate
					}, function (rowsChanged)
						xPlayer.removeMoney(Config.GetCarPrice)
						local vehicleData = json.decode(result[1].vehicle)
						cb(1, vehicleData)
					end)
				elseif result[1].stored == 1 and xPlayer.getMoney() < Config.GetCarPrice then
					cb(5, nil)
				else
					local plate_key = plate:gsub( " ", "_")
					if CarsNeedToFind[plate_key] ~= nil then
						cb(3, nil)
					elseif xPlayer.getMoney() < Config.FindCarPrice then
						cb(5, nil)
					else
						FindCar(source, plate, nil)
						cb(4, nil)
					end
				end
			else
				print(('master_vehicles: %s attempted to Cheat! Tried Getting: %s'):format(xPlayer.identifier, plate))
				cb(2, nil)
			end
		end)
	end
end)

function FindCar(source, plate, GangName)
	Citizen.CreateThread(function()
		local xPlayer = ESX.GetPlayerFromId(source)
		local plate_key = plate:gsub( " ", "_")
		if CarsNeedToFind[plate_key] ~= nil then
			return
		end
		CarsNeedToFind[plate_key] = source
		
		if GangName ~= nil then
			xPlayer.removeMoney(Config.FindGangCarPrice)
		else
			xPlayer.removeMoney(Config.FindCarPrice)
		end
		
		Citizen.Wait(60000)
		CarsNeedToFind[plate_key] = nil
		xPlayer = ESX.GetPlayerFromId(source)
		
		if GangName ~= nil then
			MySQL.Async.execute('UPDATE owned_vehicles SET stored = 1 WHERE owner = @owner AND plate = @plate', {
				['@owner'] = GangName,
				['@plate'] = plate
			}, function (rowsChanged) end)
			if xPlayer then
				TriggerClientEvent("pNotify:SendNotification", source, { text = "خودرو گنگ با پلاک " .. plate .. " به پارکینگ گاراژ منتقل شد.", type = "info", timeout = 5000, layout = "bottomCenter"})
			end
		else
			MySQL.Async.execute('UPDATE owned_vehicles SET stored = 1 WHERE owner = @owner AND plate = @plate', {
				['@owner'] = xPlayer.identifier,
				['@plate'] = plate
			}, function (rowsChanged) end)
			if xPlayer then
				TriggerClientEvent("pNotify:SendNotification", source, { text = "خودرو شما با پلاک " .. plate .. " به پارکینگ گاراژ منتقل شد.", type = "info", timeout = 5000, layout = "bottomCenter"})
			end
		end
	end)
end

RegisterServerEvent("car_lock:GiveKeys")
AddEventHandler("car_lock:GiveKeys", function(vehNet, plate)
	ESX.RunCustomFunction("anti_ddos", source, 'car_lock:GiveKeys', {plate = plate})
    local src = source
    local plate = string.upper(plate)
    table.insert(vehicleOwners, {owner = src, netid = vehNet, plate = plate})
end)

RegisterServerEvent("car_lock:CheckOwnership")
AddEventHandler("car_lock:CheckOwnership", function(vehNet, plate)
	ESX.RunCustomFunction("anti_ddos", source, 'car_lock:CheckOwnership', {plate = plate})
    local src = source
	
	if plate == nil then
		TriggerClientEvent("car_lock:ToggleOutsideLock", src, vehNet, false)
		return
	end
	
    local plate = string.upper(plate)
    for i = 1, #vehicleOwners do
        if vehicleOwners[i].netid == vehNet then
            if vehicleOwners[i].owner == src then
                if vehicleOwners[i].plate == plate then
                    TriggerClientEvent("car_lock:ToggleOutsideLock", src, vehNet, true)
                end
            end
        end
    end
    TriggerClientEvent("car_lock:ToggleOutsideLock", src, vehNet, false)
end)