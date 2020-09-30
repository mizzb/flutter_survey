import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_survey/screens/survey_view.dart';
import 'package:http/http.dart' as http;

class HomeWidget extends StatefulWidget {
  final deviceId;
  final serverIp;
  final portNumber;

  const HomeWidget(
      {@required this.deviceId,
      @required this.serverIp,
      @required this.portNumber});

  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  Timer _timer;
  var registerStatus = "Device registration in process";
  var pairStatus = "Checking device status";
  var pairFlag = false;
  var registerFlag = false;


  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (this.registerStatus == "Device registration in process") {
      registerDevice(widget.deviceId, widget.serverIp, widget.portNumber);
    }

    if (this.registerFlag) {
      checkIfPaired(widget.deviceId, widget.serverIp, widget.portNumber);
    }

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.4,
        child: Card(
          color: Colors.grey[800],
          shadowColor: Colors.black,
          elevation: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  "DEVICE ID: " + widget.deviceId,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  this.registerStatus,
                  style: TextStyle(fontSize: 18),
                ),
              ),
              if (this.registerStatus == 'Device Registered')
                Column(
                  children: [
                    Container(
                      child: Text(
                       this.pairStatus,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void registerDevice(deviceID, serverIp, portNumber) {
    if (deviceID != null && serverIp != null && portNumber != null) {
      var api = "http://" +
          serverIp.toString() +
          ":" +
          portNumber.toString() +
          "/api/devices/register";
      Map<String, String> requestHeaders = {
        HttpHeaders.contentTypeHeader: 'application/json',
      };

      var payLoad = {
        'deviceId': deviceID,
        'type': 'SURVEY',
        'connectionStatus': 'NONE'
      };
      register(api, payLoad, requestHeaders).then(
          (value) => {
                if ((value.statusCode == 200 || value.statusCode == 201) &&
                    mounted)
                  {
                    setState(() {
                      registerStatus = "Device Registered";
                      registerFlag = true;
                    })
                  }
                else if (mounted)
                  {
                    setState(() {
                      registerStatus = "Device Registration failed. Restart the app";
                    })
                  }
              },
          onError: (error) => {
                if (mounted)
                  {
                    setState(() {
                      registerStatus = "Device Registration failed. Restart the app";
                    })
                  }
              });
    } else {
      if (mounted) {
        setState(() {
          registerStatus = "Device Registration failed";
        });
      }
    }
  }

  void checkIfPaired(deviceId, serverIp, portNumber) {
    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };
    var api = "http://" +
        serverIp.toString() +
        ":" +
        portNumber.toString() +
        "/api/device";

    this._timer = new Timer.periodic(new Duration(seconds: 10), (timer) {
      if (this.pairFlag) {
        _timer.cancel();
        timer.cancel();
      }

      checkPair(api, headers).then(
          (value) => {
                if ((value.statusCode == 200 || value.statusCode == 201) &&
                    !this.pairFlag)
                  {
                    this.pairFlag = true,
                    this.pairStatus = "Device paired",
                    timer.cancel(),
                    _timer.cancel(),

                    /// call reject api to reject other devices
                    callReject(api, headers)
                  }
                else if (value.statusCode != 200 && value.statusCode != 201)
                  {
                    print("Device not paired"),
                    this.pairStatus = "Device not paired. Please pair the device",
                    setState(() {
                      this.pairFlag = false;
                    })
                  }
              },
          onError: (error) => {
            this.pairStatus = "Device not paired. Please pair the device",
            setState(() {
              this.pairFlag = false;
            })
          });
    });

  }

  void callReject(String api, headers) {
    api = api + "/reject";
    reject(api, headers).then(
        (value) => {
              print("Other devices rejected"),
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => SurveyViewWidget(
                          deviceId: widget.deviceId,
                          serverIp: widget.serverIp,
                          portNumber: widget.portNumber)),
                  (Route<dynamic> route) => false),
            },
        onError: (error) => {print(error)});
  }

  Future<http.Response> register(
      String api, payLoad, Map<String, String> requestHeaders) {
    return http.post(api, body: jsonEncode(payLoad), headers: requestHeaders);
  }

  Future<http.Response> checkPair(
      String api, Map<String, String> requestHeaders) {
    return http.get(api, headers: requestHeaders);
  }

  Future<http.Response> reject(String api, Map<String, String> requestHeaders) {
    return http.put(api, headers: requestHeaders);
  }
}
