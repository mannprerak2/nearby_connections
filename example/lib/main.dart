import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';

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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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
                    showModalBottomSheet(
                      context: context,
                      builder: (builder) {
                        return Center(
                          child: Column(
                            children: <Widget>[
                              Text("id: " + id),
                              Text("Token: " + info.authenticationToken),
                              Text("Name" + info.endpointName),
                              Text("Incoming: " +
                                  info.isIncomingConnection.toString()),
                              RaisedButton(
                                child: Text("Accept Connection"),
                                onPressed: () {
                                  Nearby().acceptConnection(id);
                                },
                              ),
                              RaisedButton(
                                child: Text("Reject Connection"),
                                onPressed: () {
                                  Nearby().rejectConnection(id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
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
                                  Nearby().requestConnection(
                                    userName,
                                    id,
                                    onConnectionInitiated: (id, info) {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (builder) {
                                          return Center(
                                            child: Column(
                                              children: <Widget>[
                                                Text("id: " + id),
                                                Text("Token: " +
                                                    info.authenticationToken),
                                                Text(
                                                    "Name" + info.endpointName),
                                                Text("Incoming: " +
                                                    info.isIncomingConnection
                                                        .toString()),
                                                RaisedButton(
                                                  child:
                                                      Text("Accept Connection"),
                                                  onPressed: () {
                                                    Nearby()
                                                        .acceptConnection(id);
                                                  },
                                                ),
                                                RaisedButton(
                                                  child:
                                                      Text("Reject Connection"),
                                                  onPressed: () {
                                                    Nearby()
                                                        .rejectConnection(id);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
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
        ],
      ),
    );
  }

  void showSnackbar(dynamic a) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }
}
