local L = BonkGlueL;

BONK_CLASSES = {
	{ token = "WARRIOR", name = "Warrior", display = L["Warrior"], races = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "ORC", "SCOURGE", "TAUREN", "TROLL" } },
	{ token = "PALADIN", name = "Paladin", display = L["Paladin"], races = { "HUMAN", "DWARF" } },
	{ token = "HUNTER",  name = "Hunter", display = L["Hunter"],  races = { "DWARF", "NIGHTELF", "ORC", "TAUREN", "TROLL" } },
	{ token = "ROGUE",   name = "Rogue", display = L["Rogue"],   races = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "ORC", "SCOURGE", "TROLL" } },
	{ token = "PRIEST",  name = "Priest", display = L["Priest"],  races = { "HUMAN", "DWARF", "NIGHTELF", "SCOURGE", "TROLL" } },
	{ token = "SHAMAN",  name = "Shaman", display = L["Shaman"],  races = { "ORC", "TAUREN", "TROLL" } },
	{ token = "MAGE",    name = "Mage", display = L["Mage"],    races = { "HUMAN", "GNOME", "SCOURGE", "TROLL" } },
	{ token = "WARLOCK", name = "Warlock", display = L["Warlock"], races = { "HUMAN", "GNOME", "ORC", "SCOURGE" } },
	{ token = "DRUID",   name = "Druid", display = L["Druid"],   races = { "NIGHTELF", "TAUREN" } },
};

BONK_RACE_NAMES = {
	HUMAN = "Human", DWARF = "Dwarf", NIGHTELF = "Night Elf", GNOME = "Gnome",
	ORC = "Orc", SCOURGE = "Undead", TAUREN = "Tauren", TROLL = "Troll",
};

BONK_RACE_DISPLAY_NAMES = {
	HUMAN = L["Human"], DWARF = L["Dwarf"], NIGHTELF = L["Night Elf"], GNOME = L["Gnome"],
	ORC = L["Orc"], SCOURGE = L["Undead"], TAUREN = L["Tauren"], TROLL = L["Troll"],
};

BONK_CLASS_COLORS = {
	WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 }, HUNTER = { 0.67, 0.83, 0.45 },
	ROGUE = { 1.0, 0.96, 0.41 }, PRIEST = { 1.0, 1.0, 1.0 }, SHAMAN = { 0.0, 0.44, 0.87 },
	MAGE = { 0.41, 0.8, 0.94 }, WARLOCK = { 0.58, 0.51, 0.79 }, DRUID = { 1.0, 0.49, 0.04 },
};

BONK_CLASS_TOKENS = {};
for _, class in BONK_CLASSES do
	BONK_CLASS_TOKENS[class.name] = class.token;
end

BONK_IRONMAN_TIP = L["This character does not share gold or unlocks with other characters."];

local NUM_STAT_ROWS = 9;
local NUM_SPELL_ROWS = 7;
local NUM_SPECS = 3;
local NUM_CLASS_RACES = 8;
local ROW_STEP = 58;
local IRONMAN_NAME = "Ironmanmode";
local RACES_PER_ROW = 4;
local RACE_COLUMN_STEP = 70;
local RACE_ROW_STEP = 64;
local STARTER_TEXT_WIDTH = 176;
local STARTER_NAME_HEIGHT = 14;
local STARTER_LINE_HEIGHT = 12;

local XML_TEXTS = {
	BonkLoginTitle = L["Hordes of Azeroth"],
	BonkLoginConnectButton = L["Connect"],
	BonkLoginQuitButton = L["Quit"],
	BonkHeroTitle = L["HORDES OF AZEROTH"],
	BonkHeroSubtitle = L["Choose your character"],
	BonkRaceNote = L["Cosmetic only, no racial bonuses"],
	BonkHeroRandomizeButton = L["Random look"],
	BonkHeroIronmanText = L["Ironman mode"],
	BonkClassRacesLabel = L["Races"],
	BonkClassStarterLabel = L["Starts with"],
	BonkSpecNote = L["Just a preview. You don't pick a spec here."],
	BonkHeroRetireButton = L["Delete character"],
	BonkHeroNameLabel = L["Name"],
	BonkHeroQuitButton = L["Quit"],
	BonkHeroWipeButton = L["Wipe account"],
	BonkHeroBackButton = L["Back"],
};

local CUSTOMIZE_LABELS = { L["Skin Color"], L["Face"], L["Hair Style"], L["Hair Color"], L["Facial Hair"] };

local HAIR_STYLE_LABELS = { NORMAL = L["Hair Style"], HORNS = L["Horn Style"] };

local HAIR_COLOR_LABELS = { NORMAL = L["Hair Color"], HORNS = L["Horn Color"] };

local FACIAL_HAIR_LABELS = {
	EARRINGS = L["Earrings"], FEATURES = L["facial feature::Features"], HAIR = L["Hair"], MARKINGS = L["Markings"],
	NORMAL = L["Facial Hair"], PIERCINGS = L["Piercings"], TUSKS = L["Tusks"],
};

local function Flag(condition)
	if ( condition ) then
		return 1;
	end
	return nil;
end

Bonk = {
	classIndex = 1,
	raceIndex = 1,
	sex = 1,
	specIndex = 1,
	customizing = nil,
	heroes = {},
	listLoaded = false,
	reuseList = false,
	creating = nil,
	wiping = nil,
	appliedRace = nil,
	screen = nil,
	refreshing = false,
	sceneDirty = false,
	sceneDelay = 0,
	startPicked = false,
	loginTried = false,
	reachedServer = false,
};

function BonkLogin_Connect()
	if ( HOA_LOGIN_ACCOUNT ) then
		BONK_ACCOUNT = HOA_LOGIN_ACCOUNT;
		BONK_PASSWORD = HOA_LOGIN_PASSWORD;
	end
	local gate, coopAccount, coopPassword;
	if ( HoaCoop_GetGate ) then
		gate, coopAccount, coopPassword = HoaCoop_GetGate();
	end
	if ( gate ) then
		BonkLoginStatus:SetText(L["Connecting to host..."]);
		DefaultServerLogin(coopAccount, coopPassword);
		return;
	end
	BonkLoginStatus:SetText(L["Connecting..."]);
	DefaultServerLogin(BONK_ACCOUNT, BONK_PASSWORD);
