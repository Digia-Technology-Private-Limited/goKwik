import 'dart:io';
import 'package:gokwik/config/cdn_config.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:gokwik/notification/data/notifiaction_data.dart';
import 'package:gokwik/notification/strategy/andriod_push.dart';
import 'package:gokwik/notification/strategy/apple_push.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notification_helper.dart';

class KwikChatNotification {
  // static const _tokenKey = 'gkNotificationToken';

  static Future<NotificationData> getNotificationData(
    dynamic rawData,
    String channel,
  ) async {
    try {
      final hasPermission =
          await NotificationHelper.checkAndRequestUserPermission();

      final messageId = rawData['data']?['message_id'];
      if (hasPermission) {
        NotificationHelper.sendNotificationStatus(messageId, 'delivered');
      } else {
        NotificationHelper.sendNotificationStatus(messageId, 'failed',
            failureReason: 'Permission Denied');
      }

      NotificationData notificationData;

      if (Platform.isAndroid) {
        final strategy = AndriodPushStrategy();
        notificationData = strategy.getNotificationData(rawData, channel);
      } else if (Platform.isIOS) {
        final strategy = ApplePushStrategy();
        notificationData = strategy.getNotificationData(rawData, channel);
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      return notificationData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cdnConfigInstance.getKeyOrDefault(KeyConfig.gkNotificationToken), token);
    // ignore: empty_catches
    } catch (e) {
    }
  }

  static Future<void> handleNotificationActions(
    String type,
    dynamic event, {
    void Function(String url)? navHandler,
  }) async {
    try {
      String url = '';
      String action = '';

      if (type == 'clicked') {
        action = event['pressAction']?['id'] ?? '';
        final data = event['notification']?['data'] ?? {};

        switch (action) {
          case 'default':
            url = data['url'] ?? '';
            break;
          case 'action-1':
            url = data['action1_url'] ?? '';
            break;
          case 'action-2':
            url = data['action2_url'] ?? '';
            break;
          case 'action-3':
            url = data['action3_url'] ?? '';
            break;
        }
      }

      final messageId = event['notification']?['data']?['message_id'];
      NotificationHelper.sendNotificationStatus(messageId, type,
          failureReason: '', buttonId: action);

      if (url.isNotEmpty) {
        if (navHandler != null) {
          navHandler(url);
        } else {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
          }
        }
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  static Future<void> updateSubscriptionStatus(
      bool granted, String channel) async {
    if (channel != 'KwikEngage Marketing') return;
    NotificationHelper.sendOptInStatus(granted);
  }
}
