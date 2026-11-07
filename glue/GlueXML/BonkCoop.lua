local L = BonkGlueL;

BONK_COOP_ROWS = 14;
BONK_COOP_MEMBERS = 4;
BONK_COOP_DIFFICULTIES = { "Normal", "Heroic", "Mythic" };
BONK_COOP_LIST_EVERY = 3;
BONK_COOP_POLL_EVERY = 1;
BONK_COOP_MYTHIC_START = 9;
BONK_COOP_MODES = { "Levels", "Dungeon", "Invasion" };
BONK_COOP_WORDS = {
	["Normal"] = L["hoa.ui.glue.normal"], ["Heroic"] = L["hoa.ui.glue.heroic"], ["Mythic"] = L["hoa.ui.glue.mythic"],
	["Levels"] = L["hoa.ui.glue.levels"], ["Dungeon"] = L["hoa.ui.glue.dungeon"], ["Invasion"] = L["hoa.ui.glue.invasion"],
};
BONK_COOP_PLACES = {
	["Westfall"] = L["hoa.ui.glue.westfall"], ["Molten Core"] = L["hoa.ui.glue.molten_core"], ["The Barrens"] = L["hoa.ui.glue.the_barrens"],
	["Duskwood"] = L["hoa.ui.glue.duskwood"], ["Zul'Gurub"] = L["hoa.ui.glue.zul_gurub"], ["Ruins of Ahn'Qiraj"] = L["hoa.ui.glue.ruins_of_ahn_qiraj"],
	["Tanaris"] = L["hoa.ui.glue.tanaris"], ["Un'Goro Crater"] = L["hoa.ui.glue.un_goro_crater"], ["Stranglethorn Vale"] = L["hoa.ui.glue.stranglethorn_vale"],
	["Desolace"] = L["hoa.ui.glue.desolace"], ["Badlands"] = L["hoa.ui.glue.badlands"], ["Arathi Highlands"] = L["hoa.ui.glue.arathi_highlands"],
	["Swamp of Sorrows"] = L["hoa.ui.glue.swamp_of_sorrows"], ["Burning Steppes"] = L["hoa.ui.glue.burning_steppes"],
	["Eastern Plaguelands"] = L["hoa.ui.glue.eastern_plaguelands"], ["Western Plaguelands"] = L["hoa.ui.glue.western_plaguelands"],
	["Feralas"] = L["hoa.ui.glue.feralas"], ["Searing Gorge"] = L["hoa.ui.glue.searing_gorge"], ["Felwood"] = L["hoa.ui.glue.felwood"], ["Dun Morogh"] = L["hoa.ui.glue.dun_morogh"],
};
BONK_COOP_NOTES = {
	["The launcher isn't running."] = L["hoa.ui.glue.the_launcher_isn_t_running"],
	["The launcher didn't answer."] = L["hoa.ui.glue.the_launcher_didn_t_answer"],
	["The launcher sent a broken answer."] = L["hoa.ui.glue.the_launcher_sent_an_invalid_response"],
	["Unknown call."] = L["hoa.ui.glue.unknown_call"],
	["Invalid request."] = L["hoa.ui.glue.invalid_request"],
	["Unknown request."] = L["hoa.ui.glue.unknown_request"],
	["Not found."] = L["hoa.ui.glue.not_found"],
	["Co-op isn't available in this build."] = L["hoa.ui.glue.co_op_isn_t_available_in_this_build"],
	["Can't connect to the co-op service. Try again later."] = L["hoa.ui.glue.can_t_connect_to_the_co_op_service_try_again_later"],
	["The co-op service sent an invalid response."] = L["hoa.ui.glue.the_co_op_service_sent_an_invalid_response"],
	["The co-op service refused the request."] = L["hoa.ui.glue.the_co_op_service_refused_the_request"],
	["Hosting only works on a regular account. This account is a game master account."] = L["hoa.ui.glue.game_master_accounts_can_t_host_games"],
	["Joining a co-op game only works on a regular account. This account is a game master account."] = L["hoa.ui.glue.game_master_accounts_can_t_join_co_op_games"],
	["Too many requests."] = L["hoa.ui.glue.too_many_requests"],
	["Too many requests. Try again in a minute."] = L["hoa.ui.glue.too_many_requests_try_again_in_a_minute"],
	["Too many requests. Try again in a few minutes."] = L["hoa.ui.glue.too_many_requests_try_again_in_a_few_minutes"],
	["Too many lobbies created. Try again in a few minutes."] = L["hoa.ui.glue.too_many_lobbies_created_try_again_in_a_few_minutes"],
	["You're already hosting a game."] = L["hoa.ui.glue.you_re_already_hosting_a_game"],
	["No game found with that code."] = L["hoa.ui.glue.no_game_found_with_that_code"],
	["That game has ended."] = L["hoa.ui.glue.that_game_has_ended"],
	["Version mismatch: that game runs a different version of Hordes of Azeroth."] = L["hoa.ui.glue.that_game_runs_a_different_version_of_hordes_of_azeroth"],
	["Incorrect password."] = L["hoa.ui.glue.incorrect_password"],
	["Game is full."] = L["hoa.ui.glue.that_game_is_full"],
	["Every open slot has a pending join request. Try again shortly."] = L["hoa.ui.glue.every_open_slot_has_a_pending_join_request_try_again_shortly"],
	["Party already has that class."] = L["hoa.ui.glue.the_party_already_has_that_class"],
	["You already have a pending join request."] = L["hoa.ui.glue.you_already_have_a_pending_join_request"],
	["Join request expired."] = L["hoa.ui.glue.join_request_expired"],
	["The host didn't respond."] = L["hoa.ui.glue.the_host_didn_t_respond"],
	["The host closed the lobby."] = L["hoa.ui.glue.the_host_closed_the_lobby"],
	["The host couldn't take your character."] = L["hoa.ui.glue.the_host_couldn_t_load_your_character"],
	["Lost connection to the host. Your progress up to the last few seconds is saved."] = L["hoa.ui.glue.lost_connection_to_the_host_your_progress_up_to_the_last_few"],
	["You were removed from the party."] = L["hoa.ui.glue.you_were_removed_from_the_party"],
	["That join has ended."] = L["hoa.ui.glue.your_join_request_has_ended"],
	["Other players can't connect to you: your router blocks automatic port forwarding, or your internet provider shares your address. You can still join other games."] = L["hoa.ui.glue.other_players_can_t_connect_to_you_because_your_router_block"],
	["Your lobby expired. Host again to list it."] = L["hoa.ui.glue.your_lobby_expired_host_again_to_list_it"],
	["The transfer was too large."] = L["hoa.ui.glue.the_transfer_was_too_large"],
	["The connection closed during the transfer."] = L["hoa.ui.glue.the_connection_closed_during_the_transfer"],
	["The game server didn't answer. Is it running?"] = L["hoa.ui.glue.the_game_server_didn_t_answer_is_it_running"],
	["The joining player's account couldn't be created."] = L["hoa.ui.glue.the_joining_player_s_account_couldn_t_be_created"],
	["broken ledger"] = L["hoa.ui.glue.the_account_progress_is_damaged"],
	["The account progress couldn't be loaded."] = L["hoa.ui.glue.the_account_progress_couldn_t_be_loaded"],
	["That character is online."] = L["hoa.ui.glue.that_character_is_online"],
	["That character belongs to another account."] = L["hoa.ui.glue.that_character_belongs_to_another_account"],
	["The old copy of the character couldn't be removed."] = L["hoa.ui.glue.the_old_copy_of_the_character_couldn_t_be_removed"],
};
BONK_COOP_TEXTS = {
	{ "BonkCoopSoloButton", L["hoa.ui.glue.solo"] },
	{ "BonkCoopCoopButton", L["hoa.ui.glue.co_op"] },
	{ "BonkCoopFindButton", L["hoa.ui.glue.browse_games"] },
	{ "BonkCoopHostButton", L["hoa.ui.glue.host_game"] },
	{ "BonkCoopStatusButton", L["hoa.ui.glue.close_lobby"] },
	{ "BonkCoopBrowserTitle", L["hoa.ui.glue.co_op_games"] },
	{ "BonkCoopHeadGame", L["hoa.ui.glue.lobby_game"] },
	{ "BonkCoopHeadClasses", L["hoa.ui.glue.classes"] },
	{ "BonkCoopHeadDifficulty", L["hoa.ui.glue.difficulty"] },
	{ "BonkCoopHeadPlayers", L["hoa.ui.glue.players"] },
	{ "BonkCoopDetailGroup", L["hoa.ui.glue.party"] },
	{ "BonkCoopFilterButton", L["hoa.ui.glue.filters"] },
	{ "BonkCoopHideFullText", L["hoa.ui.glue.hide_full_games"] },
	{ "BonkCoopHideLockedText", L["hoa.ui.glue.hide_password_protected_games"] },
	{ "BonkCoopHideUnfitText", L["hoa.ui.glue.hide_unjoinable_games"] },
	{ "BonkCoopCodeButton", L["hoa.ui.glue.join_with_address"] },
	{ "BonkCoopRefreshButton", L["hoa.ui.glue.refresh"] },
	{ "BonkCoopAskButton", L["hoa.ui.glue.join"] },
	{ "BonkCoopCloseButton", L["hoa.ui.glue.close"] },
	{ "BonkCoopHostTitle", L["hoa.ui.glue.host_game"] },
	{ "BonkCoopNameLabel", L["hoa.ui.glue.game_name"] },
	{ "BonkCoopPrivacyLabel", L["hoa.ui.glue.privacy"] },
	{ "BonkCoopDifficultyLabel", L["hoa.ui.glue.difficulty"] },
	{ "BonkCoopPauseLabel", L["hoa.ui.glue.pause"] },
	{ "BonkCoopXpLabel", L["hoa.ui.glue.xp"] },
	{ "BonkCoopModeLabel", L["hoa.ui.glue.mode"] },
	{ "BonkCoopPlayersLabel", L["hoa.ui.glue.players"] },
	{ "BonkCoopAddressLabel", L["hoa.ui.glue.public_address_optional"] },
	{ "BonkCoopAddressNote", L["hoa.ui.glue.for_zerotier_tailscale_a_tunnel_or_a_forwarded_port_otherwis"] },
	{ "BonkCoopWhoOpenText", L["hoa.ui.glue.public"] },
	{ "BonkCoopWhoPasswordText", L["hoa.ui.glue.password_protected"] },
	{ "BonkCoopWhoCodeText", L["hoa.ui.glue.hidden_code_only"] },
	{ "BonkCoopFloorEditLevel", L["hoa.ui.glue.difficulty_level_level"] },
	{ "BonkCoopAutoCheckText", L["hoa.ui.glue.auto_accept_requests"] },
	{ "BonkCoopSameClassCheckText", L["hoa.ui.glue.allow_duplicate_classes"] },
	{ "BonkCoopNewCheckText", L["hoa.ui.glue.only_allow_mastery"] },
	{ "BonkCoopMasteryEditSuffix", L["hoa.ui.glue.after_the_number_or_lower"] },
	{ "BonkCoopMinCheckText", L["hoa.ui.glue.require_mythic"] },
	{ "BonkCoopMinEditSuffix", L["hoa.ui.glue.after_the_number_cleared"] },
	{ "BonkCoopHostGoButton", L["hoa.ui.glue.verb_host"] },
	{ "BonkCoopHostCancelButton", L["hoa.ui.glue.cancel"] },
	{ "BonkCoopRequest1Accept", L["hoa.ui.glue.accept"] },
	{ "BonkCoopRequest1Decline", L["hoa.ui.glue.decline"] },
	{ "BonkCoopRequest2Accept", L["hoa.ui.glue.accept"] },
	{ "BonkCoopRequest2Decline", L["hoa.ui.glue.decline"] },
	{ "BonkCoopRequest3Accept", L["hoa.ui.glue.accept"] },
	{ "BonkCoopRequest3Decline", L["hoa.ui.glue.decline"] },
};
BONK_COOP_AWAY_WAIT = 30;
BONK_COOP_RECONNECT_DELAY = 1;
BONK_COOP_REJOIN_TRIES = 2;
BONK_COOP_REJOIN_SECONDS = 110;
BONK_COOP_REJOIN_LONGEST_WAIT = 10;
BONK_COOP_POLL_FAILURES = 10;
BONK_COOP_ENTER_DELAY = 1;
BONK_COOP_NO_ANSWER = "The launcher didn't answer.";

