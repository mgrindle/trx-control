-- Copyright (c) 2023 Marc Balmer HB9SSB
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.

-- Lower half of the trx-control Lua part

-- Yaesu FT-710 CAT driver

local validModes = {
	['lsb'] = '1',
	['usb'] = '2',
	['cw-u'] = '3',
	['fm'] = '4',
	['am'] = '5',
	['rtty-l'] = '6',
	['cw-l'] = '7',
	['data-l'] = '8',
	['rtty-u'] = '9',
	['data-fm'] = 'A',
	['rm-n'] = 'B',
	['data-u'] = 'C',
	['am-n'] = 'D',
	['psk'] = 'E',
	['data-fm-n'] = 'F'
}

local function initialize()
	trx.setspeed(38400)
	trx.write('ID;')
	local reply = trx.read(7)
	if reply ~= 'ID0800;' then
		print 'this is not a Yaesu FT-710 transceiver'
	else
		print 'this is a Yaesu FT-710 transceiver'
	end
end

-- Handling auto information

local function startStatusUpdates()
	trx.write('AI1;')
	return string.byte(';')
end

local function stopStatusUpdates()
	trx.write('AI0;')
	return 'status updates off'
end

-- Decoders for auto information

local function frequencyVfoA(data)
	local hz = tonumber(string.sub(data, 3, 11))
	return { frequency = { ['vfo-a'] = hz } }
end

local function frequencyVfoB(data)
	local hz = tonumber(string.sub(data, 3, 11))
	return { frequency = { ['vfo-b'] = hz } }
end

local function informationVfoA(data)
	mode = string.sub(data, 3, 5)
	local hz = tonumber(string.sub(data, 6, 14))

	return {
		['vfo-a'] = {
			mode = mode,
			frequency = hz
		}
	}
end

local function lockDecoder(data)
	if string.sub(data, 3, 3) == '0' then
		print('lock off')
		return { lock = 'off' }
	else
		print 'lock on'
		return { lock = 'on' }
	end
end

local function mode(data)
	local band = string.sub(data, 3, 3)
	local mode = string.sub(data, 4, 4)

	if band == '0' then
		band = 'main'
	else
		band = 'sub'
	end
	local name = 'unknown mode'

	for k, v in pairs(validModes) do
		if v == mode then
			name = k
			break
		end
	end

	return {
		operatingMode = {
			band = band,
			mode = name
		}
	}
end

local decoders = {
	FA = frequencyVfoA,
	FB = frequencyVfoB,
	IF = informationVfoA,
	LK = lockDecoder,
	MD = mode
}

local function handleStatusUpdates(data)
	print('FT-710: handle status update, data:', data)

	local command = string.sub(data, 1, 2)
	local decoder = decoders[command]
	if decoder ~= nil then
		local reply = decoder(data)
		print(reply.lock)
		return reply
	end

	return { unknownCommand = command }
end

-- direct commands

local function setLock()
	trx.write('LK1;')
	return 'locked'
end

local function setUnlock()
	trx.write('LK0;')
	return 'unlocked'
end

local function setFrequency(freq)
	trx.write(string.format('FA%s;', freq))
	return freq
end

local function getFrequency()
	trx.write('FA;')
	local reply = trx.read(12)
	return tonumber(string.sub(reply, 3, 11))
end

local function setMode(band, mode)
	print('ft-710', band, mode)
	local bcode

	if band == 'main' then
		bcode = '0'
	elseif band == 'sub' then
		bcode = '1'
	else
		return nil, 'invalid band'
	end

	if validModes[mode] ~= nil then
		trx.write(string.format('MD%s%s;', bcode, validModes[mode]))
		return band, mode
	else
		return nil, 'invalid mode'
	end
end

local function getMode(band)
	local bcode = '0'
	if band == 'sub' then
		bcode = '1'
	end

	trx.write(string.format('MD%s;', bcode))
	local reply = trx.read(5)
	local mode = string.sub(reply, 4, 4)

	for k, v in pairs(validModes) do
		if v == mode then
			return k
		end
	end
	return 'unknown mode'
end

return {
	initialize = initialize,
	startStatusUpdates = startStatusUpdates,
	stopStatusUpdates = stopStatusUpdates,
	handleStatusUpdates = handleStatusUpdates,
	setLock = setLock,
	setUnlock = setUnlock,
	setFrequency = setFrequency,
	getFrequency = getFrequency,
	getMode = getMode,
	setMode = setMode
}
