import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final StreamController<Map<String, dynamic>> _onNotificationClick = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationClick => _onNotificationClick.stream;

  Future<void> init() async {
    debugPrint('Initializing NotificationService...');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _onNotificationClick.add(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    if (Platform.isAndroid) {
      debugPrint('Creating Android notification channel...');
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'proximity_channel',
            'Proximity Alerts',
            description: 'Notifications when you are near a saved place',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ));
    }

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    debugPrint('Requesting notification permissions...');
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Android Notification permission granted: $granted');
    } else if (Platform.isIOS) {
       final granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
       debugPrint('iOS Notification permission granted: $granted');
    }
  }

  Future<void> showProximityNotification({
    required int id,
    required String placeName,
    required double lat,
    required double lng,
  }) async {
    debugPrint('Showing proximity notification for $placeName (ID: $id)');
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'proximity_channel',
      'Proximity Alerts',
      channelDescription: 'Notifications when you are near a saved place',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Proximity Alert',
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String payload = jsonEncode({
      'type': 'proximity_note',
      'placeName': placeName,
      'lat': lat,
      'lng': lng,
    });

    try {
      await _notificationsPlugin.show(
        id + 1000, // Use offset to avoid ID 0 or clashes
        'Nearby Place!',
        'You are close to $placeName. Do you want to take note?',
        notificationDetails,
        payload: payload,
      );
      debugPrint('Notification shown successfully');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
}