BonkCoop = {
	mode = nil,
	lobbies = {},
	shown = {},
	selected = nil,
	offset = 0,
	listTimer = 0,
	pollTimer = 0,
	host = nil,
	requests = {},
	answered = {},
	joining = nil,
	popup = nil,
	popupData = nil,
	who = 1,
	difficulty = 1,
	players = 4,
	pause = 1,
	xp = 1,
	runMode = 1,
	listError = nil,
	calls = {},
};

function BonkCoop_Encode(text)
	text = string.gsub(text or "", "([^%w%-%_%.%~ ])", function(c) return format("%%%02X", string.byte(c)); end);
	return string.gsub(text, " ", "+");
end

function BonkCoop_Form(fields)
	local parts = {};
	for key, value in fields do
		table.insert(parts, key.."="..BonkCoop_Encode(tostring(value)));
	end
	return table.concat(parts, "&");
end

function BonkCoop_Split(text, separator)
	local fields = {};
	local start = 1;
	while ( true ) do
		local found = string.find(text, separator, start, true);
		if ( not found ) then
			table.insert(fields, string.sub(text, start));
			return fields;
		end
		table.insert(fields, string.sub(text, start, found - 1));
		start = found + 1;
	end
end

function BonkCoop_ApplyLanguage()
	for _, entry in BONK_COOP_TEXTS do
		getglobal(entry[1]):SetText(entry[2]);
	end
end

function BonkCoop_Word(word)
	return BONK_COOP_WORDS[word] or word;
end

function BonkCoop_Words(words)
	local labels = {};
	for index = 1, table.getn(words) do
		labels[index] = BonkCoop_Word(words[index]);
	end
	return labels;
end

function BonkCoop_LevelPart(part)
	local _, _, kind, number = string.find(part, "^(%a+) (%d+)$");
	number = number and tonumber(number);
	if ( kind == "Normal" and number and number >= 1 and number <= 4 ) then
		return BonkLevelName(number);
	elseif ( kind == "Heroic" and number and number >= 1 and number <= 5 ) then
		return BonkLevelName(number + 4);
	elseif ( kind == "Mythic" and number and number >= 1 ) then
		return BonkLevelName(number + BONK_COOP_MYTHIC_START);
	end
	return BONK_COOP_WORDS[part] or BONK_COOP_PLACES[part] or part;
end

function BonkCoop_Level(text)
	if ( not text or text == "" ) then
		return text;
	end
	local result = "";
	local start = 1;
	while ( true ) do
		local found, last = string.find(text, " · ", start, true);
		result = result..BonkCoop_LevelPart(string.sub(text, start, found and found - 1 or -1));
		if ( not found ) then
			return result;
		end
		result = result.." · ";
		start = last + 1;
	end
end

function BonkCoop_AddTag(tags, tag)
	return tags.." · "..tag;
end

function BonkCoop_Note(text)
	if ( type(text) ~= "string" ) then
		return text;
	end
	if ( BONK_COOP_NOTES[text] ) then
		return BONK_COOP_NOTES[text];
	end
	local _, _, value = string.find(text, "^Requires Mythic (%d+) cleared%.$");
	if ( value ) then
		return L("hoa.ui.glue.requires_mythic_1_cleared_2", value);
	end
	_, _, value = string.find(text, "^Requires Mastery (%d+) or lower%.$");
	if ( value ) then
		return L("hoa.ui.glue.requires_mastery_1_or_lower", value);
	end
	_, _, value = string.find(text, "^The host declined your request%. You can ask again in (%d+) seconds%.$");
	if ( value ) then
		return L("hoa.ui.glue.the_host_declined_your_request_you_can_ask_again_in_1_second", value);
	end
	_, _, value = string.find(text, "^Port (%d+) is already in use, so you can't host%.$");
	if ( value ) then
		return L("hoa.ui.glue.port_1_is_already_in_use_so_you_can_t_host", value);
	end
	_, _, value = string.find(text, "^There is no account called (.*)%.$");
	if ( value ) then
		return L("hoa.ui.glue.there_is_no_account_called_1", value);
	end
	_, _, value = string.find(text, "^There is no character called (.*)%.$");
	if ( value ) then
		return L("hoa.ui.glue.there_is_no_character_called_1", value);
	end
	_, _, value = string.find(text, "^No free name for (.*)%.$");
	if ( value ) then
		return L("hoa.ui.glue.couldn_t_find_a_free_name_for_1", value);
	end
	_, _, value = string.find(text, "^The character couldn't be loaded %((%d+)%)%.$");
	if ( value ) then
		return L("hoa.ui.glue.the_character_couldn_t_be_loaded_1", value);
	end
	_, _, value = string.find(text, "^Database error: (.*)$");
	if ( value ) then
		return L("hoa.ui.glue.database_error_1", value);
	end
	return text;
end

