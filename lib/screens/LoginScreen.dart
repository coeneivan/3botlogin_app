import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:threebotlogin/widgets/ImageButton.dart';
import 'package:threebotlogin/widgets/PinField.dart';
import 'package:threebotlogin/services/userService.dart';
import 'package:threebotlogin/services/cryptoService.dart';
import 'package:threebotlogin/services/3botService.dart';
import 'package:threebotlogin/widgets/scopeDialog.dart';

class LoginScreen extends StatefulWidget {
  final Widget loginScreen;
  final message;
  final bool closeWhenLoggedIn;
  LoginScreen(this.message,
      {Key key, this.loginScreen, this.closeWhenLoggedIn = false})
      : super(key: key);

  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String helperText = 'Give in your pincode to log in';
  List<int> imageList = new List();
  var selectedImageId = -1;
  var correctImage = -1;

  @override
  void initState() {
    super.initState();

    var generated = 1;
    var rng = new Random();
    print(widget.message);
    print(widget.message['randomImageId']);
    correctImage = int.parse(widget.message['randomImageId']);

    imageList.add(correctImage);

    while (generated <= 3) {
      var x = rng.nextInt(266) + 1;
      if (!imageList.contains(x)) {
        imageList.add(x);
        generated++;
      }
    }
    setState(() {
      imageList.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
          elevation: 0.0,
        ),
        body: Container(
            width: double.infinity,
            height: double.infinity,
            color: Theme.of(context).primaryColor,
            child: Container(
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0))),
                    child: SingleChildScrollView(
                        child: Container(
                            padding: EdgeInsets.only(top: 24.0, bottom: 38.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        ImageButton(
                                            imageList[0],
                                            selectedImageId,
                                            imageSelectedCallback),
                                        ImageButton(
                                            imageList[1],
                                            selectedImageId,
                                            imageSelectedCallback),
                                        ImageButton(
                                            imageList[2],
                                            selectedImageId,
                                            imageSelectedCallback),
                                        ImageButton(
                                            imageList[3],
                                            selectedImageId,
                                            imageSelectedCallback),
                                      ]),
                                  Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.only(
                                          top: 24.0, bottom: 24.0),
                                      child: Center(
                                          child: Text(
                                        helperText,
                                        style: TextStyle(fontSize: 16.0),
                                      ))),
                                  PinField(callback: (p) => pinFilledIn(p))
                                ],
                              ),
                            )))))));
  }

  imageSelectedCallback(imageId) {
    setState(() {
      selectedImageId = imageId;
    });
  }

  pinFilledIn(p) async {
    final pin = await getPin();
    if (pin == p) {
      if (widget.message != null && widget.message['scope'] != null) {
        showScopeDialog(context, widget.message['scope'].split(","),
            widget.message['appId'], sendIt);
      } else {
        sendIt();
      }
    } else {
      setState(() {
        helperText = "Pin code not ok";
      });
    }
  }

  sendIt() async {
    if (selectedImageId == correctImage) {
      // Correct image selected
      print("We selected the CORRECT image!");
    } else {
      // Wrong image
      print("We selected the WRONG image!");
    }
    print('sendIt');
    var state = widget.message['state'];
    var publicKey = widget.message['appPublicKey'];
    var privateKey = getPrivateKey();
    var email = getEmail();

    var signedHash = signHash(state, await privateKey);
    var scope = {};
    var data;
    if (widget.message['scope'] != null) {
      if (widget.message['scope'].split(",").contains('user:email'))
        scope['email'] = await email;
    }
    if (scope.isNotEmpty) {
      print(scope.isEmpty);
      data = await encrypt(jsonEncode(scope), publicKey, await privateKey);
    }
    sendData(state, await signedHash, data, selectedImageId);

    if (widget.closeWhenLoggedIn) {
      Navigator.popUntil(context, ModalRoute.withName('/'));
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else {
      Navigator.popUntil(context, ModalRoute.withName('/'));
      Navigator.of(context).pushNamed('/success');
    }
  }
}
