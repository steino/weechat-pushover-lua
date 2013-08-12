PO = {
	["VERSION"] = "0.1",
	["AUTHOR"] = "steino",
	["LICENSE"] = "GPL-3",
	["DESC"] = "Weechat Plugin for Pushover written in Lua.",
	["NAME"] = "pushover_lua"
}

local pm = {}
local function pushover_send(postfields)
	local token = 'RTPqqbBizN3tKCUxfmym7bwxkAdhP2'
	local user = weechat.config_get_plugin'userkey'
	postfields = postfields .. "&token=%s&user=%s"
	weechat.hook_process_hashtable("url:https://api.pushover.net/1/messages.json", { post = 1, postfields = postfields:format(token, user)}, 30*1000, "", "")
end

function pushover_pm(data, signal, signal_data)
	local throttle = tonumber(weechat.config_get_plugin'throttle') or 1
	local interval = tonumber(weechat.config_get_plugin'throttle_interval') or 1

	local nick, msg = signal_data:match":(.-)%!.-:(.*)"
	if not nick then return end

	local postfields = 'title=%s&message=%s'
	if throttle == 1 and pm[nick] and (os.time() < pm[nick]+(interval*60)) then pm[nick] = os.time() return end
	pm[nick] = os.time()
	pushover_send(postfields:format(nick, msg))
end

function pushover_highlight(...)
	local _, buffer,_,_,_, highlight, prefix, msg = ...
	if tonumber(highlight) == 1 then
		local network, channel = weechat.buffer_get_string(buffer, "name"):match"(.+)%.(#.*)"
		if not channel then return end
		prefix = weechat.string_remove_color(prefix, "")
		msg = weechat.string_remove_color(msg, "")
		local postfields = 'title=%s (%s)&message=<%s> %s'
		pushover_send(postfields:format(channel, network, prefix, msg))
	end
end

weechat.register(PO["NAME"], PO["AUTHOR"], PO["VERSION"], PO["LICENSE"], PO["DESC"], "", "")
weechat.hook_print("", "", "", 0, "pushover_highlight", "")
weechat.hook_signal("irc_pv", "pushover_pm", "")
