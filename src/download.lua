local dir = "/" .. shell.dir() .. "/"
local name = "audio-player"

if fs.exists(dir .. name) then
	printError("Already installed.")
	return
end

fs.makeDir(dir .. name)
shell.execute("wget","https://raw.githubusercontent.com/Black-Mesas/cc-audio-player/main/src/play.lua",dir .. name .. "/play.lua")
io.open(dir .. name .. "/songs.txt","w"):close()
