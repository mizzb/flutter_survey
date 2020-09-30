import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_survey/lottie_widget.dart';
import 'package:flutter_survey/model/Config.dart';
import 'package:flutter_survey/model/Survey.dart';
import 'package:line_awesome_icons/line_awesome_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;

class SurveyViewWidget extends StatefulWidget {
  final deviceId;
  final serverIp;
  final portNumber;

  const SurveyViewWidget(
      {@required this.deviceId,
      @required this.serverIp,
      @required this.portNumber});

  @override
  _WebViewWidgetState createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<SurveyViewWidget> {
  /// Device Connection
  var deviceConnection = false;
  var devConnectionStatus = "Connecting to server";

  /// Device Survey
  var deviceSurvey = false;
  var assignedSurveyId;
  var surveyUrl;

  /// Device config for STOMP
  var deviceConfig = false;
  var deviceConfigStatus = "Please wait, configuring the app";

  Timer _deviceStatusTime;
  InAppWebViewController webView;

  String selectedUrl =
      'https://rodin-dev-ui.analytix-online.com/takeSurvey?survey=5dd7a167-8f2c-42ff-94e7-1bc945572ad4';

  @override
  void dispose() {
    this._deviceStatusTime.cancel();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    setUpConfig(widget.serverIp, widget.portNumber, widget.deviceId);

    _deviceStatusTime = Timer.periodic(
        Duration(seconds: 10),
        (Timer t) => checkDeviceConnectivity(
            widget.serverIp, widget.portNumber, widget.deviceId));
  }

  @override
  Widget build(BuildContext context) {
    if (!this.deviceConfig) {
      /// If device config flag is false, show connection
      return Scaffold(
        appBar: AppBar(
          title: Text("PRODIGY AI"),
          actions: <Widget>[
            Container(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05),
                child: Icon(
                  LineAwesomeIcons.link,
                  size: 30,
                  color: (this.deviceConnection)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                )),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: LottieWidget(lottieType: "config_app")),
              Container(
                child: Text(
                  this.deviceConfigStatus,
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
    } else if (this.deviceConnection) {
      /// If device connected show Survey if assigned else show error
      return Scaffold(
          appBar: AppBar(
            title: Text("PRODIGY AI"),
            actions: <Widget>[
              Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05),
                  child: Icon(
                    LineAwesomeIcons.link,
                    size: 30,
                    color: (this.deviceConnection)
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  )),
            ],
          ),
          body: buildSurveyView());
    } else {
      /// Show connection error
      return Scaffold(
        appBar: AppBar(
          title: Text("PRODIGY AI"),
          actions: <Widget>[
            Container(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05),
                child: Icon(
                  LineAwesomeIcons.link,
                  size: 30,
                  color: (this.deviceConnection)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                )),
          ],
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(child: LottieWidget(lottieType: "lost_connection")),
              Container(
                child: Text(
                  this.devConnectionStatus,
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
    }
  }

  Widget buildSurveyView() {
    if(this.deviceSurvey && assignedSurveyId != null){
      return InAppWebView(
        initialUrl: this.surveyUrl,
        initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              debuggingEnabled: true,
              useOnLoadResource: true,
              useShouldOverrideUrlLoading: true,
            )),
        onWebViewCreated: (InAppWebViewController controller) {
          webView = controller;
        },
      );
    }else{
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(child: LottieWidget(lottieType: "no_survey")),
            Container(
              child: Text(
                "No survey assigned",
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 30,
                    color: Colors.white70,
                    decoration: TextDecoration.none),
              ),
            )
          ],
        ),
      );
    }

  }




  /// Method for setting up STOMP
  void setUpConfigSocket(serverIp, portNumber, deviceId) {
    var socketUrl =
        "ws://" + serverIp.toString() + ":" + portNumber.toString() + "/push";

    final stompClient = StompClient(
        config: StompConfig(
            url: socketUrl,
            onConnect: onConnect,
            onWebSocketError: (dynamic error) =>
                {print("Failed to set up STOMP")}));
    stompClient.activate();
  }

  /// On STOMP Connect
  onConnect(StompClient client, StompFrame frame) {
    client.subscribe(
        destination: '/notifications/config',
        callback: (dynamic frame) {
          if (frame != null) {
            setUpConfig(widget.serverIp, widget.portNumber, widget.deviceId);
          }
        },
    );

    client.subscribe(
      destination: '/notifications/signage/device',
      callback: (dynamic frame) {
        if (frame != null) {
          getSurvey(widget.serverIp, widget.portNumber, widget.deviceId);
        }
      },
    );

  }

  /// Check if device connected to server
  void checkDeviceConnectivity(serverIp, portNumber, deviceId) {
    print("checking server status");
    var url = "http://" +
        serverIp.toString() +
        ":" +
        portNumber.toString() +
        "/api/device";

    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };

    getDeviceStatus(url, headers).then(
        (value) => {
              if (value != null && (value.statusCode == 200 || value.statusCode == 201))
                {
                  setState(() {
                    this.deviceConnection = true;
                  })
                }
              else
                {
                  if (this.deviceConnection)
                    {
                      setState(() {
                        this.devConnectionStatus =
                            "Cannot connect to the server";
                        this.deviceConnection = false;
                      })
                    }
                }
            },
        onError: (error) => {
              print(error),
              setState(() {
                this.devConnectionStatus = "Cannot connect to the server";
                this.deviceConnection = false;
              })
            });
  }

  /// Method for loading initial config and to set up STOMP
  void setUpConfig(serverIp, portNumber, deviceId) {
    var url = "http://" +
        serverIp.toString() +
        ":" +
        portNumber.toString() +
        "/api/signage/config";

    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };

    getDevConfig(url, headers).then(
        (value) => {
              /// load survey if survey not available
              if (!this.deviceSurvey)
                {
                  getSurvey(serverIp, portNumber, deviceId),
                },

              /// set up STOMP if not configured
              if (!this.deviceConfig)
                {
                  setUpConfigSocket(serverIp, portNumber, deviceId),
                },

              /// set config flag
              setState(() {
                this.deviceConfig = true;
              }),
            },
        onError: (error) => {
              setState(() {
                this.deviceConfig = false;
              }),
            });
  }

  /// Method for fetching assigned survey
  void getSurvey(serverIp, portNumber, deviceId) {
    var url = "http://" +
        serverIp.toString() +
        ":" +
        portNumber.toString() +
        "/api/device/survey";

    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };

    getDevSurvey(url, headers).then(
        (value) => {
              if (value.id != null)
                {
                  setState(() {
                    this.assignedSurveyId = value.id;
                    this.deviceSurvey = true;
                    this.surveyUrl = "http://" +
                        serverIp.toString() +
                        ":" +
                        portNumber.toString() +
                        "/takeSurvey?survey=" + value.id;
                  })
                }
              else
                {
                  setState(() {
                    this.assignedSurveyId = null;
                    ;
                    this.deviceSurvey = false;
                  })
                }
            },
        onError: (error) => {});
  }

  Future<http.Response> getDeviceStatus(
      String api, Map<String, String> requestHeaders) async {
    try {
      final response = await http.get(api, headers: requestHeaders);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.body != null) {
        return response;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Survey> getDevSurvey(
      String api, Map<String, String> requestHeaders) async {
    final response = await http.get(api, headers: requestHeaders);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.body != null) {
      return Survey.fromJson(json.decode(response.body));
    } else {
      return new Survey();
    }
  }

  Future<Config> getDevConfig(
      String api, Map<String, String> requestHeaders) async {
    final response = await http.get(api, headers: requestHeaders);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.body != null) {
      return Config.fromJson(json.decode(response.body));
    } else {
      return new Config();
    }
  }
}
