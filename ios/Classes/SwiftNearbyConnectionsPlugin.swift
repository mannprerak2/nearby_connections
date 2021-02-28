import Flutter
import UIKit
import MultipeerConnectivity
import SwiftyJSON

let SERVICE_TYPE = "nearby_connections"
let INVOKE_CHANGE_STATE_METHOD = "ios.stateChanged"
let INVOKE_MESSAGE_RECEIVE_METHOD = "ios.messageReceived"

enum MethodCall: String {
  case startAdvertisingPeer = "startAdvertising"
  case startBrowsingForPeers = "startDiscovery"

  case adOnConnectionInitiated = "ad.onConnectionInitiated"
  case adOnConnectionResult = "ad.onConnectionResult"
  case adOnDisconnected = "ad.onConnectionResult"

  case disOnConnectionInitiated = "dis.onConnectionInitiated"
  case disOnConnectionResult = "dis.onConnectionResult"
  case disOnDisconnected = "dis.onConnectionResult"
  case disOnEndpointFound = "dis.onEndpointFound"
  case disOnEndpointLost = "dis.onEndpointLost"

  case stopAdvertisingPeer = "stopAdvertising"
  case stopBrowsingForPeers = "stopDiscovery"

  case invitePeer = "requestConnection"
  case disconnectPeer = "disconnectFromEndpoint"

  case sendMessage = "sendPayload"
}

public class SwiftNearbyConnectionsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
  let channel = FlutterMethodChannel(name: "nearby_connections", binaryMessenger: registrar.messenger())
  let instance = SwiftNearbyConnectionsPlugin()
  registrar.addMethodCallDelegate(instance, channel: channel)
  }

  var currentReceivedDevice: Device?

  let channel: FlutterMethodChannel

  struct DeviceJson {
    var deviceId:String
    var deviceName:String
    var state:Int

    func toStringAnyObject() -> [String: Any] {
      return [
        "endpointId": deviceId,
        "userNickName": deviceName,
        "state": state
      ]
    }
  }

  @objc func stateChanged(){
    let devices = MPCManager.instance.devices.compactMap({return DeviceJson(deviceId: $0.peerID.displayName, deviceName: $0.peerID.displayName, state: $0.state.rawValue)})
    channel.invokeMethod(INVOKE_CHANGE_STATE_METHOD, arguments: JSON(devices.compactMap({return $0.toStringAnyObject()})).rawString())
  }

  @objc func adOnConnectionInitiated(){
  }
  @objc func adOnConnectionResult(){
  }
  @objc func adOnDisconnected(){
  }


  @objc func disOnConnectionInitiated(){
  }
  @objc func disOnConnectionResult(){
  }
  @objc func disOnDisconnected(){
  }
  @objc func disOnEndpointFound(){
  }
  @objc func disOnEndpointLost(){
  }

  @objc func messageReceived(notification: Notification) {
    do {
      if let data = notification.userInfo?["data"] as? Data, let stringData = JSON(data).rawString() {
        let dict = convertToDictionary(text: stringData)
        self.channel.invokeMethod(INVOKE_MESSAGE_RECEIVE_METHOD, arguments: dict)
      }
    } catch let e {
      print(e.localizedDescription)
    }
  }

  func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
      do {
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      } catch {
        print(error.localizedDescription)
      }
    }
    return nil
  }

  public init(channel:FlutterMethodChannel) {
    self.channel = channel
    super.init()

    NotificationCenter.default.addObserver(self, selector: #selector(stateChanged), name: MPCManager.Notifications.deviceDidChangeState, object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(adOnConnectionInitiated), name: MPCManager.Notifications.adOnConnectionInitiated, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(adOnConnectionResult), name: MPCManager.Notifications.adOnConnectionResult, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(adOnDisconnected), name: MPCManager.Notifications.adOnDisconnected, object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(disOnConnectionInitiated), name: MPCManager.Notifications.disOnConnectionInitiated, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disOnConnectionResult), name: MPCManager.Notifications.disOnConnectionResult, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disOnDisconnected), name: MPCManager.Notifications.disOnDisconnected, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disOnEndpointFound), name: MPCManager.Notifications.disOnEndpointFound, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disOnEndpointLost), name: MPCManager.Notifications.disOnEndpointLost, object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(messageReceived), name: Device.messageReceivedNotification, object: nil)

    MPCManager.instance.deviceDidChange = {[weak self] in
      self?.stateChanged()
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch MethodCall(rawValue: call.method) {
    case .startAdvertisingPeer:
      guard let data = call.arguments as? Dictionary<String, AnyObject> else {
        result(false)
        return
      }
      let serviceType:String = data["serviceId"] as? String ?? SERVICE_TYPE
      var deviceName:String = data["userNickName"] as? String ?? ""
      if (deviceName.isEmpty){
        deviceName =  UIDevice.current.name
      }

      MPCManager.instance.setup(serviceType: serviceType, deviceName: deviceName, isAdvert: true)
      currentReceivedDevice = Device(peerID: MPCManager.instance.localPeerID)
      MPCManager.instance.startAdvertisingPeer()
      result(true)
    case .startBrowsingForPeers:
      guard let data = call.arguments as? Dictionary<String, AnyObject> else {
        result(false)
        return
      }
      let serviceType:String = data["serviceId"] as? String ?? SERVICE_TYPE
      var deviceName:String = data["userNickName"] as? String ?? ""
      if (deviceName.isEmpty){
        deviceName =  UIDevice.current.name
      }

      MPCManager.instance.setup(serviceType: serviceType, deviceName: deviceName, isAdvert: false)
      currentReceivedDevice = Device(peerID: MPCManager.instance.localPeerID)
      MPCManager.instance.startBrowsingForPeers()
      result(true)
    case .stopAdvertisingPeer:
      MPCManager.instance.stopAdvertisingPeer()
      result(true)
    case .stopBrowsingForPeers:
      MPCManager.instance.stopBrowsingForPeers()
      result(true)
    case .invitePeer:
      guard let data = call.arguments as? Dictionary<String, AnyObject> else {
        result(false)
        return
      }
      guard let deviceId: String = data["endpointId"] as? String else {
        result(false)
        return
      }
      MPCManager.instance.invitePeer(deviceID: deviceId)
      result(true)

    case .disconnectPeer:
      guard let data = call.arguments as? Dictionary<String, AnyObject> else {
        result(false)
        return
      }
      let deviceId:String? = data["endpointId"] as? String ?? nil
      if (deviceId != nil) {
        MPCManager.instance.disconnectPeer(deviceID: deviceId!)
        result(true)
      } else {
        result(false)
      }
    case .sendMessage:
      guard let dict = call.arguments as? Dictionary<String, AnyObject> else {
        result(false)
        return
      }
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: dict["bytes"])
        if let device = MPCManager.instance.findDevice(for: dict["endpointId"] as! String) {
          currentReceivedDevice = device
          try device.send(data: jsonData)
          result(true)
          return
        }
      } catch let error as NSError {
        print(error)
      }
      result(false)
    default:
      result(FlutterMethodNotImplemented)
      return
    }
  }

}
