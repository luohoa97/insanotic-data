#include "campaign.qh"

bool CampaignList_Rich();

#include <common/campaign_common.qh>
#include "inputbox.qh"

string campaign_longdesc_wrapped[CAMPAIGN_MAX_ENTRIES];

void rewrapCampaign(float w, float l0, float emptyheight, vector theFontSize)
{
	int i, j;
	int n;
	float l;
	string r, s;
	for(i = 0; i < campaign_entries; ++i)
	{
		l = l0;
		strfree(campaign_longdesc_wrapped[i]);
		n = tokenizebyseparator(campaign_longdesc[i], "\n");
		r = "";
		for(j = 0; j < n; ++j)
		{
			s = argv(j);
			if(s == "")
			{
				l -= emptyheight;
				r = strcat(r, "\n");
				continue;
			}

			getWrappedLine_remaining = s;
			while(getWrappedLine_remaining)
			{
				s = getWrappedLine(w, theFontSize, draw_TextWidth_WithoutColors);
				if(--l < 0) goto toolong;
				r = strcat(r, s, "\n");
			}
		}
		goto nottoolong;
LABEL(toolong)
		while(substring(r, strlen(r) - 1, 1) == "\n")
			r = substring(r, 0, strlen(r) - 1);
		r = strcat(r, "...\n");
LABEL(nottoolong)
		campaign_longdesc_wrapped[i] = strzone(substring(r, 0, strlen(r) - 1));
	}
}

entity makeXonoticCampaignList()
{
	entity me;
	me = NEW(XonoticCampaignList);
	me.configureXonoticCampaignList(me);
	return me;
}
void XonoticCampaignList_configureXonoticCampaignList(entity me)
{
	me.configureXonoticListBox(me);
	me.campaignGlob = search_begin("maps/campaign*.txt", true, true);
	me.loadCvars(me);
	me.campaignGo(me, 0); // it makes work buttons too
}

void XonoticCampaignList_destroy(entity me)
{
	if(me.campaignGlob >= 0)
		search_end(me.campaignGlob);
}

void XonoticCampaignList_loadCvars(entity me)
{
	// read campaign cvars
	strcpy(campaign_name, cvar_string("g_campaign_name"));
	strcpy(me.controlledCvar, strcat("g_campaign", campaign_name, "_index"));
	registercvar(me.controlledCvar, "", 0); // saved by server QC anyway
	CampaignFile_Unload();
	CampaignFile_Load(0, CAMPAIGN_MAX_ENTRIES);
	me.campaignIndex = bound(0, cvar(me.controlledCvar), campaign_entries);
	cvar_set(me.controlledCvar, ftos(me.campaignIndex));
	if(me.columnNameSize)
		rewrapCampaign(me.columnNameSize, me.rowsPerItem - 3, me.emptyLineHeight, me.realFontSize);
	me.nItems = min(me.campaignIndex + 2, campaign_entries);
	me.setSelected(me, min(me.campaignIndex, me.nItems - 1));
	if(me.nItems - 1 > me.campaignIndex)
		me.scrollToItem(me, me.nItems - 1);
	if(me.labelTitle)
		me.labelTitle.setText(me.labelTitle, campaign_title);
}

void XonoticCampaignList_saveCvars(entity me)
{
	// write campaign cvars
	// no reason to do this!
	// cvar_set("g_campaign_name", campaign_name);
	// cvar_set(me.controlledCvar, ftos(me.campaignIndex)); // NOTE: only server QC does that!
}

void XonoticCampaignList_campaignGo(entity me, float step)
{
	string s;
	float i, j, n;

	if(me.campaignGlob >= 0)
	{
		n = search_getsize(me.campaignGlob);
		if(n > 0)
		{
			j = -1;
			s = strcat("maps/campaign", campaign_name, ".txt");
			for(i = 0; i < n; ++i)
			{
				if(search_getfilename(me.campaignGlob, i) == s)
					j = i;
			}
			if(j < 0)
			{
				s = strcat("maps/campaign", cvar_defstring("g_campaign_name"), ".txt");
				for(i = 0; i < n; ++i)
				{
					if(search_getfilename(me.campaignGlob, i) == s)
						j = i;
				}
			}
			if(j < 0)
			{
				if(step >= 0)
					j = 0;
				else
					j = n - 1;
			}
			else
				j = mod(j + step, n);
			s = search_getfilename(me.campaignGlob, j);
			s = substring(s, 13, strlen(s) - 17);
			cvar_set("g_campaign_name", s);
			me.loadCvars(me);
			me.hasNextCampaign = (j != n - 1);
			me.hasPrevCampaign = (j != 0);
		}
	}
}

void MultiCampaign_Next(entity btn, entity me)
{
	me.campaignGo(me, +1);
}
void MultiCampaign_Prev(entity btn, entity me)
{
	me.campaignGo(me, -1);
}

