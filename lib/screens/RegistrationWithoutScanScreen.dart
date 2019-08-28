import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:threebotlogin/services/openKYCService.dart';
import 'package:threebotlogin/widgets/CustomDialog.dart';
import 'package:threebotlogin/widgets/PinField.dart';
import 'package:threebotlogin/services/userService.dart';
import 'package:threebotlogin/services/cryptoService.dart';
import 'package:threebotlogin/services/3botService.dart';
import 'package:threebotlogin/main.dart';
import 'package:threebotlogin/widgets/PreferenceDialog.dart';

class RegistrationWithoutScanScreen extends StatefulWidget {
  final Widget registrationWithoutScanScreen;
  final initialData;
  final bool resetPin;
  RegistrationWithoutScanScreen(this.initialData,
      {Key key, this.registrationWithoutScanScreen, this.resetPin})
      : super(key: key);

  _RegistrationWithoutScanScreen createState() =>
      _RegistrationWithoutScanScreen();
}

class _RegistrationWithoutScanScreen
    extends State<RegistrationWithoutScanScreen> {
  String helperText = 'Choose new pin';
  String pin;
  var scope = {};

  @override
  void initState() {
    super.initState();
    if (!widget.resetPin) {
      getPrivateKey().then((pk) => pk != null ? _showDialog() : sendFlag(pk));
    }
  }

  Future sendFlag(pk) async {
    sendScannedFlag(widget.initialData['state'],
        await signData(deviceId, widget.initialData['privateKey']), widget.initialData['doubleName']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
        elevation: 0.0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).primaryColor,
        child: Container(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Container(
              padding: EdgeInsets.only(top: 0.0, bottom: 0.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(top: 0.0, bottom: 24.0),
                      child: Center(
                        child: Text(
                          helperText,
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    PinField(callback: (p) => pinFilledIn(p))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future pinFilledIn(String value) async {
    if (pin == null) {
      setState(() {
        pin = value;
        helperText = 'Confirm pin';
      });
    } else if (pin != value) {
      setState(() {
        pin = null;
        helperText = 'Pins do not match, choose pin';
      });
    } else if (pin == value) {
      var scopeFromQR;
      widget.initialData['scope'] = json.encode({"doubleName":true, "email":false, "keys":false});
      scope['doubleName'] = widget.initialData['doubleName'];

      if (widget.initialData['scope'] != null) {
        print(jsonDecode(widget.initialData['scope']));
        scopeFromQR = jsonDecode(widget.initialData['scope']);

        if (scopeFromQR.containsKey('email'))
          scope['email'] = {'email': widget.initialData['email'], 'verified': false};
        if (scopeFromQR.containsKey('keys'))
          scope['keys'] = {'keys': widget.initialData['keys']};

        openPreferencesDialog(jsonDecode(widget.initialData['scope']));
      } else {
        openPreferencesDialog({'doubleName': true});
      }
    }
  }

  void openPreferencesDialog(scopeFromQR) async {
    if (await getScopePermissions() == null) {
      saveScopePermissions(jsonEncode(HashMap()));
    }

    if (widget.initialData['appId'] == null) {
      widget.initialData['appId'] = 'localhost:8081'; // needs to be changed in default domain
    }

    var initialPermissions = jsonDecode(await getScopePermissions());

    if (!initialPermissions.containsKey(widget.initialData['appId'])) {
      var newHashMap = new HashMap();
      initialPermissions[widget.initialData['appId']] = newHashMap;

      if (scopeFromQR != null) {
        scopeFromQR.keys.toList().forEach((var value) {
          newHashMap[value] = {
            'enabled': true,
            'required': isRequired(value, scopeFromQR)
          };
        });
      }
      print(initialPermissions);
      saveScopePermissions(jsonEncode(initialPermissions));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PreferenceDialog(
          //scope: initialPermissions[qrData['appId']],
          scope: scope,
          appId: widget.initialData['appId'],
          callback: sendIt,
        );
      },
    );
  }

  bool isRequired(value, scopeFromQR) {
    bool flag = false;
    if (scopeFromQR[value]) flag = scopeFromQR[value];
    return flag;
  }

  sendIt() async {
    var hash = widget.initialData['state'];
    var privateKey = widget.initialData['privateKey'];
    var doubleName = widget.initialData['doubleName'];
    var email = widget.initialData['email'];
    var publicKey = widget.initialData['appPublicKey'];
    var phrase = widget.initialData['phrase'];

    savePin(pin);
    savePrivateKey(privateKey);
    saveFingerprint(false);

    if(!widget.resetPin) {
      saveEmail(email, false);
    } else {
      saveEmail(email, widget.initialData['emailVerified']);
    }
    
    saveDoubleName(doubleName);
    savePhrase(phrase);

    if(!widget.resetPin) {
      var signedHash = signData(hash, privateKey);
      var data = encrypt(jsonEncode(scope), publicKey, privateKey);

      sendData(hash, await signedHash, await data, null).then((x) {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        Navigator.popUntil(context, ModalRoute.withName('/'));
        Navigator.of(context).pushNamed('/success');
      });
    }
    await sendRegisterSign(doubleName);
    await sendVerificationEmail();

    print('signing $doubleName');
    

    Navigator.popUntil(context, ModalRoute.withName('/'));
    Navigator.of(context).pushNamed('/success');
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => CustomDialog(
            title: "You are about to register a new account",
            description: new Text(
                "If you continue, you won't be able to login with the current account again"),
            actions: <Widget>[
              FlatButton(
                child: new Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/preference');
                },
              ),
              FlatButton(
                child: new Text("Continue"),
                onPressed: () async {
                  Navigator.pop(context);
                  clearData();
                  sendScannedFlag(
                      widget.initialData['state'],
                      await signData(
                          deviceId, widget.initialData['privateKey']), widget.initialData['doubleName']);
                },
              ),
            ],
          ),
    );
  }
}
