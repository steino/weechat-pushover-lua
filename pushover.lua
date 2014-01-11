PO = {
	["VERSION"] = "0.1",
	["AUTHOR"] = "steino",
	["LICENSE"] = "GPL-3",
	["DESC"] = "Weechat Plugin for Pushover written in Lua.",
	["NAME"] = "pushover"
}

local urlEncode = function(str)
	return str:gsub(
		'([^%w ])',
		function (c)
			return string.format ("%%%02X", string.byte(c))
		end
	):gsub(' ', '+'):gsub('&', '%%26')
end

local createPostData = function(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		table.insert(out, string.format("%s=%s", k, urlEncode(v)))
	end

	return table.concat(out, "&")
end

local pm = {}
local function pushover_send(fields)
	fields.token = 'RTPqqbBizN3tKCUxfmym7bwxkAdhP2'
	fields.user = weechat.config_get_plugin'userkey'

	local postfields = createPostData(fields)
	weechat.hook_process_hashtable("url:https://api.pushover.net/1/messages.json", { post = 1, postfields = postfields}, 30*1000, "", "")
end

function pushover_pm(data, signal, signal_data)
	local throttle = tonumber(weechat.config_get_plugin'throttle') or 1
	local interval = tonumber(weechat.config_get_plugin'throttle_interval') or 1

	local nick, msg = signal_data:match":(.-)%!.-:(.*)"
	if not nick then return end

	if throttle == 1 and pm[nick] and (os.time() < pm[nick]+(interval*60)) then pm[nick] = os.time() return end
	pm[nick] = os.time()

	local fields = {
		title = nick,
		message = weechat.string_remove_color(msg, ""),
	}
	pushover_send(fields)
end

function pushover_highlight(...)
	local _, buffer,_,_,_, highlight, prefix, msg = ...
	if tonumber(highlight) == 1 then
		local network, channel = weechat.buffer_get_string(buffer, "name"):match"(.+)%.(#.*)"
		if not channel then return end

		local prefix = weechat.string_remove_color(prefix, "")
		local fields = {
			title = string.format("%s (%s)", channel, network),
			message = string.format("<%s> %s", prefix, weechat.string_remove_color(msg, ""))
		}
		pushover_send(fields)
	end
end

weechat.register(PO["NAME"], PO["AUTHOR"], PO["VERSION"], PO["LICENSE"], PO["DESC"], "", "")
weechat.hook_print("", "", "", 0, "pushover_highlight", "")
weechat.hook_signal("irc_pv", "pushover_pm", "")
