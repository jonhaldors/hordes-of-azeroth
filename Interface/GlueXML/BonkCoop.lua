BONK_COOP_ROWS = 14;
BONK_COOP_MEMBERS = 4;
BONK_COOP_DIFFICULTIES = { "Normal", "Heroic", "Mythic" };
BONK_COOP_LIST_EVERY = 3;
BONK_COOP_POLL_EVERY = 1;
BONK_COOP_MYTHIC_START = 9;
BONK_COOP_MODES = { "Levels", "Dungeon", "Invasion" };
BONK_COOP_AWAY_WAIT = 30;
BONK_COOP_RECONNECT_DELAY = 1;
BONK_COOP_REJOIN_TRIES = 2;
BONK_COOP_ENTER_DELAY = 1;

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
		local found = string.find(text, separator, start, 1);
		if ( not found ) then
			table.insert(fields, string.sub(text, start));
			return fields;
		end
		table.insert(fields, string.sub(text, start, found - 1));
		start = found + 1;
	end
end

function BonkCoop_Call(method, path, fields)
	if ( not HoaCoop_Call ) then
		return nil, "This client doesn't support co-op.";
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
		done(nil, "This client doesn't support co-op.");
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
			return class.name;
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
	local class = BONK_CLASSES[Bonk.classIndex];
	local hero = class and Bonk.heroes[class.token];
	if ( not hero ) then
		return nil;
	end
	local stats = BONK_STATS and BONK_STATS.heroes and BONK_STATS.heroes[hero.name] or {};
	return { name = hero.name, class = class.token, className = class.name, race = hero.race, mastery = stats.mastery or 0, best = stats.bestLevel or 0, ironman = stats.ironman };
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
		BonkCoopStatusText:SetText("You're in a co-op party.");
		BonkCoopStatusButton:SetText("Leave Party");
		BonkCoopStatus:Show();
		return;
	end
	if ( BonkCoop_IsHosting() ) then
		BonkCoopBar:Hide();
		BonkHeroPlayButton:Show();
		BonkCoopStatusText:SetText(BonkCoop_HostLine());
		BonkCoopStatusButton:SetText("Close Lobby");
		BonkCoopStatus:Show();
		return;
	end
	BonkCoopStatus:Hide();
	if ( BonkCoop.mode ) then
		local hero = BonkCoop_Hero();
		BonkHeroPlayButton:Hide();
		BonkCoopBar:Show();
		if ( hero and hero.ironman ) then
			BonkCoopBarText:SetText("Ironman characters can't play co-op.");
			BonkCoopFindButton:Disable();
			BonkCoopHostButton:Disable();
		elseif ( hero ) then
			BonkCoopBarText:SetText("Joins as "..hero.name);
			BonkCoopFindButton:Enable();
			BonkCoopHostButton:Enable();
		else
			BonkCoopBarText:SetText("Create a "..BONK_CLASSES[Bonk.classIndex].name.." first.");
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
		return "Opening lobby...";
	end
	return format("Lobby \"%s\" · %d/%s players · Code: %s", host.name or "", table.getn(host.members or {}), host.max or "4", host.code or "");
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
	BonkCoop_CallLater("GET", "/lobbies", nil, "lobbies", BonkCoop_ShowLobbies);
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
				pause = fields[15] ~= "0", xp = fields[16] ~= "0", playing = fields[17] or "",
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
	if ( search ~= "" and not string.find(strlower(lobby.name), search, 1, 1) and not string.find(strlower(lobby.host), search, 1, 1) ) then
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
	BonkCoopFilterButton:SetText(active > 0 and format("Filters (%d)", active) or "Filters");
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
			getglobal(name.."Difficulty"):SetText(lobby.playing ~= "" and lobby.playing or lobby.difficulty);
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
		BonkCoopListNote:SetText("|cffff4040"..BonkCoop.listError.."|r");
	elseif ( BonkCoop.loading and count == 0 ) then
		BonkCoopListNote:SetText("Searching for games...");
	elseif ( count == 0 and table.getn(BonkCoop.lobbies) > 0 ) then
		BonkCoopListNote:SetText(format("No games match your filters (%d hidden).", table.getn(BonkCoop.lobbies)));
	elseif ( count == 0 ) then
		BonkCoopListNote:SetText("No games found. Host your own, or join a friend with their code.");
	else
		BonkCoopListNote:SetText(format("Games: %d (%d hidden by filters)", count, table.getn(BonkCoop.lobbies) - count));
	end
	BonkCoop_UpdateDetails();
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
		return nil, "Select a character first.";
	end
	if ( hero.ironman ) then
		return nil, "Ironman characters can't play co-op.";
	end
	if ( lobby.players >= lobby.max ) then
		return nil, "Game is full.";
	end
	for _, class in lobby.classes do
		if ( strupper(class) == hero.class and not lobby.sameClass ) then
			return nil, "Party already has a "..hero.className..".";
		end
	end
	if ( lobby.minMythic > 0 and hero.best < BONK_COOP_MYTHIC_START + lobby.minMythic ) then
		return nil, format("Requires Mythic %d cleared.", lobby.minMythic);
	end
	if ( lobby.masteryLimit > 0 and hero.mastery > lobby.masteryLimit ) then
		return nil, format("Requires Mastery %d or lower.", lobby.masteryLimit);
	end
	return 1, format("You'll join as %s (Mastery %d %s).", hero.name, hero.mastery, hero.className);
