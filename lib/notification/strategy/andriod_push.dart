import 'package:gokwik/notification/data/notifiaction_data.dart';
import 'package:gokwik/notification/data/notification_builder.dart';
import 'package:gokwik/notification/strategy/notification_strategy.dart';

class AndriodPushStrategy implements NotificationStrategy {
  @override
  NotificationData getNotificationData(data, String channel) {
    final notification = NotificationBuilder()
        .setMessageId(data?.data?.message_id)
        .setTitle(data?.data?.title)
        .setBody(data?.data?.body)
        .setSubtitle(data?.data?.subtitle)
        .setSummary(data?.data?.summary)
        .setPlatform(PlatformType.android)
        .setChannel(channel)
        .setImage(data?.data?.image ?? '')
        .setUrl(data?.data?.url ?? '')
        .setButtons(data?.data?.buttons)
        .build();
    return notification;
  }
}
