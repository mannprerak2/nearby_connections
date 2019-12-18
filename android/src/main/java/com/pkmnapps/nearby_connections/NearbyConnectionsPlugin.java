package com.pkmnapps.nearby_connections;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;

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
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.util.Log;

/**
 * NearbyConnectionsPlugin
 */
public class NearbyConnectionsPlugin implements MethodCallHandler {
    private Activity activity;
    private static final String SERVICE_ID = "com.pkmnapps.nearby_connections";
    private static MethodChannel channel;

    private NearbyConnectionsPlugin(Activity activity) {
        this.activity = activity;
    }

    /**
     * Plugin registration.
     */

    public static void registerWith(Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), "nearby_connections");
        channel.setMethodCallHandler(new NearbyConnectionsPlugin(registrar.activity()));
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {

        switch (call.method) {
            case "checkLocationPermission":
                if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION)
                        == PackageManager.PERMISSION_GRANTED && ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION)
                        == PackageManager.PERMISSION_GRANTED) {
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;
            case "askLocationPermission":
                ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION},
                        0);
                Log.d("nearby_connections", "askLocationPermission");  
                result.success(null);
                break;
            case "checkExternalStoragePermission":
                if (ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_EXTERNAL_STORAGE)
                        == PackageManager.PERMISSION_GRANTED && ContextCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                        == PackageManager.PERMISSION_GRANTED) {
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;
            case "askExternalStoragePermission":
                ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE},
                        1);
                Log.d("nearby_connections", "askExternalStoragePermission");  
                result.success(null);
                break;
            case "askLocationAndExternalStoragePermission":
                ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION,Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE},
                        1);
                Log.d("nearby_connections", "askExternalStoragePermission");  
                result.success(null);
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
                if(serviceId==null || serviceId =="")
                    serviceId=SERVICE_ID;

                AdvertisingOptions advertisingOptions = new AdvertisingOptions.Builder()
                        .setStrategy(getStrategy(strategy)).build();

                Nearby.getConnectionsClient(activity)
                        .startAdvertising(
                                userNickName, serviceId, advertConnectionLifecycleCallback, advertisingOptions)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                Log.d("nearby_connections", "startAdvertising");
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
            }
            case "startDiscovery": {
                String userNickName = (String) call.argument("userNickName");
                int strategy = (int) call.argument("strategy");
                String serviceId = (String) call.argument("serviceId");

                assert userNickName != null;
                if(serviceId==null || serviceId =="")
                    serviceId=SERVICE_ID;

                DiscoveryOptions discoveryOptions =
                        new DiscoveryOptions.Builder().setStrategy(getStrategy(strategy)).build();
                Nearby.getConnectionsClient(activity)
                        .startDiscovery(serviceId, endpointDiscoveryCallback, discoveryOptions)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                Log.d("nearby_connections", "startDiscovery");
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
                        })
                        .addOnFailureListener(new OnFailureListener() {
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
                Nearby.getConnectionsClient(activity)
                        .acceptConnection(endpointId, payloadCallback)
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
            }
            case "rejectConnection": {
                String endpointId = (String) call.argument("endpointId");

                assert endpointId != null;
                Nearby.getConnectionsClient(activity)
                        .rejectConnection(endpointId)
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
                    result.success(filePayload.getId()); //return payload id to dart
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
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            args.put("endpointName", connectionInfo.getEndpointName());
            args.put("authenticationToken", connectionInfo.getAuthenticationToken());
            args.put("isIncomingConnection", connectionInfo.isIncomingConnection());
            channel.invokeMethod("ad.onConnectionInitiated", args);
        }

        @Override
        public void onConnectionResult(@NonNull String endpointId, @NonNull ConnectionResolution connectionResolution) {
            Log.d("nearby_connections", "ad.onConnectionResult");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
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
            args.put("statusCode", statusCode);
            channel.invokeMethod("ad.onConnectionResult", args);
        }

        @Override
        public void onDisconnected(@NonNull String endpointId) {
            Log.d("nearby_connections", "ad.onDisconnected");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            channel.invokeMethod("ad.onDisconnected", args);
        }
    };

    private final ConnectionLifecycleCallback discoverConnectionLifecycleCallback = new ConnectionLifecycleCallback() {
        @Override
        public void onConnectionInitiated(@NonNull String endpointId, @NonNull ConnectionInfo connectionInfo) {
            Log.d("nearby_connections", "dis.onConnectionInitiated");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            args.put("endpointName", connectionInfo.getEndpointName());
            args.put("authenticationToken", connectionInfo.getAuthenticationToken());
            args.put("isIncomingConnection", connectionInfo.isIncomingConnection());
            channel.invokeMethod("dis.onConnectionInitiated", args);
        }

        @Override
        public void onConnectionResult(@NonNull String endpointId, @NonNull ConnectionResolution connectionResolution) {
            Log.d("nearby_connections", "dis.onConnectionResult");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
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
            args.put("statusCode", statusCode);
            channel.invokeMethod("dis.onConnectionResult", args);
        }

        @Override
        public void onDisconnected(@NonNull String endpointId) {
            Log.d("nearby_connections", "dis.onDisconnected");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            channel.invokeMethod("dis.onDisconnected", args);
        }
    };

    private final PayloadCallback payloadCallback = new PayloadCallback() {
        @Override
        public void onPayloadReceived(@NonNull String endpointId, @NonNull Payload payload) {
            Log.d("nearby_connections", "onPayloadReceived");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            args.put("payloadId", payload.getId());
            args.put("type", payload.getType());

            if (payload.getType() == Payload.Type.BYTES) {
                byte[] bytes = payload.asBytes();
                assert bytes != null;
                args.put("bytes", bytes);
            } else if (payload.getType() == Payload.Type.FILE) {
                args.put("filePath", payload.asFile().asJavaFile().getAbsolutePath());
            }

            channel.invokeMethod("onPayloadReceived", args);
        }

        @Override
        public void onPayloadTransferUpdate(@NonNull String endpointId, @NonNull PayloadTransferUpdate payloadTransferUpdate) {
            //required for files and streams

            Log.d("nearby_connections", "onPayloadTransferUpdate");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            args.put("payloadId", payloadTransferUpdate.getPayloadId());
            args.put("status", payloadTransferUpdate.getStatus());
            args.put("bytesTransferred", payloadTransferUpdate.getBytesTransferred());
            args.put("totalBytes", payloadTransferUpdate.getTotalBytes());

            channel.invokeMethod("onPayloadTransferUpdate", args);
        }
    };

    private final EndpointDiscoveryCallback endpointDiscoveryCallback = new EndpointDiscoveryCallback() {
        @Override
        public void onEndpointFound(@NonNull String endpointId, @NonNull DiscoveredEndpointInfo discoveredEndpointInfo) {
            Log.d("nearby_connections", "onEndpointFound");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            args.put("endpointName", discoveredEndpointInfo.getEndpointName());
            args.put("serviceId", discoveredEndpointInfo.getServiceId());
            channel.invokeMethod("dis.onEndpointFound", args);
        }

        @Override
        public void onEndpointLost(@NonNull String endpointId) {
            Log.d("nearby_connections", "onEndpointLost");
            Map<String, Object> args = new HashMap<>();
            args.put("endpointId", endpointId);
            channel.invokeMethod("dis.onEndpointLost", args);
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
