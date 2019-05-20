import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:threebotlogin/main.dart';

class ErrorScreen extends StatefulWidget {
  final Widget errorScreen;

  ErrorScreen({Key key, this.errorScreen}) : super(key: key);

  _ErrorScreenState createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  var version = '0.0.0';
  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((packageInfo) => {
      setState(() {
        version = packageInfo.version;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Update required'),
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
                            topRight: Radius.circular(20.0))),
                    child: Container(
                        padding: EdgeInsets.only(top: 24.0, bottom: 38.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Expanded(child: Container(),),
                              Icon(
                                Icons.warning,
                                size: 42.0,
                                color: Theme.of(context).errorColor,
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              Text('Please update the app before continuing'),
                              SizedBox(
                                height: 60.0,
                              ),
                              Expanded(child: Container(),),
                              Text('v ' + version + (isInDebugMode ? '-DEBUG' : '')),
                            ],
                          ),
                        ))))));
  }
}