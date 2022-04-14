package com.pkmnapps.nearby_connections;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.location.LocationManager;
import android.util.Log;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.connection.AdvertisingOptions;
import com.google.android.gms.nearby.connection.ConnectionInfo;
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback;
import com.google.android.gms.nearby.connection.ConnectionResolution;
import com.google.android.gms.nearby.connection.ConnectionsStatusCodes;
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo;
import com.google.android.gms.nearby.connection.DiscoveryOptions;
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback;
import com.google.android.gms.nearby.connection.Payload;
import com.google.android.gms.nearby.connection.PayloadCallback;
import com.google.android.gms.nearby.connection.PayloadTransferUpdate;
import com.google.android.gms.nearby.connection.Strategy;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * NearbyConnectionsPlugin
 */
public class NearbyConnectionsPlugin implements Messages.NearbyApi, FlutterPlugin, ActivityAware {
    private Activity activity;
    private static final String SERVICE_ID = "com.pkmnapps.nearby_connections";
    private static MethodChannel channel;
    private static LocationHelper locationHelper;
    private static ActivityPluginBinding activityPluginBinding;
    private static PluginRegistry.Registrar pluginRegistrar;

    private static Messages.DiscoveryConnectionLifecycleApi discoveryConnectionLifecycleApi;
    private static Messages.AdvertisingConnectionLifecycleApi advertisingConnectionLifecycleApi;
    private static Messages.EndpointDiscoveryApi endpointDiscoveryApi;
    private static Messages.PayloadApi payloadApi;

    private NearbyConnectionsPlugin(Activity activity) {
        this.activity = activity;
    }
    public NearbyConnectionsPlugin(){}

    /**
     * Legacy Plugin registration.
     */

    public static void registerWith(Registrar registrar) {
        pluginRegistrar = registrar;
        locationHelper = new LocationHelper(registrar.activity());
        locationHelper.setActivity(registrar.activity());
        initiate();

        BinaryMessenger messenger = registrar.messenger();

        discoveryConnectionLifecycleApi = new Messages.DiscoveryConnectionLifecycleApi(messenger);
        advertisingConnectionLifecycleApi = new Messages.AdvertisingConnectionLifecycleApi(messenger);
        endpointDiscoveryApi = new Messages.EndpointDiscoveryApi(messenger);
        payloadApi = new Messages.PayloadApi(messenger);
    }

