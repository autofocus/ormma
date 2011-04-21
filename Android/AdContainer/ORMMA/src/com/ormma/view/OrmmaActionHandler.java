package com.ormma.view;

import java.util.HashMap;
import java.util.Map;

import android.app.Activity;
import android.os.Bundle;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.RelativeLayout;

import com.ormma.controller.OrmmaController.PlayerProperties;
import com.ormma.controller.util.OrmmaPlayer;
import com.ormma.controller.util.OrmmaPlayerListener;
import com.ormma.controller.util.OrmmaUtils;
import com.ormma.view.OrmmaView.ACTION;

/**
 * Activity class to handle full screen audio/video
 * @author Roshan
 *
 */
public class OrmmaActionHandler extends Activity {

	private HashMap<ACTION, Object> actionData = new HashMap<ACTION, Object>();
	private RelativeLayout layout;
		
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		Bundle data = getIntent().getExtras();
		
		layout = new RelativeLayout(this);
		layout.setLayoutParams(new ViewGroup.LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
		setContentView(layout);
		
		doAction(data);
		
	}

	/**
	 * Perform action - Play audio/video
	 * @param data - Action data
	 */
	private void doAction(Bundle data) {

		String actionData = data.getString(OrmmaView.ACTION_KEY);
				
		if(actionData == null)
			return;
		
		OrmmaView.ACTION actionType = OrmmaView.ACTION.valueOf(actionData); 
		
		switch (actionType) {
		case PLAY_AUDIO: {
			OrmmaPlayer player = initPlayer(data,actionType);			
			player.playAudio();
		}
			break;
		case PLAY_VIDEO: {
			OrmmaPlayer player = initPlayer(data,actionType);
			player.playVideo();
		}
			break;
		default:
			break;
		}
	}
	
	/**
	 * Create and initialize player
	 * @param playData - Play data
	 * @param actionType - type of action
	 * @return
	 */
	OrmmaPlayer initPlayer(Bundle playData,ACTION actionType){				

		PlayerProperties properties = (PlayerProperties) playData
				.getParcelable(OrmmaView.PLAYER_PROPERTIES);

		OrmmaPlayer player = new OrmmaPlayer(this);
		player.setPlayData(properties,OrmmaUtils.getData(OrmmaView.EXPAND_URL, playData));
		
		RelativeLayout.LayoutParams lp = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT);
		lp.addRule(RelativeLayout.CENTER_IN_PARENT);
		
		player.setLayoutParams(lp);
		layout.addView(player);
		
		this.actionData.put(actionType, player);
		setPlayerListener(player);
		
		return player;
	}
	
	/**
	 * Set listener
	 * @param player - player instance
	 */
	private void setPlayerListener(OrmmaPlayer player){
		player.setListener(new OrmmaPlayerListener() {
			
			@Override
			public void onPrepared() {
				
				
			}
			
			@Override
			public void onError() {				
				finish();
			}
			
			@Override
			public void onComplete() {
				finish();
			}
		});
	}

	@Override
	protected void onStop() {
		
		for(Map.Entry<ACTION, Object> entry: actionData.entrySet()){
			switch(entry.getKey()){
			case PLAY_AUDIO : 
			case PLAY_VIDEO : {
				OrmmaPlayer player = (OrmmaPlayer)entry.getValue();
				player.releasePlayer();
			}			
			break;
			default : break;
		}	
	}
		super.onStop();
	}	
	
}
