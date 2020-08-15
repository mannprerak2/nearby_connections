package com.pkmnapps.nearby_connections;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.location.LocationManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.common.api.ResolvableApiException;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsStatusCodes;
import com.google.android.gms.location.SettingsClient;
import com.google.android.gms.tasks.OnFailureListener;

import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

class LocationEnabler implements PluginRegistry.ActivityResultListener {

    @Nullable
    private Activity activity;

    private static final int GPS_ENABLE_REQUEST = 777;

    private SettingsClient mSettingsClient;
    private LocationSettingsRequest mLocationSettingsRequest;

    private Result pendingResult;

    private LocationManager mLocationManager;

    private LocationEnabler(@Nullable Activity activity) {
        this.activity = activity;
    }

    LocationEnabler(PluginRegistry.Registrar registrar) {
        this(registrar.activity());
    }

    LocationEnabler() {
        this.activity = null;
    }

    void setActivity(@Nullable Activity activity) {
        this.activity = activity;
        mSettingsClient = LocationServices.getSettingsClient(activity);
        mLocationManager = (LocationManager) activity.getSystemService(Context.LOCATION_SERVICE);
        initiateLocationServiceRequest();
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (pendingResult == null) {
            return false;
        }
        if (requestCode == GPS_ENABLE_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult.success(true);
            } else {
                pendingResult.success(false);
            }
            pendingResult = null;
            return true;
        }
        return false;
    }

    private void initiateLocationServiceRequest() {
        LocationRequest mLocationRequest = LocationRequest.create();
        LocationSettingsRequest.Builder builder = new LocationSettingsRequest.Builder();
        builder.addLocationRequest(mLocationRequest);
        mLocationSettingsRequest = builder.build();
    }

    private boolean checkLocationService() {
        boolean gps_enabled = mLocationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        boolean network_enabled = mLocationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        return gps_enabled || network_enabled;
    }

    void requestLocationEnable(final Result result) {
        try {
            if (this.checkLocationService()) {
                result.success(true);
                return;
            }
        } catch (Exception e) {
            result.error("LOCATION_SERVICE_ERROR", "Unable to determine location service status", null);
            return;
        }

        this.pendingResult = result;
        mSettingsClient.checkLocationSettings(mLocationSettingsRequest).addOnFailureListener(activity,
                new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        if (e instanceof ResolvableApiException) {
                            ResolvableApiException resolvableApiException = (ResolvableApiException) e;
                            int statusCode = resolvableApiException.getStatusCode();
                            if (statusCode == LocationSettingsStatusCodes.RESOLUTION_REQUIRED) {
                                try {
                                    resolvableApiException.startResolutionForResult(activity, GPS_ENABLE_REQUEST);
                                } catch (IntentSender.SendIntentException sie) {
                                    result.error("LOCATION_SERVICE_ERROR", "Unable to resolve location request",
                                            null);
                                }
                            }
                        } else {
                            result.error("LOCATION_SERVICE_ERROR", "An unexpected error occurred", null);
                        }
                    }
                });
    }

}