end

local OriginalAccountLoginOnShow = AccountLogin_OnShow;
function AccountLogin_OnShow()
	OriginalAccountLoginOnShow();
	BonkHeroFrame:Hide();

	Bonk.listLoaded = false;
	Bonk.reuseList = false;
	Bonk.startPicked = false;
	Bonk.classIndex = 1;
	Bonk.raceIndex = 1;
	Bonk.specIndex = 1;
	Bonk.customizing = nil;
	Bonk.creating = nil;
	Bonk.wiping = nil;
	Bonk.heroes = {};

	if ( not BONK_ACCOUNT or not EULAAccepted() or not TOSAccepted() ) then
		BonkLoginFrame:Hide();
		return;
	end

	BonkLogin_Begin();
end

function BonkLogin_Begin()
	AccountLoginUI:Hide();
	AccountLoginAccountEdit:ClearFocus();
	AccountLoginPasswordEdit:ClearFocus();
	BonkLoginFrame:Show();
	BonkLoginStatus:SetText("");

	if ( not Bonk.loginTried ) then
		Bonk.loginTried = true;
		BonkLogin_Connect();
	end
end

local OriginalShowUserAgreements = AccountLogin_ShowUserAgreements;
function AccountLogin_ShowUserAgreements()
	OriginalShowUserAgreements();
	if ( BONK_ACCOUNT and EULAAccepted() and TOSAccepted() and not TOSFrame:IsVisible() and AccountLogin:IsVisible() ) then
		BonkLogin_Begin();
	end
end

local OriginalAccountLoginOnKeyDown = AccountLogin_OnKeyDown;
function AccountLogin_OnKeyDown()
	if ( not BonkLoginFrame:IsVisible() ) then
		OriginalAccountLoginOnKeyDown();
	elseif ( arg1 == "ENTER" ) then
		BonkLogin_Connect();
	elseif ( arg1 == "ESCAPE" ) then
		AccountLogin_Exit();
	elseif ( arg1 == "PRINTSCREEN" ) then
		Screenshot();
	end
end

local OriginalSetGlueScreen = SetGlueScreen;
function SetGlueScreen(name)
	Bonk.screen = name;
	if ( name ~= "charselect" and name ~= "charcreate" ) then
		BonkHeroFrame:Hide();
	end
	OriginalSetGlueScreen(name);
end

local OriginalCharacterSelectOnShow = CharacterSelect_OnShow;
function CharacterSelect_OnShow()
	Bonk.reachedServer = true;
	local requestList = GetCharacterListUpdate;
	if ( Bonk.reuseList and Bonk.listLoaded and not Bonk.creating ) then
		GetCharacterListUpdate = UpdateCharacterList;
	end
	Bonk.reuseList = false;
	OriginalCharacterSelectOnShow();
	GetCharacterListUpdate = requestList;

	CharacterSelectUI:Hide();
	BonkHeroFrame:Show();

	if ( not Bonk.listLoaded ) then
		Bonk.sceneDelay = 1.0;
	end
	BonkHero_Refresh();
end

local BONK_REALM_CATEGORY = 1;

local OriginalGlueParentOnEvent = GlueParent_OnEvent;
function GlueParent_OnEvent(event)
	if ( event == "GET_PREFERRED_REALM_INFO" and BONK_ACCOUNT ) then
		SetPreferredInfo(BONK_REALM_CATEGORY, nil, nil);
		return;
	end
	OriginalGlueParentOnEvent(event);
end

local OriginalCharacterSelectOnEvent = CharacterSelect_OnEvent;
function CharacterSelect_OnEvent()
	if ( event == "SUGGEST_REALM" and BONK_ACCOUNT ) then
		SetGlueScreen("charselect");
		ChangeRealm(arg1, arg2);
		return;
	end
	OriginalCharacterSelectOnEvent();
	if ( event == "CHARACTER_LIST_UPDATE" ) then
		BonkHero_OnCharacterList();
	elseif ( event == "UPDATE_SELECTED_CHARACTER" and Bonk.listLoaded ) then
		local hero = Bonk.heroes[BONK_CLASSES[Bonk.classIndex].token];
		if ( hero and arg1 ~= hero.index ) then
			Bonk.sceneDirty = true;
		end
	end
end

function CharacterSelect_OnKeyDown()
	BonkHero_OnKeyDown();
end

local OriginalCharacterCreateOnShow = CharacterCreate_OnShow;
function CharacterCreate_OnShow()
	OriginalCharacterCreateOnShow();
	CharacterCreateFrame:Hide();
	BonkHeroFrame:Show();
	Bonk.appliedRace = nil;
	BonkHero_ApplyNewHero();
end

function CharacterCreate_OnKeyDown()
	BonkHero_OnKeyDown();
end

