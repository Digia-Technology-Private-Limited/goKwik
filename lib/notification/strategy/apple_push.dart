import 'package:gokwik/notification/data/notifiaction_data.dart';
import 'package:gokwik/notification/data/notification_builder.dart';
import 'package:gokwik/notification/strategy/notification_strategy.dart';

class ApplePushStrategy implements NotificationStrategy {
  @override
  NotificationData getNotificationData(data, String channel) {
    final notification = NotificationBuilder()
        .setTitle(data?.data?.title)
        .setSubtitle(data?.data?.subtitle)
        .setBody(data?.data?.body)
        .setPlatform(PlatformType.ios)
        .setImage(data?.data?.image ?? '')
        .setUrl(data?.data?.url ?? '')
        .build();
    return notification;
  }
}