function BonkCoop_Call(method, path, fields)
	if ( not HoaCoop_Call ) then
		return nil, L["hoa.ui.glue.this_client_doesn_t_support_co_op"];
	end
	return BonkCoop_ParseAnswer(HoaCoop_Call(method, path, fields and BonkCoop_Form(fields) or ""));
end

function BonkCoop_ParseAnswer(answer, problem)
	if ( not answer ) then
		return nil, problem;
	end
	local lines = {};
	for _, line in BonkCoop_Split(answer, "\n") do
		if ( line ~= "" ) then
			table.insert(lines, BonkCoop_Split(line, "\t"));
		end
	end
	return lines;
end

function BonkCoop_CallLater(method, path, fields, key, done)
	if ( not HoaCoop_Start ) then
		done(nil, L["hoa.ui.glue.this_client_doesn_t_support_co_op"]);
		return;
	end
	if ( BonkCoop.calls[key] ) then
		return;
	end
	BonkCoop.calls[key] = { id = HoaCoop_Start(method, path, fields and BonkCoop_Form(fields) or ""), done = done };
end

function BonkCoop_CollectAnswers()
	for key, call in BonkCoop.calls do
		local waiting, answer, problem = HoaCoop_Take(call.id);
		if ( not waiting ) then
			BonkCoop.calls[key] = nil;
			call.done(BonkCoop_ParseAnswer(answer, problem));
			return;
		end
	end
end

function BonkCoop_Who()
	return BonkCoop_OwnAccount();
end

function BonkCoop_OwnAccount()
	return HOA_LOGIN_ACCOUNT or BONK_ACCOUNT or "";
end

function BonkCoop_ClassName(token)
	for _, class in BONK_CLASSES do
		if ( class.token == strupper(token or "") ) then
			return class.display;
		end
	end
	return token or "";
end

function BonkCoop_SetClassIcon(texture, token)
	local coords = CLASS_ICON_TCOORDS[strupper(token or "")];
	if ( coords ) then
		texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		texture:Show();
	else
		texture:Hide();
	end
end

function BonkCoop_Hero()
	local class = BonkHero_SelectedClass();
	local hero = BonkHero_Selected();
	if ( not hero ) then
		return nil;
	end
	local stats = BONK_STATS and BONK_STATS.heroes and BONK_STATS.heroes[hero.name] or {};
	return { name = hero.name, class = class.token, className = class.display, race = hero.race, mastery = stats.mastery or 0, best = stats.bestLevel or 0, ironman = stats.ironman, hardcore = stats.hardcore };
end

function BonkCoop_IsJoined()
	return HoaCoop_GetGate and HoaCoop_GetGate() ~= nil;
end

function BonkCoop_IsHosting()
	return BonkCoop.host and (BonkCoop.host.state == "hosting" or BonkCoop.host.state == "starting");
end

function BonkCoop_SetMode(on)
	BonkCoop.mode = on;
	BonkCoop_Apply();
end

function BonkCoop_Apply()
	if ( not BonkHeroFrame:IsVisible() ) then
		return;
	end
	local joined = BonkCoop_IsJoined();
	if ( joined ) then
		BonkCoop.mode = 1;
	end
	if ( Bonk.customizing ) then
		BonkCoopModeFrame:Hide();
		BonkCoopBar:Hide();
		BonkCoopStatus:Hide();
		BonkCoop_HideRoom();
		if ( BonkCoopRoomButton ) then
			BonkCoopRoomButton:Hide();
		end
		BonkHeroPlayButton:Show();
		return;
	end
	BonkCoopModeFrame:Show();
	if ( BonkCoop.mode ) then
		BonkCoopSoloButton:UnlockHighlight();
		BonkCoopCoopButton:LockHighlight();
	else
		BonkCoopCoopButton:UnlockHighlight();
		BonkCoopSoloButton:LockHighlight();
	end
	if ( joined ) then
		BonkCoopModeFrame:Hide();
		BonkCoopBar:Hide();
		BonkHeroPlayButton:Show();
		BonkHeroWipeButton:Hide();
		BonkCoopStatusText:SetText(L["hoa.ui.glue.you_re_in_a_co_op_party"]);
		BonkCoopStatusButton:SetText(L["hoa.ui.glue.leave_party"]);
		if ( BonkCoopRoomButton ) then
			BonkCoopRoomButton:Hide();
		end
		BonkCoop_HideRoom();
		BonkCoopStatus:Show();
		return;
	end
	if ( BonkCoop_IsHosting() ) then
		BonkCoopBar:Hide();
		BonkHeroPlayButton:Show();
		BonkCoopStatusText:SetText(BonkCoop_HostLine());
		BonkCoopStatusButton:SetText(L["hoa.ui.glue.close_lobby"]);
		if ( BonkCoopRoomButton ) then
			BonkCoopRoomButton:SetText(L["hoa.ui.glue.host_game"]);
			BonkCoopRoomButton:Show();
		end
		BonkCoop_UpdateRoom();
		BonkCoopStatus:Show();
		return;
	end
	BonkCoopStatus:Hide();
	if ( BonkCoopRoomButton ) then
		BonkCoopRoomButton:Hide();
	end
	BonkCoop_HideRoom();
	if ( BonkCoop.mode ) then
		local hero = BonkCoop_Hero();
		BonkHeroPlayButton:Hide();
		BonkCoopBar:Show();
		if ( hero ) then
			BonkCoopBarText:SetText(L("hoa.ui.glue.joins_as_1", hero.name));
			BonkCoopFindButton:Enable();
			BonkCoopHostButton:Enable();
		else
			BonkCoopBarText:SetText(L("hoa.ui.glue.create_a_1_first", BonkHero_SelectedClass().display));
			BonkCoopFindButton:Disable();
			BonkCoopHostButton:Disable();
		end
	else
		BonkCoopBar:Hide();
		BonkHeroPlayButton:Show();
	end
end

function BonkCoop_HostLine()
	local host = BonkCoop.host;
	if ( host.state == "starting" ) then
		return L["hoa.ui.glue.opening_lobby"];
	end
	return L("hoa.ui.glue.host_1_2_3_players_address_4", host.name or "", table.getn(host.members or {}), host.max or "4", host.address or "");
end

BONK_COOP_ROOM_MEMBERS = 4;

function BonkCoop_RoomFrame()
	if ( BonkCoop.room ) then
		return BonkCoop.room;
	end
	local room = CreateFrame("Frame", "BonkCoopRoom", BonkHeroFrame, "BonkCoopPanelTemplate");
	room:SetWidth(560);
	room:SetHeight(430);
	room:SetPoint("CENTER", BonkHeroFrame, "CENTER", 0, -10);
	room:Hide();

	room.title = room:CreateFontString("BonkCoopRoomTitle", "ARTWORK", "GlueFontNormalLarge");
	room.title:SetPoint("TOP", room, "TOP", 0, -16);
	room.title:SetTextColor(1, 0.82, 0);
	room.title:SetText(L["hoa.ui.glue.host_game"]);

	room.name = room:CreateFontString("BonkCoopRoomName", "ARTWORK", "GlueFontNormalSmall");
	room.name:SetPoint("TOP", room.title, "BOTTOM", 0, -4);
	room.name:SetTextColor(0.75, 0.72, 0.66);

	room.info = room:CreateFontString("BonkCoopRoomInfo", "ARTWORK", "GlueFontNormal");
	room.info:SetPoint("TOPLEFT", room, "TOPLEFT", 24, -74);
	room.info:SetWidth(512);
	room.info:SetJustifyH("LEFT");
	room.info:SetTextColor(1, 0.82, 0);

	room.address = room:CreateFontString("BonkCoopRoomAddress", "ARTWORK", "GlueFontNormal");
	room.address:SetPoint("TOPLEFT", room.info, "BOTTOMLEFT", 0, -8);
	room.address:SetWidth(512);
	room.address:SetJustifyH("LEFT");
	room.address:SetTextColor(1, 1, 1);

	room.membersLabel = room:CreateFontString("BonkCoopRoomMembersLabel", "ARTWORK", "GlueFontNormalSmall");
	room.membersLabel:SetPoint("TOPLEFT", room.address, "BOTTOMLEFT", 0, -14);
	room.membersLabel:SetTextColor(0.62, 0.6, 0.55);
	room.membersLabel:SetText(L["hoa.ui.glue.players"]);

	room.members = {};
	for index = 1, BONK_COOP_ROOM_MEMBERS do
		local row = CreateFrame("Frame", "BonkCoopRoomMember"..index, room, "BonkCoopMemberTemplate");
		row:SetPoint("TOPLEFT", room, "TOPLEFT", 24, -(138 + (index - 1) * 36));
		row:Hide();
		room.members[index] = row;
	end

	room.close = CreateFrame("Button", nil, room, "GlueButtonSmallTemplate");
	room.close:SetWidth(120);
	room.close:SetHeight(24);
	room.close:SetPoint("BOTTOMLEFT", room, "BOTTOMLEFT", 24, 20);
	room.close:SetText(L["hoa.ui.glue.close"]);
	room.close:SetScript("OnClick", function()
		room:Hide();
	end);

	room.stop = CreateFrame("Button", nil, room, "GlueButtonSmallTemplate");
	room.stop:SetWidth(150);
	room.stop:SetHeight(24);
	room.stop:SetPoint("BOTTOMRIGHT", room, "BOTTOMRIGHT", -24, 20);
	room.stop:SetText(L["hoa.ui.glue.close_lobby"]);
	room.stop:SetScript("OnClick", function()
		BonkCoop_StatusButton();
		room:Hide();
	end);

	BonkCoop.room = room;
	return room;
