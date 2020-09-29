import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdns_plugin/flutter_mdns_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../lottie_widget.dart';
import 'home_widget.dart';

const String discovery_service = "_http._tcp";

class MDNSWidget extends StatefulWidget {
  @override
  _MDNSWidgetState createState() => _MDNSWidgetState();
}

class _MDNSWidgetState extends State<MDNSWidget> {
  var discoveryFlag = "INITIALISING";
  var deviceId;
  ServiceInfo mdnsDetails;
  FlutterMdnsPlugin _mdnsPlugin;
  DiscoveryCallbacks discoveryCallbacks;
  List<ServiceInfo> _discoveredServices = <ServiceInfo>[];

  @override
  initState() {
    super.initState();

    discoveryCallbacks = new DiscoveryCallbacks(
      onDiscovered: (ServiceInfo info) {
        setState(() {
          discoveryFlag = "DISCOVERED";
        });
      },
      onDiscoveryStarted: () {
        setState(() {
          discoveryFlag = "DISCOVERED";
        });
        print("Discovery Started");
      },
      onDiscoveryStopped: () {
        setState(() {
          discoveryFlag = "FAILED";
        });
        print("Discovery failed");
      },
      onResolved: (ServiceInfo info) async {
        print("Discovery Found: " + info.name);
        /// Check if discovered service is Queberry-halo
        if (info.name == "queberry-halo") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          if (prefs.getString("deviceId") != null) {
            print("Id from Shared Pref: " + prefs.getString("deviceId"));
            setState(() {
              mdnsDetails = info;
              deviceId = prefs.getString("deviceId");
              discoveryFlag = "RESOLVED";
            });
          } else {
            var uuid = Uuid();
            var id = uuid.v4();
            print("Generated DeviceId: " + id);
            prefs.setString("deviceId", id);
            setState(() {
              mdnsDetails = info;
              deviceId = prefs.getString("deviceId");
              discoveryFlag = "RESOLVED";
            });
          }
        }
      },
    );

    startMdnsDiscovery(discovery_service);
  }

  @override
  Widget build(BuildContext context) {
    /// load home in resolved and deviceId generated
    if (this.discoveryFlag == "RESOLVED" && this.deviceId != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("PRODIGY AI"),
        ),
        body: HomeWidget(
            deviceId: this.deviceId,
            serverIp: mdnsDetails.address,
            portNumber: mdnsDetails.port),
      );
    } else {
      switch (this.discoveryFlag) {
        case 'INITIALISING':
          return Scaffold(
            appBar: AppBar(
              title: Text("PRODIGY AI"),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      child: LottieWidget(lottieType: "connect_modem")),
                  Container(
                    child: Text(
                      "initialized",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 30,
                          color: Colors.white70,
                          decoration: TextDecoration.none),
                    ),
                  )
                ],
              ),
            ),
          );
          break;
        case 'DISCOVERED':
          return Scaffold(
            appBar: AppBar(
              title: Text("PRODIGY AI"),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      child: LottieWidget(lottieType: "connect_modem")),
                  Container(
                    child: Text(
                      "searching..",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 30,
                          color: Colors.white70,
                          decoration: TextDecoration.none),
                    ),
                  )
                ],
              ),
            ),
          );
          break;
        case 'RESOLVED':
          return Scaffold(
            appBar: AppBar(
              title: Text("PRODIGY AI"),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: LottieWidget(lottieType: "connect_modem")),
                  Container(
                    child: Text(
                      "resolving..",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 30,
                          color: Colors.white70,
                          decoration: TextDecoration.none),
                    ),
                  )
                ],
              ),
            ),
          );
          break;
        case 'FAILED':
          return Scaffold(
            appBar: AppBar(
              title: Text("PRODIGY AI"),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: LottieWidget(lottieType: "warning")),
                  Container(
                    child: Text(
                      "MDNS failed",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 40,
                          color: Colors.white70,
                          decoration: TextDecoration.none),
                    ),
                  )
                ],
              ),
            ),
          );
          break;
        default:
          return Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: LottieWidget(lottieType: "warning")),
                Container(
                  child: Text(
                    "connection failed",
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 40,
                        color: Colors.blueGrey[900],
                        decoration: TextDecoration.none),
                  ),
                )
              ],
            ),
          );
      }
    }
  }

  startMdnsDiscovery(String serviceType) {
    _mdnsPlugin = new FlutterMdnsPlugin(discoveryCallbacks: discoveryCallbacks);

    /// cannot directly start discovery, have to wait for ios to be ready first...
    Timer(Duration(seconds: 3), () => _mdnsPlugin.startDiscovery(serviceType));
  }

  void reassemble() {
    super.reassemble();
    if (null != _mdnsPlugin) {
      _discoveredServices = <ServiceInfo>[];
      _mdnsPlugin.restartDiscovery();
    }
  }
}
