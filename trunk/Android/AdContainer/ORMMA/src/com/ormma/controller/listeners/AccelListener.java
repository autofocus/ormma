package com.ormma.controller.listeners;

import java.util.List;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

import com.ormma.controller.OrmmaSensorController;

public class AccelListener implements SensorEventListener {

	private static final int FORCE_THRESHOLD = 1000;
	private static final int TIME_THRESHOLD = 100;
	private static final int SHAKE_TIMEOUT = 500;
	private static final int SHAKE_DURATION = 2000;
	private static final int SHAKE_COUNT = 2;
	OrmmaSensorController mSensorController;
	Context mCtx;
	String mKey;
	// Sensor mSensor;
	int registeredTiltListeners = 0;
	int registeredShakeListeners = 0;
	int registeredHeadingListeners = 0;

	private SensorManager sensorManager;

	private int mSensorDelay = SensorManager.SENSOR_DELAY_NORMAL;
	private long mLastForce;
	private int mShakeCount;
	private long mLastTime;
	private long mLastShake;
	private float[] mMagVals;
	private float[] mAccVals = {0,0,0};
	private boolean bMagReady;
	private boolean bAccReady;
	private float[] mLastAccVals = {0,0,0};
	private float[] mActualOrientation = {-1,-1,-1};

	public AccelListener(Context ctx, OrmmaSensorController sensorController) {
		mCtx = ctx;
		mSensorController = sensorController;
		sensorManager = (SensorManager) mCtx.getSystemService(Context.SENSOR_SERVICE);

	}

	public void setSensorDelay(int delay) {
		mSensorDelay = delay;
		if ((registeredTiltListeners > 0) || (registeredShakeListeners > 0)) {
			stop();
			start();
		}
	}

	public void startTrackingTilt() {
		registeredTiltListeners++;
		start();
	}

	public void stopTrackingTilt() {
		if (registeredTiltListeners > 0) {
			registeredTiltListeners--;
			stop();
		}
	}

	public void startTrackingShake() {
		if (registeredShakeListeners == 0)
			setSensorDelay(SensorManager.SENSOR_DELAY_GAME);
		registeredShakeListeners++;
		start();
	}

	public void stopTrackingShake() {
		if (registeredShakeListeners > 0) {
			registeredShakeListeners--;
			if (registeredShakeListeners == 0)
				setSensorDelay(SensorManager.SENSOR_DELAY_NORMAL);
			stop();
		}

	}

	public void startTrackingHeading() {
		if (registeredHeadingListeners == 0)
			startMag();
		registeredHeadingListeners++;
	}

	private void startMag() {
		List<Sensor> list = this.sensorManager.getSensorList(Sensor.TYPE_MAGNETIC_FIELD);
		if (list.size() > 0) {
			this.sensorManager.registerListener(this, list.get(0), mSensorDelay);
			start();
		} else {
			// Call fail
		}
	}

	public void stopTrackingHeading() {
		if (registeredHeadingListeners > 0) {
			registeredHeadingListeners--;
			stop();
		}

	}

	private void start() {
		List<Sensor> list = this.sensorManager.getSensorList(Sensor.TYPE_ACCELEROMETER);
		if (list.size() > 0) {
			this.sensorManager.registerListener(this, list.get(0), mSensorDelay);
		} else {
			// Call fail
		}
	}

	public void stop() {
		if ((registeredHeadingListeners == 0) && (registeredShakeListeners == 0) && (registeredTiltListeners == 0)) {
			sensorManager.unregisterListener(this);
		}
	}

	public void onAccuracyChanged(Sensor sensor, int accuracy) {
	}

	public void onSensorChanged(SensorEvent event) {
		switch (event.sensor.getType()) {
		case Sensor.TYPE_MAGNETIC_FIELD:
			Log.d("xxx", "mag");
			mMagVals = event.values.clone();
			bMagReady = true;
			break;
		case Sensor.TYPE_ACCELEROMETER:
			Log.d("xxx", "acc");
			mLastAccVals = mAccVals;
			mAccVals = event.values.clone();
			bAccReady = true;
			break;
		}
		if(mMagVals != null && mAccVals != null && bAccReady && bMagReady) {
		    bAccReady = false;
		    bMagReady = false;
		    float[] R = new float[9];
		    float[] I = new float[9];
		    SensorManager.getRotationMatrix(R, I, mAccVals, mMagVals);

		    mActualOrientation = new float[3];
		    
		    SensorManager.getOrientation(R, mActualOrientation);
		    mSensorController.onHeadingChange(mActualOrientation[0]);
		}
		if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
			long now = System.currentTimeMillis();

			if ((now - mLastForce) > SHAKE_TIMEOUT) {
				mShakeCount = 0;
			}

			if ((now - mLastTime) > TIME_THRESHOLD) {
				long diff = now - mLastTime;
				float speed = Math.abs(mAccVals[SensorManager.DATA_X] + mAccVals[SensorManager.DATA_Y]
						+ mAccVals[SensorManager.DATA_Z] - mLastAccVals[SensorManager.DATA_X]
						- mLastAccVals[SensorManager.DATA_Y] - mLastAccVals[SensorManager.DATA_Z])
						/ diff * 10000;
				if (speed > FORCE_THRESHOLD) {

					if ((++mShakeCount >= SHAKE_COUNT) && (now - mLastShake > SHAKE_DURATION)) {
						mLastShake = now;
						mShakeCount = 0;
						mSensorController.onShake();
					}
					mLastForce = now;
				}
				mLastTime = now;
				mSensorController.onTilt(mAccVals[SensorManager.DATA_X], mAccVals[SensorManager.DATA_Y], mAccVals[SensorManager.DATA_Z]);

			}
		}
	}

	public float getHeading() {
		return mActualOrientation[0];
	}

}
