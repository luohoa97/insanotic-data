#include "nexposee.qh"

	void Nexposee_close(entity me)
	{
		// user must override this
	}

	void ExposeeCloseButton_Click(entity button, entity other)
	{
		other.selectedChild = other.focusedChild;
		other.setFocus(other, NULL);
		other.animationState = 3;
	}

	void Nexposee_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		me.calc(me);
		me.resizeNotifyLie(me, relOrigin, relSize, absOrigin, absSize, Nexposee_initialOrigin, Nexposee_initialSize, Nexposee_initialFontScale);
	}

	void Nexposee_Calc_Scale(entity me, float scale)
	{
		entity e;
		for (e = me.firstChild; e; e = e.nextSibling)
		{
			e.Nexposee_smallOrigin = (e.Nexposee_initialOrigin - e.Nexposee_scaleCenter) * scale + e.Nexposee_scaleCenter;
			e.Nexposee_smallSize = e.Nexposee_initialSize * scale;
			if (e.Nexposee_align.x > 0) e.Nexposee_smallOrigin_x = 1 - e.Nexposee_align.x * scale;
			if (e.Nexposee_align.x < 0) e.Nexposee_smallOrigin_x = -e.Nexposee_smallSize.x + e.Nexposee_align.x * scale;
			if (e.Nexposee_align.y > 0) e.Nexposee_smallOrigin_y = 1 - e.Nexposee_align.y * scale;
			if (e.Nexposee_align.y < 0) e.Nexposee_smallOrigin_y = -e.Nexposee_smallSize.y + e.Nexposee_align.y * scale;
		}
	}

	// Insanotic: main menu as buttons. The big ones share a row in the
	// middle of the screen, the small ones a row below it.
	bool Nexposee_ButtonsActive(entity me)
	{
		if (cvar_type("menu_buttons") && !cvar("menu_buttons")) return false;
		for (entity e = me.firstChild; e; e = e.nextSibling)
			if (e.Nexposee_buttonTitle != "") return true;
		return false;
	}

	void Nexposee_CalcButtons(entity me)
	{
		entity e;
		int big = 0, small = 0, bi = 0, si = 0;
		for (e = me.firstChild; e; e = e.nextSibling)
		{
			if (e.Nexposee_buttonSmall) ++small;
			else ++big;
		}
		float gap = 0.02, left = 0.08, right = 0.92;
		float bw = (right - left - gap * (big - 1)) / max(1, big), bh = 0.2, by = 0.44;
		float sw = 0.14, sh = 0.065, sy = by + bh + 0.05;
		float sx = 0.5 - (small * sw + (small - 1) * gap) / 2;
		for (e = me.firstChild; e; e = e.nextSibling)
		{
			if (e.Nexposee_buttonSmall)
			{
				e.Nexposee_smallOrigin = eX * (sx + si * (sw + gap)) + eY * sy;
				e.Nexposee_smallSize = eX * sw + eY * sh;
				++si;
			}
			else
			{
				e.Nexposee_smallOrigin = eX * (left + bi * (bw + gap)) + eY * by;
				e.Nexposee_smallSize = eX * bw + eY * bh;
				++bi;
			}
		}
	}

	// picture filling the button (cropped to its shape), darkened, with the
	// title on it; the hovered or selected one lights up
	void Nexposee_DrawButton(entity me, entity e, float alpha, int order)
	{
		vector o = e.Container_origin, sz = e.Container_size;
		// start animation: each button rises a little while fading in,
		// one after another
		if (menuIntro < 1)
		{
			float k = bound(0, (menuIntro - 0.3 - order * 0.07) / 0.45, 1);
			k = 1 - (1 - k) * (1 - k);
			alpha *= k;
			o.y += (1 - k) * 0.04;
		}
		float hover = e.Nexposee_buttonHover;
		float pxw = 1 / conwidth, pxh = 1 / conheight;
		if (alpha <= 0) return;
		if (e.Nexposee_buttonImage != "" && draw_PictureExists(e.Nexposee_buttonImage))
		{
			// crop the picture to the button's aspect
			vector isz = draw_PictureSize(e.Nexposee_buttonImage);
			vector pxsz = boxToGlobalSize(sz, draw_scale);
			float aspect = pxsz.x / max(1, pxsz.y);
			float iaspect = isz.x / max(1, isz.y);
			vector src = '1 1 0', srcpos = '0 0 0';
			if (iaspect > aspect) { src.x = aspect / iaspect; srcpos.x = (1 - src.x) / 2; }
			else { src.y = iaspect / aspect; srcpos.y = (1 - src.y) / 2; }
			float b = 0.4 + 0.35 * hover;
			drawsubpic(boxToGlobal(o, draw_shift, draw_scale), boxToGlobalSize(sz, draw_scale),
				draw_UseSkinFor(e.Nexposee_buttonImage), srcpos, src, eX * b + eY * b + eZ * b, alpha * draw_alpha, 0);
		}
		else
			draw_Fill(o, sz, '0.05 0.08 0.14', alpha * (0.75 + 0.15 * hover));
		// darker towards the bottom, where the text is
		for (int i = 0; i < 8; ++i)
			draw_Fill(o + eY * sz.y * (0.4 + 0.6 * i / 8), eX * sz.x + eY * sz.y * 0.6 / 8, '0 0 0', alpha * 0.08 * (i + 1));
		// edge: thin and dim, bright blue when hovered
		vector edge = '0.3 0.65 1' * hover + '1 1 1' * (1 - hover);
		float ea = alpha * (0.25 + 0.75 * hover);
		float t = 1 + hover;
		draw_Fill(o, eX * sz.x + eY * pxh * t, edge, ea);
		draw_Fill(o + eY * (sz.y - pxh * t), eX * sz.x + eY * pxh * t, edge, ea);
		draw_Fill(o, eX * pxw * t + eY * sz.y, edge, ea);
		draw_Fill(o + eX * (sz.x - pxw * t), eX * pxw * t + eY * sz.y, edge, ea);
		// title (and a line under it on the big buttons)
		// text height from the button height, shrunk to fit its width
		float ratio = draw_scale.y / draw_scale.x; // box height to box width
		float pad = sz.y * 0.12;
		float room = (sz.x - 2 * pad * ratio) * 0.9; // text widths measure a little short
		float th = e.Nexposee_buttonSmall ? sz.y * 0.42 : sz.y * 0.2;
		vector tfs = eX * th * ratio + eY * th;
		float tw = draw_TextWidth(e.Nexposee_buttonTitle, false, tfs);
		if (tw > room) { th *= room / tw; tfs = eX * th * ratio + eY * th; }
		if (e.Nexposee_buttonSmall)
		{
			draw_CenterText(o + eX * sz.x * 0.5 + eY * (sz.y - th) * 0.5, e.Nexposee_buttonTitle, tfs, '1 1 1', alpha, false);
			return;
		}
		vector p = o + eX * pad * ratio + eY * (sz.y - pad - th);
		if (e.Nexposee_buttonText != "")
		{
			float sh = sz.y * 0.084;
			vector sfs = eX * sh * ratio + eY * sh;
			float sw = draw_TextWidth(e.Nexposee_buttonText, false, sfs);
			if (sw > room) { sh *= room / sw; sfs = eX * sh * ratio + eY * sh; }
			p.y -= sh * 1.3;
			draw_Text(p + eY * (th + sh * 0.3), e.Nexposee_buttonText, sfs, '0.8 0.85 0.9', alpha * (0.7 + 0.3 * hover), false);
		}
		draw_Text(p, e.Nexposee_buttonTitle, tfs, '1 1 1', alpha, false);
	}

	void Nexposee_setNexposeeButton(entity me, entity other, string image, string title, string text, float small)
	{
		other.Nexposee_buttonImage = image;
		other.Nexposee_buttonTitle = title;
		other.Nexposee_buttonText = text;
		other.Nexposee_buttonSmall = small;
		if (image != "") draw_PreloadPicture(image);
	}

	void Nexposee_calc(entity me)
	{
		if (Nexposee_ButtonsActive(me))
		{
			Nexposee_CalcButtons(me);
			return;
		}
		/*
		 * patented by Apple
		 * can't put that here ;)
		 */
		float scale;
		entity e, e2;
		vector emins, emaxs, e2mins, e2maxs;

		for (scale = 0.7; ; scale *= 0.99)
		{
			Nexposee_Calc_Scale(me, scale);

			for (e = me.firstChild; e; e = e.nextSibling)
			{
				emins = e.Nexposee_smallOrigin;
				emaxs = emins + e.Nexposee_smallSize;
				for (e2 = e.nextSibling; e2; e2 = e2.nextSibling)
				{
					e2mins = e2.Nexposee_smallOrigin;
					e2maxs = e2mins + e2.Nexposee_smallSize;

					// two intervals [amins, amaxs] and [bmins, bmaxs] overlap if:
					//   amins < bmins < amaxs < bmaxs
					// for which suffices
					//   bmins < amaxs
					//   amins < bmaxs
					if ((e2mins.x - emaxs.x) * (emins.x - e2maxs.x) > 0)     // x overlap
						if ((e2mins.y - emaxs.y) * (emins.y - e2maxs.y) > 0) // y overlap
							goto have_overlap;
				}
			}

			break;
LABEL(have_overlap)
		}

		scale *= 0.95;

		Nexposee_Calc_Scale(me, scale);
	}

	void Nexposee_setNexposee(entity me, entity other, vector scalecenter, float a0, float a1)
	{
		other.Nexposee_scaleCenter = scalecenter;
		other.Nexposee_smallAlpha = a0;
		me.setAlphaOf(me, other, a0);
		other.Nexposee_mediumAlpha = a1;
	}

	void Nexposee_draw(entity me)
	{
		float a;
		float a0;
		entity e;
		float f;
		vector fs;

		if (me.animationState == -1) me.animationState = 0;

		f = min(1, frametime * 5);
		switch (me.animationState)
		{
			case 0:
				me.animationFactor = 0;
				break;
			case 1:
				me.animationFactor += f;
				if (me.animationFactor >= 1)
				{
					me.animationFactor = 1;
					me.animationState = 2;
					SUPER(Nexposee).setFocus(me, me.selectedChild);
				}
				break;
			case 2:
				me.animationFactor = 1;
				break;
			case 3:
				me.animationFactor -= f;
				me.mouseFocusedChild = me.itemFromPoint(me, me.mousePosition);
				if (me.animationFactor <= 0)
				{
					me.animationFactor = 0;
					me.animationState = 0;
					me.selectedChild = me.mouseFocusedChild;
				}
				break;
		}

		bool buttons = Nexposee_ButtonsActive(me);
		f = min(1, frametime * 10);
		for (e = me.firstChild; e; e = e.nextSibling)
		{
			if (buttons)
			{
				// the dialog grows out of its button and fades in
				bool lit = (me.animationState == 0 && e == me.selectedChild);
				e.Nexposee_buttonHover += (lit ? 1 : -1) * min(1, frametime * 8);
				e.Nexposee_buttonHover = bound(0, e.Nexposee_buttonHover, 1);
				if (e == me.selectedChild)
				{
					e.Container_origin = e.Nexposee_smallOrigin * (1 - me.animationFactor) + e.Nexposee_initialOrigin * me.animationFactor;
					e.Container_size = e.Nexposee_smallSize * (1 - me.animationFactor) + e.Nexposee_initialSize * me.animationFactor;
					e.Nexposee_animationFactor = me.animationFactor;
					a = me.animationFactor;
				}
				else
				{
					e.Container_origin = e.Nexposee_smallOrigin;
					e.Container_size = e.Nexposee_smallSize;
					e.Nexposee_animationFactor = 0;
					a = 0;
				}
				me.setAlphaOf(me, e, a);
				fs = globalToBoxSize(e.Container_size, e.Nexposee_initialSize);
				e.Container_fontscale_x = fs.x * e.Nexposee_initialFontScale.x;
				e.Container_fontscale_y = fs.y * e.Nexposee_initialFontScale.y;
				continue;
			}
			if (e == me.selectedChild)
			{
				e.Container_origin = e.Nexposee_smallOrigin * (1 - me.animationFactor) + e.Nexposee_initialOrigin * me.animationFactor;
				e.Container_size = e.Nexposee_smallSize * (1 - me.animationFactor) + e.Nexposee_initialSize * me.animationFactor;
				e.Nexposee_animationFactor = me.animationFactor;
				a0 = e.Nexposee_mediumAlpha;
				if (me.animationState == 3)
					if (e != me.mouseFocusedChild) a0 = e.Nexposee_smallAlpha;
				a = a0 * (1 - me.animationFactor) + me.animationFactor;
			}
			else
			{
				// minimum theSize counts
				e.Container_origin = e.Nexposee_smallOrigin;
				e.Container_size = e.Nexposee_smallSize;
				e.Nexposee_animationFactor = 0;
				a = e.Nexposee_smallAlpha * (1 - me.animationFactor);
			}
			me.setAlphaOf(me, e, e.Container_alpha * (1 - f) + a * f);

			fs = globalToBoxSize(e.Container_size, e.Nexposee_initialSize);
			e.Container_fontscale_x = fs.x * e.Nexposee_initialFontScale.x;
			e.Container_fontscale_y = fs.y * e.Nexposee_initialFontScale.y;
		}

		if (buttons)
		{
			int order = 0;
			for (e = me.firstChild; e; e = e.nextSibling)
				Nexposee_DrawButton(me, e, 1 - me.animationFactor, order++);
		}

		SUPER(Nexposee).draw(me);
	}

	METHOD(Nexposee, mousePress, bool(Nexposee this, vector pos))
	{
		if (this.animationState == 0)
		{
			this.mouseFocusedChild = NULL;
			Nexposee_mouseMove(this, pos);
			if (this.mouseFocusedChild)
			{
				m_play_click_sound(MENU_SOUND_OPEN);
				this.animationState = 1;
				SUPER(Nexposee).setFocus(this, NULL);
			}
			else
			{
				this.close(this);
			}
			return true;
		}
		else if (this.animationState == 2)
		{
			if (!(SUPER(Nexposee).mousePress(this, pos)))
			{
				m_play_click_sound(MENU_SOUND_CLOSE);
				this.animationState = 3;
				SUPER(Nexposee).setFocus(this, NULL);
			}
			return true;
		}
		return false;
	}

	float Nexposee_mouseRelease(entity me, vector pos)
	{
		if (me.animationState == 2) return SUPER(Nexposee).mouseRelease(me, pos);
		return 0;
	}

	float Nexposee_mouseDrag(entity me, vector pos)
	{
		if (me.animationState == 2) return SUPER(Nexposee).mouseDrag(me, pos);
		return 0;
	}

	float Nexposee_mouseMove(entity me, vector pos)
	{
		entity e;
		me.mousePosition = pos;
		e = me.mouseFocusedChild;
		me.mouseFocusedChild = me.itemFromPoint(me, pos);
		if (me.animationState == 2) return SUPER(Nexposee).mouseMove(me, pos);
		if (me.animationState == 0)
		{
			if (me.mouseFocusedChild)
				if (me.mouseFocusedChild != e || me.mouseFocusedChild != me.selectedChild) me.selectedChild = me.mouseFocusedChild;
			return 1;
		}
		return 0;
	}

	float Nexposee_keyUp(entity me, float scan, float ascii, float shift)
	{
		if (me.animationState == 2) return SUPER(Nexposee).keyUp(me, scan, ascii, shift);
		return 0;
	}

	float Nexposee_keyDown(entity me, float scan, float ascii, float shift)
	{
		float nexposeeKey = 0;
		if (me.animationState == 2)
			if (SUPER(Nexposee).keyDown(me, scan, ascii, shift)) return 1;
		if (scan == K_TAB)
		{
			if (me.animationState == 0)
			{
				if (shift & S_SHIFT)
				{
					if (me.selectedChild) me.selectedChild = me.selectedChild.prevSibling;
					if (!me.selectedChild) me.selectedChild = me.lastChild;
				}
				else
				{
					if (me.selectedChild) me.selectedChild = me.selectedChild.nextSibling;
					if (!me.selectedChild) me.selectedChild = me.firstChild;
				}
			}
		}
		switch (me.animationState)
		{
			default:
			case 0:
			case 3:
				nexposeeKey = ((scan == K_SPACE) || (scan == K_ENTER) || (scan == K_KP_ENTER));
				break;
			case 1:
			case 2:
				nexposeeKey = (scan == K_ESCAPE);
				break;
		}
		if (nexposeeKey)
		{
			switch (me.animationState)
			{
				default:
				case 0:
				case 3:
					m_play_click_sound(MENU_SOUND_OPEN);
					me.animationState = 1;
					break;
				case 1:
				case 2:
					m_play_click_sound(MENU_SOUND_CLOSE);
					me.animationState = 3;
					break;
			}
			if (me.focusedChild) me.selectedChild = me.focusedChild;
			if (!me.selectedChild) me.animationState = 0;
			SUPER(Nexposee).setFocus(me, NULL);
			return 1;
		}
		return 0;
	}

	void Nexposee_addItem(entity me, entity other, vector theOrigin, vector theSize, float theAlpha)
	{
		SUPER(Nexposee).addItem(me, other, theOrigin, theSize, theAlpha);
		other.Nexposee_initialFontScale = other.Container_fontscale;
		other.Nexposee_initialSize = other.Container_size;
		other.Nexposee_initialOrigin = other.Container_origin;
		other.Nexposee_initialAlpha = other.Container_alpha;
		if (other.Nexposee_initialFontScale == '0 0 0') other.Nexposee_initialFontScale = '1 1 0';
	}

	void Nexposee_focusEnter(entity me)
	{
		if (me.animationState == 2) SUPER(Nexposee).setFocus(me, me.selectedChild);
	}

	void Nexposee_pullNexposee(entity me, entity other, vector theAlign)
	{
		other.Nexposee_align = theAlign;
	}
