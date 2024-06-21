import 'dart:io';
import 'dart:isolate';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

abstract class NotificationTemplate {
  Future<void> initializeNotifications();
  Future<void> sendNotification(
      {required String title,
      required String body,
      required RemoteMessage message});
  Future<String> getNotificationToken();
}

class NotificationRepository extends NotificationTemplate {
  final AwesomeNotifications awesomeNotifications = AwesomeNotifications();
  late NotificationChannel channel;
  static ReceivePort? receiveAction;

  NotificationRepository() {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: false,
    );
  }
  @override
  Future<String> getNotificationToken() async {
    try {
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          provisional: false,
          sound: true,
        );
        final token = await FirebaseMessaging.instance.getAPNSToken();
        debugPrint("Ios APNS token: $token");
        return token!;
      } 
        final token = await FirebaseMessaging.instance.getToken();
        debugPrint('The firebase messaging token is: $token');
        return token!;
      
    } catch (e) {
      debugPrint(e.toString());
      throw Exception('Error getting firebase messaging token');
    }
  }

  @override
  Future<void> initializeNotifications() async {
    try {
          await awesomeNotifications.initialize(
        'resource://drawable/climate',
        [
          NotificationChannel(
            channelKey: 'fcm',
            channelName: 'firebase_channel',
            defaultColor: Colors.teal,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            channelDescription:
                'This channel is used for important notifications.',
            channelGroupKey: 'firebase',
          ),
        ],
        debug: true);

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
     
      // FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            "Foreground Message received: ${message.notification!.title}");
        sendNotification(
          body: message.data['message'] ?? message.notification!.body,
          title: message.data['title'] ?? message.notification!.title!,
          message: message,
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            "Background Message received: ${message.notification!.body}");
        sendNotification(
          body: message.data['message'] ?? message.contentAvailable.toString(),
          title: message.data['title'] ?? message.notification!.title!,
          message: message,
        );
      });
      debugPrint("Firebase messaging initialized");
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error initializing firebase messaging");
    }
  }

  @override
  Future<void> sendNotification(
      {required String title,
      required String body,
      required RemoteMessage message}) {
    return awesomeNotifications.createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'fcm',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigPicture,
      ),
    );
  }

  Future<void> showNotification(
      {required String title, required String body}) async {
    await awesomeNotifications.createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'fcm',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigPicture,
      ),
    );
  }
}