end

function BonkCoop_UpdateRoom()
	local room = BonkCoop_RoomFrame();
	local host = BonkCoop.host;
	if ( not host or (host.state ~= "hosting" and host.state ~= "starting") ) then
		room:Hide();
		BonkCoop.roomShown = nil;
		return;
	end

	local members = host.members or {};
	local count = table.getn(members);
	local max = tonumber(host.max) or 4;
	room.name:SetText(host.name or "");
	room.info:SetText(L["hoa.ui.glue.players"]..": "..count.."/"..max.."  ·  "..(host.difficulty or ""));
	room.address:SetText(host.address or L["hoa.ui.glue.opening_lobby"]);

	for index = 1, BONK_COOP_ROOM_MEMBERS do
		local row = room.members[index];
		local member = members[index];
		local name = row:GetName();
		if ( member ) then
			getglobal(name.."Name"):SetText(member.name or "");
			getglobal(name.."Sub"):SetText(L("hoa.ui.glue.mastery_1_2", member.mastery or 0, BonkCoop_ClassName(member.class)));
			BonkCoop_SetClassIcon(getglobal(name.."Icon"), member.class);
			row:Show();
		else
			row:Hide();
		end
	end

	if ( host.state == "hosting" and not BonkCoop.roomShown ) then
		BonkCoop.roomShown = 1;
		room:Show();
	end
end

function BonkCoop_ShowRoom()
	local room = BonkCoop_RoomFrame();
	if ( not BonkCoop.host or (BonkCoop.host.state ~= "hosting" and BonkCoop.host.state ~= "starting") ) then
		return;
	end
	BonkCoop_UpdateRoom();
	room:Show();
end

function BonkCoop_HideRoom()
	if ( BonkCoop.room ) then
		BonkCoop.room:Hide();
	end
	BonkCoop.roomShown = nil;
end

local OriginalUpdateControls = BonkHero_UpdateControls;
function BonkHero_UpdateControls()
	OriginalUpdateControls();
	BonkCoop_Apply();
end

function BonkCoop_OpenBrowser()
	if ( BonkCoopBrowser:IsShown() ) then
		BonkCoopBrowser:Hide();
		return;
	end
	BonkCoopHostForm:Hide();
	BonkCoopBrowser:Show();
end

function BonkCoop_RefreshList()
	BonkCoop.listTimer = 0;
	BonkCoop.lobbies = {};
	BonkCoop.loading = nil;
	BonkCoop.listError = L["hoa.ui.glue.the_public_game_list_is_gone_ask_the_host_for_their_address"];
	BonkCoop_UpdateList();
end

function BonkCoop_ShowLobbies(lines, problem)
	if ( not lines ) then
		BonkCoop.listError = problem;
		BonkCoop.lobbies = {};
		BonkCoop_UpdateList();
		return;
	end
	BonkCoop.listError = nil;
	BonkCoop.loading = nil;
	local lobbies = {};
	for _, fields in lines do
		if ( fields[1] == "lobby" ) then
			table.insert(lobbies, {
				id = fields[2], name = fields[3], host = fields[4], hostClass = fields[5],
				classes = fields[6] ~= "" and BonkCoop_Split(fields[6], ",") or {},
				difficulty = fields[7], players = tonumber(fields[8]) or 1, max = tonumber(fields[9]) or 4,
				locked = fields[10] == "1", masteryLimit = tonumber(fields[11]) or 0, members = BonkCoop_ParseMembers(fields[12]),
				sameClass = fields[13] == "1", minMythic = tonumber(fields[14]) or 0,
				pause = fields[15] ~= "0", xp = fields[16] ~= "0", playing = fields[17] or "", lan = fields[18] == "1",
			});
		elseif ( fields[1] == "error" ) then
			BonkCoop.listError = fields[2];
		elseif ( fields[1] == "loading" ) then
			BonkCoop.loading = 1;
		end
	end
	BonkCoop.lobbies = lobbies;
	BonkCoop_UpdateList();
end

function BonkCoop_ParseMembers(text)
	local members = {};
	if ( not text or text == "" ) then
		return members;
	end
	for _, entry in BonkCoop_Split(text, ";") do
		local parts = BonkCoop_Split(entry, ":");
		table.insert(members, { name = parts[1], class = parts[2], mastery = tonumber(parts[3]) or 0 });
	end
	return members;
end

function BonkCoop_Matches(lobby)
	if ( BonkCoopHideFull:GetChecked() and lobby.players >= lobby.max ) then
		return nil;
	end
	if ( BonkCoopHideLocked:GetChecked() and lobby.locked ) then
		return nil;
	end
	if ( BonkCoopHideUnfit:GetChecked() and not BonkCoop_Fit(lobby, BonkCoop_Hero()) ) then
		return nil;
	end
	local search = strlower(BonkCoopSearch:GetText() or "");
	if ( search ~= "" and not string.find(strlower(lobby.name), search, 1, true) and not string.find(strlower(lobby.host), search, 1, true) ) then
		return nil;
	end
	return 1;
end

function BonkCoop_ToggleFilters()
	if ( BonkCoopFilterMenu:IsShown() ) then
		BonkCoopFilterMenu:Hide();
	else
		BonkCoopFilterMenu:Show();
	end
end

function BonkCoop_UpdateFilterButton()
	local active = 0;
	for _, check in { BonkCoopHideFull, BonkCoopHideLocked, BonkCoopHideUnfit } do
		if ( check:GetChecked() ) then
			active = active + 1;
		end
	end
	BonkCoopFilterButton:SetText(active > 0 and L("hoa.ui.glue.filters_1", active) or L["hoa.ui.glue.filters"]);
end

function BonkCoop_UpdateList()
	BonkCoop_UpdateFilterButton();
	local shown = {};
	for _, lobby in BonkCoop.lobbies do
		if ( BonkCoop_Matches(lobby) ) then
			table.insert(shown, lobby);
		end
	end
	BonkCoop.shown = shown;
	local count = table.getn(shown);
	BonkCoop.offset = math.max(0, math.min(BonkCoop.offset, count - BONK_COOP_ROWS));
	for index = 1, BONK_COOP_ROWS do
		local row = getglobal("BonkCoopRow"..index);
		local lobby = shown[index + BonkCoop.offset];
		if ( lobby ) then
			local name = row:GetName();
			getglobal(name.."Name"):SetText(lobby.name);
			BonkCoop_PlaceLanBadge(name, lobby.lan);
			getglobal(name.."Difficulty"):SetText(BonkCoop_Level(lobby.playing ~= "" and lobby.playing or lobby.difficulty));
			getglobal(name.."Players"):SetText(lobby.players.."/"..lobby.max);
			if ( lobby.locked ) then
				getglobal(name.."Lock"):Show();
			else
				getglobal(name.."Lock"):Hide();
			end
			for slot = 1, 4 do
				BonkCoop_SetClassIcon(getglobal(name.."Class"..slot), lobby.classes[slot]);
			end
			if ( lobby.id == BonkCoop.selected ) then
				getglobal(name.."Selected"):Show();
			else
				getglobal(name.."Selected"):Hide();
			end
			row:Show();
		else
			row:Hide();
		end
	end
	if ( BonkCoop.listError ) then
		BonkCoopListNote:SetText("|cffff4040"..BonkCoop_Note(BonkCoop.listError).."|r");
	elseif ( BonkCoop.loading and count == 0 ) then
		BonkCoopListNote:SetText(L["hoa.ui.glue.searching_for_games"]);
	elseif ( count == 0 and table.getn(BonkCoop.lobbies) > 0 ) then
		BonkCoopListNote:SetText(L("hoa.ui.glue.no_games_match_your_filters_1_hidden", table.getn(BonkCoop.lobbies)));
	elseif ( count == 0 ) then
		BonkCoopListNote:SetText(L["hoa.ui.glue.no_games_found_host_your_own_or_join_a_friend_with_their_cod"]);
	else
		BonkCoopListNote:SetText(L("hoa.ui.glue.games_1_2_hidden_by_filters", count, table.getn(BonkCoop.lobbies) - count));
	end
	BonkCoop_UpdateDetails();
