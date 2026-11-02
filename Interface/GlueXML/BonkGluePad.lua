local L = BonkGlueL;

BonkPad = { kind = nil, signature = nil };

local PAD_SLOTS = 7;
local PAD_GLYPH = 24;
local PAD_LABEL_GAP = 5;
local PAD_GAP = 14;
local PAD_SHADE_MIN = 460;
local PAD_SHADE_EXTRA = 160;
local PAD_GRID = 8;
local PAD_STICK_DEADZONE = 0.25;
local PAD_ROTATE_DEGREES = 180;
local PAD_PAIR_GAP = 2;
local PAD_CELLS = {
	xbox = { a = { 0, 0 }, b = { 1, 0 }, x = { 2, 0 }, y = { 3, 0 }, lb = { 4, 0 }, rb = { 5, 0 }, view = { 0, 2 }, menu = { 1, 2 }, rs = { 3, 2 } },
	ps = { a = { 0, 1 }, b = { 1, 1 }, x = { 2, 1 }, y = { 3, 1 }, lb = { 4, 1 }, rb = { 5, 1 }, view = { 0, 3 }, menu = { 1, 3 }, rs = { 3, 3 } },
	any = { dpad = { 0, 4 }, leftright = { 6, 4 }, updown = { 5, 4 } },
};
local PAD_PAIRS = { lbrb = { "lb", "rb" } };
local PAD_NAME_STARTS = { "Ash", "Bel", "Bran", "Cael", "Dor", "Eld", "Fen", "Gar", "Hal", "Ith", "Jor", "Kael", "Lor", "Mor", "Nyl",
	"Or", "Quel", "Ren", "Syl", "Thal", "Ul", "Vor", "Wyn", "Zan" };
local PAD_NAME_ENDS = { "dris", "gar", "ion", "ath", "ren", "wyn", "ok", "as", "dor", "mir", "ius", "eth", "ra", "nar", "os", "ven",
	"ia", "rik", "on", "ash", "el", "ul", "is", "orn" };

local function PadRandom(count)
	return math.random(count);
end

function BonkPad_RandomName()
	return PAD_NAME_STARTS[PadRandom(getn(PAD_NAME_STARTS))] .. PAD_NAME_ENDS[PadRandom(getn(PAD_NAME_ENDS))];
end

local function PadDialogOpen()
	return GlueDialog and GlueDialog:IsShown();
end

local function PadCreating()
	return Bonk and Bonk.customizing;
end

local function PadPreviewing()
	return Bonk and not Bonk.customizing and Bonk.heroes and not Bonk.heroes[BONK_CLASSES[Bonk.classIndex].token];
end

local function PadHeroScreen()
	return BonkHeroFrame and BonkHeroFrame:IsShown();
end

local function PadDialogButton(name)
	if ( name == "a" ) then
		GlueDialogButton1:Click();
	elseif ( name == "b" ) then
		if ( GlueDialogButton2:IsShown() ) then
			GlueDialogButton2:Click();
		else
			GlueDialogButton1:Click();
		end
	end
end

local function PadCreateHero()
	if ( BonkHeroNameEdit:GetText() == "" ) then
		BonkHeroNameEdit:SetText(BonkPad_RandomName());
	end
	BonkHero_Play();
end

local function PadNewLook()
	BonkHero_Randomize();
	BonkHeroNameEdit:SetText(BonkPad_RandomName());
end

local function PadToggleSex()
	if ( Bonk.sex == 1 ) then
		BonkHero_SelectSex(2);
	else
		BonkHero_SelectSex(1);
	end
end

function HoAController_OnButton(name, down)
	if ( not down ) then
		return;
	end
	if ( PadDialogOpen() ) then
		PadDialogButton(name);
		return;
	end
	if ( not PadHeroScreen() ) then
		return;
	end
	if ( name == "a" ) then
		if ( PadCreating() ) then
			PadCreateHero();
		else
			BonkHero_Play();
		end
	elseif ( name == "up" or name == "left" ) then
		BonkHero_StepClass(-1);
	elseif ( name == "down" or name == "right" ) then
		BonkHero_StepClass(1);
	elseif ( name == "lb" and PadCreating() ) then
		BonkHero_StepRace(-1);
	elseif ( name == "rb" and PadCreating() ) then
		BonkHero_StepRace(1);
	elseif ( name == "x" and PadCreating() ) then
		PadToggleSex();
	elseif ( name == "y" and PadCreating() ) then
		PadNewLook();
	elseif ( name == "view" and not PadCreating() ) then
		BonkHero_Retire();
	elseif ( name == "b" and PadCreating() ) then
		BonkHero_Back();
	elseif ( name == "b" or name == "menu" ) then
		BonkHero_Quit();
	end
end

function HoAController_OnDevice(kind)
	BonkPad.kind = kind;
	BonkPad.signature = nil;
end

