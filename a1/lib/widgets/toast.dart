import 'package:a1/styles/cores.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyToast {
  static get(String txt) {
    Fluttertoast.showToast(
      msg: txt,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Cores.azulClaro,
      textColor: Cores.branco,
      fontSize: 16.0,
    );
  }

  static modal(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(data),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static snack(BuildContext context, String txt) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));
  }
}
