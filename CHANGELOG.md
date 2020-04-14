## 1.1.0
* Updated Android Nearby version from 16.0.0 to 17.0.0
* Updated Example
* **Location/GPS service must be turned on** or devices may disconnect
more often, some devices may disconnect immediately. 2 convinience methods are added
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

* Changed convinience methods for asking permissions(location+storage)
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

* Added pub maintanence suggestions 

## 0.0.2

* Added dartdoc comments

## 0.0.1

* Currently only bytes (max 32k array size) payload are supported
* Analogous to NearbyConnection library in Android with similar callback names and all
* Singleton pattern using factory constructor

