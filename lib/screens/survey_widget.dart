import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:package_info/package_info.dart';
import 'package:queberry_feedback/globals.dart';
import 'package:queberry_feedback/model/Config.dart';
import 'package:queberry_feedback/model/Survey.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart' as CONSTANTS;
import '../lottie_widget.dart';

class SurveyViewWidget extends StatefulWidget {
  final deviceId;
  final serverUrl;

  const SurveyViewWidget({@required this.deviceId, @required this.serverUrl});

  @override
  _WebViewWidgetState createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<SurveyViewWidget> {
  /// Device Connection
  var deviceConnection = false;
  var devConnectionStatus = CONSTANTS.dev_conn_init;

  /// Device Survey
  var assignedSurveyId;
  var surveyUrl;
  var surveyApiError = null;

  var deviceSurvey = false; // flag to check survey assigned or not
  var surveyEnabled = false; // flag to check if survey enabled or not
  var surveyFlag = false; // flag to handle survey UI using timer

  /// Device config for STOMP
  var deviceConfig = false;
  var STOMPInit = false;
  var deviceConfigStatus = CONSTANTS.dev_config_init;

  var baseUrl;

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  Timer _deviceStatusTime;
  Timer _surveyTimer;
  Timer _stompTimer;

  Config config;
  HttpClient client = new HttpClient();

  StompClient stompClient;

  @override
  void dispose() {
    this._deviceStatusTime.cancel();
    this._stompTimer.cancel();
    super.dispose();
  }

  @override
  initState() {
    super.initState();

    client.badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);

    this.baseUrl = widget.serverUrl;
    _initPackageInfo();

    /// Fetch device config, configure STOMP and fetch survey
    setUpConfig(widget.deviceId);

    /// Check device connectivity
    checkDeviceConnectivity(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    if (this.deviceSurvey &&
        this.assignedSurveyId != null &&
        this.deviceConnection &&
        this.deviceConfig) {
      return Scaffold(
        body: Container(
            width: MediaQuery.of(context).size.width, child: loadSurveyBody()),
      );
    } else {
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
          actions: <Widget>[
            Row(
              children: [
                Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Device Id: " + widget.deviceId,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                          if (this.deviceConnection)
                            Text(
                              "Connected to Halo",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 15),
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
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                width: MediaQuery.of(context).size.width,
                child: loadSurveyBody())),
      );
    }
  }

  Widget loadSurveyBody() {
    /// Show config status if config not loaded
    if (!this.deviceConfig || !this.STOMPInit) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(

                child: LottieWidget(lottieType: "config_app")),
            Container(
              child: Text(
                this.deviceConfigStatus,
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 25,
                    color: Colors.grey,
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
                    color: Colors.blueGrey,
                    decoration: TextDecoration.none),
              ),
            )
          ],
        ),
      );
    }
  }

  Widget buildSurveyView() {
    if (this.deviceSurvey &&
        assignedSurveyId != null &&
        this.surveyEnabled &&
        this.surveyFlag) {
      startSurveyTimer(); // start timer
      return new WebviewScaffold(
          url: this.baseUrl + this.surveyUrl,
          withZoom: true,
          withLocalStorage: true,
          hidden: true,
          initialChild: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(child: LottieWidget(lottieType: "loading")),
                Container(
                  child: Text(
                    CONSTANTS.loading_survey,
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 25,
                        color: Colors.blueGrey,
                        decoration: TextDecoration.none),
                  ),
                )
              ],
            ),
          ));
    } else {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: getSurveyError()),
      );
    }
  }

  List<Widget> getSurveyError() {
    List<Widget> childrens = [];
    if (!this.deviceSurvey && assignedSurveyId == null) {
      childrens.add(LottieWidget(lottieType: "no_survey"));
      childrens.add(Container(
        child: getSurveyMessage(CONSTANTS.survey_not_assigned),
      ));
    } else if (!this.surveyEnabled) {
      childrens.add(LottieWidget(lottieType: "no_survey"));
      childrens.add(Container(
        child: getSurveyMessage(CONSTANTS.survey_disabled),
      ));
    } else {
      childrens.add(LottieWidget(lottieType: "sleeping_cat"));
      childrens.add(Container(
        child: getSurveyMessage(this.config.survey.message),
      ));
    }

    if (this.surveyApiError != null) {
      childrens.add(Container(
        child: getSurveyMessage(this.surveyApiError),
      ));
    }

    return childrens;
  }

  Text getSurveyMessage(String message) {
    return Text(
      message,
      style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 25,
          color: Colors.blueGrey,
          decoration: TextDecoration.none),
    );
  }

  /// Method for setting up STOMP
  void setUpConfigSocket(deviceId) {

    var uri = Uri.parse(this.baseUrl);
    var socketUrl = "wss://" + uri.host + ":" + uri.port.toString() + "/push";
    if (uri.scheme == 'http') {
      socketUrl = "ws://" + uri.host + ":" + uri.port.toString() + "/push";
    }

    print(" - Setting up STOMP: "+ socketUrl );
    if (this.deviceConfigStatus != "Connecting to STOMP Server") {
      setState(() {
        this.deviceConfigStatus = "Connecting to STOMP Server";
      });
    }

    if(this.stompClient != null){
      this.stompClient.deactivate();
      Timer(
          Duration(seconds: 2),
              () => setState(() {
            this.stompClient.activate();
          }));
    }else {
      this.stompClient = new StompClient(
          config: StompConfig(
            url: socketUrl,
            onConnect: onConnect,
            onWebSocketError: (dynamic error) => {
              //print("WS Error " + error.toString()),
              ToastHelper.toast("Web Socket Error"),
            },
            onStompError: (StompFrame error) => {
              //print("STOMP Error " + error.toString()),
              ToastHelper.toast("STOMP Error"),
            },
            onDisconnect: (StompFrame error) => {
              //print("Disconnect " + error.toString()),
              ToastHelper.toast("STOMP Disconnected"),
            },
            onUnhandledFrame: (StompFrame error) => {
              //print("Unhandled F"  + error.toString()),
              ToastHelper.toast("Unhandled frame"),
            },
            onUnhandledMessage: (StompFrame error) => {
              //print("Unhandled M"  + error.toString()),
              ToastHelper.toast("Unhandled Message"),
            },
            onUnhandledReceipt: (StompFrame error) => {
              //print("Unhandled R:" + error.toString()),
              ToastHelper.toast("Unhandled Receipt"),
            },
            onWebSocketDone: () => {
              ToastHelper.toast("WebSocket done: Deactivating STOMP"),
              this.stompClient.deactivate()
            },
            onDebugMessage: (String message) => {
              print("Debug:" + message),
            },
          ));

      stompClient.activate();
      print("STOMP Activated: " + stompClient.connected.toString());
    }
  }

  /// On STOMP Connect
  onConnect(StompClient client, StompFrame frame) {
    print("Connected to STOMP Server");
    if (this.deviceConfigStatus != "Connected to STOMP") {
      setState(() {
        this.deviceConfigStatus = "Connected to STOMP";
      });
    }

    if (!this.STOMPInit) {
      Timer(
          Duration(seconds: 3),
          () => setState(() {
                this.STOMPInit = true;
              }));
    }

    //refreshStomp();

    client.subscribe(
      destination: CONSTANTS.api_STOMP_config,
      callback: (dynamic frame) {
        print(CONSTANTS.api_STOMP_config + " Config changes invoked");
        if (frame != null) {
          setUpConfig(widget.deviceId);
        }
      },
    );

    client.subscribe(
      destination: CONSTANTS.api_STOMP_device,
      callback: (dynamic frame) {
        print(CONSTANTS.api_STOMP_device + " Survey Assigned/Unassigned");
        if (frame != null) {
          getSurvey(widget.deviceId);
        }
      },
    );

    client.subscribe(
      destination: CONSTANTS.api_STOMP_survey,
      callback: (dynamic frame) {
        print(CONSTANTS.api_STOMP_survey + "Notification Survey invoked");
        if (frame != null) {
          var resp = json.decode(frame.body);
          print("---> STOMP: Survey notification Invoked");
          print("Received Device Id:" + resp['deviceId']);
          print("System Device Id:" + widget.deviceId);
          if (resp['deviceId'] != null && resp['deviceId'] == widget.deviceId) {
            setState(() {
              this.surveyFlag = true;
            });
          }
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
              getDeviceStatus(url, headers, deviceId.toString()).then(
                  (value) => {
                        if (value != null && (value == 200 || value == 201))
                          {
                            if (!this.deviceConnection)
                              {
                                if (this.devConnectionStatus ==
                                        CONSTANTS.dev_conn_fail &&
                                    this.deviceConfig &&
                                    this.STOMPInit)
                                  {
                                    setUpConfig(deviceId),
                                    setUpConfigSocket(deviceId),
                                  },
                                setState(() {
                                  this.deviceConnection = true;
                                  this.devConnectionStatus =
                                      CONSTANTS.dev_conn_init;
                                }),
                              }
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
    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };
    getDevConfig(url, headers, deviceId.toString()).then(
        (value) => {
              if (value != null)
                {
                  /// set config flag
                  setState(() {
                    this.config = value;
                    this.deviceConfig = true;
                    this.surveyEnabled = value.survey.enabled;
                  }),

//                  if (value.survey.enabled)
//                    {
//                      print("---> Survey Enabled for " +
//                          value.survey.timeout.toString() +
//                          "Secs")
//                    }
//                  else
//                    {print("--> survey disabled")},

                  /// load survey if survey not available
                  if (!this.deviceSurvey && this.config.survey.enabled)
                    {
                      getSurvey(deviceId),
                    },

                  /// set up STOMP if not configured
                  if (!this.STOMPInit)
                    {
                      setUpConfigSocket(deviceId),
                    },
                }
              else
                {
                  setState(() {
                    this.deviceConfigStatus = CONSTANTS.dev_config_fail;
                    this.deviceConfig = false;
                  }),
                }
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

    getDevSurvey(url, headers, deviceId.toString()).then(
        (value) => {
              if (value != null && value.id != null)
                {
                  setState(() {
                    this.assignedSurveyId = value.id;
                    this.surveyUrl = CONSTANTS.api_take_survey + value.id;
                    print("Survey URL: " + this.surveyUrl);
                    this.deviceSurvey = true;
                    surveyApiError = null;
                  })
                }
              else
                {
                  ToastHelper.toast("Survey response error"),
                  setState(() {
                    this.assignedSurveyId = null;
                    this.deviceSurvey = false;
                    surveyApiError = null;
                  })
                }
            },
        onError: (error) => {
              setState(() {
                this.assignedSurveyId = null;
                this.deviceSurvey = false;
                surveyApiError = error.toString();
              })
            });
  }

  void startSurveyTimer() {
    int duration = this.config.survey.timeout;
    this._surveyTimer = new Timer(Duration(seconds: duration), () {
      setState(() {
        this.surveyFlag = false;
      });
      this._surveyTimer.cancel();
    });
  }

  void refreshStomp() {
    if (this._stompTimer.isActive) {
      this._stompTimer.cancel();
    }

    this._stompTimer = Timer.periodic(
        Duration(seconds: 30),
        (Timer t) => {
              if (this.deviceConnection)
                {
                  this.stompClient.deactivate(),
                  Timer(
                      Duration(seconds: 2),
                      () => setState(() {
                            this.stompClient.activate();
                          }))
                }
            });
  }

  Future<dynamic> getDeviceStatus(
      String api, Map<String, String> requestHeaders, deviceId) async {
    try {
      HttpClientRequest request = await client.getUrl(Uri.parse(api));
      request.headers.set('device-id', deviceId);
      HttpClientResponse response = await request.close();

      if ((response.statusCode == 200 || response.statusCode == 201)) {
        return response.statusCode;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Survey> getDevSurvey(
      String api, Map<String, String> requestHeaders, deviceId) async {
    try {
      HttpClientRequest request = await client.getUrl(Uri.parse(api));
      request.headers.set('device-id', deviceId);
      HttpClientResponse response = await request.close();

      if ((response.statusCode == 200 || response.statusCode == 201)) {
        var reply = await response.transform(utf8.decoder).join();
        return Survey.fromJson(json.decode(reply));
      } else {
        return null;
      }
    } catch (e) {
      return e;
    }
  }

  Future<Config> getDevConfig(
      String api, Map<String, String> headers, deviceId) async {
    try {
      HttpClientRequest request = await client.getUrl(Uri.parse(api));
      request.headers.set('device-id', deviceId);
      HttpClientResponse response = await request.close();

      if ((response.statusCode == 200 || response.statusCode == 201)) {
        var reply = await response.transform(utf8.decoder).join();
        return Config.fromJson(json.decode(reply));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }
}
