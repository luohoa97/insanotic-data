#include "button.qh"

	void Button_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		if (me.srcMulti) me.keepspaceLeft = 0;
		else me.keepspaceLeft = min(0.8, absSize.x == 0 ? 0 : (absSize.y / absSize.x));
		SUPER(Button).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

		if(me.disableOnClick)
			me.disabled = true; // initially disabled
	}
	void Button_configureButton(entity me, string txt, float sz, string gfx)
	{
		SUPER(Button).configureLabel(me, txt, sz, me.srcMulti ? 0.5 : 0);
		me.src = gfx;
	}
	float Button_keyDown(entity me, float key, float ascii, float shift)
	{
		if (key == K_ENTER || key == K_SPACE || key == K_KP_ENTER)
		{
			if(!me.disabled)
			{
				me.playClickSound(me);
				me.clickTime = 0.1;  // delayed for effect
			}
			return 1;
		}
		return 0;
	}
	float Button_mouseDrag(entity me, vector pos)
	{
		me.pressed = 1;
		if (pos.x < 0) me.pressed = 0;
		if (pos.y < 0) me.pressed = 0;
		if (pos.x >= 1) me.pressed = 0;
		if (pos.y >= 1) me.pressed = 0;
		return 1;
	}
	METHOD(Button, mousePress, bool(Button this, vector pos))
	{
		this.mouseDrag(this, pos);  // verify coordinates
		return true;
	}
	float Button_mouseRelease(entity me, vector pos)
	{
		me.mouseDrag(me, pos);  // verify coordinates
		if (me.pressed)
		{
			if (!me.disabled)
			{
				me.playClickSound(me);
				if (me.onClick)
				{
					if(me.applyButton)
						me.applyButton.disabled = false;
					me.onClick(me, me.onClickEntity);
					if(me.disableOnClick)
						me.disabled = true;
				}
			}
			me.pressed = 0;
		}
		return 1;
	}
	void Button_showNotify(entity me)
	{
		me.focusable = !me.disabled;
	}
	void Button_draw(entity me)
	{
		vector bOrigin, bSize;
		float save;

		me.focusable = !me.disabled;

		save = draw_alpha;
		if (me.disabled) draw_alpha *= me.disabledAlpha;

		if (me.fillStyle)
		{
			bool lit = !me.disabled && (me.focused || me.pressed || me.forcePressed || me.clickTime > 0);
			me.fillHover = bound(0, me.fillHover + (lit ? 1 : -1) * frametime * 8, 1);
			float hover = me.fillHover;
			vector isz = (me.fillImage != "") ? draw_PictureSize(me.fillImage) : '0 0 0';
			if (isz != '0 0 0')
			{
				vector pxsz = boxToGlobalSize('1 1 0', draw_scale);
				float aspect = pxsz.x / max(1, pxsz.y), iaspect = isz.x / max(1, isz.y);
				vector src = '1 1 0', srcpos = '0 0 0';
				if (iaspect > aspect) { src.x = aspect / iaspect; srcpos.x = (1 - src.x) / 2; }
				else { src.y = iaspect / aspect; srcpos.y = (1 - src.y) / 2; }
				float b = 0.4 + 0.35 * hover;
				drawsubpic(boxToGlobal('0 0 0', draw_shift, draw_scale), boxToGlobalSize('1 1 0', draw_scale),
					draw_UseSkinFor(me.fillImage), srcpos, src, eX * b + eY * b + eZ * b, draw_alpha, 0);
			}
			else
				draw_Fill('0 0 0', '1 1 0', me.fillColor * (1 + 0.4 * hover), 0.9);
			vector px = globalToBoxSize('1 1 0', draw_scale);
			vector edge = '0.3 0.65 1' * hover + '1 1 1' * (1 - hover);
			float ea = 0.25 + 0.75 * hover, t = 1 + hover;
			draw_Fill('0 0 0', eX + eY * px.y * t, edge, ea);
			draw_Fill(eY * (1 - px.y * t), eX + eY * px.y * t, edge, ea);
			draw_Fill('0 0 0', eX * px.x * t + eY, edge, ea);
			draw_Fill(eX * (1 - px.x * t), eX * px.x * t + eY, edge, ea);
		}
		else if (me.src)
		{
			if (me.srcMulti)
			{
				bOrigin = '0 0 0';
				bSize = '1 1 0';
				if (me.disabled) draw_ButtonPicture(bOrigin, strcat(me.src, "_d", me.srcSuffix), bSize, me.colorD, 1);
				else if (me.forcePressed || me.pressed || me.clickTime > 0) draw_ButtonPicture(bOrigin, strcat(me.src, "_c", me.srcSuffix), bSize, me.colorC, 1);
				else if (me.focused) draw_ButtonPicture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1);
				else draw_ButtonPicture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color, 1);
			}
			else
			{
				if (me.realFontSize_y == 0)
				{
					bOrigin = '0 0 0';
					bSize = '1 1 0';
				}
				else
				{
					bOrigin = eY * (0.5 * (1 - me.realFontSize.y)) + eX * (0.5 * (me.keepspaceLeft - me.realFontSize.x));
					bSize = me.realFontSize;
				}
				if (draw_flat)
				{
					// small square box: blue fill when on (check and radio
					// boxes), an x for close buttons; blue edge when hovered
					bool on = (me.srcSuffix == "1") || me.forcePressed;
					bool hot = !me.disabled && (me.focused || me.pressed || me.clickTime > 0);
					vector px = globalToBoxSize('1 1 0', draw_scale);
					vector inset = bSize * 0.2;
					draw_Fill(bOrigin + inset, bSize - 2 * inset, '0 0 0', 0.45);
					vector edge = hot ? FLAT_ACCENT : '1 1 1';
					float ea = (hot ? 1 : 0.45) * (me.disabled ? 0.4 : 1);
					vector o2 = bOrigin + inset, s2 = bSize - 2 * inset;
					draw_Fill(o2, eX * s2.x + eY * px.y, edge, ea);
					draw_Fill(o2 + eY * (s2.y - px.y), eX * s2.x + eY * px.y, edge, ea);
					draw_Fill(o2, eX * px.x + eY * s2.y, edge, ea);
					draw_Fill(o2 + eX * (s2.x - px.x), eX * px.x + eY * s2.y, edge, ea);
					if (strstrofs(me.src, "close", 0) >= 0)
						draw_CenterText(o2 + eX * s2.x * 0.5 + eY * s2.y * 0.1, "x", eX * s2.x * 0.8 + eY * s2.y * 0.8, edge, ea, false);
					else if (on)
						draw_Fill(o2 + s2 * 0.22, s2 * 0.56, FLAT_ACCENT, me.disabled ? 0.4 : 1);
				}
				else if (me.disabled) draw_Picture(bOrigin, strcat(me.src, "_d", me.srcSuffix), bSize, me.colorD, 1);
				else if (me.forcePressed || me.pressed || me.clickTime > 0) draw_Picture(bOrigin, strcat(me.src, "_c", me.srcSuffix), bSize, me.colorC, 1);
				else if (me.focused) draw_Picture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1);
				else draw_Picture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color, 1);
			}
		}
		if (me.src2)
		{
			bOrigin = me.keepspaceLeft * eX;
			bSize = eY + eX * (1 - me.keepspaceLeft);

			bOrigin += bSize * (0.5 - 0.5 * me.src2scale);
			bSize = bSize * me.src2scale;

			draw_Picture(bOrigin, me.src2, bSize, me.color2, me.alpha2);
		}

		draw_alpha = save;

		if (me.clickTime > 0 && me.clickTime <= frametime)
		{
			// keyboard click timer expired? Fire the event then.
			if (!me.disabled && me.onClick)
			{
				if(me.applyButton)
					me.applyButton.disabled = false;
				me.onClick(me, me.onClickEntity);
				if(me.disableOnClick)
					me.disabled = true;
			}
		}
		me.clickTime -= frametime;

		SUPER(Button).draw(me);
	}
	void Dialog_Close(entity button, entity me);
	void Button_playClickSound(entity me)
	{
		if (me.onClick == DialogOpenButton_Click) m_play_click_sound(MENU_SOUND_OPEN);
		else if (me.onClick == Dialog_Close) m_play_click_sound(MENU_SOUND_CLOSE);
		else m_play_click_sound(MENU_SOUND_EXECUTE);
	}
