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
          title: const Text('Plugin example app'),
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
  final String userName = Random().nextInt(1000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  String cId = "0";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          RaisedButton(
            child: Text("checkPermission"),
            onPressed: () async {
              if (await Nearby().checkPermissions()) {
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("yes")));
              } else {
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("No")));
              }
            },
          ),
          RaisedButton(
            child: Text("askPermission(location)"),
            onPressed: () async {
              await Nearby().askPermission();
            },
          ),
          Text("UserName: " + userName),
          RaisedButton(
            child: Text("Start Advertising"),
            onPressed: () async {
              try {
                bool a = await Nearby().startAdvertising(
                  userName,
                  strategy,
                  onConnectionInitiated: (id, info) {
                    oci(id, info);
                  },
                  onConnectionResult: (id, status) {
                    showSnackbar(status);
                  },
                  onDisconnected: (id) {
                    showSnackbar(id);
                  },
                );
                showSnackbar(a);
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
          RaisedButton(
            child: Text("Start Discovery"),
            onPressed: () async {
              try {
                bool a = await Nearby().startDiscovery(
                  userName,
                  strategy,
                  onEndpointFound: (id, name, serviceId) {
                    print("in callback");
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
                                      oci(id, info);
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
                    showSnackbar(id);
                  },
                );
                showSnackbar(a);
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
          RaisedButton(
            child: Text("Stop All Endpoints"),
            onPressed: () async {
              await Nearby().stopAllEndpoints();
            },
          ),
          RaisedButton(
            child: Text("Send Random Bytes Payload"),
            onPressed: () async {
              String a = Random().nextInt(100).toString();
              showSnackbar("Sending $a to $cId");
              Nearby().sendPayload(cId, Uint8List.fromList(a.codeUnits));
            },
          ),
          RaisedButton(
            child: Text("Send File Payload"),
            onPressed: () async {
              File file =
                  await ImagePicker.pickImage(source: ImageSource.gallery);

              if (file == null) return;

              Nearby().sendFilePayload(cId, file.path);
              showSnackbar("Sending file to $cId");
            },
          ),
        ],
      ),
    );
  }

  void showSnackbar(dynamic a) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  /// Called on a Connection request (on both devices)
  void oci(String id, ConnectionInfo info) {
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
                    onPayLoadRecieved: (endid, payload) {
                      if (payload.type == PayloadType.BYTES) {
                        showSnackbar(
                            endid + ": " + String.fromCharCodes(payload.bytes));
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar(endid + ": File transfer started");
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
                        print(
                            "success, total bytes = ${payloadTransferUpdate.totalBytes}");
                        showSnackbar(endid +
                            ": SUCCESS in file transfer (file is un-named in downloads) ");
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
