--- Color module
-- @module Color

--Global color defines.
--@usage: font_color=defines.colors.red to set a styles font color to red.
defines.colors = {
  white       = {r=1   , g=1   , b=1   }, black     = {r=0.00, g=0.00, b=0   },
  darkgrey    = {r=0.25, g=0.25, b=0.25}, grey      = {r=0.5 , g=0.5 , b=0.5 },
  lightgrey   = {r=0.75, g=0.75, b=0.75}, red       = {r=1   , g=0   , b=0   },
	darkred     = {r=0.5 , g=0   , b=0   }, lightred  = {r=1   , g=0.5 , b=0.5 },
  green       = {r=0   , g=1   , b=0   }, darkgreen = {r=0   , g=0.5 , b=0   },
  lightgreen  = {r=0.5 , g=1   , b=0.5 }, blue      = {r=0   , g=0   , b=1   },
	darkblue    = {r=0   , g=0   , b=0.5 }, lightblue = {r=0.5 , g=0.5 , b=1   },
	orange      = {r=1   , g=0.55, b=0.1 }, yellow    = {r=1   , g=1   , b=0   },
  pink        = {r=1   , g=0   , b=1   }, purple    = {r=0.6 , g=0.1 , b=0.6 },
  brown       = {r=0.6 , g=0.4 , b=0.1 },
}
defines.anticolors = {
	white = defines.colors.black, black = defines.colors.white, darkgrey = defines.colors.white,
  grey = defines.colors.black, 	lightgrey = defines.colors.black, 	red = defines.colors.white,
	darkred = defines.colors.white, lightred = defines.colors.black, green = defines.colors.black,
	darkgreen = defines.colors.white, 	lightgreen = defines.colors.black, 	blue = defines.colors.white,
	darkblue = defines.colors.white, 	lightblue = defines.colors.black, 	orange = defines.colors.black,
	yellow = defines.colors.black, 	pink = defines.colors.white, 	purple = defines.colors.white,
	brown = defines.colors.white,
}
defines.lightcolors = {
	white = defines.colors.lightgrey, grey = defines.colors.darkgrey, 	lightgrey = defines.colors.grey,
	red = defines.colors.lightred, 	green = defines.colors.lightgreen, 	blue = defines.colors.lightblue,
	yellow = defines.colors.orange, 	pink = defines.colors.purple,
}