end

function BonkCoop_PlaceLanBadge(rowName, lan)
	local badge = getglobal(rowName.."Lan");
	if ( not lan ) then
		badge:Hide();
		return;
	end
	local label = getglobal(rowName.."Name");
	badge:SetText(L["hoa.ui.glue.lobby_badge_lan"]);
	badge:ClearAllPoints();
	badge:SetPoint("LEFT", label, "LEFT", math.min(label:GetStringWidth(), 196) + 6, 0);
	badge:Show();
end

function BonkCoop_Scroll(delta)
	BonkCoop.offset = BonkCoop.offset - delta;
	BonkCoop_UpdateList();
end

function BonkCoop_SelectRow(index)
	local lobby = BonkCoop.shown[index + BonkCoop.offset];
	BonkCoop.selected = lobby and lobby.id;
	BonkCoop_UpdateList();
end

function BonkCoop_Selected()
	for _, lobby in BonkCoop.lobbies do
		if ( lobby.id == BonkCoop.selected ) then
			return lobby;
		end
	end
	return nil;
end

function BonkCoop_Fit(lobby, hero)
	if ( not hero ) then
		return nil, L["hoa.ui.glue.select_a_character_first"];
	end
	if ( hero.hardcore ) then
		return nil, L["hoa.ui.glue.hardcore_characters_can_t_play_co_op_yet"];
	end
	if ( lobby.players >= lobby.max ) then
		return nil, L["hoa.ui.glue.that_game_is_full"];
	end
	for _, class in lobby.classes do
		if ( strupper(class) == hero.class and not lobby.sameClass ) then
			return nil, L("hoa.ui.glue.the_party_already_has_a_1", hero.className);
		end
	end
	if ( lobby.minMythic > 0 and hero.best < BONK_COOP_MYTHIC_START + lobby.minMythic ) then
		return nil, L("hoa.ui.glue.requires_mythic_1_cleared_2", lobby.minMythic);
	end
	if ( lobby.masteryLimit > 0 and hero.mastery > lobby.masteryLimit ) then
		return nil, L("hoa.ui.glue.requires_mastery_1_or_lower", lobby.masteryLimit);
	end
	return 1, L("hoa.ui.glue.you_ll_join_as_1_mastery_2_3", hero.name, hero.mastery, hero.className);
end

function BonkCoop_UpdateDetails()
	local lobby = BonkCoop_Selected();
	if ( not lobby ) then
		BonkCoopDetailName:SetText("");
		BonkCoopDetailSub:SetText(L["hoa.ui.glue.select_a_game_to_see_the_party"]);
		BonkCoopDetailTags:SetText("");
		BonkCoopDetailGroup:Hide();
		BonkCoopDetailFit:SetText("");
		for slot = 1, BONK_COOP_MEMBERS do
			getglobal("BonkCoopMember"..slot):Hide();
		end
		BonkCoopAskButton:Disable();
		return;
	end
	BonkCoopDetailName:SetText(lobby.name);
	local access = lobby.locked and L["hoa.ui.glue.lobby_password"] or L["hoa.ui.glue.public"];
	if ( lobby.lan ) then
		access = L("hoa.ui.glue.1_your_network_only", access);
	end
	BonkCoopDetailSub:SetText(L("hoa.ui.glue.host_1_2", lobby.host, access));
	local tags = BonkCoop_Level(lobby.difficulty);
	if ( lobby.masteryLimit > 0 ) then
		tags = BonkCoop_AddTag(tags, L("hoa.ui.glue.mastery_1_or_lower_only", lobby.masteryLimit));
	end
	if ( lobby.minMythic > 0 ) then
		tags = BonkCoop_AddTag(tags, L("hoa.ui.glue.requires_mythic_1_cleared", lobby.minMythic));
	end
	if ( lobby.sameClass ) then
		tags = BonkCoop_AddTag(tags, L["hoa.ui.glue.duplicate_classes_allowed"]);
	end
	if ( lobby.playing ~= "" ) then
		local playing = L("hoa.ui.glue.playing_now_1", BonkCoop_Level(lobby.playing));
		tags = tags.."\n"..playing;
	end
	tags = tags.."\n"..BonkCoop_SettingsText(lobby.pause, lobby.xp);
	BonkCoopDetailTags:SetText(tags);
	BonkCoopDetailGroup:Show();
	for slot = 1, BONK_COOP_MEMBERS do
		local frame = getglobal("BonkCoopMember"..slot);
		local member = lobby.members[slot];
		local name = frame:GetName();
		if ( slot <= lobby.max ) then
			if ( member ) then
				getglobal(name.."Icon"):SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes");
				BonkCoop_SetClassIcon(getglobal(name.."Icon"), member.class);
				getglobal(name.."Name"):SetText(member.name);
				getglobal(name.."Sub"):SetText(L("hoa.ui.glue.mastery_1_2", member.mastery, BonkCoop_ClassName(member.class)));
			else
				getglobal(name.."Icon"):SetTexture(1, 1, 1, 0.08);
				getglobal(name.."Icon"):SetTexCoord(0, 1, 0, 1);
				getglobal(name.."Icon"):Show();
				getglobal(name.."Name"):SetText(L["hoa.ui.glue.cff808080empty_slot_r"]);
				getglobal(name.."Sub"):SetText("");
			end
			frame:Show();
		else
			frame:Hide();
		end
	end
	local fits, text = BonkCoop_Fit(lobby, BonkCoop_Hero());
	if ( fits ) then
		BonkCoopDetailFit:SetText("|cff20ff20"..text.."|r");
		BonkCoopAskButton:Enable();
	else
		BonkCoopDetailFit:SetText("|cffff4040"..text.."|r");
		BonkCoopAskButton:Disable();
	end
end

function BonkCoop_AskSelected()
	local lobby = BonkCoop_Selected();
	if ( not lobby or not BonkCoop_Fit(lobby, BonkCoop_Hero()) ) then
		return;
	end
	if ( lobby.locked ) then
		BonkCoop_ShowPopup("password", L("hoa.ui.glue.enter_the_password_for_1", lobby.name), nil, L["hoa.ui.glue.join"], L["hoa.ui.glue.cancel"], { lobby = lobby });
		return;
	end
	BonkCoop_Ask({ id = lobby.id }, lobby.host);
end

function BonkCoop_ShowCodeDialog()
	BonkCoop_ShowPopup("address", L["hoa.ui.glue.enter_the_host_s_address"], nil, L["hoa.ui.glue.join"], L["hoa.ui.glue.cancel"], {});
end

function BonkCoop_Ask(target, hostName)
	local hero = BonkCoop_Hero();
	if ( not hero ) then
		return;
	end
	if ( hero.hardcore ) then
		BonkHero_SetStatus(L["hoa.ui.glue.hardcore_characters_can_t_play_co_op_yet"]);
		return;
	end
	target.name = hero.name;
	target.class = strlower(hero.class);
	target.race = hero.race;
	target.mastery = hero.mastery;
	target.best = hero.best;
	target.account = BonkCoop_OwnAccount();
	local lines, problem = BonkCoop_Call("POST", "/ask?who="..BonkCoop_Encode(BonkCoop_Who()), target);
	if ( not lines and problem ~= BONK_COOP_NO_ANSWER ) then
		BonkCoop_ShowMessage(problem);
		return;
	end
	BonkCoop.joining = { host = hostName, started = GetTime() };
	BonkCoop_ReadJoin(lines or { { "state", "asking" } });
end

function BonkCoop_ReadJoin(lines)
	local fields = lines[1] or {};
	local state = fields[2];
	if ( state == "asking" ) then
		if ( BonkCoop.popup ~= "asking" ) then
			BonkCoop_ShowPopup("asking", L["hoa.ui.glue.sending_your_join_request"], nil, nil, L["hoa.ui.glue.cancel"], nil);
		end
	elseif ( state == "waiting" ) then
		local joining = BonkCoop.joining or { started = GetTime() };
		BonkCoop.joining = joining;
		joining.seconds = tonumber(fields[4]) or 30;
		local who = joining.host and ("|cffffd100"..joining.host.."|r") or L["hoa.ui.glue.the_host"];
		BonkCoop_ShowPopup("waiting", L("hoa.ui.glue.waiting_for_1_to_accept", who), "\""..(fields[3] or "").."\"", nil, L["hoa.ui.glue.cancel"], nil);
	elseif ( state == "transferring" ) then
		if ( BonkCoop.popup ~= "transferring" ) then
			local hero = BonkCoop_Hero();
			BonkCoop_ShowPopup("transferring", L("hoa.ui.glue.the_host_accepted_joining_with_1", hero and hero.name or L["hoa.ui.glue.your_character"]), nil, nil, L["hoa.ui.glue.cancel"], nil);
		end
	elseif ( state == "accepted" ) then
		BonkCoop.joining = nil;
		BonkCoop_ShowPopup("message", L["hoa.ui.glue.connecting_to_host"], nil, nil, nil, nil);
		BonkCoop_Switch(fields[3], fields[4], fields[5], fields[6], fields[7]);
	elseif ( state == "declined" ) then
		BonkCoop.joining = nil;
		local reason = fields[3];
		BonkCoop_ShowMessage((reason and reason ~= "") and reason or L["hoa.ui.glue.the_host_declined_your_join_request"]);
	elseif ( state == "joined" ) then
		BonkCoop.joining = nil;
	elseif ( state == "error" or state == "ended" ) then
		BonkCoop.joining = nil;
		BonkCoop_ShowMessage(fields[3] or L["hoa.ui.glue.join_request_cancelled"]);
	end