    @Override
    public void onMethod2Call(MethodCall call, final Result result) {

        switch (call.method) {
            case "checkLocationPermission":
                if (ContextCompat.checkSelfPermission(activity,
                        Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                        && ContextCompat.checkSelfPermission(activity,
                        Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;
            case "askLocationPermission":
                locationHelper.requestLocationPermission(result);
                break;
            case "checkLocationEnabled":
                LocationManager lm = (LocationManager) activity.getSystemService(activity.LOCATION_SERVICE);
                boolean gps_enabled = false;
                boolean network_enabled = false;
                try {
                    gps_enabled = lm.isProviderEnabled(LocationManager.GPS_PROVIDER);
                } catch (Exception ex) {
                }
                try {
                    network_enabled = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
                } catch (Exception ex) {
                }
                result.success(gps_enabled || network_enabled);
                break;
            case "enableLocationServices":
                locationHelper.requestLocationEnable(result);
                break;
            case "checkExternalStoragePermission":
                if (ContextCompat.checkSelfPermission(activity,
                        Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
                        && ContextCompat.checkSelfPermission(activity,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;
            case "askExternalStoragePermission":
                ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
                Log.d("nearby_connections", "askExternalStoragePermission");
                result.success(null);
                break;
            case "checkBluetoothPermission": // required for apps running on Android 12 and higher
                if (VERSION.SDK_INT >= VERSION_CODES.S) {
                    if (
                        ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED && 
                        ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
                        ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED 
                    ) {
                        result.success(true);
                    } else {
                        result.success(false);
                    }
                } else{
                    result.success(true);
                }
                break;
            case "askBluetoothPermission":
                if (VERSION.SDK_INT >= VERSION_CODES.S) {
                    ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN},
                    1);
                    Log.d("nearby_connections", "askBluetoothPermission");
                    result.success(null);
                } else{
                    result.success(null);
                }
                break;
            case "askLocationAndExternalStoragePermission":
                ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.READ_EXTERNAL_STORAGE,
                                Manifest.permission.WRITE_EXTERNAL_STORAGE},
                        1);
                Log.d("nearby_connections", "askExternalStoragePermission");
                result.success(null);
                break;
            case "copyFileAndDeleteOriginal":
                Log.d("nearby_connections", "copyFileAndDeleteOriginal");
                String sourceUri = (String) call.argument("sourceUri");
                String destinationFilepath = (String) call.argument("destinationFilepath");

                try {
                    // Copy the file to a new location.
                    Uri uri = Uri.parse(sourceUri);
                    InputStream in = activity.getContentResolver().openInputStream(uri);
                    copyStream(in, new FileOutputStream(new File(destinationFilepath)));
                    // Delete the original file.
                    activity.getContentResolver().delete(uri, null, null);
                    result.success(true);
                } catch (IOException e) {
                    // Log the error.
                    Log.e("nearby_connections", e.getMessage());
                    result.success(false);
                }
                break;
            case "stopAdvertising":
                Log.d("nearby_connections", "stopAdvertising");
                Nearby.getConnectionsClient(activity).stopAdvertising();
                result.success(null);
                break;
            case "stopDiscovery":
                Log.d("nearby_connections", "stopDiscovery");
                Nearby.getConnectionsClient(activity).stopDiscovery();
                result.success(null);
                break;
            case "startAdvertising": {
                String userNickName = (String) call.argument("userNickName");
                int strategy = (int) call.argument("strategy");
                String serviceId = (String) call.argument("serviceId");

                assert userNickName != null;
                if (serviceId == null || serviceId == "")
                    serviceId = SERVICE_ID;

                AdvertisingOptions advertisingOptions = new AdvertisingOptions.Builder()
                        .setStrategy(getStrategy(strategy)).build();

                Nearby.getConnectionsClient(activity).startAdvertising(userNickName, serviceId,
                        advertConnectionLifecycleCallback, advertisingOptions)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                Log.d("nearby_connections", "startAdvertising");
                                result.success(true);
                            }
                        }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        result.error("Failure", e.getMessage(), null);
                    }
                });
                break;
            }
            case "startDiscovery": {
                String userNickName = (String) call.argument("userNickName");
                int strategy = (int) call.argument("strategy");
                String serviceId = (String) call.argument("serviceId");

                assert userNickName != null;
                if (serviceId == null || serviceId == "")
                    serviceId = SERVICE_ID;

                DiscoveryOptions discoveryOptions = new DiscoveryOptions.Builder().setStrategy(getStrategy(strategy))
                        .build();
                Nearby.getConnectionsClient(activity)
                        .startDiscovery(serviceId, endpointDiscoveryCallback, discoveryOptions)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                Log.d("nearby_connections", "startDiscovery");
                                result.success(true);
                            }
                        }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        result.error("Failure", e.getMessage(), null);
                    }
                });
                break;
            }
            case "stopAllEndpoints":
                Log.d("nearby_connections", "stopAllEndpoints");
                Nearby.getConnectionsClient(activity).stopAllEndpoints();
                result.success(null);
                break;
            case "disconnectFromEndpoint": {
                Log.d("nearby_connections", "disconnectFromEndpoint");
                String endpointId = call.argument("endpointId");
                assert endpointId != null;
                Nearby.getConnectionsClient(activity).disconnectFromEndpoint(endpointId);
                result.success(null);
                break;
            }
            case "requestConnection": {
                Log.d("nearby_connections", "requestConnection");
                String userNickName = (String) call.argument("userNickName");
                String endpointId = (String) call.argument("endpointId");

                assert userNickName != null;
                assert endpointId != null;
                Nearby.getConnectionsClient(activity)
                        .requestConnection(userNickName, endpointId, discoverConnectionLifecycleCallback)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                result.success(true);
                            }
                        }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        result.error("Failure", e.getMessage(), null);
                    }
                });
                break;
            }
            case "acceptConnection": {
                String endpointId = (String) call.argument("endpointId");

                assert endpointId != null;
                Nearby.getConnectionsClient(activity).acceptConnection(endpointId, payloadCallback)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                result.success(true);
                            }
                        }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        result.error("Failure", e.getMessage(), null);
                    }
                });
                break;
            }
            case "rejectConnection": {
                String endpointId = (String) call.argument("endpointId");

                assert endpointId != null;
                Nearby.getConnectionsClient(activity).rejectConnection(endpointId)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                result.success(true);
                            }
                        }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        result.error("Failure", e.getMessage(), null);
                    }
                });
                break;
            }
            case "sendPayload": {
                String endpointId = (String) call.argument("endpointId");
                byte[] bytes = call.argument("bytes");

                assert endpointId != null;
                assert bytes != null;
                Nearby.getConnectionsClient(activity).sendPayload(endpointId, Payload.fromBytes(bytes));
                Log.d("nearby_connections", "sentPayload");
                result.success(true);
                break;
            }
            case "sendFilePayload": {
                String endpointId = (String) call.argument("endpointId");
                String filePath = (String) call.argument("filePath");

                assert endpointId != null;
                assert filePath != null;

                try {
                    File file = new File(filePath);

                    Payload filePayload = Payload.fromFile(file);
                    Nearby.getConnectionsClient(activity).sendPayload(endpointId, filePayload);
                    Log.d("nearby_connections", "sentFilePayload");
                    result.success(filePayload.getId()); // return payload id to dart
                } catch (FileNotFoundException e) {
                    Log.e("nearby_connections", "File not found", e);
                    result.error("Failure", e.getMessage(), null);
                    return;
                }
                break;
            }
            case "cancelPayload": {
                String payloadId = (String) call.argument("payloadId");

                assert payloadId != null;
                Nearby.getConnectionsClient(activity).cancelPayload(Long.parseLong(payloadId));
                result.success(null);
                break;
            }
            default:
                result.notImplemented();
        }
    }

    private final ConnectionLifecycleCallback advertConnectionLifecycleCallback = new ConnectionLifecycleCallback() {
        @Override
        public void onConnectionInitiated(@NonNull String endpointId, @NonNull ConnectionInfo connectionInfo) {
            Log.d("nearby_connections", "ad.onConnectionInitiated");
            advertisingConnectionLifecycleApi.onConnectionInitiated(
                    new Messages.ConnectionInfoMessage.Builder()
                            .setEndpointId(endpointId)
                            .setEndpointName(connectionInfo.getEndpointName())
                            .setAuthenticationToken(connectionInfo.getAuthenticationToken())
                            .setIsIncomingConnection(connectionInfo.isIncomingConnection())
                            .build(), null);
        }

        @Override
        public void onConnectionResult(@NonNull String endpointId, @NonNull ConnectionResolution connectionResolution) {
            Log.d("nearby_connections", "ad.onConnectionResult");
            int statusCode = -1;
            switch (connectionResolution.getStatus().getStatusCode()) {
                case ConnectionsStatusCodes.STATUS_OK:
                    statusCode = 0;
                    // We're connected! Can now start sending and receiving data.
                    break;
                case ConnectionsStatusCodes.STATUS_CONNECTION_REJECTED:
                    statusCode = 1;
                    // The connection was rejected by one or both sides.
                    break;
                case ConnectionsStatusCodes.STATUS_ERROR:
                    statusCode = 2;
                    // The connection broke before it was able to be accepted.
                    break;
                default:
                    // Unknown status code
            }
            advertisingConnectionLifecycleApi.onConnectionResult(endpointId, (long) statusCode, null);
        }

        @Override
        public void onDisconnected(@NonNull String endpointId) {
            Log.d("nearby_connections", "ad.onDisconnected");
            advertisingConnectionLifecycleApi.onDisconnected(endpointId, null);
        }
    };

    private final ConnectionLifecycleCallback discoverConnectionLifecycleCallback = new ConnectionLifecycleCallback() {
        @Override
        public void onConnectionInitiated(@NonNull String endpointId, @NonNull ConnectionInfo connectionInfo) {
            Log.d("nearby_connections", "dis.onConnectionInitiated");
            discoveryConnectionLifecycleApi.onConnectionInitiated(
                    new Messages.ConnectionInfoMessage.Builder()
                            .setEndpointId(endpointId)
                            .setEndpointName(connectionInfo.getEndpointName())
                            .setAuthenticationToken(connectionInfo.getAuthenticationToken())
                            .setIsIncomingConnection(connectionInfo.isIncomingConnection())
                            .build(), null);
        }

        @Override
        public void onConnectionResult(@NonNull String endpointId, @NonNull ConnectionResolution connectionResolution) {
            Log.d("nearby_connections", "dis.onConnectionResult");
            int statusCode = -1;
            switch (connectionResolution.getStatus().getStatusCode()) {
                case ConnectionsStatusCodes.STATUS_OK:
                    statusCode = 0;
                    // We're connected! Can now start sending and receiving data.
                    break;
                case ConnectionsStatusCodes.STATUS_CONNECTION_REJECTED:
                    statusCode = 1;
                    // The connection was rejected by one or both sides.
                    break;
                case ConnectionsStatusCodes.STATUS_ERROR:
                    statusCode = 2;
                    // The connection broke before it was able to be accepted.
                    break;
                default:
                    // Unknown status code
            }
            discoveryConnectionLifecycleApi.onConnectionResult(endpointId, (long) statusCode, null);
        }

        @Override
        public void onDisconnected(@NonNull String endpointId) {
            Log.d("nearby_connections", "dis.onDisconnected");
            discoveryConnectionLifecycleApi.onDisconnected(endpointId, null);
        }
    };

    private final PayloadCallback payloadCallback = new PayloadCallback() {
        @Override
        public void onPayloadReceived(@NonNull String endpointId, @NonNull Payload payload) {
            Log.d("nearby_connections", "onPayloadReceived");

            byte[] bytes = null;
            String uri = null;
            String filePath = null;

            if (payload.getType() == Payload.Type.BYTES) {
                bytes = payload.asBytes();
                assert bytes != null;
            } else if (payload.getType() == Payload.Type.FILE) {
                uri = payload.asFile().asUri().toString();
                if (VERSION.SDK_INT < VERSION_CODES.Q) {
                    // This is deprecated and only available on Android 10 and below.
                    filePath = payload.asFile().asJavaFile().getAbsolutePath();
                }
            }

            payloadApi.onPayloadReceived(endpointId, new Messages.PayloadMessage.Builder()
                            .setPayloadId(payload.getId())
                            .setType((long) payload.getType())
                            .setBytes(bytes)
                            .setUri(uri)
                            .setFilePath(filePath)
                            .build(),
                    null);
        }

        @Override
        public void onPayloadTransferUpdate(@NonNull String endpointId,
                                            @NonNull PayloadTransferUpdate payloadTransferUpdate) {
            // required for files and streams

            Log.d("nearby_connections", "onPayloadTransferUpdate");
            payloadApi.onPayloadTransferUpdate(endpointId, new Messages.PayloadTransferUpdateMessage.Builder()
                    .setPayloadId(payloadTransferUpdate.getPayloadId())
                    .setStatus((long) payloadTransferUpdate.getStatus())
                    .setBytesTransferred(payloadTransferUpdate.getBytesTransferred())
                    .setTotalBytes(payloadTransferUpdate.getTotalBytes())
                    .build(),
                    null);
        }
    };

    private final EndpointDiscoveryCallback endpointDiscoveryCallback = new EndpointDiscoveryCallback() {
        @Override
        public void onEndpointFound(@NonNull String endpointId,
                                    @NonNull DiscoveredEndpointInfo discoveredEndpointInfo) {
            Log.d("nearby_connections", "onEndpointFound");
            endpointDiscoveryApi.onEndpointFound(endpointId, discoveredEndpointInfo.getEndpointName(), discoveredEndpointInfo.getServiceId(), null);
        }

        @Override
        public void onEndpointLost(@NonNull String endpointId) {
            Log.d("nearby_connections", "onEndpointLost");
            endpointDiscoveryApi.onEndpointLost(endpointId, null);
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

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        locationHelper = new LocationHelper();

        BinaryMessenger messenger = binding.getBinaryMessenger();

        discoveryConnectionLifecycleApi = new Messages.DiscoveryConnectionLifecycleApi(messenger);
        advertisingConnectionLifecycleApi = new Messages.AdvertisingConnectionLifecycleApi(messenger);
        endpointDiscoveryApi = new Messages.EndpointDiscoveryApi(messenger);
        payloadApi = new Messages.PayloadApi(messenger);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        locationHelper = null;
    }

    private static void attachToActivity(ActivityPluginBinding binding) {
        activityPluginBinding = binding;
        try {
            locationHelper.setActivity(binding.getActivity());
            initiate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void detachActivity() {
        activityPluginBinding.removeRequestPermissionsResultListener(locationHelper);
        activityPluginBinding.removeActivityResultListener(locationHelper);
        activityPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        attachToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        this.detachActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.detachActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        attachToActivity(binding);
    }

    private static void initiate() {
        if (pluginRegistrar != null) {
            pluginRegistrar.addActivityResultListener(locationHelper);
            pluginRegistrar.addRequestPermissionsResultListener(locationHelper);
        } else {
            activityPluginBinding.addActivityResultListener(locationHelper);
            activityPluginBinding.addRequestPermissionsResultListener(locationHelper);
        }
    }
    /** Copies a stream from one location to another. */
    private static void copyStream(InputStream in, OutputStream out) throws IOException {
        try {
            byte[] buffer = new byte[1024];
            int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
        out.flush();
        } finally {
            in.close();
            out.close();
        }
    }

    @Override
    public void checkLocationPermission(Messages.Result<Boolean> result) {

    }

    @Override
    public void askLocationPermission(Messages.Result<Boolean> result) {

    }

    @Override
    public void checkExternalStoragePermission(Messages.Result<Boolean> result) {

    }

    @Override
    public void checkBluetoothPermission(Messages.Result<Boolean> result) {

    }

    @Override
    public void checkLocationEnabled(Messages.Result<Boolean> result) {

    }

    @Override
    public void enableLocationServices(Messages.Result<Boolean> result) {

    }

    @Override
    public void askExternalStoragePermission() {

    }

    @Override
    public void askBluetoothPermission() {

    }

    @Override
    public void askLocationAndExternalStoragePermission() {

    }

    @Override
    public void copyFileAndDeleteOriginal(@NonNull String sourceUri, @NonNull String destinationFilepath, Messages.Result<Boolean> result) {

    }

    @Override
    public void startAdvertising(@NonNull Messages.IdentifierMessage identifierMessage, Messages.Result<Boolean> result) {

    }

    @Override
    public void stopAdvertising(Messages.Result<Void> result) {

    }

    @Override
    public void startDiscovery(@NonNull Messages.IdentifierMessage identifierMessage, Messages.Result<Boolean> result) {

    }

    @Override
    public void stopDiscovery(Messages.Result<Void> result) {

    }

    @Override
    public void stopAllEndpoints(Messages.Result<Void> result) {

    }

    @Override
    public void disconnectFromEndpoint(@NonNull String endpointId, Messages.Result<Void> result) {

    }

    @Override
    public void requestConnection(@NonNull String userNickName, @NonNull String endpointId, Messages.Result<Boolean> result) {

    }

    @Override
    public void acceptConnection(@NonNull String endpointId, Messages.Result<Boolean> result) {

    }

    @Override
    public void rejectConnection(@NonNull String endpointId, Messages.Result<Boolean> result) {

    }

    @Override
    public void sendBytesPayload(@NonNull String endpointId, @NonNull byte[] bytes, Messages.Result<Void> result) {

    }

    @Override
    public void sendFilePayload(@NonNull String endpointId, @NonNull String filePath, Messages.Result<Long> result) {

    }

    @Override
    public void cancelPayload(@NonNull Long payloadId, Messages.Result<Void> result) {

    }
}
