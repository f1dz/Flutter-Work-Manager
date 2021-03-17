import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

void main() {
  runApp(MyApp());
}

const simpleTaskKey = 'simpleTask';
const simpleDelayedTask = "simpleDelayedTask";
const simplePeriodicTask = "simplePeriodicTask";
const simplePeriodic1HourTask = "simplePeriodic1HourTask";
enum _Platform { android, ios }
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_name');
    var initializationSettingsIOs = IOSInitializationSettings();
    var initSettings =
        InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOs);

    flutterLocalNotificationsPlugin.initialize(initSettings, onSelectNotification: onSelectNotification);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Work Manager"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Plugin init",
                style: Theme.of(context).textTheme.headline,
              ),
              RaisedButton(
                  child: Text("Start background service"),
                  onPressed: () {
                    Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
                  }),
              SizedBox(
                height: 16,
              ),
              Text(
                "One Off Tasks (Android only)",
                style: Theme.of(context).textTheme.headline,
              ),
              PlatformEnabledButton(
                  platform: _Platform.android,
                  child: Text("Register One Off Task"),
                  onPressed: () {
                    Workmanager.registerOneOffTask("1", simpleTaskKey,
                        inputData: <String, dynamic>{
                          'int': 1,
                          'bool': true,
                          'double': 1.0,
                          'string': 'string',
                          'array': [1, 2, 3]
                        },
                        initialDelay: Duration(seconds: 10),
                        constraints: Constraints(networkType: NetworkType.connected));
                  }),
              PlatformEnabledButton(
                  platform: _Platform.ios,
                  child: Text("Register Delayed OneOff Task"),
                  onPressed: () {
                    Workmanager.registerOneOffTask("2", simpleDelayedTask,
                        initialDelay: Duration(seconds: 10));
                  }),
              SizedBox(
                height: 8,
              ),
              Text("Periodic Tasks (Android only)", style: Theme.of(context).textTheme.headline),
              PlatformEnabledButton(
                  platform: _Platform.android,
                  child: Text("Register Periodic Task"),
                  onPressed: () {
                    Workmanager.registerPeriodicTask(
                      "3",
                      simplePeriodicTask,
                      initialDelay: Duration(seconds: 10),
                      frequency: Duration(seconds: 10),
                    );
                  }),
              PlatformEnabledButton(
                  platform: _Platform.android,
                  child: Text("Register 1 hour Periodic Task"),
                  onPressed: () {
                    Workmanager.registerPeriodicTask(
                      "5",
                      simplePeriodic1HourTask,
                      frequency: Duration(hours: 1),
                    );
                  }),
              PlatformEnabledButton(
                platform: _Platform.android,
                child: Text("Cancel All"),
                onPressed: () async {
                  await Workmanager.cancelAll();
                  print('Cancel all tasks completed');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future onSelectNotification(String payload) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return Text(payload);
    }));
  }
}

showNotification() async {
  var android = AndroidNotificationDetails('100', 'channel ', 'description',
      priority: Priority.high, importance: Importance.max);
  var iOS = IOSNotificationDetails();
  var platform = new NotificationDetails(android: android, iOS: iOS);
  await flutterLocalNotificationsPlugin.show(100, 'Flutter devs', 'Flutter Local Notification Demo', platform,
      payload: 'Welcome to the Local Notification demo');
}

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    switch (task) {
      case simpleTaskKey:
        print("$simpleTaskKey was executed. inputData = $inputData");
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("test", true);
        print("Bool from prefs: ${prefs.getBool("test")}");
        showNotification();
        break;
      case simpleDelayedTask:
        print("$simpleDelayedTask was executed");
        break;
      case simplePeriodicTask:
        print("$simplePeriodicTask was executed");
        showNotification();
        break;
      case simplePeriodic1HourTask:
        print("$simplePeriodic1HourTask was executed");
        break;
      case Workmanager.iOSBackgroundTask:
        print("The iOS background fetch was triggered");
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;
        print(
            "You can access other plugins in the background, for example Directory.getTemporaryDirectory(): $tempPath");
        break;
    }
    return Future.value(true);
  });
}

class PlatformEnabledButton extends RaisedButton {
  final _Platform platform;

  PlatformEnabledButton({this.platform, @required Widget child, @required VoidCallback onPressed})
      : assert(child != null, onPressed != null),
        super(
            child: child,
            onPressed: (Platform.isAndroid && platform == _Platform.android ||
                    Platform.isIOS && platform == _Platform.ios)
                ? onPressed
                : null);
}