end

function BonkCoop_Switch(address, token, user, password, character)
	BonkCoop_Call("POST", "/join/done?who="..BonkCoop_Encode(BonkCoop_Who()));
	BonkCoopBrowser:Hide();
	HoaCoop_SetGate(address, token, user, password, character);
	BonkCoop_Reconnect();
end

function BonkCoop_Reconnect(delay)
	Bonk.loginTried = true;
	Bonk.listLoaded = false;
	Bonk.reuseList = false;
	BonkCoop.reconnectAt = GetTime() + (delay or BONK_COOP_RECONNECT_DELAY);
	BonkCoop.checkedEnter = nil;
	BonkCoop.enterAt = nil;
	DisconnectFromServer();
end

function BonkCoop_SelectJoinedHero()
	if ( not Bonk.listLoaded or BonkHero_Selected() ) then
		return;
	end
	local hero = Bonk.heroes[1];
	if ( hero ) then
		BonkHero_ShowHero(hero);
		BonkHero_Refresh();
	end
end

function BonkCoop_EnterIfRejoining(hero)
	local lines = BonkCoop_Call("GET", "/join?who="..BonkCoop_Encode(BonkCoop_Who()));
	local fields = lines and lines[1] or {};
	if ( fields[2] ~= "joined" or fields[7] ~= "1" ) then
		return;
	end
	BonkCoop_Call("POST", "/join/entered?who="..BonkCoop_Encode(BonkCoop_Who()));
	BonkHero_EnterWorld(hero);
end

function BonkCoop_LostHost()
	GlueDialog:Hide();
	local lines = BonkCoop_Call("POST", "/join/rejoin?who="..BonkCoop_Encode(BonkCoop_Who()));
	local fields = lines and lines[1] or {};
	local tries = tonumber(fields[3]) or 0;
	local seconds = tonumber(fields[4]) or BONK_COOP_REJOIN_SECONDS + 1;
	if ( fields[2] ~= "rejoin" or seconds > BONK_COOP_REJOIN_SECONDS ) then
		BonkLoginStatus:SetText(L["hoa.ui.glue.can_t_reach_the_host_returning_to_your_own_game"]);
		BonkCoop_Leave();
		return;
	end
	BonkLoginStatus:SetText(L["hoa.ui.glue.connection_to_host_lost_reconnecting"]);
	BonkCoop_Reconnect(math.min(BONK_COOP_REJOIN_LONGEST_WAIT, tries * 2));
end

function BonkCoop_RefusalNote(shown)
	if ( shown == CHAR_LOGIN_DISABLED ) then
		return L["hoa.ui.glue.you_were_removed_from_the_party"];
	elseif ( shown == CHAR_LOGIN_DUPLICATE_CHARACTER ) then
		return L["hoa.ui.glue.your_party_already_has_this_class_join_with_a_character_of_a"];
	elseif ( shown == CHAR_LOGIN_NO_INSTANCES ) then
		return L["hoa.ui.glue.that_party_is_full"];
	elseif ( shown == CHAR_LOGIN_FAILED ) then
		return L["hoa.ui.glue.couldn_t_join_the_host_s_game"];
	end
	return nil;
end

function BonkCoop_RefusedAtLogin(note)
	BonkCoop.refusalNote = note;
	BonkCoop.leaving = 1;
	BonkCoop_ReadLeave(BonkCoop_Call("POST", "/join/leave?who="..BonkCoop_Encode(BonkCoop_Who())));
end

function BonkCoop_Leave()
	BonkCoop.leaving = 1;
	BonkCoop_ShowPopup("message", L["hoa.ui.glue.leaving_party"], nil, nil, nil, nil);
	BonkCoop_ReadLeave(BonkCoop_Call("POST", "/join/leave?who="..BonkCoop_Encode(BonkCoop_Who())));
end

function BonkCoop_ReadLeave(lines)
	local fields = lines and lines[1] or { "state", "home", "" };
	if ( fields[2] ~= "home" and fields[2] ~= "none" ) then
		return;
	end
	BonkCoop.leaving = nil;
	BonkCoop.homeNote = fields[3] ~= "" and fields[3] or BonkCoop.refusalNote;
	BonkCoop.refusalNote = nil;
	HoaCoop_SetGate(nil);
	BonkCoop.mode = 1;
	BonkCoop_Reconnect();
end

function BonkCoop_ShowMessage(text)
	BonkCoop_ShowPopup("message", BonkCoop_Note(text), nil, L["hoa.ui.glue.okay"], nil, nil);
end

function BonkCoop_ShowPopup(kind, text, sub, first, second, data)
	BonkCoop.popup = kind;
	BonkCoop.popupData = data;
	BonkCoopPopupText:SetText(text or "");
	BonkCoopPopupSub:SetText(sub or "");
	BonkCoopPopupEdit:SetText("");
	if ( kind == "password" or kind == "code" or kind == "address" ) then
		BonkCoopPopupEdit:Show();
		BonkCoopPopupEdit:SetFocus();
	else
		BonkCoopPopupEdit:Hide();
		BonkCoopPopupEdit:ClearFocus();
	end
	if ( kind == "waiting" ) then
		BonkCoopPopupBar:Show();
	else
		BonkCoopPopupBar:Hide();
	end
	BonkCoop_SetPopupButtons(first, second);
	local height = 64 + BonkCoopPopupText:GetHeight() + BonkCoopPopupSub:GetHeight();
	if ( BonkCoopPopupEdit:IsShown() or BonkCoopPopupBar:IsShown() ) then
		height = height + 40;
	end
	BonkCoopPopup:SetHeight(math.max(110, height));
	BonkCoopPopup:Show();
	BonkCoop_ShowRequests();
end

function BonkCoop_SetPopupButtons(first, second)
	BonkCoopPopupButton1:ClearAllPoints();
	BonkCoopPopupButton2:ClearAllPoints();
	if ( first and second ) then
		BonkCoopPopupButton1:SetPoint("BOTTOMRIGHT", "BonkCoopPopup", "BOTTOM", -6, 16);
		BonkCoopPopupButton2:SetPoint("BOTTOMLEFT", "BonkCoopPopup", "BOTTOM", 6, 16);
	else
		BonkCoopPopupButton1:SetPoint("BOTTOM", "BonkCoopPopup", "BOTTOM", 0, 16);
		BonkCoopPopupButton2:SetPoint("BOTTOM", "BonkCoopPopup", "BOTTOM", 0, 16);
	end
	if ( first ) then
		BonkCoopPopupButton1:SetText(first);
		BonkCoopPopupButton1:Show();
	else
		BonkCoopPopupButton1:Hide();
	end
	if ( second ) then
		BonkCoopPopupButton2:SetText(second);
		BonkCoopPopupButton2:Show();
	else
		BonkCoopPopupButton2:Hide();
	end
end

function BonkCoop_PopupButton(index)
	local kind = BonkCoop.popup;
	local data = BonkCoop.popupData;
	BonkCoopPopup:Hide();
	BonkCoop.popup = nil;
	BonkCoop.popupData = nil;
	if ( kind == "password" and index == 1 ) then
		BonkCoop_Ask({ id = data.lobby.id, password = BonkCoopPopupEdit:GetText() }, data.lobby.host);
	elseif ( kind == "code" and index == 1 ) then
		BonkCoop_Ask({ code = strupper(BonkCoopPopupEdit:GetText()) }, nil);
	elseif ( kind == "address" and index == 1 ) then
		BonkCoop_Ask({ address = BonkCoopPopupEdit:GetText() }, nil);
	elseif ( kind == "waiting" or kind == "asking" or kind == "transferring" ) then
		BonkCoop.joining = nil;
		BonkCoop_Call("POST", "/join/cancel?who="..BonkCoop_Encode(BonkCoop_Who()));
	elseif ( kind == "rejoin" and index == 1 ) then
		BonkCoop_Call("POST", "/join/rejoin?who="..BonkCoop_Encode(BonkCoop_Who()));
		BonkCoop_Switch(data[3], data[4], data[5], data[6], data[2] == "joined" and data[8] or data[7]);
	elseif ( kind == "rejoin" ) then
		BonkCoop_Leave();
	end
	BonkCoop_ShowRequests();