end

function BonkCoop_UpdateDetails()
	local lobby = BonkCoop_Selected();
	if ( not lobby ) then
		BonkCoopDetailName:SetText("");
		BonkCoopDetailSub:SetText("Select a game to see the party.");
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
	BonkCoopDetailSub:SetText("Host: "..lobby.host.." · "..(lobby.locked and "Password" or "Public"));
	local tags = lobby.difficulty;
	if ( lobby.masteryLimit > 0 ) then
		tags = tags.." · Mastery "..lobby.masteryLimit.." or lower only";
	end
	if ( lobby.minMythic > 0 ) then
		tags = tags.." · Mythic "..lobby.minMythic.." cleared required";
	end
	if ( lobby.sameClass ) then
		tags = tags.." · Duplicate classes allowed";
	end
	if ( lobby.playing ~= "" ) then
		tags = tags.."\nPlaying now: "..lobby.playing;
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
				getglobal(name.."Sub"):SetText(format("Mastery %d %s", member.mastery, BonkCoop_ClassName(member.class)));
			else
				getglobal(name.."Icon"):SetTexture(1, 1, 1, 0.08);
				getglobal(name.."Icon"):SetTexCoord(0, 1, 0, 1);
				getglobal(name.."Icon"):Show();
				getglobal(name.."Name"):SetText("|cff808080Empty slot|r");
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
		BonkCoop_ShowPopup("password", "Enter password for \""..lobby.name.."\".", nil, "Join", "Cancel", { lobby = lobby });
		return;
	end
	BonkCoop_Ask({ id = lobby.id }, lobby.host);
end

function BonkCoop_ShowCodeDialog()
	BonkCoop_ShowPopup("code", "Enter your friend's game code.", nil, "Join", "Cancel", {});
end

function BonkCoop_Ask(target, hostName)
	local hero = BonkCoop_Hero();
	if ( not hero ) then
		return;
	end
	if ( hero.ironman ) then
		BonkCoop_ShowMessage("Ironman characters can't play co-op.");
		return;
	end
	target.name = hero.name;
	target.class = strlower(hero.class);
	target.race = hero.race;
	target.mastery = hero.mastery;
	target.best = hero.best;
	target.account = BonkCoop_OwnAccount();
	local lines, problem = BonkCoop_Call("POST", "/ask?who="..BonkCoop_Encode(BonkCoop_Who()), target);
	if ( not lines ) then
		BonkCoop_ShowMessage(problem);
		return;
	end
	BonkCoop.joining = { host = hostName, started = GetTime() };
	BonkCoop_ReadJoin(lines);
end

function BonkCoop_ReadJoin(lines)
	local fields = lines[1] or {};
	local state = fields[2];
	if ( state == "waiting" ) then
		local joining = BonkCoop.joining or { started = GetTime() };
		BonkCoop.joining = joining;
		joining.seconds = tonumber(fields[4]) or 30;
		local who = joining.host and ("|cffffd100"..joining.host.."|r") or "the host";
		BonkCoop_ShowPopup("waiting", "Waiting on "..who.." to accept...", "\""..(fields[3] or "").."\"", nil, "Cancel", nil);
	elseif ( state == "transferring" ) then
		local hero = BonkCoop_Hero();
		BonkCoop_ShowPopup("message", "The host accepted. Joining with "..(hero and hero.name or "your character").."...", nil, nil, nil, nil);
	elseif ( state == "accepted" ) then
		BonkCoop.joining = nil;
		BonkCoop_ShowPopup("message", "Connecting to host...", nil, nil, nil, nil);
		BonkCoop_Switch(fields[3], fields[4], fields[5], fields[6], fields[7]);
	elseif ( state == "declined" ) then
		BonkCoop.joining = nil;
		local reason = fields[3];
		BonkCoop_ShowMessage((reason and reason ~= "") and reason or "The host declined your join request.");
	elseif ( state == "joined" ) then
		BonkCoop.joining = nil;
	elseif ( state == "error" or state == "ended" ) then
		BonkCoop.joining = nil;
		BonkCoop_ShowMessage(fields[3] or "Join request cancelled.");
	end
