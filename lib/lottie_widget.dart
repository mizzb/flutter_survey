import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieWidget extends StatelessWidget {
  final lottieType;

  LottieWidget({this.lottieType});

  @override
  Widget build(BuildContext context) {
    return Column(children: [loadLottie(this.lottieType, context)]);
  }

  loadLottie(lottieType, context) {
    switch (lottieType) {
      case 'config_app':
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              fetchLottie(context, 'assets/lottie/config_app.json'),
            ]);
        break;
      case 'lost_connection':
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              fetchLottie(context, 'assets/lottie/lost_connection.json'),
            ]);
        break;
      case 'connect_modem':
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              fetchLottie(context, 'assets/lottie/connect_modem.json'),
            ]);
        break;
      case 'warning':
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              fetchLottie(context, 'assets/lottie/warning.json'),
            ]);
        break;
      default:
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              fetchLottie(context, 'assets/lottie/loading.json'),
            ]);

    }
  }

  LottieBuilder fetchLottie(context, path) {
    return Lottie.asset(
      path,
      width: MediaQuery.of(context).size.width / 4,
      frameBuilder: (context, child, composition) {
        return AnimatedOpacity(
          child: child,
          opacity: 1,
          duration: Duration(seconds: 120),
        );
      },
    );
  }
}
