package com.ormma.view;

import java.util.HashMap;

import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;

import com.ormma.controller.OrmmaController.Properties;
import com.ormma.controller.util.TransitionStringEnum;
public class AnimationHelper {
	
	Properties mProperties = new Properties();
	static final int DURATION = 5000;
	
	HashMap <TransitionStringEnum, Animation> inAnimations = new HashMap<TransitionStringEnum, Animation>();
	HashMap <TransitionStringEnum, Animation> outAnimations = new HashMap<TransitionStringEnum, Animation>();
	
	AnimationHelper(){
		inAnimations.put(TransitionStringEnum.DEFAULT, getExpandSlideInAnimation());
		inAnimations.put(TransitionStringEnum.DISSOLVE, getExpandDissolveInAnimation());
		inAnimations.put(TransitionStringEnum.FADE, getExpandSlideInAnimation());
		inAnimations.put(TransitionStringEnum.NONE, getExpandSlideInAnimation());
		inAnimations.put(TransitionStringEnum.ROLL, getExpandSlideInAnimation());
		inAnimations.put(TransitionStringEnum.SLIDE, getExpandSlideInAnimation());
		inAnimations.put(TransitionStringEnum.ZOOM, getExpandSlideInAnimation());

	
		outAnimations.put(TransitionStringEnum.DEFAULT, getExpandSlideOutAnimation());
		outAnimations.put(TransitionStringEnum.DISSOLVE, getExpandDissolveOutAnimation());
		outAnimations.put(TransitionStringEnum.FADE, getExpandSlideOutAnimation());
		outAnimations.put(TransitionStringEnum.NONE, getExpandSlideOutAnimation());
		outAnimations.put(TransitionStringEnum.ROLL, getExpandSlideOutAnimation());
		outAnimations.put(TransitionStringEnum.SLIDE, getExpandSlideOutAnimation());
		outAnimations.put(TransitionStringEnum.ZOOM, getExpandSlideOutAnimation());

	}
	
	Animation getExpandInAnimation() {
		return inAnimations.get(mProperties.transition);
	}

	Animation getExpandOutAnimation() {
		return outAnimations.get(mProperties.transition);
	}

	
	private Animation getExpandSlideInAnimation() {
		Animation animation;

		animation = new TranslateAnimation(Animation.RELATIVE_TO_SELF, -1, Animation.RELATIVE_TO_SELF, 0.0f,
				Animation.RELATIVE_TO_SELF, 0, Animation.RELATIVE_TO_SELF, 0.0f);
		animation.setDuration(DURATION);
		return animation;
	}

	private Animation getExpandSlideOutAnimation() {
		Animation animation;

		animation = new TranslateAnimation(Animation.RELATIVE_TO_SELF, 0, Animation.RELATIVE_TO_SELF, 1.0f,
				Animation.RELATIVE_TO_SELF, 0, Animation.RELATIVE_TO_SELF, 0.0f);
		animation.setDuration(DURATION);
		return animation;
	}

	
	private Animation getExpandDissolveInAnimation() {
		Animation animation;

		animation = new AlphaAnimation(0,1);
		animation.setDuration(DURATION);
		return animation;
	}

	private Animation getExpandDissolveOutAnimation() {
		Animation animation;

		animation = new AlphaAnimation(1,0);
		animation.setDuration(DURATION);
		return animation;
	}

	
	
	public void setProperties(Properties properties) {
		mProperties = properties;
	}
}