void XonoticCampaignList_draw(entity me)
{
	if(me.buttonNext)
		me.buttonNext.disabled = !me.hasNextCampaign;
	if(me.buttonPrev)
		me.buttonPrev.disabled = !me.hasPrevCampaign;

	if(cvar(me.controlledCvar) != me.campaignIndex || cvar_string("g_campaign_name") != campaign_name)
		me.loadCvars(me);
	SUPER(XonoticCampaignList).draw(me);
}

void XonoticCampaignList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticCampaignList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin1 = 0.5 * me.realFontSize.y;
	me.realUpperMargin2 = me.realUpperMargin1 + 2 * me.realFontSize.y;

	me.checkMarkSize = (eX * (me.itemAbsSize.y / me.itemAbsSize.x) + eY) * 0.5;

	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = me.itemAbsSize.y / me.itemAbsSize.x * 4 / 3;
	me.columnCheckMarkSize = me.checkMarkSize.x;
	me.columnNameSize = 1 - me.columnPreviewSize - me.columnCheckMarkSize - 4 * me.realFontSize.x;
	me.columnNameOrigin = me.columnPreviewOrigin + me.columnPreviewSize + me.realFontSize.x;
	me.columnCheckMarkOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize.x * 2;

	me.checkMarkOrigin = eY + eX * (me.columnCheckMarkOrigin + me.columnCheckMarkSize) - me.checkMarkSize;

	me.typeIconOrigin = vec3(me.columnPreviewSize - me.checkMarkSize.x, me.checkMarkOrigin.y, 0);
	me.typeIconSize = me.checkMarkSize;

	if (CampaignList_Rich())
	{
		// Insanotic: text over the map picture, on the left 60% of the row
		me.columnNameOrigin = 3 * me.realFontSize.x;
		me.columnNameSize = 0.6 - me.columnNameOrigin;
	}

	rewrapCampaign(me.columnNameSize, me.rowsPerItem - 3, me.emptyLineHeight, me.realFontSize);
}
void XonoticCampaignList_doubleClickListBoxItem(entity me, float i, vector where)
{
	CampaignList_LoadMap(me, me);
}
// Insanotic: every level is a banner filled with its map's picture
bool CampaignList_Rich()
{
	return !(cvar_type("menu_buttons") && !cvar("menu_buttons"));
}

void CampaignList_DrawRichItem(entity me, int i, bool isSelected, bool isFocused)
{
	bool done = (i < me.campaignIndex), current = (i == me.campaignIndex), locked = (i > me.campaignIndex);
	float ratio = me.itemAbsSize.y / max(1, me.itemAbsSize.x); // row height in row widths
	vector o = eY * 0.04, sz = eX + eY * 0.92;
	vector accent = '0.3 0.65 1';
	string img = strcat("/maps/", campaign_mapname[i]);
	vector isz = draw_PictureSize(img);
	float lit = (isSelected || isFocused) ? 1 : 0;
	if (isz != '0 0 0')
	{
		// cover the row with the picture, centered
		float aspect = me.itemAbsSize.x * sz.x / max(1, me.itemAbsSize.y * sz.y);
		float iaspect = isz.x / max(1, isz.y);
		vector src = '1 1 0', srcpos = '0 0 0';
		if (iaspect > aspect) { src.x = aspect / iaspect; srcpos.x = (1 - src.x) / 2; }
		else { src.y = iaspect / aspect; srcpos.y = (1 - src.y) / 2; }
		float b = locked ? 0.15 : (done ? 0.45 : 0.6);
		b += 0.2 * lit;
		drawsubpic(boxToGlobal(o, draw_shift, draw_scale), boxToGlobalSize(sz, draw_scale), draw_UseSkinFor(img),
			srcpos, src, eX * b + eY * b + eZ * b, draw_alpha, 0);
	}
	else
		draw_Fill(o, sz, '0.05 0.08 0.14', 1);
	// darker on the left, where the text is
	for (int k = 0; k < 10; ++k)
		draw_Fill(o + eX * 0.07 * k, eX * 0.07 + eY * sz.y, '0 0 0', 0.07 * (10 - k));
	// current level: accent stripe; selected: accent edge
	if (current)
		draw_Fill(o, eX * 4 * ratio * 0.03 + eY * sz.y, accent, 1);
	if (isSelected)
	{
		float px = 1 / max(1, me.itemAbsSize.x), py = 1 / max(1, me.itemAbsSize.y);
		draw_Fill(o, eX + eY * py * 2, accent, 1);
		draw_Fill(o + eY * (sz.y - py * 2), eX + eY * py * 2, accent, 1);
		draw_Fill(o, eX * px * 2 + eY * sz.y, accent, 1);
		draw_Fill(o + eX * (1 - px * 2), eX * px * 2 + eY * sz.y, accent, 1);
	}

	// level number, title, description
	vector fs = me.realFontSize;
	vector tfs = fs * 1.7;
	vector p = eX * me.columnNameOrigin + eY * (0.12);
	draw_Text(p, strtoupper(sprintf(_("Level %d"), i + 1)), fs, (locked ? '0.6 0.6 0.6' : accent), 1, 0);
	p.y += fs.y * 1.3;
	string title = locked ? _("Locked") : campaign_shortdesc[i];
	draw_Text(p, draw_TextShortenToWidth(title, me.columnNameSize, 0, tfs), tfs, '1 1 1', (locked ? 0.6 : 1), 0);
	p.y += tfs.y * 1.25;
	if (!locked)
	{
		string s = campaign_longdesc_wrapped[i];
		int n = tokenizebyseparator(s, "\n");
		for (int j = 0; j < n && p.y + fs.y < 0.95; ++j)
		{
			if (argv(j) == "") { p.y += fs.y * me.emptyLineHeight; continue; }
			draw_Text(p, argv(j), fs, '0.85 0.88 0.92', 0.9, 0);
			p.y += fs.y;
		}
	}

	// right side: done check, "NEXT" chip or lock
	vector chip = eX * (1 - 3 * fs.x) + eY * 0.12;
	if (done)
		draw_Picture(eX * (1 - me.checkMarkSize.x - 2 * fs.x) + eY * 0.1, "checkmark", me.checkMarkSize, '1 1 1', 1);
	else if (current)
	{
		string t = _("NEXT");
		float tw = draw_TextWidth(t, 0, fs);
		vector cp = chip - eX * (tw + fs.x);
		draw_Fill(cp - eX * fs.x * 0.5 - eY * fs.y * 0.3, eX * (tw + fs.x) + eY * fs.y * 1.6, accent, 0.9);
		draw_Text(cp, t, fs, '1 1 1', 1, 0);
	}
	string gt = strcat("/gfx/menu/", cvar_string("menu_skin"), "/gametype_", campaign_gametype[i]);
	if (!locked && draw_PictureSize(gt) != '0 0 0')
		draw_Picture(eX * (1 - me.checkMarkSize.x - 2 * fs.x) + eY * (0.9 - me.checkMarkSize.y), gt, me.checkMarkSize, '1 1 1', 0.9);
}