local function PadPrompts()
	if ( PadDialogOpen() ) then
		local prompts = { { "a", GlueDialogButton1:GetText() or "" } };
		if ( GlueDialogButton2:IsShown() ) then
			tinsert(prompts, { "b", GlueDialogButton2:GetText() or "" });
		end
		return prompts;
	end
	if ( not PadHeroScreen() ) then
		return nil;
	end
	if ( PadCreating() ) then
		return { { "a", L["Create"] }, { "lbrb", L["Race"] }, { "x", L["Male or female"] }, { "y", L["New look"] }, { "rs", L["Turn"] }, { "b", L["Back"] } };
	end
	if ( PadPreviewing() ) then
		return { { "a", L("Create {1}", BONK_CLASSES[Bonk.classIndex].display) }, { "dpad", L["Class"] }, { "rs", L["Turn"] }, { "b", L["Quit"] } };
	end
	return { { "a", L["Play"] }, { "dpad", L["Class"] }, { "view", L["Delete"] }, { "rs", L["Turn"] }, { "b", L["Quit"] } };
end

local function PadSetGlyph(texture, name)
	local cells = PAD_CELLS[BonkPad.kind] or PAD_CELLS.xbox;
	local cell = cells[name] or PAD_CELLS.any[name];
	if ( not cell ) then
		texture:Hide();
		return;
	end
	texture:SetTexCoord(cell[1] / PAD_GRID, (cell[1] + 1) / PAD_GRID, cell[2] / PAD_GRID, (cell[2] + 1) / PAD_GRID);
	texture:Show();
end

local function PadShowPrompts(prompts)
	local signature = BonkPad.kind;
	for index = 1, getn(prompts) do
		signature = signature .. "|" .. prompts[index][1] .. "=" .. prompts[index][2];
	end
	if ( signature == BonkPad.signature and BonkPadFrame:IsShown() ) then
		return;
	end
	BonkPad.signature = signature;
	local x = 0;
	for index = 1, PAD_SLOTS do
		local slot = getglobal("BonkPadSlot" .. index);
		local prompt = prompts[index];
		if ( prompt ) then
			local glyph = getglobal("BonkPadSlot" .. index .. "Glyph");
			local second = getglobal("BonkPadSlot" .. index .. "Glyph2");
			local pair = PAD_PAIRS[prompt[1]];
			local glyphsWidth = PAD_GLYPH;
			local labelAnchor = glyph;
			if ( pair ) then
				PadSetGlyph(glyph, pair[1]);
				PadSetGlyph(second, pair[2]);
				glyphsWidth = PAD_GLYPH * 2 + PAD_PAIR_GAP;
				labelAnchor = second;
			else
				PadSetGlyph(glyph, prompt[1]);
				second:Hide();
			end
			local label = getglobal("BonkPadSlot" .. index .. "Label");
			label:SetText(prompt[2]);
			label:ClearAllPoints();
			label:SetPoint("LEFT", labelAnchor, "RIGHT", PAD_LABEL_GAP, 0);
			local width = glyphsWidth + PAD_LABEL_GAP + label:GetStringWidth();
			slot:SetWidth(width);
			slot:ClearAllPoints();
			slot:SetPoint("LEFT", "BonkPadFrame", "LEFT", x, 0);
			slot:Show();
			x = x + width + PAD_GAP;
		else
			slot:Hide();
		end
	end
	local width = x - PAD_GAP;
	if ( width < 1 ) then
		width = 1;
	end
	BonkPadFrame:SetWidth(width);
	if ( width + PAD_SHADE_EXTRA > PAD_SHADE_MIN ) then
		BonkPadFrameShade:SetWidth(width + PAD_SHADE_EXTRA);
	else
		BonkPadFrameShade:SetWidth(PAD_SHADE_MIN);
	end
	BonkPadFrame:Show();
end

local function PadTurn(elapsed)
	if ( not HoAController_GetSticks or not PadHeroScreen() or PadDialogOpen() ) then
		return;
	end
	local _, _, rx = HoAController_GetSticks();
	if ( not rx or (rx < PAD_STICK_DEADZONE and rx > -PAD_STICK_DEADZONE) ) then
		return;
	end
	local turn = rx * PAD_ROTATE_DEGREES * elapsed;
	if ( Bonk.screen == "charcreate" ) then
		SetCharacterCreateFacing(GetCharacterCreateFacing() + turn);
	else
		SetCharacterSelectFacing(GetCharacterSelectFacing() + turn);
	end
end

function BonkPad_OnUpdate(elapsed)
	local prompts = BonkPad.kind and PadPrompts();
	if ( prompts ) then
		PadShowPrompts(prompts);
		PadTurn(elapsed or 0);
	elseif ( BonkPadFrame:IsShown() ) then
		BonkPad.signature = nil;
		BonkPadFrame:Hide();
	end
end
