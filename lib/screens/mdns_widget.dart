import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdns_plugin/flutter_mdns_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../lottie_widget.dart';
import 'home_widget.dart';

import '../constants/constants.dart' as CONSTANTS;

class MDNSWidget extends StatefulWidget {
  @override
  _MDNSWidgetState createState() => _MDNSWidgetState();
}

class _MDNSWidgetState extends State<MDNSWidget> {
  var discoveryFlag = CONSTANTS.mdns_init;
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
          discoveryFlag = CONSTANTS.mdns_discovered;
        });
      },
      onDiscoveryStarted: () {
        setState(() {
          discoveryFlag = CONSTANTS.mdns_discovered;
        });
        print("Discovery Started");
      },
      onDiscoveryStopped: () {
        setState(() {
          discoveryFlag = CONSTANTS.mdns_failed;
        });
        print("Discovery failed");
      },
      onResolved: (ServiceInfo info) async {
        print("Discovery Found: " + info.name);

        /// Check if discovered service is Queberry-halo
        if (info.name == CONSTANTS.halo_title) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          if (prefs.getString("deviceId") != null) {
            print("Id from Shared Pref: " + prefs.getString("deviceId"));
            setState(() {
              mdnsDetails = info;
              deviceId = prefs.getString("deviceId");
              discoveryFlag = CONSTANTS.mdns_resolved;
            });
          } else {
            var uuid = Uuid();
            var id = uuid.v4();
            print("Generated DeviceId: " + id);
            prefs.setString("deviceId", id);
            setState(() {
              mdnsDetails = info;
              deviceId = prefs.getString("deviceId");
              discoveryFlag = CONSTANTS.mdns_resolved;
            });
          }
        }
      },
    );

    startMdnsDiscovery(CONSTANTS.discovery_service);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(CONSTANTS.app_tittle),
        ),
        body: loadBody());
  }

  startMdnsDiscovery(String serviceType) {
    _mdnsPlugin = new FlutterMdnsPlugin(discoveryCallbacks: discoveryCallbacks);
    Timer(Duration(seconds: 3), () => _mdnsPlugin.startDiscovery(serviceType));
  }

  void reassemble() {
    super.reassemble();
    if (null != _mdnsPlugin) {
      _discoveredServices = <ServiceInfo>[];
      _mdnsPlugin.restartDiscovery();
    }
  }

  List<Widget> loadStatusLottie(discoveryFlag) {
    List<Widget> childrens = [];
    switch (discoveryFlag) {
      case CONSTANTS.mdns_init:
        childrens
            .add(Container(child: LottieWidget(lottieType: "connect_modem")));
        childrens.add(Container(child: generateText(CONSTANTS.initialized)));
        break;
      case CONSTANTS.mdns_discovered:
        childrens
            .add(Container(child: LottieWidget(lottieType: "connect_modem")));
        childrens.add(Container(child: generateText(CONSTANTS.searching)));
        break;
      case CONSTANTS.mdns_resolved:
        childrens
            .add(Container(child: LottieWidget(lottieType: "connect_modem")));
        childrens.add(Container(child: generateText(CONSTANTS.resolving)));
        break;
      case CONSTANTS.mdns_failed:
        childrens.add(Container(child: LottieWidget(lottieType: "warning")));
        childrens.add(Container(child: generateText(CONSTANTS.failed)));
        break;
      default:
        childrens.add(Container(child: LottieWidget(lottieType: "warning")));
        childrens
            .add(Container(child: generateText(CONSTANTS.something_wrong)));
        break;
    }
    return childrens;
  }

  Text generateText(text) {
    return Text(
      text,
      style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 30,
          color: Colors.white70,
          decoration: TextDecoration.none),
    );
  }

  Widget loadBody() {
    /// load HOME if resolved and deviceId generated
    if (this.discoveryFlag == CONSTANTS.mdns_resolved &&
        this.deviceId != null) {
      return HomeWidget(
          deviceId: this.deviceId,
          serverIp: mdnsDetails.address,
          portNumber: mdnsDetails.port);
    } else {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: loadStatusLottie(this.discoveryFlag)));
    }
  }
}
