ESX = nil
local categories, vehicles, job_cars = {}, {}, {}
local RentCars = {}
local LastRentID = 1
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function RemoveOwnedVehicle(plate)
	MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	})
end

MySQL.ready(function()
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
	cb(categories)
end)

ESX.RegisterServerCallback('esx_vehicleshop:getVehicles', function(source, cb)
	cb(vehicles)
end)

ESX.RegisterServerCallback('esx_vehicleshop:buyVehicle', function(source, cb, model, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	local modelPrice

	for k,v in ipairs(vehicles) do
		if model == v.model then
			modelPrice = v.price
			break
		end
	end

	if modelPrice and xPlayer.getMoney() >= modelPrice then
		xPlayer.removeMoney(modelPrice)

		MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
			['@owner']   = xPlayer.identifier,
			['@plate']   = plate,
			['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate})
		}, function(rowsChanged)
			TriggerClientEvent("pNotify:SendNotification", source, { text = _U('vehicle_belongs', plate), type = "success", timeout = 5000, layout = "bottomCenter"})
			cb(true)
		end)
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:isPlateTaken', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)

ESX.RegisterServerCallback('esx_vehicleshop:retrieveJobGradeVehicles', function(source, cb, vtype)
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
