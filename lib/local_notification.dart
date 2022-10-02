import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class LocalNotificationManager {
  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notif_icon');
  late IOSInitializationSettings initializationSettingsIOS;
  late InitializationSettings initializationSettings;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  LocalNotificationManager() {
    initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  }

  Future initialize() async {
    await _configureLocalTimeZone();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    await _requestPermissions();
    // _zonedScheduleNotification(1, "ثبت وعده غذایی", "صبحانه خود را وارد کنید");
    scheduleDailyTenAMNotification(
        id: 0,
        title: "ثبت وعده غذایی",
        body: "صبحانه خود را وارد کنید",
        hour: 9,
        minutes: 0);
    scheduleDailyTenAMNotification(
        id: 1,
        title: "ثبت وعده غذایی",
        body: "ناهار خود را وارد کنید",
        hour: 13,
        minutes: 30);
    scheduleDailyTenAMNotification(
        id: 2,
        title: "ثبت وعده غذایی",
        body: "شام خود را وارد کنید",
        hour: 2,
        minutes: 0);
  }

  onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {}

  onSelectNotification(String? text) {}

  Future<void> _zonedScheduleNotification(
      int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        NotificationDetails(
            android: AndroidNotificationDetails('main', 'main',
                channelDescription: 'Meals reminder', playSound: true)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  Future<void> scheduleDailyTenAMNotification(
      {required int id,
      required String title,
      required String body,
      required int hour,
      minutes}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTenAM(hour: hour, minutes: minutes),
        const NotificationDetails(
          iOS: IOSNotificationDetails(),
          android: AndroidNotificationDetails('main', 'main',
              channelDescription: 'Meals reminder'),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  tz.TZDateTime _nextInstanceOfTenAM({required int hour, int minutes = 0}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minutes);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestPermission();
    }
  }
}
