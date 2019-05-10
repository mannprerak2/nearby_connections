package com.pkmnapps.nearby_connections;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.provider.Settings;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.connection.AdvertisingOptions;
import com.google.android.gms.nearby.connection.ConnectionInfo;
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback;
import com.google.android.gms.nearby.connection.ConnectionResolution;
import com.google.android.gms.nearby.connection.PayloadTransferUpdate;
import com.google.android.gms.nearby.connection.Strategy;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * NearbyConnectionsPlugin
 */
public class NearbyConnectionsPlugin implements MethodCallHandler {
    private Activity activity;
    private static final String SERVICE_ID = "PKMNAPPS_NEARBY_CONNECTION";


    private NearbyConnectionsPlugin(Activity activity) {
        this.activity = activity;
    }

    /**
     * Plugin registration.
     */

    public static void registerWith(Registrar registrar) {

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "nearby_connections");
        channel.setMethodCallHandler(new NearbyConnectionsPlugin(registrar.activity()));
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {

        switch (call.method) {
            case "checkPermissions":
                if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION)
                        != PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION)
                        != PackageManager.PERMISSION_GRANTED) {
                    result.success(false);
                } else {
                    result.success(true);
                }
                break;
            case "askPermissions":
                ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION},
                        0);
                result.success(null);
                break;
            case "stopAdvertising":
                Nearby.getConnectionsClient(activity).stopAdvertising();
                result.success(null);
                break;
            case "startAdvertising":
                String userNickName = (String) call.argument("userNickName");
                int strategy = (int) call.argument("strategy");

                assert userNickName != null;
                Nearby.getConnectionsClient(activity).startAdvertising(
                        userNickName,
                        SERVICE_ID,
                        connectionLifecycleCallback,
                        new AdvertisingOptions.Builder().setStrategy(getStrategy(strategy)).build())
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                result.success(true);
                            }
                        })
                        .addOnFailureListener(new OnFailureListener() {
                            @Override
                            public void onFailure(@NonNull Exception e) {
                                result.error("Failure", e.getMessage(), null);
                            }
                        });

                break;
            default:
                result.notImplemented();
        }
    }

    private final ConnectionLifecycleCallback connectionLifecycleCallback = new ConnectionLifecycleCallback() {
        @Override
        public void onConnectionInitiated(@NonNull String s, @NonNull ConnectionInfo connectionInfo) {

        }

        @Override
        public void onConnectionResult(@NonNull String s, @NonNull ConnectionResolution connectionResolution) {
        }

        @Override
        public void onDisconnected(@NonNull String s) {

        }
    };

    private Strategy getStrategy(int strategy) {
        switch (strategy) {
            case 0:
                return Strategy.P2P_CLUSTER;
            case 1:
                return Strategy.P2P_STAR;
            case 2:
                return Strategy.P2P_POINT_TO_POINT;
            default:
                return Strategy.P2P_CLUSTER;
        }
    }
}
