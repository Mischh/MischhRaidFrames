local MRF = Apollo.GetAddon("MischhRaidFrames")

function MRF:GetDefaults()
	local colors = {
		Class = {},
		White = {name = "White", c="FFFFFFFF"},
		Black = {name = "Black", c="FF000000"},
		FUIGray={name = "FUIGray", c="FF272727"},
		Red	  =	{name = "Red", c="FFFF0000"},
		LightBlue = {name = "LightBlue", c="FF00A0FF"},
		Yellow = {name = "Yellow", c = "FFFFD000"},
		Invisible = {name = "Invisible", c = "00FFFFFF"},
		Health = {
			anchors = {
				[0] = {a=1, r=0.7, g=0.7, b=0.7}, --White
				[1] = {a=1, r=1, g=0, b=0}, --Red
				[100] = {a=1, r=1, g=1, b=0}, --Yellow
			},
			name = "Health"
		}
	}
	
	local options = {
		["Frame Handler"] = {
			direction = "row",
			length = 1,
		},
		modules = {
			["Health"] = {
				text = "%n"
			},
			["Name"] = {
				text = "%n"
			},
			["Shield"] = {
				text = "%p%%"
			},
			["Absorb"] = {
				text = "%p%%",
				reference = "GetMaxHealth"
			},
			["Class Colors"] = {
				ref = colors["Class"],
			},
			["Constant Colors"] = {
				colors["White"],
				colors["Black"],
				colors["FUIGray"],
				colors["Red"],			
				colors["LightBlue"],
				colors["Yellow"],
				colors["Invisible"],
			},
			["Gradient Colors"] = {
				colors["Health"]
			},
			["Raid Markers"] = {
				xOffset = 1,
				yOffset = 0.5,
				width = 11,
				height = 11,
			},
			["Lead Marker"] = {
				xOffset = 0,
				yOffset = 0.5,
				width = 3,
				height = 15,
			},
			["Class Icons"] = {
				activated = false,
				xOffset = 0.03,
				yOffset = 0.5,
				width = 11,
				height = 11,
			},
			["Readycheck"] = {
				activated = true,
				xOffset = 0.15,
				yOffset = 0.5,
				width = 13,
				height = 13,
			},
			["Distance Fader"] = {
				activated = true,
				distance = 40,
				fraction = 0.3,
			},
		},
		frame = {
			size = {0,0,250,25},
			inset = 1,
			[1] = {size = 4, modKey = "Health", lColor = colors["FUIGray"], rColor = colors["Health"], textSource = "Name", textColor = colors["Class"]},
			[2] = {size = 1, modKey = "Shield", lColor = colors["FUIGray"], rColor = colors["LightBlue"]},
			[{[0]=4}] = {size = 1, modKey = "Absorb", lColor = colors["Yellow"], rColor = colors["Invisible"]},
		},
	}

	return options
end
--function MRF:Defaultify()
--MRF:GetOption():Set(options)
--end
