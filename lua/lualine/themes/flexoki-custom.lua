local p = {
	bg = "#FFFCF0",
	bg2 = "#F2F0E5",
	ui = "#E6E4D9",
	ui2 = "#DAD8CE",
	tx = "#403E3C",
	tx2 = "#6F6E69",
	tx3 = "#9F9D96",
	red = "#AF3029",
	orange = "#BC5215",
	green = "#66800B",
	blue = "#205EA6",
	blue_soft = "#C6DDE8",
	purple = "#5E409D",
	magenta = "#A02F6F",
}

local function mode(color)
	return {
		a = { fg = p.tx2, bg = color, gui = "bold" },
		b = { fg = p.tx2, bg = p.bg2 },
		c = { fg = p.tx, bg = p.ui },
		x = { fg = p.tx, bg = p.ui },
		y = { fg = p.tx2, bg = p.bg2 },
		z = { fg = p.tx2, bg = color, gui = "bold" },
	}
end

return {
	normal = mode(p.blue_soft),
	insert = mode("#DDE2B2"),
	visual = mode("#E2D9E9"),
	replace = mode("#FFCABB"),
	command = mode("#FED3AF"),
	terminal = mode("#BFE8D9"),
	inactive = {
		a = { fg = p.tx3, bg = p.ui },
		b = { fg = p.tx3, bg = p.ui },
		c = { fg = p.tx3, bg = p.ui },
		x = { fg = p.tx3, bg = p.ui },
		y = { fg = p.tx3, bg = p.ui },
		z = { fg = p.tx3, bg = p.ui },
	},
}