end

function BonkCoop_Switch(address, token, user, password, character)
	BonkCoop_Call("POST", "/join/done?who="..BonkCoop_Encode(BonkCoop_Who()));
	BonkCoopBrowser:Hide();
	HoaCoop_SetGate(address, token, user, password, character);
	BonkCoop_Reconnect();
end

function BonkCoop_Reconnect()
	Bonk.loginTried = true;
	Bonk.listLoaded = false;
	Bonk.reuseList = false;
	BonkCoop.reconnectAt = GetTime() + BONK_COOP_RECONNECT_DELAY;
	BonkCoop.checkedEnter = nil;
	BonkCoop.enterAt = nil;
	DisconnectFromServer();
end

function BonkCoop_SelectJoinedHero()
	if ( not Bonk.listLoaded or Bonk.heroes[BONK_CLASSES[Bonk.classIndex].token] ) then
		return;
	end
	for index, class in ipairs(BONK_CLASSES) do
		if ( Bonk.heroes[class.token] ) then
			Bonk.classIndex = index;
			BonkHero_Refresh();
			return;
		end
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
	local tries = tonumber(lines and lines[1] and lines[1][3]) or BONK_COOP_REJOIN_TRIES + 1;
	if ( tries > BONK_COOP_REJOIN_TRIES ) then
		BonkLoginStatus:SetText("Can't reach the host. Returning to your own game...");
		BonkCoop_Leave();
		return;
	end
	BonkLoginStatus:SetText("Connection to host lost. Reconnecting...");
	BonkCoop_Reconnect();
end

function BonkCoop_RefusalNote(shown)
	if ( shown == CHAR_LOGIN_DISABLED ) then
		return "You were removed from the party.";
	elseif ( shown == CHAR_LOGIN_DUPLICATE_CHARACTER ) then
		return "Your party already has this class. Join with a character of another class.";
	elseif ( shown == CHAR_LOGIN_NO_INSTANCES ) then
		return "That party is full.";
	elseif ( shown == CHAR_LOGIN_FAILED ) then
		return "Couldn't join the host's game.";
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
	BonkCoop_ShowPopup("message", "Leaving party...", nil, nil, nil, nil);
	BonkCoop_ReadLeave(BonkCoop_Call("POST", "/join/leave?who="..BonkCoop_Encode(BonkCoop_Who())));
end

function BonkCoop_ReadLeave(lines)
	local fields = lines and lines[1] or { "state", "home", "" };
	if ( fields[2] ~= "home" ) then
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
	BonkCoop_ShowPopup("message", text, nil, "Okay", nil, nil);
end

function BonkCoop_ShowPopup(kind, text, sub, first, second, data)
	BonkCoop.popup = kind;
	BonkCoop.popupData = data;
	BonkCoopPopupText:SetText(text or "");
	BonkCoopPopupSub:SetText(sub or "");
	BonkCoopPopupEdit:SetText("");
	if ( kind == "password" or kind == "code" ) then
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
	elseif ( kind == "waiting" ) then
		BonkCoop.joining = nil;
		BonkCoop_Call("POST", "/join/cancel?who="..BonkCoop_Encode(BonkCoop_Who()));
	elseif ( kind == "rejoin" and index == 1 ) then
		BonkCoop_Call("POST", "/join/rejoin?who="..BonkCoop_Encode(BonkCoop_Who()));
		BonkCoop_Switch(data[3], data[4], data[5], data[6], data[8]);
	elseif ( kind == "rejoin" ) then
		BonkCoop_Leave();
	end
	BonkCoop_ShowRequests();
end

