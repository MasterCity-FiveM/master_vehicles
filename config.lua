Config                            = {}
Config.DrawDistance               = 100
Config.MarkerColor                = {r = 120, g = 120, b = 240}
Config.EnablePlayerManagement     = false -- enables the actual car dealer job. You'll need esx_addonaccount, esx_billing and master_society
Config.ResellPercentage           = 50

Config.Locale                     = 'en'

Config.LicenseEnable = false -- require people to own drivers license when buying vehicles? Only applies if EnablePlayerManagement is disabled. Requires esx_license

-- looks like this: 'LLL NNN'
-- The maximum plate length is 8 chars (including spaces & symbols), don't go past it!
Config.PlateLetters  = 3
Config.PlateNumbers  = 3
Config.PlateUseSpace = true

Config.RentPrice = 400
Config.RentbackMoney = 200
Config.RentCar = 'panto'

Config.ChangeOwnerPrice = 500

Config.Zones = {
	-- BLIP BUY
	ShopEntering = {
		Pos   = vector3(-33.7, -1102.0, 25.4),
		Size  = {x = 1.5, y = 1.5, z = 1.0},
		Type  = 1
	},
	-- DISPLAY CAR
	ShopInside = {
		Pos     = vector3(404.90, -949.58, -99.71),
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Heading = -20.0,
		Type    = -1
	},
	-- Car bought
	ShopOutside = {
		Pos     = vector3(-28.6, -1085.6, 25.5),
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Heading = 330.0,
		Type    = -1
	},
	
	-- Foroshe Mashin
	ResellVehicle = {
		Pos   = vector3(-44.6, -1080.7, 25.6),
		Size  = {x = 3.0, y = 3.0, z = 1.0},
		Type  = 1
	}
}

Config.RentSize    = {x = 1.5, y = 1.5, z = 1.0}
Config.RentMarkerColor = {r = 255, g = 252, b = 77}
Config.RentType    = 36

Config.RentLocations = {
	Prison = {
		BlipPos = vector3(602.0176, 89.6967, 92.75317),
		SpawnPos = {{coords = vector3(616.7341, 100.8528, 92.60144), heading = 249.44882, radius = 6.0}}
	},
	PD = {
		BlipPos = vector3(453.4418, -890.9934, 35.96924),
		SpawnPos = {{coords = vector3(463.8725, -894.8044, 35.96924), heading = 249.44882, radius = 6.0}}
	},
	Sheriff = {
		BlipPos = vector3(1706.769, 3592.193, 35.41321),
		SpawnPos = {{coords = vector3(1715.815, 3597.903, 35.21094), heading = 116.44882, radius = 6.0}}
	},
	Mining = {
		BlipPos = vector3(2538.237, 2606.914, 37.94067),
		SpawnPos = {{coords = vector3(2544.646, 2610.87, 37.94067), heading = 17.44882, radius = 6.0}}
	},
	CityWest = {
		BlipPos = vector3(-518.9934, -602.6638, 30.4425),
		SpawnPos = {{coords = vector3(-509.8549, -595.134, 30.29089), heading = 178.44882, radius = 6.0}}
	},
	CitySouth = {
		BlipPos = vector3(107.5121, -1408.062, 29.27991),
		SpawnPos = {{coords = vector3(105.6923, -1399.253, 29.27991), heading = 136.44882, radius = 6.0}}
	},
	CityNorth = {
		BlipPos = vector3(-352.7604, 34.86594, 47.78101),
		SpawnPos = {{coords = vector3(-355.4637, 29.61758, 47.76416), heading = 76.44882, radius = 6.0}}
	},
	CityEast = {
		BlipPos = vector3(998.0967, -1864.668, 30.88062),
		SpawnPos = {{coords = vector3(1005.191, -1870.971, 30.88062), heading = 354.44882, radius = 6.0}}
	},
	CityNorthSouth = {
		BlipPos = vector3(-1768.022, -506.9406, 38.81689),
		SpawnPos = {{coords = vector3(-1776.211, -517.4506, 38.7832), heading = 300.44882, radius = 6.0}}
	},
	CityAirPort = {
		BlipPos = vector3(-1129.24, -2682.884, 14.01392),
		SpawnPos = {{coords = vector3(-1138.787, -2690.545, 13.92969), heading = 283.44882, radius = 6.0}}
	},
	BironShahr = { -- ATM Dasht khodesh
		BlipPos = vector3(-3051.244, 592.7868, 7.543579),
		SpawnPos = {{coords = vector3(-3053.169, 599.7099, 7.341431), heading = 289.44882, radius = 6.0}}
	},
	BironShahrBalaSamtRast = { -- ATM Dasht khodesh
		BlipPos = vector3(1695.31, 4785.336, 41.98462),
		SpawnPos = {{coords = vector3(1692.264, 4778.044, 41.91724), heading = 87.44882, radius = 6.0}}
	},
	BironShahrVasat = { 
		BlipPos = vector3(624.5275, 2744.703, 42.01831),
		SpawnPos = {{coords = vector3(618.1583, 2723.393, 41.8667), heading = 2.44882, radius = 6.0}}
	},
	BironShahrPayinSamtRast = { 
		BlipPos = vector3(2587.925, 425.3934, 108.4403),
		SpawnPos = {{coords = vector3(2579.42, 428.4791, 108.4403), heading = 175.44882, radius = 6.0}}
	},
	BironShahrBalayeBala = { 
		BlipPos = vector3(-128.2813, 6291.534, 31.33557),
		SpawnPos = {{coords = vector3(-132.4088, 6284.598, 31.33557), heading = 226.44882, radius = 6.0}}
	},
	BaghalJobCenter = {
		BlipPos = vector3(-296.3473, -987.2571, 31.06592),
		SpawnPos = {
			{coords = vector3(-305.367, -989.7626, 31.06592), heading = 340.15747070313, radius = 6.0},
			{coords = vector3(-312.0396, -986.1362, 31.06592), heading = 340.15747070313, radius = 6.0},
			{coords = vector3(-319.2132, -984.1846, 31.06592), heading = 340.15747070313, radius = 6.0}
		}
	},
	NewMining = {
		BlipPos = vector3(-522.6066, 1991.895, 205.8828),
		SpawnPos = {{coords = vector3(-524.7956, 1985.987, 205.9165), heading = 141.7322845459, radius = 6.0}}
	},
	ParkingBala = {
		BlipPos = vector3(234.422, -751.4374, 34.62122),
		SpawnPos = {{coords = vector3(249.8901, -745.3318, 34.62122), heading = 158.74014282227, radius = 6.0}}
	},
	Carshop = {
		BlipPos = vector3(-59.18242, -1115.209, 26.43225),
		SpawnPos = {{coords = vector3(-59.18242, -1115.209, 26.43225), heading = 0.0, radius = 6.0}}
	}
}