local OriginalGlueDialogOnEvent = GlueDialog_OnEvent;
function GlueDialog_OnEvent()
	local text = arg1;
	if ( event == "OPEN_STATUS_DIALOG" ) then
		text = arg2;
	end
	local success = text == CHAR_DELETE_SUCCESS or text == CHAR_CREATE_SUCCESS;
	local failed = not success and ((event == "OPEN_STATUS_DIALOG" and arg1 == "OKAY") or (event == "UPDATE_STATUS_DIALOG" and arg2));
	if ( Bonk.creating and failed ) then
		Bonk.creating = nil;
		BonkHero_SetStatus("");
	end
	local wipeRefused = Bonk.wiping and failed and Bonk.wiping.step == "create";
	if ( Bonk.wiping and failed ) then
		BonkHero_StopWipe(L["The account was not wiped."]);
	end
	OriginalGlueDialogOnEvent();

	local shown = GlueDialogText:GetText();
	local noServer = shown == RESPONSE_FAILED_TO_CONNECT or shown == LOGIN_FAILED or shown == LOGIN_SERVER_DOWN or shown == REALM_LIST_FAILED
		or shown == RESPONSE_DISCONNECTED or shown == DISCONNECTED;
	if ( noServer and BonkCoop_IsJoined() and not BonkCoop.leaving ) then
		BonkCoop_LostHost();
	elseif ( noServer and not Bonk.reachedServer ) then
		GlueDialogText:SetText(L["The game's server isn't running. Close the game and start Hordes of Azeroth with HoALauncher.exe in your World of Warcraft folder."]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
		BonkLoginStatus:SetText("");
	elseif ( noServer ) then
		GlueDialogText:SetText(L["The game's server stopped. Close the game and start Hordes of Azeroth again with HoALauncher.exe. If it keeps happening, click Report a bug in the launcher."]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
		BonkLoginStatus:SetText("");
	elseif ( BonkCoop_IsJoined() and BonkCoop_RefusalNote(shown) ) then
		GlueDialog:Hide();
		BonkCoop_RefusedAtLogin(BonkCoop_RefusalNote(shown));
	elseif ( shown == CHAR_LOGIN_LOCKED_FOR_TRANSFER ) then
		GlueDialogText:SetText(L["This character is in a co-op party. Leave the party first."]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
	elseif ( wipeRefused ) then
		GlueDialogText:SetText(L["The account was not wiped because a character is still left. Try again."]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
	elseif ( Bonk.wiping and success and event == "UPDATE_STATUS_DIALOG" and arg2 ) then
		GlueDialog:Hide();
	end
end

local OriginalGlueDialogOnClick = GlueDialog_OnClick;
function GlueDialog_OnClick(index)
	local which = GlueDialog.which;
	OriginalGlueDialogOnClick(index);
	if ( Bonk.creating ) then
		Bonk.creating = nil;
		BonkHero_SetStatus("");
	end
	if ( Bonk.wiping and which ~= "BONK_WIPE" ) then
		BonkHero_StopWipe(L["Wipe stopped. Some characters may already be gone."]);
	end
end

GlueDialogTypes["BONK_QUIT"] = {
	text = L["Quit Hordes of Azeroth?"],
	button1 = L["Yes"],
	button2 = L["No"],
	OnAccept = function()
		QuitGame();
	end,
	OnCancel = function()
	end,
};

GlueDialogTypes["BONK_RETIRE"] = {
	text = "",
	button1 = L["Yes"],
	button2 = L["No"],
	showAlert = 1,
	OnAccept = function()
		DeleteCharacter(GlueDialog.data);
	end,
	OnCancel = function()
	end,
};

GlueDialogTypes["BONK_WIPE"] = {
	text = L["Are you sure? This deletes all your characters and all account progress: gold, Darkmoon Tickets, upgrades, Sayge's Fortunes, quests and Mastery. It cannot be undone."],
	button1 = L["Yes"],
	button2 = L["No"],
	showAlert = 1,
	OnAccept = function()
		BonkHero_StartWipe();
	end,
	OnCancel = function()
	end,
};

local function FormatGold(copper)
	copper = copper or 0;
	local gold = floor(copper / 10000);
	local silver = floor(mod(copper, 10000) / 100);
	local text = format("|cffeda55f%s|r", L("copper coin::{1}c", format("%d", mod(copper, 100))));
	if ( gold > 0 or silver > 0 ) then
		text = format("|cffc7c7cf%s|r ", L("silver coin::{1}s", format("%d", silver)))..text;
	end
	if ( gold > 0 ) then
		text = format("|cffffd700%s|r ", L("gold coin::{1}g", format("%d", gold)))..text;
	end
	return text;
end

local function FormatTime(seconds)
	seconds = seconds or 0;
	local hours = floor(seconds / 3600);
	local minutes = floor(mod(seconds, 3600) / 60);
	if ( hours > 0 ) then
		return format("%d:%02d:%02d", hours, minutes, mod(seconds, 60));
	end
	return format("%d:%02d", minutes, mod(seconds, 60));
end

local function CurrentClass()
	return BONK_CLASSES[Bonk.classIndex];
end

local function CurrentHero()
	return Bonk.heroes[CurrentClass().token];
end

local function NewHeroRace()
	return CurrentClass().races[Bonk.raceIndex];
end

local function HeroStats(hero)
	if ( BONK_STATS and BONK_STATS.heroes ) then
		return BONK_STATS.heroes[hero.name];
	end
	return nil;
end

local function SetTexCoords(texture, coords)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
end

local function RaceIconCoords(race, sex)
	local gender = "MALE";
	if ( sex == 2 ) then
		gender = "FEMALE";
	end
	return RACE_ICON_TCOORDS[race.."_"..gender];
end

local function SexName(sex)
	if ( sex == 2 ) then
		return L["Female"];
	end
	return L["Male"];
end

local function SetClassColor(fontString, token)
	local color = BONK_CLASS_COLORS[token];
	fontString:SetTextColor(color[1], color[2], color[3]);
end

local function IsSelectable(class)
	return not class.locked or Bonk.heroes[class.token];
end

local function PlayableCount()
	local playable = 0;
	for _, class in BONK_CLASSES do
		if ( not class.locked ) then
			playable = playable + 1;
		end
	end
	return playable;
end

local function HeroCount()
	local count = 0;
	for _, class in BONK_CLASSES do
		if ( Bonk.heroes[class.token] ) then
			count = count + 1;
		end
	end
	return count;
end

function BonkHero_SetStatus(text)
	BonkHeroStatus:SetText(text);
end

function BonkHero_OnLoad()
	for index, class in BONK_CLASSES do
		local row = getglobal("BonkCharRow"..index);
		row:SetPoint("TOPLEFT", "BonkListPanel", "TOPLEFT", 20, -50 - (index - 1) * ROW_STEP);
		SetTexCoords(getglobal(row:GetName().."Icon"), CLASS_ICON_TCOORDS[class.token]);
	end

	for index = 1, NUM_STAT_ROWS do
		getglobal("BonkHeroStat"..index):SetPoint("TOPLEFT", "BonkHeroRecordFrame", "TOPLEFT", 0, -(index - 1) * 22);
	end

	BonkClassStarterName:SetWidth(STARTER_TEXT_WIDTH);
	BonkClassStarterName:SetHeight(STARTER_NAME_HEIGHT);
	BonkClassStarterLine:SetWidth(STARTER_TEXT_WIDTH);
	BonkClassStarterLine:SetHeight(STARTER_LINE_HEIGHT);

	BonkHeroGenderButton1Icon:SetTexCoord(0, 0.5, 0, 1.0);
	BonkHeroGenderButton2Icon:SetTexCoord(0.5, 1.0, 0, 1.0);
	BonkHeroGenderButton1Label:SetText(L["Male"]);
	BonkHeroGenderButton2Label:SetText(L["Female"]);
	BonkRaceBoxCaption:SetText(L["Race"]);
	BonkGenderBoxCaption:SetText(L["Gender"]);
	BonkFeatureBoxCaption:SetText(L["Features"]);
	BonkListPanelTitle:SetText(L["Characters"]);
	BonkAppearPanelTitle:SetText(L["Appearance"]);

	for name, text in XML_TEXTS do
		getglobal(name):SetText(text);
	end

	BonkHero_UpdateCount();
end

function BonkHero_UpdateCount()
	BonkListCount:SetText(L("{1} of {2} classes created", HeroCount(), PlayableCount()));
end

function BonkHero_ToggleIronman()
	Bonk.ironman = BonkHeroIronman:GetChecked() and true or nil;
	if ( Bonk.ironman ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
end

function BonkHero_CustomizeLabel(id)
	return CUSTOMIZE_LABELS[id] or getglobal("CHAR_CUSTOMIZATION"..id.."_DESC");
end

function BonkHero_ShowIronmanTip(owner)
	BonkHero_ShowTip(owner, L["Ironman mode"], BONK_IRONMAN_TIP);
end

function BonkHero_ShowTip(owner, title, text)
	BonkTipTitle:SetText(title);
	BonkTipText:SetText(text);
	BonkTip:SetHeight(BonkTipTitle:GetHeight() + BonkTipText:GetHeight() + 24);
	BonkTip:ClearAllPoints();
	if ( owner:GetLeft() and owner:GetLeft() > GlueParent:GetWidth() / 2 ) then
		BonkTip:SetPoint("BOTTOMRIGHT", owner, "TOPLEFT", 0, 0);
	else
		BonkTip:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 0, 0);
	end
	BonkTip:Show();
end

function BonkHero_ShowSpellTip(frame)
	if ( frame.spell ) then
		BonkHero_ShowTip(frame, frame.spell.name, frame.spell.tip);
	end
end

function BonkHero_ShowRaceTip(frame)
	if ( frame.race ) then
		BonkHero_ShowTip(frame, BONK_RACE_DISPLAY_NAMES[frame.race], "");
	end
end

function BonkHero_ReadHeroes()
	Bonk.heroes = {};
	local unknown;
	for index = 1, GetNumCharacters() do
		local name, race, class, level, zone, fileString, gender = GetCharacterInfo(index);
		local classToken = BONK_CLASS_TOKENS[class];
		if ( name and not (classToken and fileString) ) then
			unknown = name.." ("..tostring(class)..", "..tostring(fileString)..")";
		end
		if ( name and classToken and fileString and not Bonk.heroes[classToken] ) then
			local sex = 1;
			if ( gender and gender ~= 0 ) then
				sex = 2;
			end
			Bonk.heroes[classToken] = { index = index, name = name, race = strupper(fileString), level = level, sex = sex };
		end
	end
	if ( unknown ) then
		BonkHero_SetStatus(L("Could not read the class of {1}.", unknown));
	end
end

local function SelectClassToken(classToken)
	for index, class in BONK_CLASSES do
		if ( class.token == classToken ) then
			Bonk.classIndex = index;
		end
	end
end

function BonkHero_AccountKey()
	return strupper(BONK_ACCOUNT or "");
end

function BonkHero_OnCharacterList()
	if ( BONK_STATS_ACCOUNTS ) then
		BONK_STATS = BONK_STATS_ACCOUNTS[BonkHero_AccountKey()];
	end
	BonkHero_ReadHeroes();

	if ( Bonk.wiping ) then
		Bonk.listLoaded = true;
		if ( Bonk.wiping.step == "create" ) then
			BonkHero_FinishWipe();
		else
			Bonk.wiping.sent = nil;
			Bonk.wiping.wait = BONK_WIPE_GAP;
			BonkHero_UpdateRoster();
		end
		return;
	end

	if ( Bonk.creating and Bonk.creating.ironmanSent ) then
		Bonk.creating.ironmanSent = nil;
		BonkHero_CreateCharacter();
		return;
	end

	if ( Bonk.creating ) then
		local hero = Bonk.heroes[Bonk.creating.class];
		if ( hero ) then
			Bonk.creating = nil;
			Bonk.customizing = nil;
			BonkHeroNameEdit:SetText("");
			BonkHero_EnterWorld(hero);
			return;
		end
	end

	Bonk.listLoaded = true;
	local count = GetNumCharacters();
	if ( not Bonk.startPicked and count > 0 ) then
		Bonk.startPicked = true;
		local start;
		for index = 1, count do
			if ( BONK_STATS and BONK_STATS.lastHero and GetCharacterInfo(index) == BONK_STATS.lastHero ) then
				start = index;
			end
		end
		if ( not start and CharacterSelect.selectedIndex and CharacterSelect.selectedIndex > 0 and CharacterSelect.selectedIndex <= count ) then
			start = CharacterSelect.selectedIndex;
		end
		if ( not start ) then
			start = 1;
		end
		local name, race, class = GetCharacterInfo(start);
		if ( BONK_CLASS_TOKENS[class] ) then
			SelectClassToken(BONK_CLASS_TOKENS[class]);
		end
	end

	BonkHero_Refresh();
end

function BonkHero_Refresh()
	if ( Bonk.refreshing ) then
		return;
	end
	Bonk.refreshing = true;
	if ( CurrentHero() ) then
		Bonk.customizing = nil;
	end
	BonkHero_UpdateRoster();
	BonkHero_UpdateInfo();
	BonkHero_UpdateCount();
	BonkHero_UpdateControls();
	Bonk.refreshing = false;

	Bonk.sceneDirty = true;
end

function BonkHero_UpdateRoster()
	for index, class in BONK_CLASSES do
		local row = getglobal("BonkCharRow"..index);
		local icon = getglobal(row:GetName().."Icon");
		local name = getglobal(row:GetName().."Name");
		local sub = getglobal(row:GetName().."Sub");
		local hero = Bonk.heroes[class.token];
		if ( index == Bonk.classIndex ) then
			getglobal(row:GetName().."Selected"):Show();
		else
			getglobal(row:GetName().."Selected"):Hide();
		end
		if ( hero ) then
			local stats = HeroStats(hero) or {};
			icon:SetVertexColor(1.0, 1.0, 1.0);
			name:SetText(hero.name);
			name:SetTextColor(1.0, 0.82, 0);
			sub:SetText(L("Mastery {1} {2} {3}", format("%d", stats.mastery or 0), BONK_RACE_DISPLAY_NAMES[hero.race] or "", class.display));
			sub:SetTextColor(1.0, 1.0, 1.0);
		elseif ( class.locked ) then
			icon:SetVertexColor(0.25, 0.25, 0.25);
			name:SetText(class.display);
			name:SetTextColor(0.4, 0.4, 0.4);
			sub:SetText(L["Locked"]);
			sub:SetTextColor(0.4, 0.4, 0.4);
		else
			icon:SetVertexColor(0.4, 0.4, 0.4);
			name:SetText(class.display);
			name:SetTextColor(0.55, 0.55, 0.55);
			sub:SetText(L("Create a {1}", class.display));
			sub:SetTextColor(0.5, 0.5, 0.5);
		end
	end
end

function BonkHero_UpdateControls()
	local hero = CurrentHero();
	if ( hero ) then
		BonkHeroPlayButton:SetText(L["Play"]);
	elseif ( Bonk.customizing ) then
		BonkHeroPlayButton:SetText(L["Create"]);
	else
		BonkHeroPlayButton:SetText(L("Create {1}", CurrentClass().display));
	end

	if ( Bonk.customizing ) then
		BonkListPanel:Hide();
		BonkAppearPanel:Show();
		BonkHeroNameEdit:Show();
		BonkHeroQuitButton:Hide();
		BonkHeroWipeButton:Hide();
		BonkHeroBackButton:Show();
		BonkHeroSubtitle:SetText(L("Create your {1}", CurrentClass().display));
		BonkHeroPreview:SetText("");
	else
		BonkAppearPanel:Hide();
		BonkListPanel:Show();
		BonkHeroNameEdit:Hide();
		BonkHeroNameEdit:ClearFocus();
		BonkHeroBackButton:Hide();
		BonkHeroQuitButton:Show();
		BonkHeroWipeButton:Show();
		BonkHeroSubtitle:SetText(L["Choose your character"]);
		if ( hero ) then
			BonkHeroPreview:SetText("");
		else
			BonkHeroPreview:SetText(L("Preview: {1}", BONK_RACE_DISPLAY_NAMES[NewHeroRace()]));
		end
	end
end

local function ShowSpellRow(row, spell, tag)
	row.spell = spell;
	getglobal(row:GetName().."Icon"):SetTexture(spell.icon);
	getglobal(row:GetName().."Name"):SetText(spell.name);
	getglobal(row:GetName().."Line"):SetText(spell.line);
	local tagText = getglobal(row:GetName().."Tag");
	if ( tagText ) then
		tagText:SetText(tag or "");
	end
	row:Show();
end

function BonkHero_UpdateClassInfo(class, sex)
	local info = BONK_CLASS_INFO[class.token];
	BonkClassFrame:Show();
	if ( not info ) then
		BonkClassBlurb:SetText("");
		return;
	end

	BonkClassBlurb:SetText(info.blurb);

	for index = 1, NUM_CLASS_RACES do
		local frame = getglobal("BonkClassRace"..index);
		local race = class.races[index];
		if ( race ) then
			frame.race = race;
			SetTexCoords(getglobal(frame:GetName().."Icon"), RaceIconCoords(race, sex));
			frame:Show();
		else
			frame:Hide();
		end
	end

	if ( info.starter ) then
		ShowSpellRow(BonkClassStarter, info.starter);
		BonkClassStarterLabel:Show();
	else
		BonkClassStarter:Hide();
		BonkClassStarterLabel:Hide();
	end

	local specCount = getn(info.specs);
	if ( Bonk.specIndex > specCount ) then
		Bonk.specIndex = 1;
	end
	for index = 1, NUM_SPECS do
		local button = getglobal("BonkSpecButton"..index);
		local spec = info.specs[index];
		if ( spec ) then
			getglobal(button:GetName().."Icon"):SetTexture(spec.icon);
			local label = getglobal(button:GetName().."Label");
			label:SetText(spec.name);
			if ( index == Bonk.specIndex ) then
				label:SetTextColor(1.0, 0.82, 0);
				getglobal(button:GetName().."Icon"):SetVertexColor(1.0, 1.0, 1.0);
			else
				label:SetTextColor(0.78, 0.75, 0.68);
				getglobal(button:GetName().."Icon"):SetVertexColor(0.6, 0.6, 0.6);
			end
			button:SetChecked(Flag(index == Bonk.specIndex));
			button:Show();
		else
			button:Hide();
		end
	end

	local spec = info.specs[Bonk.specIndex];
	local rows = 0;
	if ( spec ) then
		BonkClassSpecText:SetText(spec.text);
		for _, spell in ipairs(spec.spells) do
			if ( rows < NUM_SPELL_ROWS ) then
				rows = rows + 1;
				ShowSpellRow(getglobal("BonkSpellRow"..rows), spell);
			end
		end
	else
		BonkClassSpecText:SetText("");
	end
	for _, spell in ipairs(info.shared) do
		if ( rows < NUM_SPELL_ROWS ) then
			rows = rows + 1;
			ShowSpellRow(getglobal("BonkSpellRow"..rows), spell, L["every spec"]);
		end
	end
	for index = rows + 1, NUM_SPELL_ROWS do
		getglobal("BonkSpellRow"..index):Hide();
	end
end

function BonkHero_UpdateInfo()
	local class = CurrentClass();
	local hero = CurrentHero();
	SetTexCoords(BonkInfoIcon, CLASS_ICON_TCOORDS[class.token]);

	if ( hero ) then
		BonkInfoPanelTitle:SetText(L["Stats"]);
		BonkHeroName:SetText(hero.name);
		SetClassColor(BonkHeroName, class.token);
		local stats = HeroStats(hero) or {};
		local detail;
		if ( stats.ironman ) then
			detail = L("Mastery {1} {2} {3} (Ironman)", format("%d", stats.mastery or 0), BONK_RACE_DISPLAY_NAMES[hero.race] or "", class.display);
		else
			detail = L("Mastery {1} {2} {3}", format("%d", stats.mastery or 0), BONK_RACE_DISPLAY_NAMES[hero.race] or "", class.display);
		end
		BonkHeroDetail:SetText(detail);
		BonkHeroRetireButton:Show();
		BonkClassFrame:Hide();
		BonkHeroRecordFrame:Show();
		BonkHero_UpdateRecord(hero);
		return;
	end

	if ( Bonk.raceIndex > getn(class.races) ) then
		Bonk.raceIndex = 1;
	end
	BonkInfoPanelTitle:SetText(L["Class"]);
	BonkHeroName:SetText(class.display);
	SetClassColor(BonkHeroName, class.token);
	if ( Bonk.customizing ) then
		BonkHeroDetail:SetText(BONK_RACE_DISPLAY_NAMES[NewHeroRace()].." - "..SexName(Bonk.sex));
	else
		BonkHeroDetail:SetText(L["|cff808080Not created yet|r"]);
	end
	BonkHeroRetireButton:Hide();
	BonkHeroRecordFrame:Hide();
	BonkHero_UpdateClassInfo(class, Bonk.sex);
	BonkHero_UpdateAppearance(class);
end

function BonkHero_UpdateAppearance(class)
	BonkHeroIronman:SetChecked(Flag(Bonk.ironman));
	local raceCount = getn(class.races);
	local rows = ceil(raceCount / RACES_PER_ROW);
	for index = 1, 8 do
		local button = getglobal("BonkHeroRaceButton"..index);
		local race = class.races[index];
		if ( race ) then
			local rowIndex = floor((index - 1) / RACES_PER_ROW);
			local inRow = RACES_PER_ROW;
			if ( rowIndex == rows - 1 ) then
				inRow = raceCount - rowIndex * RACES_PER_ROW;
			end
			local column = mod(index - 1, RACES_PER_ROW);
			local x = (column - (inRow - 1) / 2) * RACE_COLUMN_STEP;
			button:ClearAllPoints();
			button:SetPoint("TOP", "BonkRaceBox", "TOP", x, -10 - rowIndex * RACE_ROW_STEP);
			local icon = getglobal(button:GetName().."Icon");
			icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races");
			SetTexCoords(icon, RaceIconCoords(race, Bonk.sex));
			getglobal(button:GetName().."Label"):SetText(BONK_RACE_DISPLAY_NAMES[race]);
			button:SetChecked(Flag(index == Bonk.raceIndex));
			button:Show();
		else
			button:Hide();
		end
	end
	BonkRaceBox:SetHeight(rows * RACE_ROW_STEP + 10);
	BonkHeroGenderButton1:SetChecked(Flag(Bonk.sex == 1));
	BonkHeroGenderButton2:SetChecked(Flag(Bonk.sex == 2));
end

function BonkLevelName(level)
	level = tonumber(level) or 0;
	if ( level <= 0 ) then
		return "-";
	elseif ( level <= 4 ) then
		return L("level name::{1} {2}", L["Normal"], level);
	elseif ( level <= 9 ) then
		return L("level name::{1} {2}", L["Heroic"], level - 4);
	end
	return L("level name::{1} {2}", L["Mythic"], level - 9);
end

local function FormatPlayed(seconds)
	if ( not seconds or seconds <= 0 ) then
		return "-";
	end
	local hours = floor(seconds / 3600);
	local minutes = floor(mod(seconds, 3600) / 60);
	if ( hours > 0 ) then
		return L("hours and minutes::{1}h {2}m", hours, minutes);
	end
	return L("minutes::{1}m", minutes);
end

local function SetStatRow(index, label, value)
	getglobal("BonkHeroStat"..index.."Label"):SetText(label);
	getglobal("BonkHeroStat"..index.."Value"):SetText(value);
end

function BonkHero_UpdateRecord(hero)
	local stats = HeroStats(hero) or {};
	local runs = stats.runs or 0;

	SetStatRow(1, L["Runs"], runs);
	SetStatRow(2, L["Time played"], FormatPlayed(stats.played));
	SetStatRow(3, L["Best level"], BonkLevelName(stats.bestLevel));
	SetStatRow(4, L["Longest run"], stats.bestTime and FormatTime(stats.bestTime) or "-");
	SetStatRow(5, L["Enemies slain"], stats.kills or 0);
	SetStatRow(6, L["Gold earned"], FormatGold(stats.goldEarned));
	if ( stats.items and stats.items > 0 ) then
		SetStatRow(7, L["Gear"], L("{1} items, item level {2}", stats.items, stats.itemLevel or 0));
	else
		SetStatRow(7, L["Gear"], "-");
	end
	SetStatRow(8, L["Gear value"], FormatGold(stats.gearValue));
	if ( stats.ironman ) then
		SetStatRow(9, L["Gold"], FormatGold(stats.gold));
		BonkHeroStat9:Show();
	else
		BonkHeroStat9:Hide();
	end

	if ( not HeroStats(hero) ) then
		BonkHeroRecordNote:SetText(L("The record updates when {1} logs out.", hero.name));
	elseif ( runs == 0 ) then
		BonkHeroRecordNote:SetText(L("{1} has not done a run yet.", hero.name));
	else
		BonkHeroRecordNote:SetText("");
	end
end

function BonkHero_UpdateScene()
	if ( not Bonk.listLoaded or Bonk.creating or Bonk.wiping ) then
		return;
	end

	local hero = CurrentHero();
	if ( hero ) then
		if ( Bonk.screen ~= "charselect" ) then
			Bonk.reuseList = true;
			SetGlueScreen("charselect");
			CharacterSelect_SelectCharacter(hero.index, 1);
		elseif ( CharacterSelect.selectedIndex ~= hero.index ) then
			CharacterSelect_SelectCharacter(hero.index, 1);
		end
	elseif ( Bonk.screen ~= "charcreate" ) then
		SetGlueScreen("charcreate");
	else
		BonkHero_ApplyNewHero();
	end
end

function BonkHero_ApplyNewHero()
	if ( CurrentHero() ) then
		return;
	end
	local class = CurrentClass();
	local race = NewHeroRace();

	local races = { GetAvailableRaces() };
	local raceId;
	for i = 1, getn(races) / 2 do
		if ( strupper(races[i * 2]) == race ) then
			raceId = i;
		end
	end
	if ( not raceId ) then
		return;
	end

	if ( Bonk.appliedRace ~= race ) then
		Bonk.appliedRace = race;
		SetSelectedRace(raceId);
		SetCharacterRace(raceId);
	end
	if ( GetSelectedSex() ~= Bonk.sex ) then
		SetCharacterGender(Bonk.sex);
	end

	local classes = { GetClassesForRace() };
	for i = 1, getn(classes) / 2 do
		if ( strupper(classes[i * 2]) == class.token ) then
			SetSelectedClass(i);
			SetCharacterClass(i);
		end
	end
	BonkHero_UpdateCustomization();
end

function BonkHero_UpdateCustomization()
	local hair = GetHairCustomization();
	BonkHeroLook3Text:SetText(HAIR_STYLE_LABELS[hair] or getglobal("HAIR_"..hair.."_STYLE"));
	BonkHeroLook4Text:SetText(HAIR_COLOR_LABELS[hair] or getglobal("HAIR_"..hair.."_COLOR"));
	local facialHair = GetFacialHairCustomization();
	if ( facialHair == "NONE" ) then
		BonkHeroLook5:Hide();
	else
		BonkHeroLook5Text:SetText(FACIAL_HAIR_LABELS[facialHair] or getglobal("FACIAL_HAIR_"..facialHair));
		BonkHeroLook5:Show();
	end
end

function BonkHero_SelectClass(index)
	local class = BONK_CLASSES[index];
	if ( not IsSelectable(class) ) then
		PlaySound("igMainMenuOptionCheckBoxOff");
		BonkHero_SetStatus(L("The {1} is not available yet.", class.display));
		BonkHero_UpdateRoster();
		return;
	end
	PlaySound("gsCharacterCreationClass");
	if ( not Bonk.creating and not Bonk.wiping and not Bonk.customizing and index ~= Bonk.classIndex ) then
		Bonk.classIndex = index;
		Bonk.raceIndex = 1;
		Bonk.specIndex = 1;
		BonkHero_SetStatus("");
	end
	BonkHero_Refresh();
end

function BonkHero_SelectSpec(index)
	PlaySound("igMainMenuOptionCheckBoxOn");
	Bonk.specIndex = index;
	BonkHero_UpdateInfo();
end

function BonkHero_SelectRace(index)
	PlaySound("gsCharacterCreationClass");
	if ( not Bonk.creating ) then
		Bonk.raceIndex = index;
		BonkHero_SetStatus("");
	end
	BonkHero_Refresh();
end

function BonkHero_SelectSex(sex)
	PlaySound("gsCharacterCreationClass");
	if ( not Bonk.creating and not Bonk.wiping ) then
		Bonk.sex = sex;
	end
	BonkHero_Refresh();
end

function BonkHero_Randomize()
	PlaySound("gsCharacterCreationLook");
	if ( Bonk.screen == "charcreate" ) then
		RandomizeCharCustomization();
		BonkHero_UpdateCustomization();
	end
end

function BonkHero_CreateCharacter()
	PlaySound("gsCharacterCreationCreateChar");
	CreateCharacter(BonkHeroNameEdit:GetText());
end

function BonkHero_EnterWorld(hero)
	BonkHero_SetStatus(L["Entering the world..."]);
	CharacterSelect_SelectCharacter(hero.index, 1);
	PlaySound("gsCharacterSelectionEnterWorld");
	EnterWorld();
end

function BonkHero_StartCustomizing()
	PlaySound("gsCharacterSelectionCreateNew");
	Bonk.customizing = true;
	BonkHero_SetStatus("");
	BonkHero_Refresh();
	BonkHeroNameEdit:SetFocus();
end

function BonkHero_Back()
	if ( not Bonk.customizing or Bonk.creating ) then
		return;
	end
	PlaySound("gsCharacterCreationCancel");
	Bonk.customizing = nil;
	BonkHero_SetStatus("");
	BonkHero_Refresh();
end

function BonkHero_Play()
	if ( Bonk.creating or Bonk.wiping or not Bonk.listLoaded ) then
		return;
	end

	local hero = CurrentHero();
	if ( hero ) then
		BonkHero_EnterWorld(hero);
		return;
	end

	if ( not Bonk.customizing ) then
		BonkHero_StartCustomizing();
		return;
	end

	if ( Bonk.screen ~= "charcreate" ) then
		return;
	end
	if ( BonkHeroNameEdit:GetText() == "" ) then
		BonkHero_SetStatus(L["Enter a name for your character"]);
		BonkHeroNameEdit:SetFocus();
		return;
	end

	BonkHeroNameEdit:ClearFocus();
	Bonk.creating = { class = CurrentClass().token };
	BonkHero_SetStatus(L["Creating your character..."]);
	if ( Bonk.ironman ) then
		Bonk.creating.ironmanSent = true;
		CreateCharacter(IRONMAN_NAME);
		return;
	end
	BonkHero_CreateCharacter();
end

function BonkHero_Retire()
	local hero = CurrentHero();
	if ( not hero or Bonk.creating or Bonk.wiping ) then
		return;
	end
	PlaySound("gsCharacterSelectionDelCharacter");
	GlueDialog_Show("BONK_RETIRE", L("Delete {1}, your {2}?\nThis permanently deletes the character and their gear. Your gold stays on the account.", hero.name, CurrentClass().display), hero.index);
end

BONK_WIPE_GAP = 0.3;
local WIPE_NAME = "Wipeaccount";
local WIPE_ASK_AGAIN = 3;
local WIPE_TIMEOUT = 15;

function BonkHero_Wipe()
	if ( Bonk.creating or Bonk.wiping or not Bonk.listLoaded ) then
		return;
	end
	PlaySound("gsCharacterSelectionDelCharacter");
	GlueDialog_Show("BONK_WIPE");
end

function BonkHero_StartWipe()
	Bonk.wiping = { step = "delete", wait = 0 };
	Bonk.customizing = nil;
	BonkHeroNameEdit:ClearFocus();
	BonkHero_SetStatus(L["Wiping the account..."]);
end

function BonkHero_StopWipe(text)
	Bonk.wiping = nil;
	BonkHero_SetStatus(text);
	BonkHero_Refresh();
end

function BonkHero_FinishWipe()
	Bonk.wiping = nil;
	BONK_STATS = { gold = 0, lastHero = "", heroes = {} };
	BONK_STATS_ACCOUNTS = BONK_STATS_ACCOUNTS or {};
	BONK_STATS_ACCOUNTS[BonkHero_AccountKey()] = BONK_STATS;
	Bonk.classIndex = 1;
	Bonk.raceIndex = 1;
	Bonk.specIndex = 1;
	BonkHeroNameEdit:SetText("");
	BonkHero_Refresh();
	BonkHero_SetStatus(L["|cff20ff20Account wiped.|r Every character and all progress are gone."]);
end

function BonkHero_UpdateWipe(elapsed)
	local wipe = Bonk.wiping;
	if ( wipe.sent ) then
		wipe.sentFor = wipe.sentFor + elapsed;
		if ( wipe.sent == "delete" and not wipe.askedAgain and wipe.sentFor > WIPE_ASK_AGAIN ) then
			wipe.askedAgain = true;
			GetCharacterListUpdate();
		elseif ( wipe.sentFor > WIPE_TIMEOUT ) then
			BonkHero_StopWipe(L["The server didn't answer, so the account was not wiped."]);
		end
		return;
	end
	wipe.wait = wipe.wait - elapsed;
	if ( wipe.wait > 0 ) then
		return;
	end

	local count = GetNumCharacters();
	if ( count > 0 ) then
		if ( count == 1 ) then
			BonkHero_SetStatus(L["Wiping the account... 1 character left"]);
		else
			BonkHero_SetStatus(L("Wiping the account... {1} characters left", count));
		end
		wipe.sent = "delete";
		wipe.sentFor = 0;
		wipe.askedAgain = nil;
		DeleteCharacter(1);
		return;
	end

	if ( Bonk.screen ~= "charcreate" ) then
		SetGlueScreen("charcreate");
		wipe.wait = BONK_WIPE_GAP;
		return;
	end
	BonkHero_SetStatus(L["Wiping the account..."]);
	wipe.step = "create";
	wipe.sent = "create";
	wipe.sentFor = 0;
	CreateCharacter(WIPE_NAME);
end

function BonkHero_Quit()
	PlaySound("gsTitleQuit");
	GlueDialog_Show("BONK_QUIT");
end

function BonkHero_StepClass(direction)
	if ( Bonk.customizing ) then
		return;
	end
	local count = getn(BONK_CLASSES);
	local index = Bonk.classIndex;
	for step = 1, count do
		index = mod(index - 1 + direction + count, count) + 1;
		if ( IsSelectable(BONK_CLASSES[index]) ) then
			BonkHero_SelectClass(index);
			return;
		end
	end
end

function BonkHero_StepRace(direction)
	if ( not Bonk.customizing ) then
		return;
	end
	local count = getn(CurrentClass().races);
	BonkHero_SelectRace(mod(Bonk.raceIndex - 1 + direction + count, count) + 1);
end

function BonkHero_OnKeyDown()
	if ( arg1 == "ESCAPE" ) then
		if ( Bonk.customizing ) then
			BonkHero_Back();
		else
			BonkHero_Quit();
		end
	elseif ( arg1 == "ENTER" ) then
		BonkHero_Play();
	elseif ( arg1 == "UP" ) then
		BonkHero_StepClass(-1);
	elseif ( arg1 == "DOWN" ) then
		BonkHero_StepClass(1);
	elseif ( arg1 == "LEFT" ) then
		BonkHero_StepRace(-1);
	elseif ( arg1 == "RIGHT" ) then
		BonkHero_StepRace(1);
	elseif ( arg1 == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function BonkHero_OnMouseDown(button)
	if ( Bonk.screen == "charcreate" ) then
		CharacterCreateFrame_OnMouseDown(button);
	else
		CharacterSelectFrame_OnMouseDown(button);
	end
end

function BonkHero_OnMouseUp(button)
	CharacterCreateFrame_OnMouseUp(button);
	CharacterSelectFrame_OnMouseUp(button);
end

function BonkHero_OnUpdate(elapsed)
	if ( Bonk.wiping ) then
		BonkHero_UpdateWipe(elapsed or 0);
	end
	if ( Bonk.sceneDelay > 0 ) then
		Bonk.sceneDelay = Bonk.sceneDelay - (elapsed or 0);
	elseif ( Bonk.sceneDirty and (Bonk.screen == "charselect" or Bonk.screen == "charcreate") ) then
		Bonk.sceneDirty = false;
		BonkHero_UpdateScene();
	end

	if ( Bonk.screen == "charcreate" ) then
		CharacterCreateFrame_OnUpdate();
	else
		CharacterSelectFrame_OnUpdate();
	end
end
