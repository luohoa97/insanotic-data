// SPDX-License-Identifier: GPL-3.0-or-later
// Insanotic: Game > Assist settings. The cvars belong to the aim_assist
// client mod (mods/aim_assist), which registers and saves them.
#include "dialog_settings_game_assist.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "textslider.qh"
#include "slider.qh"

void XonoticGameAssistSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameAssistSettingsTab()
{
	entity me;
	me = NEW(XonoticGameAssistSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameAssistSettingsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Aim assist:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("aim_assist_mode",
			_("Only in your own games and on servers that allow it (sv_allow_assist)")));
			e.addValue(e, ZCTX(_("ASSIST^Off")), "0");
			e.addValue(e, ZCTX(_("ASSIST^Touch only")), "1");
			e.addValue(e, ZCTX(_("ASSIST^Always")), "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Pull toward enemies")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Cone")));
			setDependent(e, "aim_assist_mode", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 30, 1, "aim_assist_cone",
			_("Degrees from the crosshair where the pull starts")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Min pull")));
			setDependent(e, "aim_assist_mode", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 10, 0.5, "aim_assist_pull_min",
			_("Pull strength at the edge of the cone")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Max pull")));
			setDependent(e, "aim_assist_mode", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 20, 0.5, "aim_assist_pull_max",
			_("Pull strength with the crosshair on the enemy")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Range")));
			setDependent(e, "aim_assist_mode", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(500, 8000, 250, "aim_assist_range",
			_("Farthest enemy the pull reaches")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "aim_assist_lead", _("Lead moving enemies"),
			_("Projectile weapons aim where the shot meets the enemy")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "aim_assist_feet", _("Splash weapons aim at the feet"),
			_("A near miss still catches a standing enemy in the blast")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "aim_assist_rifle_head", _("Rifle aims for the head"), "-"));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "aim_assist_steer", _("Steer and detonate Devastator rockets"),
			_("Keeps the rocket on the enemy and sets it off next to them")));
			setDependent(e, "aim_assist_mode", 1, 2);

	me.gotoRC(me, 0, 3.4); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "aim_assist_autofire", _("Auto-fire"),
			_("Fire while an enemy is under the crosshair; never at teammates, into walls, or where the blast would hurt you")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Range")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(250, 8000, 250, "aim_assist_autofire_range",
			_("Farthest enemy auto-fire shoots at")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Hitbox")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 2, 0.05, "aim_assist_hitbox_scale",
			_("How much bigger an enemy counts as for auto-fire")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Delay")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 0.5, 0.02, "aim_assist_autofire_delay",
			_("Reaction time before auto-fire starts")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox_T(0, "aim_assist_lock", _("Lock the shot onto the enemy"),
			_("Every shot auto-fire takes goes exactly to the enemy")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Lock cone")));
			setDependentAND3(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1, "aim_assist_lock", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 15, 0.5, "aim_assist_autofire_cone",
			_("With the lock, fire as soon as the enemy is this many degrees from the crosshair")));
			setDependentAND3(e, "aim_assist_mode", 1, 2, "aim_assist_autofire", 1, 1, "aim_assist_lock", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "aim_assist_autoswitch", _("Switch to the best weapon"),
			_("Picks the weapon for the distance, the enemy's movement, your ammo and health")));
			setDependent(e, "aim_assist_mode", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Hands off")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autoswitch", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 15, 1, "aim_assist_switch_manual",
			_("Seconds it leaves a weapon you picked yourself alone")));
			setDependentAND(e, "aim_assist_mode", 1, 2, "aim_assist_autoswitch", 1, 1);
}
