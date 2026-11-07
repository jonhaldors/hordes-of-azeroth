local L = VanillaBonkL

VanillaBonkCoop = {
	pollEvery = 1,
	pollQuiet = 1,
	pollAway = 30,
	timer = 0,
	host = nil,
	answered = {},
	shown = nil,
};

do
	local Coop = VanillaBonkCoop;

	local function Split(text, separator)
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

	local function ParseAnswer(answer)
		if ( not answer ) then
			return nil;
		end
		local lines = {};
		for _, line in Split(answer, "\n") do
			if ( line ~= "" ) then
				table.insert(lines, Split(line, "\t"));
			end
		end
		return lines;
	end

	local pendingCalls = {};

	local function Call(method, path, body, done)
		if ( not HoaCoop_Start ) then
			if ( done ) then
				done(nil);
			end
			return;
		end
		table.insert(pendingCalls, { id = HoaCoop_Start(method, path, body or ""), done = done });
	end

	local function CollectAnswers()
		local index = 1;
		while ( pendingCalls[index] ) do
			local call = pendingCalls[index];
			local waiting, answer = HoaCoop_Take(call.id);
			if ( waiting ) then
				index = index + 1;
			else
				table.remove(pendingCalls, index);
				if ( call.done ) then
					call.done(ParseAnswer(answer));
				end
			end
		end
	end

	local CLASS_NAMES = { warrior = "Warrior", paladin = "Paladin", hunter = "Hunter", rogue = "Rogue", priest = "Priest", shaman = "Shaman", mage = "Mage", warlock = "Warlock", druid = "Druid" };
	local RACE_NAMES = { HUMAN = "hoa.addon.human", DWARF = "hoa.addon.dwarf", NIGHTELF = "hoa.addon.night_elf", GNOME = "hoa.addon.gnome", ORC = "hoa.addon.orc", SCOURGE = "hoa.addon.undead", TAUREN = "hoa.addon.tauren", TROLL = "hoa.addon.troll" };

	local function Label(text)
		return text and L[text] or "";
	end

	local function DarkBackdrop(frame)
		frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } });
		frame:SetBackdropColor(0.03, 0.03, 0.05, 0.96);
		frame:SetBackdropBorderColor(0.55, 0.55, 0.55);
	end

	local MAX_PROMPTS = 3;
	local PROMPT_HEIGHT = 150;
	local PROMPT_GAP = 8;
	local prompts = {};

	local function Answer(prompt, accept)
		local request = prompt.request;
		prompt:Hide();
		prompt.request = nil;
		if ( not request ) then
			return;
		end
		Coop.answered[request.ask] = 1;
		Call("POST", "/host/answer", "ask="..request.ask.."&accept="..(accept and "1" or "0"));
	end

	for index = 1, MAX_PROMPTS do
		local prompt = CreateFrame("Frame", "VanillaBonkCoopPrompt"..index, UIParent);
		prompt:SetWidth(440);
		prompt:SetHeight(PROMPT_HEIGHT);
		prompt:SetPoint("TOP", UIParent, "TOP", 0, -90 - (index - 1) * (PROMPT_HEIGHT + PROMPT_GAP));
		prompt:SetFrameStrata("DIALOG");
		prompt:EnableMouse(true);
		DarkBackdrop(prompt);
		prompt:Hide();

		prompt.title = prompt:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
		prompt.title:SetPoint("TOP", prompt, "TOP", 0, -18);
		prompt.sub = prompt:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall");
		prompt.sub:SetPoint("TOP", prompt.title, "BOTTOM", 0, -6);

		prompt.bar = CreateFrame("StatusBar", nil, prompt);
		prompt.bar:SetWidth(320);
		prompt.bar:SetHeight(10);
		prompt.bar:SetPoint("BOTTOM", prompt, "BOTTOM", 0, 56);
		prompt.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
		prompt.bar:SetStatusBarColor(1, 0.82, 0.2);
		prompt.bar:SetMinMaxValues(0, 30);
		local barBack = prompt.bar:CreateTexture(nil, "BACKGROUND");
		barBack:SetAllPoints(prompt.bar);
		barBack:SetTexture(1, 1, 1, 0.12);

		local accept = CreateFrame("Button", "VanillaBonkCoopAccept"..index, prompt, "UIPanelButtonTemplate");
		accept:SetWidth(130);
		accept:SetHeight(26);
		accept:SetPoint("BOTTOMRIGHT", prompt, "BOTTOM", -6, 16);
		accept:SetText(L["hoa.addon.accept"]);
		accept:SetScript("OnClick", function() Answer(prompt, 1); end);

		local decline = CreateFrame("Button", "VanillaBonkCoopDecline"..index, prompt, "UIPanelButtonTemplate");
		decline:SetWidth(130);
		decline:SetHeight(26);
		decline:SetPoint("BOTTOMLEFT", prompt, "BOTTOM", 6, 16);
		decline:SetText(L["hoa.addon.decline"]);
		decline:SetScript("OnClick", function() Answer(prompt, nil); end);

		prompts[index] = prompt;
	end

	local function HidePrompts()
		for _, prompt in prompts do
			prompt:Hide();
			prompt.request = nil;
		end
	end

	local line = CreateFrame("Frame", "VanillaBonkCoopHosting", UIParent);
	line:SetWidth(240);
	line:SetHeight(40);
	line:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", -8, -4);
	line:Hide();
	local lineTitle = line:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	lineTitle:SetPoint("TOPRIGHT", line, "TOPRIGHT", 0, 0);
	lineTitle:SetJustifyH("RIGHT");
	local lineSub = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	lineSub:SetPoint("TOPRIGHT", lineTitle, "BOTTOMRIGHT", 0, -2);
	lineSub:SetJustifyH("RIGHT");

	local room = CreateFrame("Frame", "VanillaBonkCoopRoom", UIParent);
	room:SetWidth(440);
	room:SetHeight(360);
	room:SetPoint("CENTER", UIParent, "CENTER", 0, 20);
	room:SetFrameStrata("DIALOG");
	room:EnableMouse(true);
	DarkBackdrop(room);
	room:Hide();
	tinsert(UISpecialFrames, "VanillaBonkCoopRoom");
	room.title = room:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
	room.title:SetPoint("TOP", room, "TOP", 0, -18);
	room.address = room:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	room.address:SetPoint("TOPLEFT", room, "TOPLEFT", 24, -54);
	room.address:SetWidth(392);
	room.address:SetJustifyH("LEFT");
	room.count = room:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	room.count:SetPoint("TOPLEFT", room, "TOPLEFT", 24, -78);
	room.members = {};
	for index = 1, 4 do
		local row = CreateFrame("Frame", nil, room);
		row:SetWidth(392);
		row:SetHeight(26);
		row:SetPoint("TOPLEFT", room, "TOPLEFT", 24, -(108 + (index - 1) * 34));
		row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0);
		row.name:SetJustifyH("LEFT");
		row.sub = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14);
		row.sub:SetJustifyH("LEFT");
		row:Hide();
		room.members[index] = row;
	end
	local roomClose = CreateFrame("Button", nil, room, "UIPanelButtonTemplate");
	roomClose:SetWidth(120);
	roomClose:SetHeight(24);
	roomClose:SetPoint("BOTTOM", room, "BOTTOM", 0, 18);
	roomClose:SetText(L["hoa.addon.close"]);
	roomClose:SetScript("OnClick", function() room:Hide(); end);
	line:EnableMouse(true);
	line:SetScript("OnMouseUp", function()
		if ( room:IsShown() ) then
			room:Hide();
		elseif ( Coop.host ) then
			room:Show();
		end
	end);

	local function ShowRoom(host)
		room.title:SetText(L("hoa.addon.lobby_1", host.name or ""));
		room.address:SetText("IP: "..(host.address or ""));
		room.count:SetText(host.members.."/"..(host.max or "4"));
		for index = 1, 4 do
			local row = room.members[index];
			local member = host.memberList and host.memberList[index];
			if ( member ) then
				row.name:SetText(member.name or "");
				row.sub:SetText(L["hoa.addon.mastery_2"].." "..(member.mastery or "0").."  ·  "..Label(CLASS_NAMES[member.class or ""] or member.class or ""));
				row:Show();
			else
				row:Hide();
			end
		end
		room:Show();
	end

	local function Read(lines)
		local host = { members = 0, memberList = {}, requests = {} };
		for _, fields in lines do
			if ( fields[1] == "state" ) then
				host.state = fields[2];
			elseif ( fields[1] == "game" ) then
				host.name = fields[2];
				host.code = fields[3];
				host.max = fields[4];
			elseif ( fields[1] == "address" ) then
				host.address = fields[2];
			elseif ( fields[1] == "member" ) then
				host.members = host.members + 1;
				table.insert(host.memberList, { name = fields[2], class = fields[3], mastery = fields[4] });
			elseif ( fields[1] == "request" ) then
				table.insert(host.requests, { ask = fields[2], name = fields[3], class = fields[4], race = fields[5], mastery = tonumber(fields[6]) or 0, best = tonumber(fields[7]) or 0, seconds = tonumber(fields[8]) or 30 });
			end
		end
		return host;
	end

	local function ShowRequests(waiting)
		local sound;
		for index, prompt in prompts do
			local request = waiting[index];
			if ( request ) then
				if ( not prompt.request or prompt.request.ask ~= request.ask ) then
					prompt.title:SetText(L("hoa.addon.1_wants_to_join", "|cffffd100"..(request.name or "").."|r"));
					prompt.sub:SetText(L("hoa.addon.mastery_1_2_3_best_4", request.mastery, Label(RACE_NAMES[string.upper(request.race or "")]), Label(CLASS_NAMES[request.class or ""]), VanillaBonkUI.LevelName(request.best)));
					sound = 1;
				end
				prompt.request = request;
				prompt.bar:SetValue(request.seconds);
				prompt:Show();
			else
				prompt:Hide();
				prompt.request = nil;
			end
		end
		if ( sound ) then
			PlaySound("igPlayerInvite");
		end
	end

	local function ShowHostState(lines)
		Coop.pollEvery = lines and Coop.pollQuiet or Coop.pollAway;
		if ( not lines ) then
			Coop.host = nil;
			line:Hide();
			room:Hide();
			Coop.roomShown = nil;
			HidePrompts();
			return;
		end
		local host = Read(lines);
		Coop.host = host;
		if ( host.state ~= "hosting" ) then
			Coop.host = nil;
			line:Hide();
			room:Hide();
			Coop.roomShown = nil;
			HidePrompts();
			return;
		end
		lineTitle:SetText(L("hoa.addon.lobby_1", host.name or ""));
		lineSub:SetText(host.members.."/"..(host.max or "4").."  ·  IP: "..(host.address or ""));
		if ( GetRealZoneText() == "GM Island" ) then
			line:Show();
			if ( not Coop.roomShown ) then
				Coop.roomShown = 1;
				ShowRoom(host);
			end
		else
			line:Hide();
			room:Hide();
		end
		local waiting = {};
		for _, request in host.requests do
			if ( not Coop.answered[request.ask] ) then
				table.insert(waiting, request);
			end
		end
		ShowRequests(waiting);
	end

	local function Refresh()
		if ( HoaCoop_GetGate and HoaCoop_GetGate() ) then
			Coop.host = nil;
			line:Hide();
			room:Hide();
			Coop.roomShown = nil;
			HidePrompts();
			return;
		end
		if ( Coop.polling ) then
			return;
		end
		Coop.polling = 1;
		Call("GET", "/host", nil, function(lines)
			Coop.polling = nil;
			ShowHostState(lines);
		end);
	end

	local poller = CreateFrame("Frame");
	poller:SetScript("OnUpdate", function()
		CollectAnswers();
		Coop.timer = Coop.timer + arg1;
		if ( Coop.timer < Coop.pollEvery ) then
			return;
		end
		Coop.timer = 0;
		Refresh();
	end);

	local ready = CreateFrame("Frame", "VanillaBonkCoopReady", UIParent);
	ready:SetWidth(440);
	ready:SetHeight(150);
	ready:SetPoint("TOP", UIParent, "TOP", 0, -90);
	ready:SetFrameStrata("DIALOG");
	ready:EnableMouse(true);
	DarkBackdrop(ready);
	ready:Hide();

	local readyTitle = ready:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
	readyTitle:SetPoint("TOP", ready, "TOP", 0, -18);
	readyTitle:SetWidth(400);
	local readySub = ready:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	readySub:SetPoint("TOP", readyTitle, "BOTTOM", 0, -6);
	readySub:SetText(L["hoa.addon.ready_check"]);

	local readyBar = CreateFrame("StatusBar", nil, ready);
	readyBar:SetWidth(320);
	readyBar:SetHeight(10);
	readyBar:SetPoint("BOTTOM", ready, "BOTTOM", 0, 56);
	readyBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	readyBar:SetStatusBarColor(1, 0.82, 0.2);
	local readyBarBack = readyBar:CreateTexture(nil, "BACKGROUND");
	readyBarBack:SetAllPoints(readyBar);
	readyBarBack:SetTexture(1, 1, 1, 0.12);

	local function AnswerReady(yes)
		ready:Hide();
		SendChatMessage(".bonk coopready " .. (yes and "1" or "0"), "SAY");
	end

	local yes = CreateFrame("Button", "VanillaBonkCoopReadyYes", ready, "UIPanelButtonTemplate");
	yes:SetWidth(130);
	yes:SetHeight(26);
	yes:SetPoint("BOTTOMRIGHT", ready, "BOTTOM", -6, 16);
	yes:SetText(L["hoa.addon.ready"]);
	yes:SetScript("OnClick", function() AnswerReady(1); end);

	local no = CreateFrame("Button", "VanillaBonkCoopReadyNo", ready, "UIPanelButtonTemplate");
	no:SetWidth(130);
	no:SetHeight(26);
	no:SetPoint("BOTTOMLEFT", ready, "BOTTOM", 6, 16);
	no:SetText(L["hoa.addon.not_ready"]);
	no:SetScript("OnClick", function() AnswerReady(nil); end);

	ready:SetScript("OnUpdate", function()
		this.left = (this.left or 0) - arg1;
		readyBar:SetValue(math.max(0, this.left));
		if ( this.left <= 0 ) then
			this:Hide();
		end
	end);

	local leash = CreateFrame("Frame", "VanillaBonkCoopLeash", UIParent);
	leash:SetWidth(400);
	leash:SetHeight(40);
	leash:SetPoint("TOP", UIParent, "TOP", 0, -112);
	leash:Hide();
	local leashTitle = leash:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	leashTitle:SetPoint("TOP", leash, "TOP", 0, 0);
	leashTitle:SetTextColor(1, 0.3, 0.2);
	local leashSub = leash:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	leashSub:SetPoint("TOP", leashTitle, "BOTTOM", 0, -4);
	leash:SetScript("OnUpdate", function()
		this.left = (this.left or 0) - arg1;
		if ( this.left <= 0 ) then
			this:Hide();
		else
			this:SetAlpha(math.min(1, this.left / 0.5));
		end
	end);

	local function ShowLeash(distance, radius, slow)
		if ( distance > radius ) then
			leashTitle:SetText(L["hoa.addon.you_re_too_far_from_your_party"]);
		else
			leashTitle:SetText(L["hoa.addon.you_re_straying_too_far_from_your_party"]);
		end
		if ( slow > 0 ) then
			leashSub:SetText(L("hoa.addon.slowed_by_1_return_to_your_party", slow));
		else
			leashSub:SetText(L["hoa.addon.return_to_your_party"]);
		end
		leash.left = 1.5;
		leash:SetAlpha(1);
		leash:Show();
	end

	local DOWN_WIDTH = 360;
	local DOWN_PADDING = 48;
	local down = CreateFrame("Frame", "VanillaBonkCoopDown", UIParent);
	down:SetWidth(DOWN_WIDTH);
	down:SetHeight(64);
	down:EnableMouse(true);
	down:SetPoint("CENTER", UIParent, "CENTER", 0, 120);
	DarkBackdrop(down);
	down:Hide();
	local downTitle = down:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	downTitle:SetPoint("TOP", down, "TOP", 0, -12);
	local downBar = CreateFrame("StatusBar", nil, down);
	downBar:SetWidth(300);
	downBar:SetHeight(10);
	downBar:SetPoint("TOP", downTitle, "BOTTOM", 0, -10);
	downBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	downBar:SetMinMaxValues(0, 100);
	local downBarBack = downBar:CreateTexture(nil, "BACKGROUND");
	downBarBack:SetAllPoints(downBar);
	downBarBack:SetTexture(1, 1, 1, 0.12);
	local downOkay = CreateFrame("Button", "VanillaBonkCoopDownOkay", down, "UIPanelButtonTemplate");
	downOkay:SetWidth(110);
	downOkay:SetHeight(24);
	downOkay:SetPoint("BOTTOM", down, "BOTTOM", 0, 12);
	downOkay:SetText(L["hoa.addon.ok"]);
	downOkay:SetScript("OnClick", function()
		Coop.outSeen = 1;
		down:Hide();
	end);
	downOkay:Hide();

	local deadNote = UIParent:CreateFontString("VanillaBonkCoopDeadNote", "OVERLAY", "GameFontNormalLarge");
	deadNote:SetTextColor(1, 0.82, 0);
	deadNote:SetText(L["hoa.addon.you_died"]);
	deadNote:Hide();

	local function ShowDeadNote(shown)
		if ( not shown ) then
			deadNote:Hide();
			return;
		end
		local plate = VanillaBonkHeroBar and VanillaBonkHeroBar.levelPlate;
		deadNote:ClearAllPoints();
		if ( plate ) then
			deadNote:SetPoint("BOTTOMLEFT", plate, "TOPRIGHT", 4, 2);
		else
			deadNote:SetPoint("BOTTOM", UIParent, "BOTTOM", 60, 120);
		end
		deadNote:Show();
	end

	local WATCH_BUTTON_SIZE = 26;
	local watchBar = CreateFrame("Frame", "VanillaBonkCoopWatch", UIParent);
	watchBar:SetWidth(240);
	watchBar:SetHeight(WATCH_BUTTON_SIZE);
	watchBar:Hide();
	local watchName = watchBar:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	watchName:SetPoint("CENTER", watchBar, "CENTER", 0, 0);

	local function WatchButton(direction, texture, point)
		local button = CreateFrame("Button", nil, watchBar);
		button:SetWidth(WATCH_BUTTON_SIZE);
		button:SetHeight(WATCH_BUTTON_SIZE);
		button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-"..texture.."-Up");
		button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-"..texture.."-Down");
		button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD");
		button:SetPoint(point, watchBar, point, 0, 0);
		button:SetScript("OnClick", function()
			SendChatMessage(".bonk watchnext "..direction, "SAY");
		end);
	end
	WatchButton("prev", "PrevPage", "LEFT");
	WatchButton("next", "NextPage", "RIGHT");

	local function ShowWatchChoice(name, choices)
		if ( choices < 2 or name == "" ) then
			watchBar:Hide();
			return;
		end
		watchName:SetText(L("hoa.addon.watching_1", name));
		watchBar:ClearAllPoints();
		if ( VanillaBonkHeroBar ) then
			watchBar:SetPoint("BOTTOM", VanillaBonkHeroBar, "TOP", 0, 8);
		else
			watchBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140);
		end
		watchBar:Show();
	end

	local partySkulls = {};

	local function PartySkull(index)
		if ( partySkulls[index] ) then
			return partySkulls[index];
		end
		local frame = getglobal("PartyMemberFrame"..index);
		local portrait = getglobal("PartyMemberFrame"..index.."Portrait");
		if ( not frame or not portrait ) then
			return nil;
		end
		local skull = CreateFrame("Frame", nil, frame);
		skull:SetFrameLevel(frame:GetFrameLevel() + 4);
		skull:SetWidth(20);
		skull:SetHeight(20);
		local health = getglobal("PartyMemberFrame"..index.."HealthBar");
		if ( health ) then
			skull:SetPoint("LEFT", health, "RIGHT", 1, -4);
		else
			skull:SetAllPoints(portrait);
		end
		skull.icon = skull:CreateTexture(nil, "OVERLAY");
		skull.icon:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull");
		skull.icon:SetAllPoints(skull);
		skull.seconds = skull:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
		skull.seconds:SetTextColor(1, 0.3, 0.25);
		skull.seconds:SetPoint("LEFT", skull, "RIGHT", 3, 0);
		skull:Hide();
		partySkulls[index] = skull;
		return skull;
	end

	local function ShowPartySkulls(entries)
		local byName = {};
		for _, entry in entries do
			byName[entry.name] = entry;
		end
		for index = 1, 4 do
			local entry = UnitExists("party"..index) and byName[UnitName("party"..index)];
			local skull = entry and PartySkull(index) or partySkulls[index];
			if ( skull and entry ) then
				skull.seconds:SetText(entry.spectator and "" or entry.seconds);
				skull:Show();
			elseif ( skull ) then
				skull:Hide();
			end
		end
	end

	local function ReadDowned(list)
		local entries = {};
		if ( not list or list == "" ) then
			return entries;
		end
		for _, entry in Split(list, ",") do
			local fields = Split(entry, ":");
			table.insert(entries, { name = fields[1], seconds = tonumber(fields[2]) or 0, progress = tonumber(fields[3]) or 0, spectator = fields[4] == "1", reviving = fields[5] == "1" });
		end
		return entries;
	end

	local function ShowDowned(entries)
		local me = UnitName("player");
		local mine;
		local reviving;
		for _, entry in entries do
			if ( entry.name == me ) then
				mine = entry;
			elseif ( not entry.spectator and entry.reviving ) then
				reviving = entry;
			end
		end
		ShowPartySkulls(entries);
		Coop.downed = mine and 1 or nil;
		if ( not mine or not mine.spectator ) then
			Coop.outSeen = nil;
		end
		ShowDeadNote(mine);
		if ( mine and mine.spectator ) then
			downTitle:SetText(L["hoa.addon.you_re_out_for_this_stage_your_party_fights_on"]);
			down:SetWidth(math.max(DOWN_WIDTH, downTitle:GetStringWidth() + DOWN_PADDING));
			downBar:Hide();
			downOkay:Show();
			down:SetHeight(80);
			if ( Coop.outSeen ) then
				down:Hide();
			else
				down:Show();
			end
		elseif ( mine ) then
			downTitle:SetText(L("hoa.addon.you_re_downed_bleeding_out_in_1_s", mine.seconds));
			down:SetWidth(math.max(DOWN_WIDTH, downTitle:GetStringWidth() + DOWN_PADDING));
			downBar:SetStatusBarColor(1, 0.35, 0.25);
			downBar:SetValue(math.min(100, mine.seconds * 100 / 30));
			downBar:Show();
			downOkay:Hide();
			down:SetHeight(64);
			down:Show();
		else
			down:Hide();
		end
		if ( VanillaBonkUI.SetReviveBar ) then
			if ( mine and not mine.spectator and mine.reviving ) then
				VanillaBonkUI.SetReviveBar(L["hoa.addon.being_revived"], mine.progress / 100);
			elseif ( reviving and UnitIsDeadOrGhost("player") == nil ) then
				VanillaBonkUI.SetReviveBar(L("hoa.addon.reviving_1", reviving.name), reviving.progress / 100);
			else
				VanillaBonkUI.SetReviveBar(nil);
			end
		end
	end

	local WAIT_TOTAL = 20;

	local function ShowWait(names, seconds)
		if ( not VanillaBonkUI.SetWaitBar ) then
			return;
		end
		if ( not names or names == "" ) then
			VanillaBonkUI.SetWaitBar(nil);
			return;
		end
		local me = UnitName("player");
		local others = {};
		local mine;
		for _, name in Split(names, ",") do
			if ( name == me ) then
				mine = 1;
			else
				table.insert(others, name);
			end
		end
		if ( mine ) then
			VanillaBonkUI.SetWaitBar(L["hoa.addon.your_party_is_waiting_for_you"], seconds, WAIT_TOTAL);
		else
			VanillaBonkUI.SetWaitBar(L("hoa.addon.waiting_for_1", table.concat(others, ", ")), seconds, WAIT_TOTAL);
		end
	end

	VanillaBonkUI.ListenHoa({
		HOA_COOP_WAIT = function(wait)
			ShowWait(wait.names, tonumber(wait.seconds) or 0);
		end,
		HOA_COOP_WATCH = function(watch)
			ShowWatchChoice(watch.name or "", tonumber(watch.choices) or 0);
		end,
		HOA_COOP_REMOVED = function()
			Call("POST", "/join/removed");
		end,
		HOA_COOP_DOWN = function(down)
			ShowDowned(ReadDowned(down.list));
		end,
		HOA_LEASH = function(leash)
			ShowLeash(tonumber(leash.distance) or 0, tonumber(leash.radius) or 80, tonumber(leash.slow_percent) or 0);
		end,
		HOA_COOP_READY = function(readyCheck)
			local seconds = tonumber(readyCheck.seconds) or 20;
			readyTitle:SetText(readyCheck.text or "");
			readyBar:SetMinMaxValues(0, seconds);
			ready.left = seconds;
			ready:Show();
			PlaySound("ReadyCheck");
		end,
		HOA_COOP_READY_END = function()
			ready:Hide();
		end,
	});
end
