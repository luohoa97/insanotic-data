#include "dialog_welcome.qh"

#include "image.qh"
#include "textlabel.qh"
#include "textbox.qh"
#include "radiobutton.qh"
#include "commandbutton.qh"
#include "slider.qh"
#include <common/campaign_common.qh>

void welcomeDialog_resetStrings(entity me)
{
	strcpy(me.serverinfo_name, _("Welcome"));
	strcpy(me.serverinfo_MOTD, "");
	strcpy(me.bannerMap, "");
	strcpy(me.bannerTitle, "");
	strcpy(me.bannerType, "");
}

string welcomeDialog_trim(string s)
{
	while (substring(s, 0, 1) == " ") s = substring(s, 1, -1);
	return s;
}

// Insanotic: the welcome text the game sends lists the version greeting,
// game type and map line by line; take the map and game type out for the
// banner and keep the rest (player limits, modifications, the server's own
// message) as the details
string welcomeDialog_splitBanner(entity me, string motd)
{
	string rest = "", line, plain;
	int n = tokenizebyseparator(motd, "\\n");
	int skipped_greeting = false;
	for (int i = 0; i < n; ++i)
	{
		line = argv(i);
		plain = strdecolorize(line);
		if (substring(plain, 0, strlen(_("Gametype:"))) == _("Gametype:"))
		{
			strcpy(me.bannerType, welcomeDialog_trim(substring(plain, strlen(_("Gametype:")), -1)));
			continue;
		}
		if (substring(plain, 0, strlen(_("Map:"))) == _("Map:"))
		{
			string m = welcomeDialog_trim(substring(plain, strlen(_("Map:")), -1));
			int sep = strstrofs(m, " // ", 0);
			string bsp = (sep >= 0) ? substring(m, 0, sep) : m;
			strcpy(me.bannerTitle, (sep >= 0) ? substring(m, sep + 4, -1) : m);
			strcpy(me.bannerMap, strcat("/maps/", strtolower(bsp)));
			continue;
		}
		// the plain greeting ("Welcome to ..."); version warnings stay
		if (!skipped_greeting && plain != "" && strstrofs(line, "^1", 0) < 0 && strstrofs(line, "^3", 0) < 0)
		{
			skipped_greeting = true;
			continue;
		}
		if (plain == "" && rest == "") continue;
		rest = (rest == "") ? line : strcat(rest, "\\n", line);
	}
	return rest;
}

float XonoticWelcomeDialog_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		case K_KP_ENTER:
		case K_ENTER:
		case K_SPACE:
			XonoticCommandButton_Click(me.joinButton_ent, me);
			return true;
		default:
			return SUPER(XonoticWelcomeDialog).keyDown(me, key, ascii, shift);
	}
}

// the same implentation in mousePress apparently works, but for some reason if you try to open
// the dialog again it doesn't show up and requires opening it a seconds time to show up
bool XonoticWelcomeDialog_mouseRelease(entity me, vector pos)
{
	if (pos.x >= 0 && pos.y >= 0 && pos.x < 1 && pos.y < 1)
	{
		return SUPER(XonoticWelcomeDialog).mouseRelease(me, pos);
	}
	me.close(me);
	return true;
}

void XonoticWelcomeDialog_destroy(entity me)
{
	cvar_set("_menu_welcome_dialog_available", "0");
}

void XonoticWelcomeDialog_readInputArgs(entity me, int argsbuf)
{
	int i = 0;
	string s;
	welcomeDialog_resetStrings(me);
	if(argsbuf >= 0)
	while((s = bufstr_get(argsbuf, i)) != "")
	{
		if(s == "HOSTNAME")
			strcpy(me.serverinfo_name, bufstr_get(argsbuf, ++i));
		else if(s == "WELCOME")
			strcpy(me.serverinfo_MOTD, bufstr_get(argsbuf, ++i));
		else if(s == "CAMPAIGN")
		{
			strcpy(me.serverinfo_name, campaign_title);

			int level = stoi(bufstr_get(argsbuf, ++i)) - 1;
			string campaign_msg;
			if (level < 0 || level >= campaign_entries)
				campaign_msg = strcat("^1Error: invalid level number ", itos(level + 1));
			else
			{
				string desc = strcat(campaign_shortdesc[level], "\n\n", campaign_longdesc[level]);
				desc = strreplace("\n", "\\n", desc);
				campaign_msg = strreplace("_LEVEL_DESC", desc, bufstr_get(argsbuf, ++i));
			}
			strcpy(me.serverinfo_MOTD, campaign_msg);
			if (level >= 0 && level < campaign_entries)
			{
				strcpy(me.bannerMap, strcat("/maps/", campaign_mapname[level]));
				strcpy(me.bannerTitle, campaign_shortdesc[level]);
				strcpy(me.bannerType, sprintf(_("Level %d"), level + 1));
			}
			break;
		}
		else if(s == "RESET")
		{
			welcomeDialog_resetStrings(me);
			break;
		}
		++i;
	}
	//me.serverinfo_name_ent.setText(me.serverinfo_name_ent, me.serverinfo_name);
	string details = me.serverinfo_MOTD;
	if (me.bannerTitle == "" && details != "")
		details = welcomeDialog_splitBanner(me, details);
	me.serverinfo_MOTD_ent.setText(me.serverinfo_MOTD_ent, details);
	me.frame.setText(me.frame, me.serverinfo_name);
}