end

function BonkCoop_OpenHostForm()
	local hero = BonkCoop_Hero();
	if ( not hero ) then
		return;
	end
	if ( hero.hardcore ) then
		BonkHero_SetStatus(L["hoa.ui.glue.hardcore_characters_can_t_play_co_op_yet"]);
		return;
	end
	if ( BonkCoopHostForm:IsShown() ) then
		BonkCoopHostForm:Hide();
		return;
	end
	BonkCoopBrowser:Hide();
	BonkCoopNameEdit:SetText(L("hoa.ui.glue.1_s_game", hero.name));
	BonkCoopPasswordEdit:SetText("");
	BonkCoopFloorEdit:SetText("1");
	BonkCoopMasteryEdit:SetText("10");
	BonkCoopAutoCheck:SetChecked(nil);
	BonkCoopSameClassCheck:SetChecked(nil);
	BonkCoopMinCheck:SetChecked(nil);
	BonkCoopMinEdit:SetText("1");
	BonkCoopNewCheck:SetChecked(nil);
	BonkCoop.difficulty = 1;
	BonkCoop.players = 4;
	BonkCoop_SetWho(1);
	BonkCoop_UpdateHostForm();
	BonkCoopHostForm:Show();
end

function BonkCoop_SetWho(index)
	BonkCoop.who = index;
	BonkCoopWhoOpen:SetChecked(index == 1 and 1 or nil);
	BonkCoopWhoPassword:SetChecked(index == 2 and 1 or nil);
	BonkCoopWhoCode:SetChecked(index == 3 and 1 or nil);
end

function BonkCoop_ShowChoices(anchor, labels, current, pick)
	local menu = BonkCoopChoiceMenu;
	if ( menu:IsShown() and menu.anchor == anchor ) then
		menu:Hide();
		return;
	end
	menu.anchor = anchor;
	menu.pick = pick;
	local count = table.getn(labels);
	for index = 1, 5 do
		local button = getglobal("BonkCoopChoice"..index);
		if ( index <= count ) then
			local text = getglobal(button:GetName().."Text");
			text:SetText(labels[index]);
			if ( index == current ) then
				text:SetTextColor(1, 0.82, 0);
			else
				text:SetTextColor(1, 1, 1);
			end
			button:Show();
		else
			button:Hide();
		end
	end
	menu:SetHeight(16 + count * 20);
	menu:ClearAllPoints();
	menu:SetPoint("TOP", anchor, "BOTTOM", 0, -2);
	menu:Show();
end

function BonkCoop_PickChoice(index)
	BonkCoopChoiceMenu:Hide();
	if ( BonkCoopChoiceMenu.pick ) then
		BonkCoopChoiceMenu.pick(index);
	end
	BonkCoop_UpdateHostForm();
end

function BonkCoop_ChooseDifficulty(anchor)
	BonkCoop_ShowChoices(anchor, BonkCoop_Words(BONK_COOP_DIFFICULTIES), BonkCoop.difficulty, function(index) BonkCoop.difficulty = index; end);
end

function BonkCoop_ChoosePlayers(anchor)
	BonkCoop_ShowChoices(anchor, { "2", "3", "4" }, BonkCoop.players - 1, function(index) BonkCoop.players = index + 1; end);
end

function BonkCoop_ChoosePause(anchor)
	BonkCoop_ShowChoices(anchor, { L["hoa.ui.glue.pause_party"], L["hoa.ui.glue.off"] }, BonkCoop.pause == 1 and 1 or 2, function(index) BonkCoop.pause = index == 1 and 1 or 0; end);
end

function BonkCoop_ChooseXp(anchor)
	BonkCoop_ShowChoices(anchor, { L["hoa.ui.glue.shared"], L["hoa.ui.glue.individual"] }, BonkCoop.xp == 1 and 1 or 2, function(index) BonkCoop.xp = index == 1 and 1 or 0; end);
end

function BonkCoop_ChooseMode(anchor)
	BonkCoop_ShowChoices(anchor, BonkCoop_Words(BONK_COOP_MODES), BonkCoop.runMode, function(index) BonkCoop.runMode = index; end);
end

function BonkCoop_SettingsText(pause, xp)
	return L("hoa.ui.glue.pause_1_xp_2", pause and L["hoa.ui.glue.pause_party"] or L["hoa.ui.glue.off"], xp and L["hoa.ui.glue.shared"] or L["hoa.ui.glue.individual"]);
end

function BonkCoop_UpdateHostForm()
	BonkCoopDifficultyButton:SetText(BonkCoop_Word(BONK_COOP_DIFFICULTIES[BonkCoop.difficulty]));
	BonkCoopPlayersButton:SetText(BonkCoop.players);
	BonkCoopPauseButton:SetText(BonkCoop.pause == 1 and L["hoa.ui.glue.pause_party"] or L["hoa.ui.glue.off"]);
	BonkCoopXpButton:SetText(BonkCoop.xp == 1 and L["hoa.ui.glue.shared"] or L["hoa.ui.glue.individual"]);
	BonkCoopModeButton:SetText(BonkCoop_Word(BONK_COOP_MODES[BonkCoop.runMode]));
	if ( BONK_COOP_DIFFICULTIES[BonkCoop.difficulty] == "Mythic" ) then
		BonkCoopFloorEdit:Show();
	else
		BonkCoopFloorEdit:Hide();
	end
end

function BonkCoop_Host()
	local hero = BonkCoop_Hero();
	if ( not hero ) then
		return;
	end
	local difficulty = BONK_COOP_DIFFICULTIES[BonkCoop.difficulty];
	if ( difficulty == "Mythic" ) then
		difficulty = "Mythic "..(tonumber(BonkCoopFloorEdit:GetText()) or 1);
	end
	if ( BonkCoop.runMode > 1 ) then
		difficulty = difficulty.." · "..BONK_COOP_MODES[BonkCoop.runMode];
	end
	local password = "";
	if ( BonkCoop.who == 2 ) then
		password = BonkCoopPasswordEdit:GetText() or "";
		if ( password == "" ) then
			BonkCoopPasswordEdit:SetFocus();
			return;
		end
	end
	local limit = 0;
	if ( BonkCoopNewCheck:GetChecked() ) then
		limit = tonumber(BonkCoopMasteryEdit:GetText()) or 10;
	end
	local minMythic = 0;
	if ( BonkCoopMinCheck:GetChecked() ) then
		minMythic = tonumber(BonkCoopMinEdit:GetText()) or 1;
	end
	local lines, problem = BonkCoop_Call("POST", "/host", {
		name = BonkCoopNameEdit:GetText(), password = password, listed = BonkCoop.who == 3 and "0" or "1",
		difficulty = difficulty, max = BonkCoop.players, mastery_limit = limit, auto = BonkCoopAutoCheck:GetChecked() and "1" or "0", same_class = BonkCoopSameClassCheck:GetChecked() and "1" or "0", min_mythic = minMythic, pause = BonkCoop.pause, xp = BonkCoop.xp,
		host_name = hero.name, host_class = strlower(hero.class), mastery = hero.mastery, account = BonkCoop_OwnAccount(),
		address = BonkCoopAddressEdit:GetText() or "",
	});
	BonkCoopHostForm:Hide();
	if ( not lines ) then
		BonkCoop_ShowMessage(problem);
		return;
	end
	BonkCoop_ReadHost(lines);
end

function BonkCoop_ReadHost(lines)
	local host = { members = {}, requests = {} };
	for _, fields in lines do
		if ( fields[1] == "state" ) then
			host.state = fields[2];
			host.message = fields[3];
		elseif ( fields[1] == "game" ) then
			host.name = fields[2];
			host.code = fields[3];
			host.max = fields[4];
			host.difficulty = fields[5];
		elseif ( fields[1] == "address" ) then
			host.address = fields[2];
		elseif ( fields[1] == "member" ) then
			table.insert(host.members, { name = fields[2], class = fields[3], mastery = fields[4] });
		elseif ( fields[1] == "request" ) then
			table.insert(host.requests, { ask = fields[2], name = fields[3], class = fields[4], race = fields[5], mastery = tonumber(fields[6]) or 0, best = tonumber(fields[7]) or 0, seconds = tonumber(fields[8]) or 30 });
		end
	end
	local before = BonkCoop.host and BonkCoop.host.state;
	local beforeMessage = BonkCoop.host and BonkCoop.host.message;
	if ( host.state == "off" ) then
		BonkCoop.host = nil;
	else
		BonkCoop.host = host;
	end
	if ( host.state == "hosting" and host.message and host.message ~= "" and (before ~= "hosting" or host.message ~= beforeMessage) ) then
		BonkCoop_ShowMessage(host.message);
	end
	if ( host.state == "error" and before ~= "error" ) then
		BonkCoop_ShowMessage(host.message);
		BonkCoop_Call("POST", "/host/stop");
		BonkCoop.host = nil;
	end
	BonkCoop_ShowRequests();
	BonkCoop_Apply();
