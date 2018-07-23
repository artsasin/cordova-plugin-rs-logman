package ru.cinet.rslogman;

import java.util.ArrayList;
import java.util.List;
import android.util.Log;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

import android.os.Handler;
import android.os.Looper;

/**
 * This class echoes a string called from JavaScript.
 */
public class CordovaPluginRsLogman extends CordovaPlugin implements SensorEventListener {

    public static int STOPPED = 0;
    public static int STARTING = 1;
    public static int RUNNING = 2;
    public static int ERROR_FAILED_TO_START = 3;

    private float x, y, z;
    private long timestamp;
    private int status;
    private int accuracy = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM;
    private Boolean collectData;
    private Double median;
    private Integer moduleNumber;
    private Integer moduleStage;
    private Integer logEntryIndex;
    private String logEntryCategoryKey;
    private String logEntryStimulKey;
    private String stype;

    private ArrayList<String[]> results = new ArrayList<>();


    private SensorManager sensorManager;
    private Sensor mSensor;

    private CallbackContext callbackContext;

    private Handler mainHandler = null;

    private Runnable mainRunnable = new Runnable() {
        public void run() {
            CordovaPluginRsLogman.this.timeout();
        }
    };

    public CordovaPluginRsLogman() {
        this.x = 0;
        this.y = 0;
        this.z = 0;
        this.timestamp = 0;
        this.setStatus(CordovaPluginRsLogman.STOPPED);
        this.collectData = false;
        this.median = 0.0d;
        this.moduleNumber = -1;
        this.moduleStage = -1;
        this.logEntryIndex = 0;
        this.logEntryCategoryKey = "N";
        this.logEntryStimulKey = "N";
        this.stype = "bmp";
    }

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        this.sensorManager = (SensorManager) cordova.getActivity().getSystemService(Context.SENSOR_SERVICE);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        if (action.equals("start")) {
            this.callbackContext = callbackContext;
            if (this.status != CordovaPluginRsLogman.RUNNING) {
                // If not running, then this is an async call, so don't worry about waiting
                // We drop the callback onto our stack, call start, and let start and the sensor callback fire off the callback down the road
                this.start();
            }
        } else if (action.equals("stop")) {
            if (this.status == CordovaPluginRsLogman.RUNNING) {
                this.stop();
            }
        } else if (action.equals("setMedian")) {
            Double m;
            try {
                m = args.getDouble(0);
            } catch (JSONException e) {
                e.printStackTrace();
                return false;
            }
            this.median = m;
        } else if (action.equals("startCollect")) {
            this.collectData = true;
        } else if (action.equals("stopCollect")) {
            this.collectData = false;
        } else if (action.equals("setLogentryProps")) {
            /**
             * stype - тип предьявляемых стимулов (bmp, spi и тд.)
             * sindex - номер модуля
             * state - этап внутри модуля
             * cat - категория
             * stm - идентификатор (название) стимула
             * stmkey - индекс стимула (общий счетчик в рамках исследования)
             * median - медиана
             */
            JSONObject logentryProps;
            try {
                logentryProps = args.getJSONObject(0);
            } catch (JSONException e) {
                e.printStackTrace();
                return false;
            }

            String stype;
            Integer sindex;
            Integer state;
            String cat;
            String stm;
            Boolean stmkey;
            Double median;

            try {
                stype = logentryProps.isNull("stype") ? null : logentryProps.getString("stype");
                sindex = logentryProps.isNull("sindex") ? null : logentryProps.getInt("sindex");
                state = logentryProps.isNull("state") ? null : logentryProps.getInt("state");
                cat = logentryProps.isNull("cat") ? null : logentryProps.getString("cat");
                stm = logentryProps.isNull("stm") ? null : logentryProps.getString("stm");
                stmkey = logentryProps.isNull("stmkey") ? false : logentryProps.getBoolean("stmkey");
                median = logentryProps.isNull("median") ? null : logentryProps.getDouble("median");
            } catch (JSONException e) {
                e.printStackTrace();
                return false;
            }

            if (stype != null) {
                this.stype = stype;
            }
            if (sindex != null) {
                this.moduleNumber = sindex;
            }
            if (state != null) {
                this.moduleStage = state;
            }
            if (cat != null) {
                this.logEntryCategoryKey = cat;
            }
            if (stm != null) {
                this.logEntryStimulKey = stm;
            }
            if (stmkey) {
                this.logEntryIndex++;
            }
            if (median != null) {
                this.median = median;
            }
        } else if (action.equals("result")) {
            JSONArray sensorData;
            sensorData = new JSONArray(this.results);
            PluginResult r = new PluginResult(PluginResult.Status.OK, sensorData);
            r.setKeepCallback(true);
            callbackContext.sendPluginResult(r);
            this.results = new ArrayList<>();
            return true;
        } else {
            // Unsupported action
            return false;
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, "");
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
        return true;
    }

    public void onDestroy() {
        this.stop();
    }

    private int start() {
        // If already starting or running, then restart timeout and return
        if ((this.status == CordovaPluginRsLogman.RUNNING) || (this.status == CordovaPluginRsLogman.STARTING)) {
            startTimeout();
            return this.status;
        }

        this.setStatus(CordovaPluginRsLogman.STARTING);

        // Get accelerometer from sensor manager
        List<Sensor> list = this.sensorManager.getSensorList(Sensor.TYPE_ACCELEROMETER);

        // If found, then register as listener
        if ((list != null) && (list.size() > 0)) {
            this.mSensor = list.get(0);
            if (this.sensorManager.registerListener(this, this.mSensor, SensorManager.SENSOR_DELAY_FASTEST)) {
                this.setStatus(CordovaPluginRsLogman.STARTING);
                // CB-11531: Mark accuracy as 'reliable' - this is complementary to
                // setting it to 'unreliable' 'stop' method
                this.accuracy = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM;
            } else {
                this.setStatus(CordovaPluginRsLogman.ERROR_FAILED_TO_START);
                this.fail(CordovaPluginRsLogman.ERROR_FAILED_TO_START, "Device sensor returned an error.");
                return this.status;
            };
        } else {
            this.setStatus(CordovaPluginRsLogman.ERROR_FAILED_TO_START);
            this.fail(CordovaPluginRsLogman.ERROR_FAILED_TO_START, "No sensors found to register accelerometer listening to.");
            return this.status;
        }

        startTimeout();

        return this.status;
    }

    private void startTimeout() {
        // Set a timeout callback on the main thread.
        stopTimeout();
        mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.postDelayed(mainRunnable, 2000);
    }


    private void stopTimeout() {
        if (mainHandler!=null) {
            mainHandler.removeCallbacks(mainRunnable);
        }
    }
    /**
     * Stop listening to acceleration sensor.
     */
    private void stop() {
        stopTimeout();
        if (this.status != CordovaPluginRsLogman.STOPPED) {
            this.sensorManager.unregisterListener(this);
        }
        this.setStatus(CordovaPluginRsLogman.STOPPED);
        this.accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE;
    }

    /**
     * Returns latest cached position if the sensor hasn't returned newer value.
     *
     * Called two seconds after starting the listener.
     */
    private void timeout() {
        if (this.status == CordovaPluginRsLogman.STARTING && this.accuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM) {
            // call win with latest cached position
            // but first check if cached position is reliable
            this.timestamp = System.currentTimeMillis() * 1000000;
            this.win();
        }
    }

    /**
     * Called when the accuracy of the sensor has changed.
     *
     * @param sensor
     * @param accuracy
     */
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // Only look at accelerometer events
        if (sensor.getType() != Sensor.TYPE_ACCELEROMETER) {
            return;
        }

        // If not running, then just return
        if (this.status == CordovaPluginRsLogman.STOPPED) {
            return;
        }
        this.accuracy = accuracy;
    }

    /**
     * Sensor listener event.
     *
     * @param SensorEvent event
     */
    public void onSensorChanged(SensorEvent event) {
        // Only look at accelerometer events
        if (event.sensor.getType() != Sensor.TYPE_ACCELEROMETER) {
            return;
        }

        // If not running, then just return
        if (this.status == CordovaPluginRsLogman.STOPPED) {
            return;
        }
        this.setStatus(CordovaPluginRsLogman.RUNNING);

        if (this.accuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM) {
            // Save time that event was received
            this.timestamp = event.timestamp;
            this.x = event.values[0];
            this.y = event.values[1];
            this.z = event.values[2];

            this.win();
        }
    }

    /**
     * Called when the view navigates.
     */
    @Override
    public void onReset() {
        if (this.status == CordovaPluginRsLogman.RUNNING) {
            this.stop();
        }
    }

    // Sends an error back to JS
    private void fail(int code, String message) {
        // Error object
        JSONObject errorObj = new JSONObject();
        try {
            errorObj.put("code", code);
            errorObj.put("message", message);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        PluginResult err = new PluginResult(PluginResult.Status.ERROR, errorObj);
        err.setKeepCallback(true);
        callbackContext.sendPluginResult(err);
    }

    private void win() {
        if (this.collectData) {
            String[] result = new String[11];
            result[0] = Long.toString(this.timestamp);
            result[1] = this.stype;
            result[2] = Integer.toString(this.moduleNumber);
            result[3] = Integer.toString(this.moduleStage);
            result[4] = this.logEntryCategoryKey;
            result[5] = this.logEntryStimulKey;
            result[6] = Integer.toString(this.logEntryIndex);
            result[7] = "1";
            result[8] = String.format("%.10f", this.x).replace(',', '.');
            result[9] = String.format("%.10f", this.y).replace(',', '.');
            result[10] = String.format("%.10f", this.z).replace(',', '.');
            this.results.add(result);
        }
    }

    private void setStatus(int status) {
        this.status = status;
    }
}
