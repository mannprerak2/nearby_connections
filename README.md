<img src="https://developers.google.com/nearby/images/nearby_logo.svg" align="right">

# nearby_connections

An **ANDROID** flutter plugin for the [Nearby Connections API](https://developers.google.com/nearby/connections/overview)
Currently supports Bytes and Files.

**Transfer Data between multiple connected devices using fully offline peer to peer networking**

[![pub package](https://img.shields.io/pub/v/nearby_connections.svg)](https://pub.dartlang.org/packages/nearby_connections)
[![Stars](https://img.shields.io/github/stars/mannprerak2/nearby_connections?logo=github&style=flat&color=green)](https://github.com/mannprerak2/nearby_connections)
[![Forks](https://img.shields.io/github/forks/mannprerak2/nearby_connections?logo=github&style=flat&color=purple)](https://github.com/mannprerak2/nearby_connections)

## Table of Content

-   [Setup](#setup)
-   [Work Flow](#work-flow)
    -   [Advertise For connections](#advertise-for-connection)
    -   [Discover Advertisers](#discover-advertisers)
    -   [Request Connection](#request-connection)
    -   [Accept Connection](#accept-connection)
-   [Sending Data](#sending-data)
    -   [Sending Bytes Payload](#sending-bytes-payload)
    -   [Sending Files](#sending-file-payload)

## Setup

### Note regarding Location(GPS)

While using this,
**Location/GPS service must be turned on** or devices may disconnect
more often, some devices may disconnect immediately.

### Set [Permissions](https://developers.google.com/nearby/connections/android/get-started#request_permissions)

Add these to your project's `android/src/main/AndroidManifest.xml`

```xml
<!-- Required for Nearby Connections -->
<uses-permission android:maxSdkVersion="31" android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:maxSdkVersion="31" android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:maxSdkVersion="30" android:name="android.permission.BLUETOOTH" />
<uses-permission android:maxSdkVersion="30" android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:maxSdkVersion="28" android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:minSdkVersion="29" android:maxSdkVersion="31" android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:minSdkVersion="32" android:name="android.permission.NEARBY_WIFI_DEVICES" />
<!-- Optional: only required for FILE payloads -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

> Note: Android 12+ has introduced some new [bluetooth permissions](https://developer.android.com/about/versions/12/features#bluetooth-permissions) - `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, which need to be handled as well. You may also need to set `compileSdkVersion 32` in your build.gradle file.

### Request Permissions

Since ACCESS_FINE_LOCATION, BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT, BLUETOOTH_SCAN and READ_EXTERNAL_STORAGE are considered to be dangerous system permissions, in addition to adding them to your manifest, you must request these permissions at runtime.

> You can use:
>
> -   [permission_handler](https://pub.dev/packages/permission_handler) package to handle all these permissions
> -   [location](https://pub.dev/packages/location) package to request enabling location.
> -   [device_info_plus](https://pub.dev/packages/device_info_plus) to check Android verison.

```dart
// location permission
await Permission.location.isGranted         // Check Permission
await Permission.location.request()         // Ask

// Check Location Status
await Permission.location.serviceStatus.isEnabled;

// location enable dialog
await Location.instance.requestService()

// external storage permission
await Permission.storage.isGranted          // Check Permission
await Permission.storage.request()          // Ask

// Bluetooth permissions
bool granted = !(await Future.wait([        // Check Permissions
    Permission.bluetooth.isGranted,
    Permission.bluetoothAdvertise.isGranted,
    Permission.bluetoothConnect.isGranted,
    Permission.bluetoothScan.isGranted,
])).any((element) => false);
[                                           // Ask Permissions
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.bluetoothScan
].request();

// Check Bluetooth Status
await Permission.bluetooth.serviceStatus.isEnabled;


// Android 12+
await Permission.nearbyWifiDevices.request()
```

Checkout the [**Example**](https://github.com/mannprerak2/nearby_connections/tree/master/example) in Repository for more details.

## NOTE

**Location/GPS service must be turned on** or devices may disconnect
more often, some devices may disconnect immediately.

## Work Flow

The work flow is similar to the [Android Nearby Connections library](https://developers.google.com/nearby/connections/overview)

### Advertise for connection

```dart
try {
    bool a = await Nearby().startAdvertising(
        userName,
        strategy, // https://developers.google.com/nearby/connections/strategies
        onConnectionInitiated: (String id,ConnectionInfo info) {
        // Called whenever a discoverer requests connection
        },
        onConnectionResult: (String id,Status status) {
        // Called when connection is accepted/rejected
        },
        onDisconnected: (String id) {
        // Callled whenever a discoverer disconnects from advertiser
        },
        serviceId: "com.yourdomain.appname", // uniquely identifies your app
    );
} catch (exception) {
    // platform exceptions like unable to start bluetooth or insufficient permissions
}
```

### Discover Advertisers

```dart
try {
    bool a = await Nearby().startDiscovery(
        userName,
        strategy, // https://developers.google.com/nearby/connections/strategies
        onEndpointFound: (String id,String userName, String serviceId) {
            // called when an advertiser is found
        },
        onEndpointLost: (String id) {
            //called when an advertiser is lost (only if we weren't connected to it )
        },
        serviceId: "com.yourdomain.appname", // uniquely identifies your app
    );
} catch (e) {
    // platform exceptions like unable to start bluetooth or insufficient permissions
}
```

### Stopping Advertising and Discovery

```dart
Nearby().stopAdvertising();
Nearby().stopDiscovery();
// endpoints already discovered will still be available to connect
// even after stopping discovery
// You should stop discovery once you have found the intended advertiser
// this will reduce chances for disconnection
```

### Request Connection

```dart
// to be called by discover whenever an endpoint is found
// callbacks are similar to those in startAdvertising method
try{
    Nearby().requestConnection(
        userName,
        id,
        onConnectionInitiated: (id, info) {
        },
        onConnectionResult: (id, status) {
        },
        onDisconnected: (id) {
        },
    );
}catch(exception){
    // called if request was invalid
}
```

### Accept Connection

```dart
Nearby().acceptConnection(
    id,
    onPayLoadRecieved: (endpointId, payload) {
        // called whenever a payload is recieved.
    },
    onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {
        // gives status of a payload
        // e.g success/failure/in_progress
        // bytes transferred and total bytes etc
    }
);
```

## Sending Data

### Sending Bytes Payload

```dart
Nearby().sendBytesPayload(endpointId, bytes_array);

// payloads are recieved by callback given to acceptConnection method.
```

### Sending File Payload

You need to send the File Payload and File Name seperately.

File is stored in `DOWNLOAD_DIRECTORY/.nearby/` and given a generic name.
You need to copy the file to another directory of your choice.

```dart
//creates file with generic name (without extension) in Downloads Directory
//its your responsibility to rename the file properly
Nearby().sendFilePayload(endpointId, filePath);

//Send filename as well so that receiver can move and rename the file
Nearby().sendBytesPayload(endpointId,fileNameEncodedWithPayloadId);
//e.g send a string like "payloadId:FileExtensionOrFullName" as bytes

//payloads are recieved by callback given to acceptConnection method.
```

Every payload has an **ID** which is same for sender and receiver.

You can get the `uri` of the file from Payload in _onPayloadReceived_ function.
We have a convenience method to copy the file to a location you want-

```dart
// Convenience method to copy file using it's `uri`.
final newPath = '${await getExternalStorageDirectory}/$fileName';
await Nearby().copyFileAndDeleteOriginal(uri, newPath);
```

Checkout the [**Example**](https://github.com/mannprerak2/nearby_connections/tree/master/example) in Repository for more details.