end

BONK_COOP_REQUEST_SLOTS = 3;

function BonkCoop_ShowRequests()
	local shown = 0;
	local host = BonkCoop.host;
	if ( host and not BonkCoop.popup ) then
		for _, request in host.requests do
			if ( not BonkCoop.answered[request.ask] and shown < BONK_COOP_REQUEST_SLOTS ) then
				shown = shown + 1;
				BonkCoop_FillRequest(getglobal("BonkCoopRequest"..shown), request);
			end
		end
	end
	for index = shown + 1, BONK_COOP_REQUEST_SLOTS do
		local frame = getglobal("BonkCoopRequest"..index);
		frame.request = nil;
		frame:Hide();
	end
end

function BonkCoop_FillRequest(frame, request)
	local name = frame:GetName();
	frame.request = request;
	local race = BONK_RACE_DISPLAY_NAMES[strupper(request.race or "")] or "";
	getglobal(name.."Text"):SetText(L("hoa.ui.glue.1_wants_to_join", "|cffffd100"..request.name.."|r"));
	getglobal(name.."Sub"):SetText(L("hoa.ui.glue.mastery_1_2_3_best_4", request.mastery, race, BonkCoop_ClassName(request.class), BonkLevelName(request.best)));
	getglobal(name.."Bar"):SetValue(request.seconds / 30);
	frame:Show();
end

function BonkCoop_AnswerRequest(frame, accept)
	local request = frame.request;
	if ( not request ) then
		return;
	end
	BonkCoop.answered[request.ask] = 1;
	local lines, problem = BonkCoop_Call("POST", "/host/answer", { ask = request.ask, accept = accept and "1" or "0" });
	if ( not lines ) then
		BonkCoop_ShowMessage(problem);
	end
	BonkCoop_ShowRequests();
end

function BonkCoop_StatusButton()
	if ( BonkCoop_IsJoined() ) then
		BonkCoop_Leave();
		return;
	end
	BonkCoop_Call("POST", "/host/stop");
	BonkCoop.host = nil;
	BonkCoop_HideRoom();
	BonkCoop_Apply();
end

function BonkCoop_OnUpdate(elapsed)
	BonkCoop_CollectAnswers();
	if ( BonkCoop.reconnectAt and GetTime() >= BonkCoop.reconnectAt ) then
		BonkCoop.reconnectAt = nil;
		BonkCoopPopup:Hide();
		BonkCoop.popup = nil;
		BonkLogin_Begin();
		BonkLogin_Connect();
		return;
	end
	if ( not BonkHeroFrame:IsVisible() ) then
		BonkCoop.hiddenTimer = (BonkCoop.hiddenTimer or 0) + elapsed;
		if ( BonkCoop.leaving and BonkCoop.hiddenTimer >= BONK_COOP_POLL_EVERY ) then
			BonkCoop.hiddenTimer = 0;
			BonkCoop_PollLeave();
		end
		return;
	end
	if ( BonkCoop_IsJoined() and not BonkCoop.reconnectAt ) then
		BonkCoop_SelectJoinedHero();
	end
	local hero = BonkCoop_IsJoined() and Bonk.listLoaded and BonkHero_Selected();
	if ( hero and not BonkCoop.checkedEnter and not BonkCoop.reconnectAt ) then
		BonkCoop.enterAt = BonkCoop.enterAt or GetTime() + BONK_COOP_ENTER_DELAY;
		if ( GetTime() >= BonkCoop.enterAt ) then
			BonkCoop.checkedEnter = 1;
			BonkCoop.enterAt = nil;
			BonkCoop_EnterIfRejoining(hero);
		end
	end
	if ( BonkCoopBrowser:IsVisible() ) then
		BonkCoop.listTimer = BonkCoop.listTimer + elapsed;
		if ( BonkCoop.listTimer >= BONK_COOP_LIST_EVERY or (BonkCoop.loading and BonkCoop.listTimer >= 1) ) then
			BonkCoop_RefreshList();
		end
	end
	if ( BonkCoop.joining and BonkCoop.popup == "waiting" ) then
		local left = BonkCoop.joining.seconds - (GetTime() - BonkCoop.joining.started);
		BonkCoopPopupBar:SetValue(math.max(0, left / 30));
	end
	BonkCoop.pollTimer = BonkCoop.pollTimer + elapsed;
	if ( BonkCoop.pollTimer < BONK_COOP_POLL_EVERY ) then
		return;
	end
	BonkCoop.pollTimer = 0;
	if ( not BonkCoop.checkedHome and Bonk.listLoaded and not BonkCoop_IsJoined() ) then
		BonkCoop.checkedHome = 1;
		BonkCoop_CallLater("GET", "/join?who="..BonkCoop_Encode(BonkCoop_Who()), nil, "home", BonkCoop_ReadHome);
	end
	if ( BonkCoop.homeNote and not BonkCoop.reconnectAt and Bonk.listLoaded ) then
		BonkCoop_ShowMessage(BonkCoop.homeNote);
		BonkCoop.homeNote = nil;
	end
	if ( BonkCoop.joining ) then
		BonkCoop_CallLater("GET", "/join?who="..BonkCoop_Encode(BonkCoop_Who()), nil, "join", BonkCoop_ReadJoinPoll);
	end
	if ( BonkCoop.leaving ) then
		BonkCoop_PollLeave();
	elseif ( BonkCoop_IsJoined() and not BonkCoop.joining and Bonk.listLoaded ) then
		BonkCoop_CallLater("GET", "/join?who="..BonkCoop_Encode(BonkCoop_Who()), nil, "joined", function(lines)
			local fields = lines and lines[1];
			if ( fields and (fields[2] == "returning" or fields[2] == "home") and not BonkCoop.leaving ) then
				BonkCoop.leaving = 1;
				BonkCoop_ReadLeave(lines);
			end
		end);
	end
	if ( BonkCoop.host or BonkCoop.mode ) then
		BonkCoop_CallLater("GET", "/host", nil, "host", function(lines)
			if ( lines ) then
				BonkCoop_ReadHost(lines);
			else
				BonkCoop.pollTimer = -BONK_COOP_AWAY_WAIT;
			end
		end);
	end
end

function BonkCoop_ReadJoinPoll(lines, problem)
	if ( not BonkCoop.joining ) then
		return;
	end
	if ( not lines ) then
		BonkCoop.joinFailures = (BonkCoop.joinFailures or 0) + 1;
		if ( BonkCoop.joinFailures >= BONK_COOP_POLL_FAILURES ) then
			BonkCoop.joining = nil;
			BonkCoop.joinFailures = nil;
			BonkCoop_ShowMessage(problem or L["hoa.ui.glue.the_launcher_stopped_answering_restart_the_launcher_and_try_"]);
		end
		return;
	end
	BonkCoop.joinFailures = nil;
	BonkCoop_ReadJoin(lines);
end

function BonkCoop_PollLeave()
	BonkCoop_CallLater("GET", "/join?who="..BonkCoop_Encode(BonkCoop_Who()), nil, "leave", function(lines)
		if ( BonkCoop.leaving ) then
			BonkCoop_ReadLeave(lines);
		end
	end);
end

function BonkCoop_ReadHome(lines)
	local fields = lines and lines[1] or {};
	if ( fields[2] == "asking" or fields[2] == "waiting" or fields[2] == "transferring" ) then
		BonkCoop.joining = { started = GetTime() };
		BonkCoop_ReadJoin(lines);
		return;
	end
	if ( (fields[2] == "joined" or fields[2] == "accepted") and fields[3] and fields[3] ~= "" ) then
		BonkCoop_ShowPopup("rejoin", L["hoa.ui.glue.you_re_still_in_a_co_op_party"], L["hoa.ui.glue.reconnect_or_leave_the_party_your_progress_there_is_already_"], L["hoa.ui.glue.reconnect"], L["hoa.ui.glue.leave_party"], fields);
	elseif ( fields[2] == "joined" or fields[2] == "accepted" ) then
		BonkCoop_Leave();
	end
end
