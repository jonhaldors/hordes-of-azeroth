local L = BonkGlueL;

if ( not GetBillingPlan ) then
	function GetBillingPlan()
		return 0, 0, 0;
	end
	function GetBillingTimeRemaining()
		return 0;
	end
	function GetBillingTimeRested()
		return 0;
	end
end

BONK_CLASSES = {
	{ token = "WARRIOR", id = 1, name = "Warrior", display = L["Warrior"], races = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "ORC", "SCOURGE", "TAUREN", "TROLL" } },
	{ token = "PALADIN", id = 2, name = "Paladin", display = L["Paladin"], races = { "HUMAN", "DWARF" } },
	{ token = "HUNTER",  id = 3, name = "Hunter", display = L["Hunter"],  races = { "DWARF", "NIGHTELF", "ORC", "TAUREN", "TROLL" } },
	{ token = "ROGUE",   id = 4, name = "Rogue", display = L["Rogue"],   races = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "ORC", "SCOURGE", "TROLL" } },
	{ token = "PRIEST",  id = 5, name = "Priest", display = L["Priest"],  races = { "HUMAN", "DWARF", "NIGHTELF", "SCOURGE", "TROLL" } },
	{ token = "SHAMAN",  id = 7, name = "Shaman", display = L["Shaman"],  races = { "ORC", "TAUREN", "TROLL" } },
	{ token = "MAGE",    id = 8, name = "Mage", display = L["Mage"],    races = { "HUMAN", "GNOME", "SCOURGE", "TROLL" } },
	{ token = "WARLOCK", id = 9, name = "Warlock", display = L["Warlock"], races = { "HUMAN", "GNOME", "ORC", "SCOURGE" } },
	{ token = "DRUID",   id = 11, name = "Druid", display = L["Druid"],   races = { "NIGHTELF", "TAUREN" } },
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

BONK_CLIENT_CLASS_NAMES = {
	WARRIOR = { "战士", "戰士" },
	PALADIN = { "圣骑士", "聖騎士" },
	HUNTER = { "猎人", "獵人" },
	ROGUE = { "潜行者", "盗贼", "盜賊" },
	PRIEST = { "牧师", "牧師" },
	SHAMAN = { "萨满祭司", "薩滿" },
	MAGE = { "法师", "法師" },
	WARLOCK = { "术士", "術士" },
	DRUID = { "德鲁伊", "德魯伊" },
};

BONK_CLASS_TOKENS = {};
BONK_CLASS_BY_ID = {};
for _, class in BONK_CLASSES do
	BONK_CLASS_BY_ID[class.id] = class.token;
	BONK_CLASS_TOKENS[class.name] = class.token;
	BONK_CLASS_TOKENS[class.token] = class.token;
	for _, clientName in BONK_CLIENT_CLASS_NAMES[class.token] do
		BONK_CLASS_TOKENS[clientName] = class.token;
	end
	local localized = getglobal("CLASS_" .. class.token);
	if ( localized ) then
		BONK_CLASS_TOKENS[localized] = class.token;
	end
end

BONK_IRONMAN_TIP = L["This character does not share gold or unlocks with other characters."];
BONK_HARDCORE_TIP = L["Hardcore characters share their own gold, mastery and bank. If this character dies, it leaves Hardcore and plays on as a regular character."];

