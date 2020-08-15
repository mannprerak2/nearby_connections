package com.pkmnapps.nearby_connections;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

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

class LocationHelper implements PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {

    @Nullable
    private Activity activity;

    private static final int LOCATION_ENABLE_REQUEST = 777;
    private static final int REQUEST_LOCATION_PERMISSION = 7777;

    private LocationSettingsRequest mLocationSettingsRequest;
    private Result pendingResult;

    private LocationHelper(@Nullable Activity activity) {
        this.activity = activity;
    }

    LocationHelper(PluginRegistry.Registrar registrar) {
        this(registrar.activity());
    }

    LocationHelper() {
        this.activity = null;
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

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == REQUEST_LOCATION_PERMISSION && permissions.length > 0) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if (pendingResult != null) {
                    pendingResult.success(true);
                    pendingResult = null;
                }
            } else {
                if (pendingResult != null) {
                    pendingResult.success(false);
                    pendingResult = null;
                }
            }
            return true;
        }
        return false;
    }

    void setActivity(@Nullable Activity activity) {
        this.activity = activity;
        initiateLocationServiceRequest();
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

    void requestLocationPermission(Result result) {
        this.pendingResult = result;
        ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION}, REQUEST_LOCATION_PERMISSION);
    }

}