function BonkCoop_OpenHostForm()
	local hero = BonkCoop_Hero();
	if ( not hero or hero.ironman ) then
		return;
	end
	if ( BonkCoopHostForm:IsShown() ) then
		BonkCoopHostForm:Hide();
		return;
	end
	BonkCoopBrowser:Hide();
	BonkCoopNameEdit:SetText(hero.name.."'s Game");
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
	BonkCoop_ShowChoices(anchor, BONK_COOP_DIFFICULTIES, BonkCoop.difficulty, function(index) BonkCoop.difficulty = index; end);
end

function BonkCoop_ChoosePlayers(anchor)
	BonkCoop_ShowChoices(anchor, { "2", "3", "4" }, BonkCoop.players - 1, function(index) BonkCoop.players = index + 1; end);
end

function BonkCoop_ChoosePause(anchor)
	BonkCoop_ShowChoices(anchor, { "Party", "Off" }, BonkCoop.pause == 1 and 1 or 2, function(index) BonkCoop.pause = index == 1 and 1 or 0; end);
end

function BonkCoop_ChooseXp(anchor)
	BonkCoop_ShowChoices(anchor, { "Shared", "Individual" }, BonkCoop.xp == 1 and 1 or 2, function(index) BonkCoop.xp = index == 1 and 1 or 0; end);
end

function BonkCoop_ChooseMode(anchor)
	BonkCoop_ShowChoices(anchor, BONK_COOP_MODES, BonkCoop.runMode, function(index) BonkCoop.runMode = index; end);
end

function BonkCoop_SettingsText(pause, xp)
	return "Pause: "..(pause and "Party" or "Off").." · XP: "..(xp and "Shared" or "Individual");
end

function BonkCoop_UpdateHostForm()
	BonkCoopDifficultyButton:SetText(BONK_COOP_DIFFICULTIES[BonkCoop.difficulty]);
	BonkCoopPlayersButton:SetText(BonkCoop.players);
	BonkCoopPauseButton:SetText(BonkCoop.pause == 1 and "Party" or "Off");
	BonkCoopXpButton:SetText(BonkCoop.xp == 1 and "Shared" or "Individual");
	BonkCoopModeButton:SetText(BONK_COOP_MODES[BonkCoop.runMode]);
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
		elseif ( fields[1] == "member" ) then
			table.insert(host.members, { name = fields[2], class = fields[3], mastery = fields[4] });
		elseif ( fields[1] == "request" ) then
			table.insert(host.requests, { ask = fields[2], name = fields[3], class = fields[4], race = fields[5], mastery = tonumber(fields[6]) or 0, best = tonumber(fields[7]) or 0, seconds = tonumber(fields[8]) or 30 });
		end
	end
	local before = BonkCoop.host and BonkCoop.host.state;
	if ( host.state == "off" ) then
		BonkCoop.host = nil;
	else
		BonkCoop.host = host;
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
	local race = BONK_RACE_NAMES[strupper(request.race or "")] or "";
	getglobal(name.."Text"):SetText("|cffffd100"..request.name.."|r wants to join.");
	getglobal(name.."Sub"):SetText(format("Mastery %d %s %s · Best: %s", request.mastery, race, BonkCoop_ClassName(request.class), BonkLevelName(request.best)));
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
		return;
	end
	if ( BonkCoop_IsJoined() and not BonkCoop.reconnectAt ) then
		BonkCoop_SelectJoinedHero();
	end
	local hero = BonkCoop_IsJoined() and Bonk.listLoaded and Bonk.heroes[BONK_CLASSES[Bonk.classIndex].token];
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
		BonkCoop_CallLater("GET", "/join?who="..BonkCoop_Encode(BonkCoop_Who()), nil, "join", function(lines)
			if ( lines and BonkCoop.joining ) then
				BonkCoop_ReadJoin(lines);
			end
		end);
	end
	if ( BonkCoop.leaving ) then
		BonkCoop_CallLater("GET", "/join?who="..BonkCoop_Encode(BonkCoop_Who()), nil, "leave", function(lines)
			if ( BonkCoop.leaving ) then
				BonkCoop_ReadLeave(lines);
			end
		end);
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

function BonkCoop_ReadHome(lines)
	local fields = lines and lines[1] or {};
	if ( (fields[2] == "joined" or fields[2] == "accepted") and fields[3] and fields[3] ~= "" ) then
		BonkCoop_ShowPopup("rejoin", "You're still in a co-op party.", "Reconnect, or leave the party. Your progress there is already saved.", "Reconnect", "Leave Party", fields);
	elseif ( fields[2] == "joined" or fields[2] == "accepted" ) then
		BonkCoop_Leave();
	end
end