local NUM_STAT_ROWS = 9;
local NUM_SPELL_ROWS = 7;
local NUM_SPECS = 3;
local NUM_CLASS_RACES = 8;
local NUM_LIST_ROWS = 12;
local LIST_ROW_HEIGHT = 40;
local IRONMAN_NAME = "Ironmanmode";
local HARDCORE_NAME = "Hardcoremode";
local SIDE_PANEL_ALPHA = 0.75;
local NUM_FALLEN_ROWS = 9;
local FALLEN_ROW_HEIGHT = 40;
local FALLEN_LIST_HEIGHT = 384;
local FALLEN_DETAIL_TOP = 28;
local FALLEN_DETAIL_LINE = 16;
local FALLEN_DETAIL_PAD = 8;
local FALLEN_DETAIL_COLUMN = 216;
local FALLEN_DETAIL_VALUE_RIGHT = 196;
local FALLEN_DETAIL_LEFT = 16;
local NUM_FALLEN_DETAILS = 6;
local SCROLL_ARROW_SPACE = 34;
local SCROLL_THUMB_MIN = 16;
local PLUS_BOX = "Interface\\Buttons\\UI-PlusButton-Up";
local MINUS_BOX = "Interface\\Buttons\\UI-MinusButton-Up";
local BADGE_LOOKS = {
	hardcore = { icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", disc = { 0.3, 0.04, 0.03 }, ring = { 1.0, 0.35, 0.3 } },
	ironman = { icon = "Interface\\Icons\\INV_Shield_06", disc = { 0.05, 0.05, 0.06 }, ring = { 0.8, 0.85, 0.95 }, round = true },
};
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
	BonkHeroRandomizeButton = L["Randomize"],
	BonkHeroIronmanText = L["Ironman Mode"],
	BonkHeroHardcoreText = L["Hardcore Mode"],
	BonkHeroFallenButton = L["Graveyard"],
	BonkClassRacesLabel = L["Races"],
	BonkClassStarterLabel = L["Starts with"],
	BonkSpecNote = L["Preview only. You choose your specialization later."],
	BonkHeroRetireButton = L["Delete Character"],
	BonkHeroNameLabel = L["Name"],
	BonkHeroQuitButton = L["Quit"],
	BonkHeroWipeButton = L["Wipe Account"],
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
	heroesByClass = {},
	heroName = nil,
	openClass = nil,
	listOffset = 0,
	revealSelection = nil,
	fallenOffset = 0,
	fallenOpen = nil,
	fallenReady = nil,
	backTo = nil,
	listLoaded = false,
	reuseList = false,
	creating = nil,
	wiping = nil,
	appliedRace = nil,
	classNamesLearned = false,
	createdClasses = {},
	unknownHero = nil,
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
	Bonk.heroesByClass = {};
	Bonk.heroName = nil;
	Bonk.openClass = nil;
	Bonk.listOffset = 0;
	Bonk.fallenOffset = 0;
	Bonk.fallenOpen = nil;
	Bonk.backTo = nil;

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
		local hero = BonkHero_Selected();
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
	if ( Bonk.unknownHero and BonkHero_LearnClassNames() ) then
		BonkHero_OnCharacterList();
	end
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
	local accountGone = shown and (shown == LOGIN_UNKNOWN_ACCOUNT or shown == LOGIN_INCORRECT_PASSWORD or shown == LOGIN_NO_GAME_ACCOUNT);
	if ( accountGone and BonkCoop_IsJoined() and not BonkCoop.leaving ) then
		GlueDialog:Hide();
		BonkCoop_RefusedAtLogin(L["Your spot in the host's game is no longer available. Returning to your own game..."]);
	elseif ( noServer and BonkCoop_IsJoined() and not BonkCoop.leaving ) then
		BonkCoop_LostHost();
	elseif ( noServer and not Bonk.reachedServer ) then
		GlueDialogText:SetText(L["The Hordes of Azeroth server isn't running. Close the game and start it with HoALauncher.exe in your World of Warcraft folder."]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
		BonkLoginStatus:SetText("");
	elseif ( noServer ) then
		GlueDialogText:SetText(L["The Hordes of Azeroth server stopped. Restart the game with HoALauncher.exe. If this keeps happening, click Report a bug in the launcher."]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
		BonkLoginStatus:SetText("");
	elseif ( BonkCoop_IsJoined() and BonkCoop_RefusalNote(shown) ) then
		GlueDialog:Hide();
		BonkCoop_RefusedAtLogin(BonkCoop_RefusalNote(shown));
	elseif ( shown == CHAR_LOGIN_LOCKED_FOR_TRANSFER ) then
		GlueDialogText:SetText(L["This character is in a co-op party. Leave the party first."]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
	elseif ( wipeRefused ) then
		GlueDialogText:SetText(L["The account was not wiped because a character couldn't be deleted. Try again."]);
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

local NO_HEROES = {};

local function HeroesOfClass(token)
	return Bonk.heroesByClass[token] or NO_HEROES;
end

local function FindHero(name)
	if ( not name ) then
		return nil;
	end
	local wanted = strlower(name);
	for index = 1, getn(Bonk.heroes) do
		local hero = Bonk.heroes[index];
		if ( strlower(hero.name) == wanted ) then
			return hero;
		end
	end
	return nil;
end

local function ClassIndexOf(token)
	for index = 1, getn(BONK_CLASSES) do
		if ( BONK_CLASSES[index].token == token ) then
			return index;
		end
	end
	return 1;
end

local function CurrentHero()
	local hero = FindHero(Bonk.heroName);
	if ( hero and hero.class == CurrentClass().token ) then
		return hero;
	end
	return nil;
end

function BonkHero_Selected()
	return CurrentHero();
end

function BonkHero_SelectedClass()
	return CurrentClass();
end

local function FirstHeroName(token)
	local first = HeroesOfClass(token)[1];
	return first and first.name;
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

local function HeroDetail(hero, class)
	local stats = HeroStats(hero) or {};
	local mastery = format("%d", stats.mastery or 0);
	local race = BONK_RACE_DISPLAY_NAMES[hero.race] or "";
	if ( stats.hardcore and stats.ironman ) then
		return L("Mastery {1} {2} {3} (Hardcore Ironman)", mastery, race, class.display);
	elseif ( stats.hardcore ) then
		return L("Mastery {1} {2} {3} (Hardcore)", mastery, race, class.display);
	elseif ( stats.fell and (stats.fellBest or 0) > 0 ) then
		return L("Mastery {1} {2} {3} (Fell in Hardcore, {4})", mastery, race, class.display, BonkLevelName(stats.fellBest));
	elseif ( stats.fell ) then
		return L("Mastery {1} {2} {3} (Fell in Hardcore)", mastery, race, class.display);
	elseif ( stats.ironman ) then
		return L("Mastery {1} {2} {3} (Ironman)", mastery, race, class.display);
	end
	return L("Mastery {1} {2} {3}", mastery, race, class.display);
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

local function CharacterCount(count)
	if ( count == 1 ) then
		return L["1 character"];
	end
	return L("{1} characters", count);
end

function BonkHero_SetBadge(badge, kind)
	local look = BADGE_LOOKS[kind];
	local name = badge:GetName();
	local icon = getglobal(name.."Icon");
	if ( look.round and SetPortraitToTexture ) then
		SetPortraitToTexture(icon:GetName(), look.icon);
	else
		icon:SetTexture(look.icon);
	end
	getglobal(name.."Disc"):SetVertexColor(look.disc[1], look.disc[2], look.disc[3]);
	getglobal(name.."Ring"):SetVertexColor(look.ring[1], look.ring[2], look.ring[3]);
	badge:Show();
end

local function ShowBadges(first, second, hardcore, ironman)
	first:Hide();
	second:Hide();
	if ( hardcore and ironman ) then
		BonkHero_SetBadge(first, "ironman");
		BonkHero_SetBadge(second, "hardcore");
	elseif ( hardcore ) then
		BonkHero_SetBadge(second, "hardcore");
	elseif ( ironman ) then
		BonkHero_SetBadge(second, "ironman");
	end
end

function BonkHero_SetupLegend(legend)
	local name = legend:GetName();
	local hardcore = getglobal(name.."Hardcore");
	local hardcoreText = getglobal(name.."HardcoreText");
	local ironman = getglobal(name.."Ironman");
	local ironmanText = getglobal(name.."IronmanText");
	local both1 = getglobal(name.."Both1");
	local both2 = getglobal(name.."Both2");
	local bothText = getglobal(name.."BothText");
	BonkHero_SetBadge(hardcore, "hardcore");
	BonkHero_SetBadge(ironman, "ironman");
	BonkHero_SetBadge(both1, "ironman");
	BonkHero_SetBadge(both2, "hardcore");
	hardcoreText:SetText(L["Hardcore"]);
	ironmanText:SetText(L["Ironman"]);
	bothText:SetText(L["Hardcore Ironman"]);
	hardcore:SetPoint("LEFT", legend, "LEFT", 0, 0);
	hardcoreText:SetPoint("LEFT", hardcore, "RIGHT", 2, 0);
	ironman:SetPoint("LEFT", hardcoreText, "RIGHT", 12, 0);
	ironmanText:SetPoint("LEFT", ironman, "RIGHT", 2, 0);
	both1:Hide();
	both2:Hide();
	bothText:Hide();
end

function BonkScroll_Step(bar, delta)
	if ( bar.scroll ) then
		bar.scroll(delta);
	end
end

local function UpdateScrollBar(bar, offset, maxOffset, visible, total)
	if ( maxOffset <= 0 or total <= 0 ) then
		bar:Hide();
		return;
	end
	local name = bar:GetName();
	local track = getglobal(name.."Track");
	local thumb = getglobal(name.."Thumb");
	local height = bar:GetHeight() - SCROLL_ARROW_SPACE;
	local thumbHeight = math.max(SCROLL_THUMB_MIN, floor(height * visible / total));
	if ( thumbHeight > height ) then
		thumbHeight = height;
	end
	thumb:SetHeight(thumbHeight);
	thumb:ClearAllPoints();
	thumb:SetPoint("TOP", track, "TOP", 0, -floor((height - thumbHeight) * offset / maxOffset));
	if ( offset > 0 ) then
		getglobal(name.."Up"):Enable();
	else
		getglobal(name.."Up"):Disable();
	end
	if ( offset < maxOffset ) then
		getglobal(name.."Down"):Enable();
	else
		getglobal(name.."Down"):Disable();
	end
	bar:Show();
end

local function Clamp(value, low, high)
	if ( value > high ) then
		value = high;
	end
	if ( value < low ) then
		value = low;
	end
	return value;
end

function BonkHero_SetStatus(text)
	BonkHeroStatus:SetText(text);
end

function BonkHero_OnLoad()
	for _, panel in { BonkInfoPanel, BonkListPanel, BonkAppearPanel } do
		panel:SetBackdropColor(0.11, 0.1, 0.1, SIDE_PANEL_ALPHA);
		getglobal(panel:GetName().."Fill"):SetAlpha(SIDE_PANEL_ALPHA);
	end
	for index = 1, NUM_LIST_ROWS do
		getglobal("BonkCharRow"..index):SetPoint("TOPLEFT", "BonkCharList", "TOPLEFT", 0, -(index - 1) * LIST_ROW_HEIGHT);
	end
	BonkCharScroll.scroll = BonkHero_ScrollList;
	BonkHero_SetupLegend(BonkListLegend);

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
	BonkListCount:SetText(CharacterCount(getn(Bonk.heroes)));
end

function BonkHero_ToggleIronman()
	Bonk.ironman = BonkHeroIronman:GetChecked() and true or nil;
	if ( Bonk.ironman ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
end

function BonkHero_ToggleHardcore()
	Bonk.hardcore = BonkHeroHardcore:GetChecked() and true or nil;
	if ( Bonk.hardcore ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
end

function BonkHero_ShowHardcoreTip(owner)
	BonkHero_ShowTip(owner, L["Hardcore Mode"], BONK_HARDCORE_TIP);
end

function BonkHero_CustomizeLabel(id)
	return CUSTOMIZE_LABELS[id] or getglobal("CHAR_CUSTOMIZATION"..id.."_DESC");
end

function BonkHero_ShowIronmanTip(owner)
	BonkHero_ShowTip(owner, L["Ironman Mode"], BONK_IRONMAN_TIP);
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

local function HeroClassToken(name, className)
	if ( not name ) then
		return nil;
	end
	local created = Bonk.createdClasses[strlower(name)];
	if ( created ) then
		return created;
	end
	local stats = BONK_STATS and BONK_STATS.heroes and BONK_STATS.heroes[name];
	if ( stats and BONK_CLASS_BY_ID[stats.class] ) then
		return BONK_CLASS_BY_ID[stats.class];
	end
	return BONK_CLASS_TOKENS[className];
end

function BonkHero_ReadHeroes()
	Bonk.heroes = {};
	Bonk.heroesByClass = {};
	local unknown;
	for index = 1, GetNumCharacters() do
		local name, race, class, level, zone, fileString, gender = GetCharacterInfo(index);
		local classToken = HeroClassToken(name, class);
		if ( name and not (classToken and fileString) ) then
			unknown = name.." ("..tostring(class)..", "..tostring(fileString)..")";
		end
		if ( name and classToken and fileString ) then
			local sex = 1;
			if ( gender and gender ~= 0 ) then
				sex = 2;
			end
			local hero = { index = index, name = name, race = strupper(fileString), level = level, sex = sex, class = classToken };
			tinsert(Bonk.heroes, hero);
			if ( not Bonk.heroesByClass[classToken] ) then
				Bonk.heroesByClass[classToken] = {};
			end
			tinsert(Bonk.heroesByClass[classToken], hero);
		end
	end
	Bonk.unknownHero = unknown;
	if ( unknown and Bonk.classNamesLearned ) then
		BonkHero_SetStatus(L("Could not read the class of {1}.", unknown));
	end
end

local CLASS_NAME_RACES = { "HUMAN", "TAUREN" };

local function LearnClassesOfSelectedRace()
	local classes = { GetClassesForRace() };
	for i = 1, getn(classes) / 2 do
		local name = classes[i * 2 - 1];
		local token = strupper(classes[i * 2] or "");
		if ( name and BONK_CLASS_TOKENS[token] == token ) then
			BONK_CLASS_TOKENS[name] = token;
		end
	end
end

function BonkHero_LearnClassNames()
	if ( Bonk.classNamesLearned ) then
		return false;
	end
	Bonk.classNamesLearned = true;
	local races = { GetAvailableRaces() };
	for _, raceToken in CLASS_NAME_RACES do
		for i = 1, getn(races) / 2 do
			if ( strupper(races[i * 2]) == raceToken ) then
				SetSelectedRace(i);
				SetCharacterRace(i);
				LearnClassesOfSelectedRace();
			end
		end
	end
	return true;
end

function BonkHero_ShowHero(hero)
	local classIndex = ClassIndexOf(hero.class);
	if ( classIndex ~= Bonk.classIndex ) then
		Bonk.raceIndex = 1;
		Bonk.specIndex = 1;
	end
	Bonk.classIndex = classIndex;
	Bonk.heroName = hero.name;
	Bonk.openClass = hero.class;
	Bonk.revealSelection = true;
end

local function StartHero()
	local lastHero = BONK_STATS and BONK_STATS.lastHero;
	if ( lastHero and lastHero ~= "" and FindHero(lastHero) ) then
		return FindHero(lastHero);
	end
	local selected = CharacterSelect.selectedIndex;
	for index = 1, getn(Bonk.heroes) do
		if ( Bonk.heroes[index].index == selected ) then
			return Bonk.heroes[index];
		end
	end
	return Bonk.heroes[1];
end

local function KeepSelectionValid()
	if ( Bonk.heroName and not CurrentHero() ) then
		Bonk.heroName = FirstHeroName(CurrentClass().token);
		Bonk.revealSelection = true;
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

	if ( Bonk.creating and Bonk.creating.modeSent ) then
		Bonk.creating.modeSent = nil;
		BonkHero_SendNextMode();
		return;
	end

	if ( Bonk.unknownHero and not Bonk.classNamesLearned and Bonk.screen == "charselect" ) then
		SetGlueScreen("charcreate");
		return;
	end

	if ( Bonk.creating ) then
		local hero = FindHero(Bonk.creating.name);
		if ( hero and hero.class == Bonk.creating.class ) then
			Bonk.creating = nil;
			Bonk.customizing = nil;
			BonkHeroNameEdit:SetText("");
			BonkHero_ShowHero(hero);
			BonkHero_EnterWorld(hero);
			return;
		end
	end

	Bonk.listLoaded = true;
	if ( not Bonk.startPicked and getn(Bonk.heroes) > 0 ) then
		Bonk.startPicked = true;
		local start = StartHero();
		if ( start ) then
			BonkHero_ShowHero(start);
		end
		Bonk.openClass = CurrentClass().token;
	end
	KeepSelectionValid();

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

local function ListEntries()
	local entries = {};
	for classIndex = 1, getn(BONK_CLASSES) do
		local class = BONK_CLASSES[classIndex];
		tinsert(entries, { kind = "class", classIndex = classIndex });
		if ( Bonk.openClass == class.token ) then
			local heroes = HeroesOfClass(class.token);
			for index = 1, getn(heroes) do
				tinsert(entries, { kind = "hero", classIndex = classIndex, hero = heroes[index] });
			end
			tinsert(entries, { kind = "new", classIndex = classIndex });
		end
	end
	return entries;
end

local function IsEntrySelected(entry)
	if ( entry.kind == "class" ) then
		return Bonk.openClass == BONK_CLASSES[entry.classIndex].token;
	elseif ( entry.kind == "hero" ) then
		return entry.classIndex == Bonk.classIndex and entry.hero == CurrentHero();
	end
	return entry.classIndex == Bonk.classIndex and not CurrentHero();
end

local function RevealSelection(entries)
	local header, chosen;
	for index = 1, getn(entries) do
		local entry = entries[index];
		if ( entry.kind == "class" and entry.classIndex == Bonk.classIndex ) then
			header = index;
		elseif ( entry.kind ~= "class" and IsEntrySelected(entry) ) then
			chosen = index;
		end
	end
	chosen = chosen or header;
	if ( not chosen ) then
		return;
	end
	local top = chosen;
	if ( header and chosen - header < NUM_LIST_ROWS ) then
		top = header;
	end
	if ( top <= Bonk.listOffset ) then
		Bonk.listOffset = top - 1;
	elseif ( chosen > Bonk.listOffset + NUM_LIST_ROWS ) then
		Bonk.listOffset = chosen - NUM_LIST_ROWS;
	end
end

local function HeroLine(hero)
	local stats = HeroStats(hero) or {};
	local mastery = format("%d", stats.mastery or 0);
	local race = BONK_RACE_DISPLAY_NAMES[hero.race] or "";
	if ( stats.fell ) then
		return L("Mastery {1} · fell in Hardcore", mastery);
	end
	return L("Mastery {1} {2}", mastery, race);
end

local function ClearRow(row)
	local name = row:GetName();
	getglobal(name.."Box"):Hide();
	getglobal(name.."Icon"):Hide();
	getglobal(name.."Sub"):Hide();
	getglobal(name.."Count"):Hide();
	getglobal(name.."BestLabel"):Hide();
	getglobal(name.."Best"):Hide();
	getglobal(name.."Badge1"):Hide();
	getglobal(name.."Badge2"):Hide();
end

local function PlaceRowName(row, centered)
	local text = getglobal(row:GetName().."Name");
	text:ClearAllPoints();
	if ( centered ) then
		text:SetPoint("LEFT", row, "LEFT", 62, 0);
	else
		text:SetPoint("TOPLEFT", row, "TOPLEFT", 62, -4);
	end
	return text;
end

local function DrawClassRow(row, class)
	local name = row:GetName();
	local count = getn(HeroesOfClass(class.token));
	local box = getglobal(name.."Box");
	box:ClearAllPoints();
	box:SetPoint("LEFT", row, "LEFT", 6, 0);
	if ( Bonk.openClass == class.token ) then
		box:SetTexture(MINUS_BOX);
	else
		box:SetTexture(PLUS_BOX);
	end
	box:Show();
	local icon = getglobal(name.."Icon");
	SetTexCoords(icon, CLASS_ICON_TCOORDS[class.token]);
	icon:Show();
	local text = PlaceRowName(row, true);
	text:SetText(class.display);
	local countText = getglobal(name.."Count");
	if ( count > 0 ) then
		icon:SetVertexColor(1.0, 1.0, 1.0);
		SetClassColor(text, class.token);
		countText:SetText(CharacterCount(count));
	else
		icon:SetVertexColor(0.5, 0.5, 0.5);
		text:SetTextColor(0.55, 0.55, 0.55);
		countText:SetText(L["Create"]);
	end
	countText:SetTextColor(0.75, 0.75, 0.75);
	countText:Show();
end

local function DrawHeroRow(row, hero)
	local name = row:GetName();
	local stats = HeroStats(hero) or {};
	ShowBadges(getglobal(name.."Badge1"), getglobal(name.."Badge2"), stats.hardcore, stats.ironman);
	local text = PlaceRowName(row, false);
	text:SetText(hero.name);
	SetClassColor(text, hero.class);
	local sub = getglobal(name.."Sub");
	sub:SetText(HeroLine(hero));
	sub:SetTextColor(0.8, 0.8, 0.8);
	sub:Show();
	getglobal(name.."BestLabel"):SetText(L["Best"]);
	getglobal(name.."BestLabel"):Show();
	getglobal(name.."Best"):SetText(BonkLevelName(stats.bestLevel));
	getglobal(name.."Best"):Show();
end

local function DrawNewRow(row, class)
	local box = getglobal(row:GetName().."Box");
	box:ClearAllPoints();
	box:SetPoint("LEFT", row, "LEFT", 40, 0);
	box:SetTexture(PLUS_BOX);
	box:Show();
	local text = PlaceRowName(row, true);
	text:SetText(L("New {1}", class.display));
	text:SetTextColor(1.0, 0.82, 0);
end

local ROW_LOOKS = {
	class = { fill = { 0.24, 0.18, 0.12, 0.95 }, edge = { 0.66, 0.53, 0.33 } },
	hero = { fill = { 0, 0, 0, 0 }, edge = { 0, 0, 0, 0 } },
	new = { fill = { 0, 0, 0, 0 }, edge = { 0, 0, 0, 0 } },
};

function BonkHero_StyleRow(row, look)
	row:SetBackdropColor(look.fill[1], look.fill[2], look.fill[3], look.fill[4]);
	row:SetBackdropBorderColor(look.edge[1], look.edge[2], look.edge[3], look.edge[4] or 1);
end

local function DrawRow(row, entry)
	ClearRow(row);
	local class = BONK_CLASSES[entry.classIndex];
	if ( entry.kind == "class" ) then
		DrawClassRow(row, class);
	elseif ( entry.kind == "hero" ) then
		DrawHeroRow(row, entry.hero);
	else
		DrawNewRow(row, class);
	end
	local selected = IsEntrySelected(entry);
	if ( selected ) then
		getglobal(row:GetName().."Selected"):Show();
	else
		getglobal(row:GetName().."Selected"):Hide();
	end
	BonkHero_StyleRow(row, ROW_LOOKS[entry.kind]);
end

function BonkHero_UpdateRoster()
	local entries = ListEntries();
	local total = getn(entries);
	local maxOffset = math.max(0, total - NUM_LIST_ROWS);
	if ( Bonk.revealSelection ) then
		Bonk.revealSelection = nil;
		RevealSelection(entries);
	end
	Bonk.listOffset = Clamp(Bonk.listOffset, 0, maxOffset);
	for slot = 1, NUM_LIST_ROWS do
		local row = getglobal("BonkCharRow"..slot);
		local entry = entries[Bonk.listOffset + slot];
		row.entry = entry;
		if ( entry ) then
			DrawRow(row, entry);
			row:Show();
		else
			row:Hide();
		end
	end
	UpdateScrollBar(BonkCharScroll, Bonk.listOffset, maxOffset, NUM_LIST_ROWS, total);
	BonkHero_UpdateFallen();
end

function BonkHero_ScrollList(delta)
	Bonk.listOffset = Bonk.listOffset - delta;
	BonkHero_UpdateRoster();
end

local function Busy()
	return Bonk.creating or Bonk.wiping or Bonk.customizing;
end

function BonkHero_Choose(classIndex, heroName)
	if ( Busy() ) then
		return;
	end
	if ( classIndex ~= Bonk.classIndex ) then
		Bonk.raceIndex = 1;
		Bonk.specIndex = 1;
	end
	Bonk.classIndex = classIndex;
	Bonk.heroName = heroName;
	Bonk.openClass = BONK_CLASSES[classIndex].token;
	Bonk.revealSelection = true;
	BonkHero_SetStatus("");
	BonkHero_Refresh();
end

function BonkHero_ClickClass(classIndex)
	if ( Busy() ) then
		return;
	end
	local class = BONK_CLASSES[classIndex];
	if ( Bonk.openClass == class.token ) then
		PlaySound("igMainMenuOptionCheckBoxOff");
		Bonk.openClass = nil;
		BonkHero_UpdateRoster();
		return;
	end
	PlaySound("gsCharacterCreationClass");
	if ( classIndex == Bonk.classIndex ) then
		Bonk.openClass = class.token;
		Bonk.revealSelection = true;
		BonkHero_UpdateRoster();
		return;
	end
	BonkHero_Choose(classIndex, FirstHeroName(class.token));
end

function BonkHero_NewHero(classIndex)
	if ( Busy() ) then
		return;
	end
	local current = CurrentHero();
	local back = { classIndex = Bonk.classIndex, heroName = current and current.name };
	BonkHero_Choose(classIndex, nil);
	BonkHero_StartCustomizing();
	Bonk.backTo = back;
end

function BonkHero_ClickRow(slot)
	local entry = getglobal("BonkCharRow"..slot).entry;
	if ( not entry ) then
		return;
	end
	if ( entry.kind == "class" ) then
		BonkHero_ClickClass(entry.classIndex);
	elseif ( entry.kind == "hero" ) then
		PlaySound("gsCharacterCreationClass");
		BonkHero_Choose(entry.classIndex, entry.hero.name);
	else
		BonkHero_NewHero(entry.classIndex);
	end
end

function BonkHero_DoubleClickRow(slot)
	local entry = getglobal("BonkCharRow"..slot).entry;
	if ( entry and entry.kind == "hero" and entry.hero == CurrentHero() ) then
		BonkHero_Play();
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
		BonkHeroFallenButton:Hide();
		BonkFallenPanel:Hide();
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
		BonkHero_UpdateFallen();
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
		BonkHeroDetail:SetText(HeroDetail(hero, class));
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
	BonkHeroHardcore:SetChecked(Flag(Bonk.hardcore));
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
	if ( stats.ironman or stats.hardcore ) then
		SetStatRow(9, L["Gold"], FormatGold(stats.gold));
		BonkHeroStat9:Show();
	else
		BonkHeroStat9:Hide();
	end

	if ( not HeroStats(hero) ) then
		BonkHeroRecordNote:SetText(L("These stats update when {1} logs out.", hero.name));
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
	local name = BonkHeroNameEdit:GetText();
	if ( Bonk.creating ) then
		Bonk.createdClasses[strlower(name)] = Bonk.creating.class;
		Bonk.creating.name = name;
	end
	CreateCharacter(name);
end

function BonkHero_EnterWorld(hero)
	BonkHero_SetStatus(L["Entering the world..."]);
	CharacterSelect_SelectCharacter(hero.index, 1);
	PlaySound("gsCharacterSelectionEnterWorld");
	EnterWorld();
end

function BonkHero_StartCustomizing()
	PlaySound("gsCharacterSelectionCreateNew");
	Bonk.backTo = nil;
	Bonk.customizing = true;
	BonkHero_SetStatus("");
	BonkHero_Refresh();
	BonkHeroNameEdit:SetFocus();
end

local function ReturnFromNewHero()
	local back = Bonk.backTo;
	Bonk.backTo = nil;
	if ( not back or not FindHero(back.heroName) ) then
		return;
	end
	if ( back.classIndex ~= Bonk.classIndex ) then
		Bonk.raceIndex = 1;
		Bonk.specIndex = 1;
	end
	Bonk.classIndex = back.classIndex;
	Bonk.heroName = back.heroName;
	Bonk.openClass = BONK_CLASSES[back.classIndex].token;
	Bonk.revealSelection = true;
end

function BonkHero_Back()
	if ( not Bonk.customizing or Bonk.creating ) then
		return;
	end
	PlaySound("gsCharacterCreationCancel");
	Bonk.customizing = nil;
	ReturnFromNewHero();
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
	Bonk.creating.modes = {};
	if ( Bonk.hardcore ) then
		tinsert(Bonk.creating.modes, HARDCORE_NAME);
	end
	if ( Bonk.ironman ) then
		tinsert(Bonk.creating.modes, IRONMAN_NAME);
	end
	BonkHero_SendNextMode();
end

function BonkHero_SendNextMode()
	local mode = Bonk.creating.modes and tremove(Bonk.creating.modes, 1);
	if ( mode ) then
		Bonk.creating.modeSent = true;
		CreateCharacter(mode);
		return;
	end
	BonkHero_CreateCharacter();
end

local function FallenRecords()
	return BONK_STATS and BONK_STATS.fallen or {};
end

local function FallenClass(record)
	for index = 1, getn(BONK_CLASSES) do
		if ( BONK_CLASSES[index].id == record.class ) then
			return BONK_CLASSES[index];
		end
	end
	return nil;
end

local function ServerName(name)
	if ( not name or name == "" ) then
		return L["unknown"];
	end
	return L[name];
end

local function FallenDate(diedAt)
	diedAt = tonumber(diedAt);
	if ( not date or not diedAt or diedAt <= 0 ) then
		return "";
	end
	return date("%b %d", diedAt) or "";
end

local function FallenDetails(record)
	local details = {
		{ L["Best level"], BonkLevelName(record.bestLevel) },
		{ L["Mastery"], record.mastery or 0 },
		{ L["Runs"], record.runs or 0 },
		{ L["Enemies slain"], record.kills or 0 },
		{ L["Time played"], FormatPlayed(record.played) },
	};
	if ( (record.crashes or 0) > 0 ) then
		tinsert(details, { L["Forgiven crashes"], record.crashes });
	end
	return details;
end

local function FallenDetailHeight(record)
	return FALLEN_DETAIL_TOP + ceil(getn(FallenDetails(record)) / 2) * FALLEN_DETAIL_LINE + FALLEN_DETAIL_PAD;
end

local function FallenRowHeight(fallen, index)
	if ( index == Bonk.fallenOpen ) then
		return FALLEN_ROW_HEIGHT + FallenDetailHeight(fallen[index]);
	end
	return FALLEN_ROW_HEIGHT;
end

local function FallenHeightBetween(fallen, first, last)
	local height = 0;
	for index = first, last do
		height = height + FallenRowHeight(fallen, index);
	end
	return height;
end

local function FallenMaxOffset(fallen)
	local skipped = getn(fallen);
	local height = 0;
	while ( skipped > 0 ) do
		local rowHeight = FallenRowHeight(fallen, skipped);
		if ( height + rowHeight > FALLEN_LIST_HEIGHT or getn(fallen) - skipped + 1 > NUM_FALLEN_ROWS ) then
			return skipped;
		end
		height = height + rowHeight;
		skipped = skipped - 1;
	end
	return 0;
end

local function DrawFallenRow(row, record, open)
	local name = row:GetName();
	BonkHero_StyleRow(row, ROW_LOOKS.hero);
	local arrow = getglobal(name.."Arrow");
	if ( open ) then
		arrow:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0);
		getglobal(name.."Selected"):Show();
	else
		arrow:SetTexCoord(0, 1, 0, 1);
		getglobal(name.."Selected"):Hide();
	end
	local class = FallenClass(record);
	local icon = getglobal(name.."Icon");
	local text = getglobal(name.."Name");
	text:SetText(record.name or "");
	if ( class ) then
		SetTexCoords(icon, CLASS_ICON_TCOORDS[class.token]);
		icon:Show();
		SetClassColor(text, class.token);
		getglobal(name.."Sub"):SetText(L("Level {1} {2}", record.level or 0, class.display));
	else
		icon:Hide();
		text:SetTextColor(1.0, 0.82, 0);
		getglobal(name.."Sub"):SetText(L("Level {1}", record.level or 0));
	end
	getglobal(name.."Sub"):SetTextColor(0.8, 0.8, 0.8);
	ShowBadges(getglobal(name.."Badge1"), getglobal(name.."Badge2"), true, record.ironman);
	getglobal(name.."Level"):SetText(BonkLevelName(record.bestLevel));
	getglobal(name.."Date"):SetText(FallenDate(record.diedAt));
	getglobal(name.."Date"):SetTextColor(0.7, 0.7, 0.7);
end

local function ShowFallenDetail(record, top)
	local killer = format("|cffff5040%s|r", ServerName(record.killer));
	if ( record.killer == "" and record.rested ) then
		BonkFallenDetailSlain:SetText(L("Fled the fight in {1}. Laid to rest.", ServerName(record.map)));
	elseif ( record.killer == "" ) then
		BonkFallenDetailSlain:SetText(L("Fled the fight in {1}.", ServerName(record.map)));
	elseif ( record.rested ) then
		BonkFallenDetailSlain:SetText(L("Slain by {1} in {2}. Laid to rest.", killer, ServerName(record.map)));
	else
		BonkFallenDetailSlain:SetText(L("Slain by {1} in {2}.", killer, ServerName(record.map)));
	end
	local details = FallenDetails(record);
	for index = 1, NUM_FALLEN_DETAILS do
		local label = getglobal("BonkFallenDetailLabel"..index);
		local value = getglobal("BonkFallenDetailValue"..index);
		local detail = details[index];
		if ( detail ) then
			local x = FALLEN_DETAIL_LEFT + mod(index - 1, 2) * FALLEN_DETAIL_COLUMN;
			local y = -FALLEN_DETAIL_TOP - floor((index - 1) / 2) * FALLEN_DETAIL_LINE;
			label:ClearAllPoints();
			label:SetPoint("TOPLEFT", BonkFallenDetail, "TOPLEFT", x, y);
			label:SetText(detail[1]);
			label:Show();
			value:ClearAllPoints();
			value:SetPoint("TOPRIGHT", BonkFallenDetail, "TOPLEFT", x + FALLEN_DETAIL_VALUE_RIGHT, y);
			value:SetText(detail[2]);
			value:Show();
		else
			label:Hide();
			value:Hide();
		end
	end
	BonkFallenDetail:SetHeight(FallenDetailHeight(record));
	BonkFallenDetail:ClearAllPoints();
	BonkFallenDetail:SetPoint("TOPLEFT", BonkFallenList, "TOPLEFT", 0, -top);
	BonkFallenDetail:Show();
end

function BonkHero_UpdateFallenList()
	local fallen = FallenRecords();
	local count = getn(fallen);
	if ( Bonk.fallenOpen and not fallen[Bonk.fallenOpen] ) then
		Bonk.fallenOpen = nil;
	end
	local maxOffset = FallenMaxOffset(fallen);
	Bonk.fallenOffset = Clamp(Bonk.fallenOffset, 0, maxOffset);
	BonkFallenDetail:Hide();
	local top = 0;
	local slot = 0;
	local index = Bonk.fallenOffset + 1;
	while ( slot < NUM_FALLEN_ROWS and fallen[index] and top + FallenRowHeight(fallen, index) <= FALLEN_LIST_HEIGHT ) do
		slot = slot + 1;
		local row = getglobal("BonkFallenRow"..slot);
		local open = index == Bonk.fallenOpen;
		row.record = index;
		DrawFallenRow(row, fallen[index], open);
		row:ClearAllPoints();
		row:SetPoint("TOPLEFT", BonkFallenList, "TOPLEFT", 0, -top);
		row:Show();
		top = top + FALLEN_ROW_HEIGHT;
		if ( open ) then
			ShowFallenDetail(fallen[index], top);
			top = top + FallenDetailHeight(fallen[index]);
		end
		index = index + 1;
	end
	for hidden = slot + 1, NUM_FALLEN_ROWS do
		local row = getglobal("BonkFallenRow"..hidden);
		row.record = nil;
		row:Hide();
	end
	UpdateScrollBar(BonkFallenScroll, Bonk.fallenOffset, maxOffset, slot, count);
end

function BonkHero_ScrollFallen(delta)
	Bonk.fallenOffset = Bonk.fallenOffset - delta;
	BonkHero_UpdateFallenList();
end

function BonkHero_ToggleFallenRow(slot)
	local index = getglobal("BonkFallenRow"..slot).record;
	if ( not index ) then
		return;
	end
	if ( Bonk.fallenOpen == index ) then
		PlaySound("igMainMenuOptionCheckBoxOff");
		Bonk.fallenOpen = nil;
	else
		PlaySound("igMainMenuOptionCheckBoxOn");
		Bonk.fallenOpen = index;
		local fallen = FallenRecords();
		while ( Bonk.fallenOffset < index - 1 and FallenHeightBetween(fallen, Bonk.fallenOffset + 1, index) > FALLEN_LIST_HEIGHT ) do
			Bonk.fallenOffset = Bonk.fallenOffset + 1;
		end
	end
	BonkHero_UpdateFallenList();
end

local function PrepareFallenPanel()
	if ( Bonk.fallenReady ) then
		return;
	end
	Bonk.fallenReady = true;
	BonkFallenScroll.scroll = BonkHero_ScrollFallen;
	BonkHero_SetupLegend(BonkFallenLegend);
	BonkFallenPanelTitle:SetText(L["Graveyard"]);
	BonkFallenCloseButton:SetText(L["Close"]);
	BonkFallenEmpty:SetText(L["No character has fallen in Hardcore yet."]);
	BonkFallenHint:SetText(L["Click a name to see its record."]);
	BonkFallenHint:SetTextColor(0.75, 0.75, 0.75);
end

function BonkHero_UpdateFallen()
	if ( not BonkFallenPanel ) then
		return;
	end
	PrepareFallenPanel();
	local count = getn(FallenRecords());
	if ( count > 0 ) then
		BonkHeroFallenButton:SetText(L("Graveyard ({1})", count));
		BonkHeroFallenButton:Show();
		BonkFallenEmpty:Hide();
		BonkFallenHint:Show();
	else
		BonkHeroFallenButton:Hide();
		BonkFallenPanel:Hide();
		BonkFallenEmpty:Show();
		BonkFallenHint:Hide();
	end
	BonkHero_UpdateFallenList();
end

function BonkHero_ToggleFallen()
	if ( BonkFallenPanel:IsShown() ) then
		BonkFallenPanel:Hide();
		return;
	end
	BonkHero_UpdateFallen();
	BonkFallenPanel:Show();
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
	Bonk.heroName = nil;
	Bonk.openClass = BONK_CLASSES[1].token;
	Bonk.listOffset = 0;
	Bonk.fallenOffset = 0;
	Bonk.fallenOpen = nil;
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
	if ( Busy() ) then
		return;
	end
	local count = getn(BONK_CLASSES);
	local index = mod(Bonk.classIndex - 1 + direction + count, count) + 1;
	PlaySound("gsCharacterCreationClass");
	BonkHero_Choose(index, FirstHeroName(BONK_CLASSES[index].token));
end

local function RowStops()
	local stops = {};
	for classIndex = 1, getn(BONK_CLASSES) do
		local heroes = HeroesOfClass(BONK_CLASSES[classIndex].token);
		for index = 1, getn(heroes) do
			tinsert(stops, { classIndex = classIndex, hero = heroes[index] });
		end
		tinsert(stops, { classIndex = classIndex });
	end
	return stops;
end

function BonkHero_StepRow(direction)
	if ( Busy() ) then
		return;
	end
	local stops = RowStops();
	local count = getn(stops);
	local current = CurrentHero();
	local position = 1;
	for index = 1, count do
		if ( stops[index].classIndex == Bonk.classIndex and stops[index].hero == current ) then
			position = index;
		end
	end
	local stop = stops[mod(position - 1 + direction + count, count) + 1];
	PlaySound("gsCharacterCreationClass");
	BonkHero_Choose(stop.classIndex, stop.hero and stop.hero.name);
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
		BonkHero_StepRow(-1);
	elseif ( arg1 == "DOWN" ) then
		BonkHero_StepRow(1);
	elseif ( arg1 == "LEFT" and Bonk.customizing ) then
		BonkHero_StepRace(-1);
	elseif ( arg1 == "RIGHT" and Bonk.customizing ) then
		BonkHero_StepRace(1);
	elseif ( arg1 == "LEFT" ) then
		BonkHero_StepClass(-1);
	elseif ( arg1 == "RIGHT" ) then
		BonkHero_StepClass(1);
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
