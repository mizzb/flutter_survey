import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_survey/lottie_widget.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:line_awesome_icons/line_awesome_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart' as webView;

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
  var deviceConnection = false;
  var deviceConfig = true;
  Timer _deviceStatusTime;
  InAppWebViewController webView;
  String url = "";
  double progress = 0;

  String selectedUrl =
      'https://rodin-dev-ui.analytix-online.com/takeSurvey?survey=5dd7a167-8f2c-42ff-94e7-1bc945572ad4';

  @override
  initState() {
    super.initState();
    setUpConfigSocket(widget.serverIp, widget.portNumber, widget.deviceId);
    _deviceStatusTime = Timer.periodic(
        Duration(seconds: 10),
        (Timer t) => checkDeviceConnectivity(
            widget.serverIp, widget.portNumber, widget.deviceId));
  }

  @override
  void dispose() {
    this._deviceStatusTime.cancel();
    super.dispose();
  }

  Future<String> loadLocal() async {
    return await rootBundle.loadString('assets/html/index.html');
  }

  @override
  Widget build(BuildContext context) {
    if (!this.deviceConfig) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.4,
              child: LottieWidget(lottieType: "config_app")),
          Container(
            child: Text(
              "Please wait, configuring the app",
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 40,
                  color: Colors.blueGrey[900],
                  decoration: TextDecoration.none),
            ),
          )
        ],
      );
    } else if (this.deviceConnection) {
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
        body: FutureBuilder<String>(
          future: loadLocal(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return InAppWebView(
                initialUrl: selectedUrl,
                initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      debuggingEnabled: true,
                      useOnLoadResource: true,
                      useShouldOverrideUrlLoading: true,
                )),

                onWebViewCreated: (InAppWebViewController controller) {
                  webView = controller;
                },

                onLoadStart: (InAppWebViewController controller, String url) {
                  print("loadStarted" + url);
                },

                onLoadStop:
                    (InAppWebViewController controller, String url) async {},

                onProgressChanged:
                    (InAppWebViewController controller, int progress) {
                  setState(() {
                    this.progress = progress / 100;
                  });
                  print(this.progress);
                },

              );

              return WebviewScaffold(
                url:
                    new Uri.dataFromString(snapshot.data, mimeType: 'text/html')
                        .toString(),
                withJavascript: true,
                withZoom: true,
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ), // This trailing comma makes auto-formatting nicer for build methods.
      );
    } else {
      return Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(child: LottieWidget(lottieType: "lost_connection")),
            Container(
              child: Text(
                "Trying to connect to server",
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

  void setUpConfigSocket(serverIp, portNumber, deviceId) {
    var socketUrl =
        "ws://" + serverIp.toString() + ":" + portNumber.toString() + "/push";

    final stompClient = StompClient(
        config: StompConfig(
      url: socketUrl,
      onConnect: onConnect,
      onWebSocketError: (dynamic error) => print(error.toString()),
    ));
    stompClient.activate();
  }

  onConnect(StompClient client, StompFrame frame) {
    client.subscribe(
        destination: '/notifications/config',
        callback: (dynamic frame) {
          if (frame != null) {
            setState(() {
              this.deviceConfig = true;
            });
          }
        });
  }

  void checkDeviceConnectivity(serverIp, portNumber, deviceId) {
    print("checking device connection");
    var url = "http://" +
        serverIp.toString() +
        ":" +
        portNumber.toString() +
        "/api/device";

    Map<String, String> headers = {
      'device-id': deviceId.toString(),
    };

    getDevice(url, headers).then(
        (value) => {
              if (value.statusCode == 200 || value.statusCode == 201)
                {
                  setState(() {
                    this.deviceConnection = true;
                  })
                }
              else
                {
                  setState(() {
                    this.deviceConnection = false;
                  })
                }
            },
        onError: (error) => {
              setState(() {
                this.deviceConnection = false;
              })
            });
  }

  Future<http.Response> getDevice(
      String api, Map<String, String> requestHeaders) {
    return http.get(api, headers: requestHeaders);
  }
}