void XonoticCampaignList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	if (CampaignList_Rich())
	{
		CampaignList_DrawRichItem(me, i, isSelected, isFocused);
		return;
	}
	string s;
	vector theColor;
	float theAlpha;
	float j, n;
	vector o;

	if(i < me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_SELECTABLE;
		theColor = SKINCOLOR_CAMPAIGN_SELECTABLE;
	}
	else if(i == me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_CURRENT;
		theColor = SKINCOLOR_CAMPAIGN_CURRENT;
	}
	else
	{
		theAlpha = SKINALPHA_CAMPAIGN_FUTURE;
		theColor = SKINCOLOR_CAMPAIGN_FUTURE;
	}

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	if(draw_PictureSize(strcat("/maps/", campaign_mapname[i])) == '0 0 0')
		draw_Picture(me.columnPreviewOrigin * eX, "nopreview_map", me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	else
		draw_Picture(me.columnPreviewOrigin * eX, strcat("/maps/", campaign_mapname[i]), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);

	s = strcat("/gfx/menu/", cvar_string("menu_skin"), "/gametype_", campaign_gametype[i]);
	if(i <= me.campaignIndex && draw_PictureSize(s) != '0 0 0')
		draw_Picture(me.typeIconOrigin, s, me.typeIconSize, '1 1 1', 1);

	if(i < me.campaignIndex)
		draw_Picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);
	if(i <= me.campaignIndex)
		s = campaign_shortdesc[i]; // fteqcc sucks
	else
		s = "???";
	// NOTE the following string should be equal to the one used in the Welcome dialog
	// to avoid adding a slightly different string to translate
	s = draw_TextShortenToWidth(strcat(sprintf(_("Level %d:"), i+1), " ", s), me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, theColor, theAlpha, 0);

	if(i <= me.campaignIndex)
	{
		s = campaign_longdesc_wrapped[i];
		n = tokenizebyseparator(s, "\n");
		o = me.realUpperMargin2 * eY + me.columnNameOrigin * eX;
		for(j = 0; j < n; ++j)
			if(argv(j) != "")
			{
				draw_Text(o, argv(j), me.realFontSize, theColor, theAlpha * SKINALPHA_CAMPAIGN_DESCRIPTION, 0);
				o.y += me.realFontSize.y;
			}
			else
				o.y += me.realFontSize.y * me.emptyLineHeight;
	}
}
void CampaignList_LoadMap(entity btn, entity me)
{
	if(me.selectedItem >= me.nItems || me.selectedItem < 0)
		return;
	CampaignSetup(me.selectedItem);
}

void XonoticCampaignList_setSelected(entity me, float i)
{
	// prevent too late items from being played
	SUPER(XonoticCampaignList).setSelected(me, min(i, me.campaignIndex));
}

float XonoticCampaignList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_SPACE || scan == K_KP_ENTER)
		CampaignList_LoadMap(me, me);
	else
		return SUPER(XonoticCampaignList).keyDown(me, scan, ascii, shift);
	return 1;
}
