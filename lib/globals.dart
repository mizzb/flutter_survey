import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


class Globals {
  static const Color white = const Color(0xffffffff);
  static const Color mediumBlue = const Color(0xff4A64FE);
}

class ToastHelper {
  static toast(dynamic message) {
    return Fluttertoast.showToast(
        msg: message,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.white,
        textColor: Colors.black,
        fontSize: 16.0);
  }
}