void XonoticWelcomeDialog_draw(entity me)
{
	SUPER(XonoticWelcomeDialog).draw(me);

	// map banner: the map's picture with its name and the game type
	entity b = me.bannerItem;
	if (b && me.bannerTitle != "")
	{
		vector o = b.Container_origin, sz = b.Container_size;
		if (!draw_PictureCover(o, me.bannerMap, sz, 0.55, 1))
			draw_Fill(o, sz, '0.06 0.09 0.15', 1);
		for (int k = 0; k < 8; ++k)
			draw_Fill(o + eY * sz.y * (0.35 + 0.65 * k / 8), eX * sz.x + eY * sz.y * 0.65 / 8, '0 0 0', 0.09 * (k + 1));
		float th = sz.y * 0.26, gh = sz.y * 0.12;
		float ratio = draw_scale.y / draw_scale.x;
		vector p = o + eX * sz.y * 0.12 * ratio + eY * (sz.y - th - gh * 1.6);
		if (me.bannerType != "")
			draw_Text(p, strtoupper(me.bannerType), eX * gh * ratio + eY * gh, '0.3 0.65 1', 1, false);
		draw_Text(p + eY * gh * 1.4, draw_TextShortenToWidth(me.bannerTitle, sz.x * 0.9, false, eX * th * ratio + eY * th), eX * th * ratio + eY * th, '1 1 1', 1, false);
	}

	if (!(gamestatus & (GAME_ISSERVER | GAME_CONNECTED)))
		me.close(me);

	if(me.serverinfo_MOTD == "" && gamestatus & (GAME_CONNECTED | GAME_ISSERVER))
	{
		// if serverinfo_MOTD is empty while connected it means we are connected to an old server
		// in this case show the csqc welcome message and instantly close the dialog
		localcmd("\n+show_info0; defer 2 -show_info0\n");
		me.close(me);
	}

	if (isdemo())
	{
		me.joinButton_ent.disabled = true;
		me.spectateButton_ent.disabled = true;
	}
	else
	{
		me.joinButton_ent.disabled = false;
		me.spectateButton_ent.disabled = false;
	}
}

void XonoticWelcomeDialog_fill(entity me)
{
	registercvar("_menu_welcome_dialog_available", "0", 0);
	cvar_set("_menu_welcome_dialog_available", "1");

	me.frame.allowColors = true; // allow color codes in the title

	entity e;

	me.TR(me);
		me.TD(me, 5, me.columns, me.bannerItem = makeXonoticTextLabel(0, ""));
	me.gotoRC(me, 5.5, 0);
		me.TD(me, me.rows - 6.5, me.columns, me.serverinfo_MOTD_ent = makeXonoticTextBox());
			me.serverinfo_MOTD_ent.align = 0.5;
			me.serverinfo_MOTD_ent.allowColors = true;
			me.serverinfo_MOTD_ent.escapedNewLines = true;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns / 2, me.joinButton_ent = makeXonoticCommandButton(_("Join"), '0 0 0', "cmd join", COMMANDBUTTON_CLOSE));
			me.joinButton_ent.preferredFocusPriority = 1;
			me.joinButton_ent.fillStyle = true;
			me.joinButton_ent.fillColor = '0.12 0.38 0.75';
		me.TD(me, 1, me.columns / 2, me.spectateButton_ent = makeXonoticCommandButton(_("Spectate"), '0 0 0', "cmd spectate", COMMANDBUTTON_CLOSE));
			me.spectateButton_ent.fillStyle = true;
}