Config.GarageSize    = {x = 1.5, y = 1.5, z = 1.0}
Config.GarageMarkerColor = {r = 66, g = 245, b = 149}
Config.GarageType    = 36
Config.GetCarPrice   = 10
Config.FindCarPrice   = 450
Config.FindGangCarPrice   = 1500

Config.GarageLocations = {
	Main = {
		ShowBlipOnMap = true,
		BlipPos = vector3(225.4549, -763.345, 30.81323),
		SpawnPos = {
			Spawn1 = { coords = vector3(219.2176, -768.8835, 30.81323), heading = 246.61418151855, radius = 6.0 },
            Spawn2 = { coords = vector3(214.7209, -778.6285, 30.81323), heading = 246.61418151855, radius = 6.0 },
            Spawn3 = { coords = vector3(237.5473, -795.5736, 30.81323), heading = 68.61418151855, radius = 6.0 },
            Spawn4 = { coords = vector3(239.6176, -787.7143, 30.81323), heading = 68.61418151855, radius = 6.0 }
		}
	},
    Sheriff = {
		ShowBlipOnMap = true,
		BlipPos = vector3(1737.785, 3718.958, 34.03149),
		SpawnPos = {
			Spawn1 = { coords = vector3(1728.725, 3714.316, 34.16626), heading = 17.007873535156, radius = 6.0 },
			Spawn2 = { coords = vector3(1722.198, 3711.903, 34.23364), heading = 17.007873535156, radius = 6.0 }

		}
	},
    BankSheriff = {
		ShowBlipOnMap = true,
		BlipPos = vector3(120.567, 6615.93, 31.84106),
		SpawnPos = {
			Spawn1 = { coords = vector3(117.5868, 6599.301, 32.00952), heading = 274.96063232422, radius = 6.0 },
			Spawn2 = { coords = vector3(125.7785, 6589.583, 32.00952), heading = 274.96063232422, radius = 6.0 }
		}
	}
}