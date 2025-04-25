import 'package:gokwik/notification/data/notifiaction_data.dart';

abstract class NotificationStrategy {
  NotificationData getNotificationData(dynamic data, String channel);
}
