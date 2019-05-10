# nearby_connections

An android flutter plugin for the Nearby Connections API

## Getting Started

### Set Permissions
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

