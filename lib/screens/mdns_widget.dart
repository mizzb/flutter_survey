import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mdns_plugin/flutter_mdns_plugin.dart';
import 'package:line_awesome_icons/line_awesome_icons.dart';
import 'package:regexed_validator/regexed_validator.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../lottie_widget.dart';
import 'home_widget.dart';

import '../constants/constants.dart' as CONSTANTS;
import 'package:package_info/package_info.dart';

class MDNSWidget extends StatefulWidget {
  @override
  _MDNSWidgetState createState() => _MDNSWidgetState();
}

class _MDNSWidgetState extends State<MDNSWidget> {
  var discoveryFlag = CONSTANTS.mdns_init;
  var deviceId;
  bool _ipError = false;

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  ServiceInfo mdnsDetails;
  FlutterMdnsPlugin _mdnsPlugin;
  DiscoveryCallbacks discoveryCallbacks;
  List<ServiceInfo> _discoveredServices = <ServiceInfo>[];
  Timer _timer;

  TextEditingController _popUpIPCtrl;
  TextEditingController _popUpPORTCtrl;



  @override
  initState() {
    super.initState();
    _popUpIPCtrl = new TextEditingController();
    _popUpPORTCtrl = new TextEditingController();
    discoveryCallbacks = new DiscoveryCallbacks(
      onDiscovered: (ServiceInfo info) {
        if (mounted)
          setState(() {
            discoveryFlag = CONSTANTS.mdns_discovered;
          });
      },
      onDiscoveryStarted: () {
        if (mounted)
          setState(() {
            discoveryFlag = CONSTANTS.mdns_discovered;
          });
        print("Discovery Started");
      },
      onDiscoveryStopped: () {
        if (mounted)
          setState(() {
            discoveryFlag = CONSTANTS.mdns_failed;
          });
        print("Discovery failed");
      },
      onResolved: (ServiceInfo info) async {
        print("Discovery Found: " + info.name);

        /// Check if discovered service is Queberry-halo
        if (info.name == CONSTANTS.halo_title &&
            discoveryFlag != CONSTANTS.mdns_resolved) {
          await configureDeviceId(info);
        }
      },
    );
    _initPackageInfo()
        .then((value) => {startMdnsDiscovery(CONSTANTS.discovery_service)});
  }

  Future configureDeviceId(ServiceInfo info) async {
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

  @override
  void dispose() {
    this._mdnsPlugin.stopDiscovery();
    this._timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Container(
              child: Column(
            children: [
              Text(CONSTANTS.app_tittle),
              if (this._packageInfo.version != null)
                Text("V " + this._packageInfo.version,
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          )),
          actions: [
            Container(
              child: Column(
                children: [
                  GestureDetector(
                      child: Container(
                        child: Icon(LineAwesomeIcons.cog),
                      ),
                      onLongPress: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Enter the Server details"),
                                content: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Form(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Padding(
                                          padding: EdgeInsets.all(5.0),
                                          child: TextFormField(
                                            controller: this._popUpIPCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                                border: new OutlineInputBorder(
                                                    borderSide: new BorderSide(
                                                  color: Color.fromRGBO(
                                                      45, 51, 62, 1),
                                                )),
                                                labelText: "IP Address",
                                            ),

                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(5.0),
                                          child: TextFormField(
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(4),
                                            ],
                                            controller: this._popUpPORTCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                                border: new OutlineInputBorder(
                                                    borderSide: new BorderSide(
                                                  color: Color.fromRGBO(
                                                      45, 51, 62, 1),
                                                )),
                                                labelText: "PORT"),
                                          ),
                                        ),

                                        if(this._ipError)
                                          Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Text("Please enter valid details"),
                                          ),

                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  RaisedButton(
                                    child: Text("Save"),
                                    onPressed: () {
                                      if(this._popUpIPCtrl.text != null && this._popUpIPCtrl.text != ""
                                          && this._popUpPORTCtrl.text != null && this._popUpPORTCtrl.text != ""){
                                        if(validator.ip(this._popUpIPCtrl.text)){
                                          ServiceInfo info = new ServiceInfo(null,
                                              null, null, null, this._popUpIPCtrl.text, int.parse(this._popUpPORTCtrl.text));
                                          configureDeviceId(info);
                                          Navigator.of(context).pop();
                                        }else {
                                          setState(() {
                                            this._ipError = true;
                                          });
                                        }
                                      }else {
                                        setState(() {
                                          this._ipError = true;
                                        });
                                      }
                                    },
                                  ),
                                  RaisedButton(
                                    child: Text("Cancel"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        this._ipError = false;
                                      });
                                      this._popUpIPCtrl.clear();
                                      this._popUpPORTCtrl.clear();
                                    },
                                  )
                                ],
                              );
                            });
                      })
                ],
              ),
            )
          ],
        ),
        body: loadBody());
  }

  startMdnsDiscovery(String serviceType) {
    print("MDNS INIT FOR " + serviceType);
    _mdnsPlugin = new FlutterMdnsPlugin(discoveryCallbacks: discoveryCallbacks);
    this._timer = Timer(
        Duration(seconds: 3), () => _mdnsPlugin.startDiscovery(serviceType));
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
    print(discoveryFlag);
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
          color: Colors.blueGrey,
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

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

//
//  /// MDNS TEST
//  Future<void> fetchServer(String name) async {
//
//
//
//
//    final MDnsClient client = MDnsClient();
//    await client.start();
//    await for (IPAddressResourceRecord record in client
//        .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(name))) {
//      print('Found address (${record.address}).');
//    }
//
//    await for (IPAddressResourceRecord record in client
//        .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv6(name))) {
//      print('Found address (${record.address}).');
//    }
//    client.stop();
//  }
}
