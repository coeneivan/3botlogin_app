import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:threebotlogin/screens/LoginScreen.dart';
import 'package:threebotlogin/services/3botService.dart';
import 'package:threebotlogin/services/userService.dart';
import 'package:threebotlogin/services/firebaseService.dart';
import 'package:package_info/package_info.dart';
import 'package:threebotlogin/main.dart';
import 'package:uni_links/uni_links.dart';
import 'RegistrationWithoutScanScreen.dart';
import 'package:threebotlogin/services/openKYCService.dart';
import 'dart:convert';


class HomeScreen extends StatefulWidget {
  final Widget homeScreen;

  HomeScreen({Key key, this.homeScreen}) : super(key: key);

  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool openPendingLoginAttemt = true;
  String doubleName = '';
  String version = '0.0.0';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PackageInfo.fromPlatform().then((packageInfo) => {
          setState(() {
            version = packageInfo.version;
          })
        });
    onActivate(context: context);
  }

  void testCallback() {}

  Future<Null> initUniLinks() async {
    String initialLink = await getInitialLink();
    if (initialLink != null) {
      checkWhatPageToOpen(Uri.parse(initialLink));
    } else {
      getLinksStream().listen((String incomingLink) {
        checkWhatPageToOpen(Uri.parse(incomingLink));
      });
    }
  }

  checkWhatPageToOpen(Uri link) {
    print(link.queryParameters);
    setState(() {
      openPendingLoginAttemt = false;
    });
    if (link.host == 'register') {
      print('Register via link');
      openPage(RegistrationWithoutScanScreen(
        link.queryParameters,
      ));
    } else if (link.host == 'login') {
      print('Login via link');
      openPage(LoginScreen(
        link.queryParameters,
        closeWhenLoggedIn: true,
      ));
    }
  }

  openPage(page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void checkIfThereAreLoginAttempts(dn) async {
    if (await getPrivateKey() != null && deviceId != null) {
      checkLoginAttempts(dn).then((attempt) {
        print('-----=====------');
        print(deviceId);
        print(attempt.body);
        if (attempt.body != '' && openPendingLoginAttemt)
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginScreen(jsonDecode(attempt.body))));
        print('-----=====------');
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    if (state == AppLifecycleState.resumed) {
      onActivate();
    }
  }

  Future onActivate({context}) async {
    if (context != null) {
      initFirebaseMessagingListener(context);
    }
    initUniLinks();
    String dn = await getDoubleName();
    checkIfThereAreLoginAttempts(dn);
    if (dn != null || dn != '') {
      getEmail().then((emailMap) async {
        if (!emailMap['verified']) {
          checkVerificationStatus(dn).then((newEmailMap) async {
            print(newEmailMap.body);
            var body = jsonDecode(newEmailMap.body);
            saveEmailVerified(body['verified'] == 1);
          });
        }
      });
      setState(() {
        doubleName = dn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('3Bot'), elevation: 0.0, actions: <Widget>[
          doubleName != null
              ? IconButton(
                  icon: Icon(Icons.person),
                  tooltip: 'Your profile',
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                )
              : Container(),
        ]),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                            child: Center(
                          child: FutureBuilder(
                              initialData: loading(context),
                              future: getDoubleName(),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (snapshot.hasData)
                                  return alreadyRegistered(context);
                                else
                                  return notRegistered(context);
                              }),
                        )),
                        Text('v ' + version + (isInDebugMode ? '-DEBUG' : '')),
                      ],
                    )))));
  }

  Column loading(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircularProgressIndicator(),
        SizedBox(
          height: 20,
        ),
        Text('Checking if you are already registered....'),
      ],
    );
  }

  Column notRegistered(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('You are not registered yet.'),
        SizedBox(
          height: 20,
        ),
        RaisedButton(
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(10)),
          padding: EdgeInsets.all(12),
          child: Text(
            "Register now",
            style: TextStyle(color: Colors.white),
          ),
          color: Theme.of(context).accentColor,
          onPressed: () {
            // showScopeDialog(context, 'user:email'.split(','), 'YOUR APP', testCallback);
            Navigator.pushNamed(context, '/scan');
          },
        )
      ],
    );
  }

  Column alreadyRegistered(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.check_circle,
          size: 42.0,
          color: Theme.of(context).accentColor,
        ),
        SizedBox(
          height: 20.0,
        ),
        Text('Hi ' + doubleName, style: TextStyle(fontSize: 24.0), ),
        SizedBox(
          height: 24.0,
        ),
        Text('You are already registered.'),
        Text('If you need to login you\'ll get a notification.'),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  
}
