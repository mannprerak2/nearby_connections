package com.pkmnapps.nearby_connections;

import android.app.Activity;
import android.content.Intent;
import android.content.IntentSender;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.ResolvableApiException;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsResponse;
import com.google.android.gms.location.LocationSettingsStatusCodes;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;

import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

class LocationEnabler implements PluginRegistry.ActivityResultListener {

    @Nullable
    private Activity activity;

    private static final int LOCATION_ENABLE_REQUEST = 777;

    private LocationSettingsRequest mLocationSettingsRequest;
    private Result pendingResult;

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
        initiateLocationServiceRequest();
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (pendingResult == null) {
            return false;
        }
        if (requestCode == LOCATION_ENABLE_REQUEST) {
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
        LocationSettingsRequest.Builder builder = new LocationSettingsRequest
                .Builder()
                .addLocationRequest(mLocationRequest)
                .setAlwaysShow(true);
        mLocationSettingsRequest = builder.build();
    }

    void requestLocationEnable(final Result result) {
        this.pendingResult = result;
        Task<LocationSettingsResponse> task = LocationServices.getSettingsClient(activity)
                .checkLocationSettings(mLocationSettingsRequest);

        task.addOnCompleteListener(new OnCompleteListener<LocationSettingsResponse>() {
            @Override
            public void onComplete(@NonNull Task<LocationSettingsResponse> task) {
                try {
                    task.getResult(ApiException.class);
                    result.success(true);
                } catch (ApiException ex) {
                    switch (ex.getStatusCode()) {
                        case LocationSettingsStatusCodes.SUCCESS:
                            result.success(true);
                            break;
                        case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
                            try {
                                ResolvableApiException resolvableApiException =
                                        (ResolvableApiException) ex;
                                resolvableApiException
                                        .startResolutionForResult(activity, LOCATION_ENABLE_REQUEST);
                            } catch (IntentSender.SendIntentException e) {
                                result.error("LOCATION_SERVICE_ERROR", e.getMessage(), null);
                            }
                            break;
                        default:
                            result.success(false);
                    }
                }
            }
        });
    }

}