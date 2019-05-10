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
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: Column(
        children: <Widget>[
          RaisedButton(
            child: Text("checkPermission"),
            onPressed: () async {
              if (await Nearby.instance.checkPermissions()) {
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("yes")));
              } else {
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("No")));
              }
            },
          ),
          RaisedButton(
            child: Text("askPermission(permission handler)"),
            onPressed: () async {
              await Nearby.instance.askPermission();
            },
          ),
          RaisedButton(
            child: Text("Start Advertising"),
            onPressed: () async {
              try {
                bool a = await Nearby.instance
                    .startAdvertising("pkmn", STRATEGY.P2P_STAR);
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text(a.toString())));
              } catch (exception) {
                Scaffold.of(context).showSnackBar(
                    SnackBar(content: Text(exception.toString())));
              }
            },
          ),
          RaisedButton(
            child: Text("Stop Advertising"),
            onPressed: () async {
              await Nearby.instance.stopAdvertising();
            },
          ),
        ],
      ),
    );
  }
}
