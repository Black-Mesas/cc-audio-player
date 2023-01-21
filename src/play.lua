local dir = "/" .. fs.getDir(shell.getRunningProgram()) .. "/"

local speaker = peripheral.find("speaker")

assert(speaker,"Missing speaker.")

local songlist = {} do
	local file = io.open(dir .. "songs.txt","r")
	
	assert(file,"Missing songs.txt")
	
	for line in file:lines() do
		local equals = string.find(line,"=")
		
		if equals then
			local name = string.sub(line,1,equals - 1)
			local link = string.sub(line,equals + 1,#line)
			
			table.insert(songlist,{name,link})
		end
	end
	
	file:close()
end

local dfpwm = require("cc.audio.dfpwm")

local decoder = dfpwm.make_decoder()

local screenx,screeny = term.getSize()

local maxlength = math.min(screeny - 3,#songlist)
local songscroll = 0
local songindex = 1
local songdata

local error = {"",""}
local status = ""

local function setcolor(fg,bg)
	term.setTextColor(fg)
	term.setBackgroundColor(bg)
end

local function loadchunk()
	local chunk = songdata.read(8 * 1024)
	
	if not chunk then
		
		return false
	end
	
	speaker.playAudio(decoder(chunk))
	
	return true
end

os.queueEvent("start")

while true do
	local event = {os.pullEventRaw()}
	
	if event[1] == "terminate" then
		setcolor(colors.white,colors.black)
		term.setCursorPos(1,1)
		term.clear()
		
		speaker.stop()
		
		return 
	end
	
	if event[1] == "key" then
		local code = event[2]
		
		if code == keys.up then
			songindex = math.max(songindex - 1,1)
			
			if songindex <= songscroll then
				songscroll = math.max(songscroll - 1,0)
			end
		elseif code == keys.down then
			songindex = math.min(songindex + 1,#songlist)
			
			if songindex > songscroll + maxlength then
				songscroll = math.min(songscroll + 1,#songlist)
			end
		elseif code == keys.space then
			status = "Stopped"
			songdata = nil
			speaker.stop()
		elseif code == keys.enter then
			local download = http.get(songlist[songindex][2],{},true)
			
			local response,reason = download.getResponseCode()
			
			error[1] = response
			error[2] = reason
			
			if response == 200 then
				status = "Playing"
				songdata = download
				speaker.stop()
				loadchunk()
			end
		end
		
	end
	
	if event[1] == "speaker_audio_empty" then
		if songdata then
			if not loadchunk() then
				status = "Finished"
				songdata = nil
			end
		end
	end
	
	term.clear()
	
	for i=1,maxlength do
		local song = songlist[i + songscroll]
		
		if song then
			if i == songindex - songscroll then
				setcolor(colors.black,colors.white)
			else
				setcolor(colors.white,colors.black)
			end
			
			term.setCursorPos(1,i)
			term.write(song[1])
		end
	end
	
	setcolor(colors.gray,colors.black)
	
	term.setCursorPos(1,maxlength + 2)
	term.write(tostring(error[1]) .. " " .. error[2])
	
	term.setCursorPos(1,maxlength + 3)
	term.write(status)
	
	setcolor(colors.white,colors.black)
end
