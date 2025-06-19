import 'dart:convert';

class NotificationData {
  final String title;
  final String body;
  final String subtitle;
  final String platform;
  final AndroidData android;
  final IOSData? ios;
  final MiscData data;

  NotificationData({
    required String messageId,
    required this.title,
    required String subtitle,
    required String summary,
    required this.body,
    required this.platform,
    required String channel,
    required String image,
    required String url,
    required String actions,
    required String categoryId,
  })  : subtitle = summary,
        android = _buildAndroidData(channel, image, body, url, actions),
        ios = _buildIOSData(subtitle, categoryId, image, actions),
        data = _buildMiscData(url, platform, messageId, actions);

  static AndroidData _buildAndroidData(
    String channel,
    String image,
    String body,
    String url,
    String actions,
  ) {
    final androidStyle = image.isNotEmpty
        ? AndroidStyle(type: "bigPicture", picture: image)
        : AndroidStyle(type: "bigText", picture: image, text: body);

    final defaultActions = ActionData(id: "default", url: url);
    final otherActions = _parseActions(actions);

    return AndroidData(
      channelId: channel,
      style: androidStyle,
      pressAction: defaultActions,
      actions: otherActions,
    );
  }

  static IOSData? _buildIOSData(
    String subtitle,
    String categoryId,
    String image,
    String actions,
  ) {
    final iosImageData = image.isNotEmpty
        ? [IosImageData(url: image, thumbnailHidden: false)]
        : [] as List<IosImageData>;

    final otherActions = _parseActions(actions);
    final iosCategory = IOSCategory(
      id: categoryId,
      actions: otherActions.map((action) => action.pressAction).toList(),
    );

    return IOSData(
      subtitle: subtitle,
      categoryId: categoryId,
      iosCategory: iosCategory,
      attachments: iosImageData,
    );
  }

  static MiscData _buildMiscData(
    String url,
    String platform,
    String messageId,
    String actions,
  ) {
    final otherActions = _parseActions(actions);
    final actionUrls =
        otherActions.map((action) => action.pressAction.url).toList();

    return MiscData(
      url: url,
      source: "kwikchat",
      platform: platform,
      messageId: messageId,
      action1Url: actionUrls.isNotEmpty ? actionUrls[0] : '',
      action2Url: actionUrls.length > 1 ? actionUrls[1] : '',
      action3Url: actionUrls.length > 2 ? actionUrls[2] : '',
    );
  }

  static List<Action> _parseActions(String actions) {
    try {
      if (actions.isNotEmpty) {
        final parsedArray =
            List<Map<String, dynamic>>.from(jsonDecode(actions));
        return parsedArray.map((item) {
          final pressAction = ActionData(
            id: item['pressAction']['id'],
            url: item['pressAction']['url'],
            title: item['title'] ?? '',
          );
          return Action(title: item['title'], pressAction: pressAction);
        }).toList();
      }
      return [];
    } catch (error) {
      return [];
    }
  }
}

class Action {
  String title;
  ActionData pressAction;

  Action({required this.title, required this.pressAction});
}

class ActionData {
  String id;
  String title;
  String url;

  ActionData({required this.id, required this.url, this.title = ""});
}

class AndroidStyle {
  String type;
  String picture;
  String text;

  AndroidStyle({required this.type, required this.picture, this.text = ""});
}

class AndroidData {
  String channelId;
  AndroidStyle style;
  ActionData pressAction;
  List<Action> actions;
  int timestamp;
  bool showTimestamp;
  String summary;

  AndroidData({
    required this.channelId,
    required this.style,
    required this.pressAction,
    required this.actions,
  })  : timestamp = DateTime.now().millisecondsSinceEpoch,
        showTimestamp = true,
        summary = "new summary";
}

class IosImageData {
  String url;
  bool thumbnailHidden;

  IosImageData({required this.url, required this.thumbnailHidden});
}

class IOSData {
  String subtitle;
  String categoryId;
  IOSCategory iosCategory;
  List<IosImageData> attachments;

  IOSData({
    required this.subtitle,
    this.categoryId = '',
    required this.iosCategory,
    required this.attachments,
  });
}

class IOSCategory {
  String id;
  List<ActionData> actions;

  IOSCategory({required this.id, required this.actions});
}

class MiscData {
  String url;
  String source;
  String platform;
  String messageId;
  String action1Url;
  String action2Url;
  String action3Url;

  MiscData({
    required this.url,
    required this.source,
    required this.platform,
    required this.messageId,
    this.action1Url = '',
    this.action2Url = '',
    this.action3Url = '',
  });
}
