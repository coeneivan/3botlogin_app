import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:threebotlogin/screens/LoginScreen.dart';
import 'package:threebotlogin/services/3botService.dart';
import 'package:threebotlogin/services/cryptoService.dart';
import 'package:threebotlogin/services/openKYCService.dart';
import 'package:threebotlogin/services/userService.dart';
import 'package:threebotlogin/main.dart';

FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

void initFirebaseMessagingListener(context) async {
  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
      logger.log('On message $message');
      openLogin(context, message);
    },
    onLaunch: (Map<String, dynamic> message) async {
      logger.log('On launch $message');
      openLogin(context, message);
    },
    onResume: (Map<String, dynamic> message) async {
      logger.log('On resume $message');
      openLogin(context, message);
    },
  );

  _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true));
  _firebaseMessaging.onIosSettingsRegistered
      .listen((IosNotificationSettings settings) {
    logger.log("Settings registered: $settings");
  });
}

Future openLogin(context, message) async {
  logger.log('OpenLogin');

  var data = message['data'];
  if (Platform.isIOS) data = message;
  if (data['logintoken'] != null) {
    logger.log('---------------');
    logger.log('Got loginToken');
    if (data['logintoken'] == await getLoginToken()) {
      logger.log('sendIt');
      var state = data['state'];
      var publicKey = data['appPublicKey'];
      var privateKey = getPrivateKey();
      var email = getEmail();

      var signedHash = signHash(state, await privateKey);
      var scope = {};
      var dataToSend;
      if (data['scope'] != null) {
        if (data['scope'].split(",").contains('user:email'))
          scope['email'] = await email;
      }
      if (scope.isNotEmpty) {
        logger.log(scope.isEmpty);
        dataToSend =
            await encrypt(jsonEncode(scope), publicKey, await privateKey);
      }
      sendData(state, await signedHash, dataToSend, null);
    }
  } else {
    logger.log(data['type']);
    if (data['type'] == 'login' && data['mobile'] != 'true') {
      Navigator.popUntil(context, ModalRoute.withName('/'));
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginScreen(data)));
    } else if (data['type'] == 'email_verification') {
      getEmail().then((emailMap) async {
        if (!emailMap['verified']) {
          checkVerificationStatus(await getDoubleName())
              .then((newEmailMap) async {
            logger.log("newEmailMap.body: ");
            logger.log(newEmailMap.body);
            var body = jsonDecode(newEmailMap.body);
            saveEmailVerified(body['verified'] == 1);
          });
        }
      });
    }
  }
}
