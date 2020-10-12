import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queberry_feedback/screens/survey_widget.dart';

import '../constants/constants.dart' as CONSTANTS;
import '../lottie_widget.dart';

class HomeWidget extends StatefulWidget {
  final deviceId;
  final Key key;

  final serverUrl;

  const HomeWidget(
      {@required this.deviceId, @required this.key, @required this.serverUrl});

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

  HttpClient client = new HttpClient();

  @override
  initState() {
    super.initState();
    client.badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
    registerStatus = CONSTANTS.dev_reg_init;
    pairStatus = CONSTANTS.dev_pair_init;
    pairFlag = false;
    registerFlag = false;
    this.baseUrl = widget.serverUrl;
  }

  @override
  void dispose() {
    if (_timer != null) _timer.cancel();
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
      checkIfPaired(widget.deviceId);
    }

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Card(
          color: Colors.white70,
          shadowColor: Color.fromRGBO(45, 51, 62, 50),
          elevation: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  "DEVICE ID: " + widget.deviceId,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(45, 51, 62, 1)),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  this.registerStatus,
                  style: TextStyle(
                      fontSize: 18, color: Color.fromRGBO(45, 51, 62, 1)),
                ),
              ),

              /// If device registered, show device paring status
              if (this.registerStatus == CONSTANTS.dev_reg_completed)
                Column(
                  children: [
                    Container(
                      child: Text(
                        this.pairStatus,
                        style: TextStyle(
                            fontSize: 18, color: Color.fromRGBO(45, 51, 62, 1)),
                      ),
                    ),
                    Container(child: LottieWidget(lottieType: "loading_bubble"))
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
          (HttpClientResponse value) => {
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

  void checkIfPaired(deviceId) {
    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };

    var api = this.baseUrl + CONSTANTS.api_device_status;

    if (this._timer != null && this._timer.isActive) {
      this._timer.cancel();
    }

    this._timer = new Timer.periodic(new Duration(seconds: 10), (timer) {
      if (this.pairFlag) {
        timer.cancel();

        if (this._timer != null && this._timer.isActive) {
          this._timer.cancel();
        }
      }

      checkPair(api, headers, deviceId.toString()).then(
          (HttpClientResponse value) => {
                if ((value.statusCode == 200 || value.statusCode == 201) &&
                    !this.pairFlag)
                  {
                    this.pairFlag = true,
                    this.pairStatus = CONSTANTS.dev_paired,
                    timer.cancel(),
                    if (this._timer != null && this._timer.isActive)
                      {this._timer.cancel()},

                    /// call reject api to reject other devices
                    callReject(api, headers, deviceId)
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

  void callReject(String api, headers, deviceId) {
    api = api + "/reject";
    reject(api, headers, deviceId).then(
        (HttpClientResponse value) => {
              if (value.statusCode == 200 || value.statusCode == 201)
                {
                  print("Other devices rejected"),
                }
              else
                {
                  print("Device rejection failed"),
                  // todo
                },
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => SurveyViewWidget(
                          deviceId: widget.deviceId, serverUrl: this.baseUrl)),
                  (Route<dynamic> route) => false),
            },
        onError: (error) => {print(error)});
  }

  Future<HttpClientResponse> register(
      String api, payLoad, Map<String, String> requestHeaders) async {
    HttpClientRequest request = await client.postUrl(Uri.parse(api));
    request.headers.set('content-type', 'application/json');
    request.add(utf8.encode(json.encode(payLoad)));
    HttpClientResponse response = await request.close();
    return response;
  }

  Future<HttpClientResponse> checkPair(
      String api, Map<String, String> requestHeaders, String deviceId) async {
    HttpClientRequest request = await client.getUrl(Uri.parse(api));
    request.headers.set('device-id', deviceId);
    HttpClientResponse response = await request.close();

    return response;
  }

  Future<HttpClientResponse> reject(
      String api, Map<String, String> requestHeaders, String deviceId) async {
    HttpClientRequest request = await client.putUrl(Uri.parse(api));
    request.headers.set('device-id', deviceId);
    HttpClientResponse response = await request.close();
    return response;
    //return http.put(api, headers: requestHeaders);
  }
}
