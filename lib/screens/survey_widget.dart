import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_survey/lottie_widget.dart';
import 'package:flutter_survey/model/Config.dart';
import 'package:flutter_survey/model/Survey.dart';
import 'package:line_awesome_icons/line_awesome_icons.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart' as CONSTANTS;

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
  var devConnectionStatus = CONSTANTS.dev_conn_init;

  /// Device Survey
  var deviceSurvey = false;
  var assignedSurveyId;
  var surveyUrl;

  /// Device config for STOMP
  var deviceConfig = false;
  var STOMPInit = false;
  var deviceConfigStatus = CONSTANTS.dev_config_init;

  Timer _deviceStatusTime;
  InAppWebViewController webView;

  var baseUrl;

  @override
  void dispose() {
    this._deviceStatusTime.cancel();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    this.baseUrl = "http://" +
        widget.serverIp.toString() +
        ":" +
        widget.portNumber.toString();

    /// Fetch device config, configure STOMP and fetch survey
    setUpConfig(widget.deviceId);

    /// Check device connectivity
    checkDeviceConnectivity(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CONSTANTS.app_tittle),
        actions: <Widget>[
          Container(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Device Id: " + widget.deviceId,
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                    if (this.deviceConnection)
                      Text(
                        "Connected to Halo",
                        style: TextStyle(color: Colors.green, fontSize: 15),
                      )
                    else
                      Text(
                        "Halo not available",
                        style: TextStyle(color: Colors.red, fontSize: 15),
                      )
                  ],
                ),
              )),
        ],
      ),
      body: SingleChildScrollView(
          child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              width: MediaQuery.of(context).size.width,
              child: loadSurveyBody())),
    );
  }

  Widget loadSurveyBody() {
    /// Show config status if config not loaded
    if (!this.deviceConfig || !this.STOMPInit) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(child: LottieWidget(lottieType: "config_app")),
            Container(
              child: Text(
                this.deviceConfigStatus,
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 25,
                    color: Colors.white70,
                    decoration: TextDecoration.none),
              ),
            )
          ],
        ),
      );
    } else if (this.deviceConnection) {
      /// Show Survey if assigned else show error
      return buildSurveyView();
    } else {
      /// Show connection error
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(child: LottieWidget(lottieType: "lost_connection")),
            Container(
              child: Text(
                this.devConnectionStatus,
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 25,
                    color: Colors.white70,
                    decoration: TextDecoration.none),
              ),
            )
          ],
        ),
      );
    }
  }

  Widget buildSurveyView() {
    if (this.deviceSurvey && assignedSurveyId != null) {
      return InAppWebView(
        initialUrl: this.baseUrl + this.surveyUrl,
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
    } else {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(child: LottieWidget(lottieType: "no_survey")),
            Container(
              child: Text(
                CONSTANTS.no_survey_assigned,
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 25,
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
  void setUpConfigSocket(deviceId) {
    var socketUrl = "ws://" +
        widget.serverIp.toString() +
        ":" +
        widget.portNumber.toString() +
        "/push";

    final stompClient = StompClient(
        config: StompConfig(
      url: socketUrl,
      onConnect: onConnect,
      onWebSocketError: (dynamic error) => {
        setState(() {
          this.STOMPInit = false;
          this.deviceConfigStatus = CONSTANTS.dev_config_fail;
        }),
      },
    ));

    stompClient.activate();
  }

  /// On STOMP Connect
  onConnect(StompClient client, StompFrame frame) {
    if (!this.STOMPInit) {
      setState(() {
        this.STOMPInit = true;
      });
    }
    client.subscribe(
      destination: CONSTANTS.api_STOMP_config,
      callback: (dynamic frame) {
        if (frame != null) {
          setUpConfig(widget.deviceId);
        }
      },
    );

    client.subscribe(
      destination: CONSTANTS.api_STOMP_device,
      callback: (dynamic frame) {
        if (frame != null) {
          getSurvey(widget.deviceId);
        }
      },
    );
  }

  /// Check if device connected to server in every 10 seconds.
  void checkDeviceConnectivity(deviceId) {
    var url = this.baseUrl + CONSTANTS.api_device_status;

    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };
    this._deviceStatusTime = Timer.periodic(
        Duration(seconds: 10),
        (Timer t) => {
              print("checking halo status"),
              getDeviceStatus(url, headers).then(
                  (value) => {
                        if (value != null &&
                            (value.statusCode == 200 ||
                                value.statusCode == 201))
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
                                      CONSTANTS.dev_conn_fail;
                                  this.deviceConnection = false;
                                })
                              }
                          }
                      },
                  onError: (error) => {
                        print(error),
                        setState(() {
                          this.devConnectionStatus = CONSTANTS.dev_conn_fail;
                          this.deviceConnection = false;
                        })
                      })
            });
  }

  /// Method for loading initial config and to set up STOMP
  void setUpConfig(deviceId) {
    var url = this.baseUrl + CONSTANTS.api_signage_config;

    getDevConfig(url).then(
        (value) => {
              /// set config flag
              setState(() {
                this.deviceConfig = true;
              }),

              /// load survey if survey not available
              if (!this.deviceSurvey)
                {
                  getSurvey(deviceId),
                },

              /// set up STOMP if not configured
              if (!this.STOMPInit)
                {
                  setUpConfigSocket(deviceId),
                },
            },
        onError: (error) => {
              setState(() {
                this.deviceConfigStatus = CONSTANTS.dev_config_fail;
                this.deviceConfig = false;
              }),
            });
  }

  /// Method for fetching assigned survey
  void getSurvey(deviceId) {
    var url = this.baseUrl + CONSTANTS.api_device_survey;

    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };

    getDevSurvey(url, headers).then(
        (value) => {
              if (value.id != null)
                {
                  setState(() {
                    this.assignedSurveyId = value.id;
                    this.surveyUrl = CONSTANTS.api_take_survey + value.id;
                    print("Survey URL: " + this.surveyUrl);
                    this.deviceSurvey = true;
                  })
                }
              else
                {
                  setState(() {
                    this.assignedSurveyId = null;
                    this.deviceSurvey = false;
                  })
                }
            },
        onError: (error) => {
              setState(() {
                this.assignedSurveyId = null;
                this.deviceSurvey = false;
              })
            });
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

  Future<Config> getDevConfig(String api) async {
    final response = await http.get(api);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.body != null) {
      return Config.fromJson(json.decode(response.body));
    } else {
      return new Config();
    }
  }
}
