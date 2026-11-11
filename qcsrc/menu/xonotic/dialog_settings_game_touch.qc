// SPDX-License-Identifier: GPL-3.0-or-later
// Insanotic: Game > Touch settings. The cvars belong to the touch_controls
// client mod (mods/touch_controls), which registers and saves them.
#include "dialog_settings_game_touch.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "textslider.qh"
#include "slider.qh"

void XonoticGameTouchSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameTouchSettingsTab()
{
	entity me;
	me = NEW(XonoticGameTouchSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameTouchSettingsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 6, e = makeXonoticHeaderLabel(_("On-screen controls")));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Show:")));
		me.TD(me, 1, 4.5, e = makeXonoticTextSlider_T("touch_controls_force",
			_("Automatic shows them while you play with a touchscreen and hides them when you use keyboard or mouse")));
			e.addValue(e, ZCTX(_("TOUCH^Automatic")), "0");
			e.addValue(e, ZCTX(_("TOUCH^Always")), "1");
			e.addValue(e, ZCTX(_("TOUCH^Never")), "-1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Size:")));
		me.TD(me, 1, 4.5, e = makeXonoticSlider_T(0.5, 2, 0.05, "touch_controls_size",
			_("Scale of all buttons and the joystick")));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Opacity:")));
		me.TD(me, 1, 4.5, e = makeXonoticSlider_T(0.2, 1, 0.05, "touch_controls_opacity",
			_("How solid the controls are drawn")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 6, e = makeXonoticHeaderLabel(_("Joystick and looking")));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Look speed:")));
		me.TD(me, 1, 4.5, e = makeXonoticSlider_T(0.05, 1, 0.01, "touch_controls_look_sensitivity",
			_("Degrees the view turns per screen unit your finger moves")));
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Dead zone:")));
		me.TD(me, 1, 4.5, e = makeXonoticSlider_T(0, 0.5, 0.01, "touch_controls_stick_deadzone",
			_("Share of the joystick's radius around the centre that does nothing")));
	me.TR(me);
		me.TD(me, 1, 6, e = makeXonoticCheckBox_T(0, "touch_controls_fire_look", _("Turn the view while dragging on FIRE"),
			_("Move your finger on the fire button to aim while shooting")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 6, e = makeXonoticHeaderLabel(_("Movement help")));
	me.TR(me);
		me.TD(me, 1, 6, e = makeXonoticCheckBox_T(0, "touch_controls_autohop", _("Bunny hop while holding JUMP"),
			_("Jumps again at every landing, so you keep your speed")));
	me.TR(me);
		me.TD(me, 1, 6, e = makeXonoticCheckBox_T(0, "touch_controls_airstrafe", _("Air strafing"),
			_("In the air, sideways joystick input while you turn the view strafes the way you turn to gain speed. Only in your own games and on servers that allow assists (sv_allow_assist)")));
}
