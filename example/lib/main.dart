import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Connections example app'),
        ),
        body: Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  @override
  _MyBodyState createState() => _MyBodyState();
}

class _MyBodyState extends State<Body> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;

  String cId = "0"; //currently connected device ID
  File tempFile; //reference to the file currently being transferred
  Map<int, String> map =
      Map(); //store filename mapped to corresponding payloadId

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Text(
              "Permissions",
            ),
            Wrap(
              children: <Widget>[
                RaisedButton(
                  child: Text("checkLocationPermission"),
                  onPressed: () async {
                    if (await Nearby().checkLocationPermission()) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text("Location permissions granted :)")));
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content:
                              Text("Location permissions not granted :(")));
                    }
                  },
                ),
                RaisedButton(
                  child: Text("askLocationPermission"),
                  onPressed: () {
                    Nearby().askLocationPermission();
                  },
                ),
                RaisedButton(
                  child: Text("checkExternalStoragePermission"),
                  onPressed: () async {
                    if (await Nearby().checkExternalStoragePermission()) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content:
                              Text("External Storage permissions granted :)")));
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "External Storage permissions not granted :(")));
                    }
                  },
                ),
                RaisedButton(
                  child: Text("askExternalStoragePermission"),
                  onPressed: () {
                    Nearby().askExternalStoragePermission();
                  },
                ),
              ],
            ),
            Divider(),
            Text("Location Enabled"),
            Wrap(
              children: <Widget>[
                RaisedButton(
                  child: Text("checkLocationEnabled"),
                  onPressed: () async {
                    if (await Nearby().checkLocationEnabled()) {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Location is ON :)")));
                    } else {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Location is OFF :(")));
                    }
                  },
                ),
                RaisedButton(
                  child: Text("enableLocationServices"),
                  onPressed: () async {
                    if (await Nearby().enableLocationServices()) {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Location Service Enabled :)")));
                    } else {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Enabling Location Service Failed :(")));
                    }
                  },
                ),
              ],
            ),
            Divider(),
            Text("User Name: " + userName),
            Wrap(
              children: <Widget>[
                RaisedButton(
                  child: Text("Start Advertising"),
                  onPressed: () async {
                    try {
                      bool a = await Nearby().startAdvertising(
                        userName,
                        strategy,
                        onConnectionInitiated: onConnectionInit,
                        onConnectionResult: (id, status) {
                          showSnackbar(status);
                        },
                        onDisconnected: (id) {
                          showSnackbar("Disconnected: " + id);
                        },
                      );
                      showSnackbar("ADVERTISING: " + a.toString());
                    } catch (exception) {
                      showSnackbar(exception);
                    }
                  },
                ),
                RaisedButton(
                  child: Text("Stop Advertising"),
                  onPressed: () async {
                    await Nearby().stopAdvertising();
                  },
                ),
              ],
            ),
            Wrap(
              children: <Widget>[
                RaisedButton(
                  child: Text("Start Discovery"),
                  onPressed: () async {
                    try {
                      bool a = await Nearby().startDiscovery(
                        userName,
                        strategy,
                        onEndpointFound: (id, name, serviceId) {
                          // show sheet automatically to request connection
                          showModalBottomSheet(
                            context: context,
                            builder: (builder) {
                              return Center(
                                child: Column(
                                  children: <Widget>[
                                    Text("id: " + id),
                                    Text("Name: " + name),
                                    Text("ServiceId: " + serviceId),
                                    RaisedButton(
                                      child: Text("Request Connection"),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Nearby().requestConnection(
                                          userName,
                                          id,
                                          onConnectionInitiated: (id, info) {
                                            onConnectionInit(id, info);
                                          },
                                          onConnectionResult: (id, status) {
                                            showSnackbar(status);
                                          },
                                          onDisconnected: (id) {
                                            showSnackbar(id);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        onEndpointLost: (id) {
                          showSnackbar("Lost Endpoint:" + id);
                        },
                      );
                      showSnackbar("DISCOVERING: " + a.toString());
                    } catch (e) {
                      showSnackbar(e);
                    }
                  },
                ),
                RaisedButton(
                  child: Text("Stop Discovery"),
                  onPressed: () async {
                    await Nearby().stopDiscovery();
                  },
                ),
              ],
            ),
            RaisedButton(
              child: Text("Stop All Endpoints"),
              onPressed: () async {
                await Nearby().stopAllEndpoints();
              },
            ),
            Divider(),
            Text(
              "Sending Data",
            ),
            RaisedButton(
              child: Text("Send Random Bytes Payload"),
              onPressed: () async {
                String a = Random().nextInt(100).toString();
                showSnackbar("Sending $a to $cId");
                Nearby().sendBytesPayload(cId, Uint8List.fromList(a.codeUnits));
              },
            ),
            RaisedButton(
              child: Text("Send File Payload"),
              onPressed: () async {
                File file =
                    await ImagePicker.pickImage(source: ImageSource.gallery);

                if (file == null) return;

                int payloadId = await Nearby().sendFilePayload(cId, file.path);
                showSnackbar("Sending file to $cId");
                Nearby().sendBytesPayload(
                    cId,
                    Uint8List.fromList(
                        "$payloadId:${file.path.split('/').last}".codeUnits));
              },
            ),
          ],
        ),
      ),
    );
  }

  void showSnackbar(dynamic a) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  /// Called upon Connection request (on both devices)
  /// Both need to accept connection to start sending/receiving
  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: " + id),
              Text("Token: " + info.authenticationToken),
              Text("Name" + info.endpointName),
              Text("Incoming: " + info.isIncomingConnection.toString()),
              RaisedButton(
                child: Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  cId = id;
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes);
                        showSnackbar(endid + ": " + str);

                        if (str.contains(':')) {
                          // used for file payload as file payload is mapped as
                          // payloadId:filename
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);

                          if (map.containsKey(payloadId)) {
                            if (await tempFile.exists()) {
                              tempFile.rename(
                                  tempFile.parent.path + "/" + fileName);
                            } else {
                              showSnackbar("File doesnt exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar(endid + ": File transfer started");
                        tempFile = File(payload.filePath);
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                        showSnackbar(endid + ": FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        showSnackbar(
                            "success, total bytes = ${payloadTransferUpdate.totalBytes}");

                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id];
                          tempFile.rename(tempFile.parent.path + "/" + name);
                        } else {
                          //bytes not received till yet
                          map[payloadTransferUpdate.id] = "";
                        }
                      }
                    },
                  );
                },
              ),
              RaisedButton(
                child: Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
