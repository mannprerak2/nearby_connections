package com.pkmnapps.nearby_connections;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.provider.Settings;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * NearbyConnectionsPlugin
 */
public class NearbyConnectionsPlugin implements MethodCallHandler {
    private Activity activity;

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
    public void onMethodCall(MethodCall call, Result result) {

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
            default:
                result.notImplemented();
        }

    }
}
