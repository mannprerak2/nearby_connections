# nearby_connections

An **android** flutter plugin for the Nearby Connections API

[![pub package](https://img.shields.io/pub/v/nearby_connections.svg)](https://pub.dartlang.org/packages/nearby_connections)

## Table of Content
* [Setup](#setup)
* [Work Flow](#work-flow)
    * [Advertise For connections](#advertise-for-connection)
    * [Discover Advertisers](#discover-advertisers)
    * [Request Connection](#request-connection)
    * [Accept Connection](#accept-connection)
* [Sending Data](#sending-data)
    * [Sending Bytes Payload](#sending-bytes-payload)

## Setup

### Set Permissions
Add these to AndroidManifest.xml
```xml
<!-- Required for Nearby Connections -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```
Since ACCESS_FINE_LOCATION is considered to be dangerous system permissions, in addition to adding them to your manifest, you must request these permissions at runtime.

##### As a convinience the library provides methods to check and request location permissions
```java
// returns true/false asynchronously 
bool a = await Nearby().checkPermissions()

// asks for permissions only if its not given
Nearby().askPermission()
```

## Work Flow

The work flow is similar to the [android nearby connections library](https://developers.google.com/nearby/connections/overviewoverview)

### Advertise for connection
```dart
try {
    bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id,ConnectionInfo info) {
        // Called whenever a discoverer requests connection 
        },
        onConnectionResult: (String id,Status status) {
        // Called when connection is accepted/rejected
        },
        onDisconnected: (id) {
        // Callled whenever a discoverer disconnects from advertiser
        },
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
        strategy,
        onEndpointFound: (String id,String name, String serviceId) {
            // called when an advertiser is found
        },
        onEndpointLost: (String id) {
            //called when an advertiser is lost (only if we weren't connected to it )
        },
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
    onPayLoadRecieved: (endid,Uint8List bytes) {
        // called whenever a payload is recieved.
    },
);
```
## Sending Data
### Sending Bytes Payload

```dart
Nearby().sendPayload(endpointId, bytes_array);

// payloads are recieved by callback given to acceptConnection method.
```




