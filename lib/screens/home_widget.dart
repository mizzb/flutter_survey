import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_survey/screens/survey_widget.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart' as CONSTANTS;

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
  var registerStatus = CONSTANTS.dev_reg_init;
  var pairStatus = CONSTANTS.dev_pair_init;

  var pairFlag = false;
  var registerFlag = false;
  var baseUrl;

  @override
  initState() {
    super.initState();
    this.baseUrl = "http://" + widget.serverIp.toString() + ":" + widget.portNumber.toString();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    /// Make API call to register the device
    if (this.registerStatus == CONSTANTS.dev_reg_init) {
      registerDevice(widget.deviceId);
    }

    /// If the device is registered, initialize timer
    /// and start checking if the device is paired.
    /// If paired reditect to Survey widget
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
              /// If device registered, show device paring status
              if (this.registerStatus == CONSTANTS.dev_reg_completed)
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

  void registerDevice(deviceID) {
    if (deviceID != null && this.baseUrl != null) {

      var api = this.baseUrl + CONSTANTS.api_device_register;

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
                      registerStatus = CONSTANTS.dev_reg_completed;
                      registerFlag = true;
                    })
                  }
                else if (mounted)
                  {
                    setState(() {
                      registerStatus = CONSTANTS.dev_reg_failed;
                    })
                  }
              },
          onError: (error) => {
                if (mounted)
                  {
                    setState(() {
                      registerStatus = CONSTANTS.dev_reg_failed;
                    })
                  }
              });
    } else {
      if (mounted) {
        setState(() {
          registerStatus = CONSTANTS.dev_reg_failed;
        });
      }
    }
  }

  void checkIfPaired(deviceId, serverIp, portNumber) {

    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };

    var api = this.baseUrl + CONSTANTS.api_device_status;

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
                    this.pairStatus = CONSTANTS.dev_paired,
                    timer.cancel(),
                    _timer.cancel(),

                    /// call reject api to reject other devices
                    callReject(api, headers)
                  }
                else if (value.statusCode != 200 && value.statusCode != 201)
                  {
                    print("Device not paired"),
                    this.pairStatus = CONSTANTS.dev_pair_fail,
                    setState(() {
                      this.pairFlag = false;
                    })
                  }
              },
          onError: (error) => {
            this.pairStatus = CONSTANTS.dev_pair_fail,
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
