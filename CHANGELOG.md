## 3.0.1
- Fix issues when running with sound null safety.

## 3.0.0
* Bump version to 3.0.0 (dart sdk `>=2.12.0 <3.0.0`).

## 3.0.0-nullsafety.1
* Fix typo in PayloadStatus enum (`IN_PROGRRESS -> IN_PROGRESS`).

## 3.0.0-nullsafety.0
* Migrated to Null Safety.

## 2.0.2
* Fix missingPluginException.

## 2.0.1
* Fix missing default constructor bug in android.

## 2.0.0
* `askLocationPermission` & `enableLocationService` return type changed to Future<bool>
* Fix typose, uUpdated example and readme

## 1.1.1+1
* Corrected supported platforms in pubpsec

## 1.1.0
* Updated Android Nearby version from 16.0.0 to 17.0.0
* Updated Example
* **Location/GPS service must be turned on** or devices may disconnect
more often, some devices may disconnect immediately. 2 convenience methods are added
`enableLocationServices` and `checkLocationEnabled`

## 1.0.3

* Added serviceId parameter in startAdvertising and startDiscovery
* Added new method askLocationAndExternalStoragePermission()
* Readme Fixes

## 1.0.2+1

* Updated dartdoc and Readme

## 1.0.2

* Added payload cancellation and other assertions 

## 1.0.1

* Changed convenience methods for asking permissions(location+storage)
* Updated example  

## 1.0.0

* Added support for Files (sendFilePayload)
* Breaking Change (sendPayload method signature is changed)
* Updated Example and Readme for file transfer

## 0.1.3+1

* Update documentation and Readme 

## 0.1.1

* Fixed sendPayload future not completing bug

## 0.1.0

* Added pub maintenance suggestions 

## 0.0.2

* Added dartdoc comments

## 0.0.1

* Currently only bytes (max 32k array size) payload are supported
* Analogous to NearbyConnection library in Android with similar callback names and all
* Singleton pattern using factory constructor

