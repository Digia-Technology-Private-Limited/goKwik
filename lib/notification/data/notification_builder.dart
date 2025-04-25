import 'package:gokwik/notification/data/notifiaction_data.dart';

enum PlatformType { android, ios }

class NotificationBuilder {
  String _messageId = '';
  String _title = '';
  String _body = '';
  String _channel = '';
  String _image = '';
  String _url = '';
  String _subtitle = '';
  String _summary = '';
  String _buttons = '';
  String _buttonId = '';
  PlatformType _platform = PlatformType.android; // 'android' or 'ios'

  NotificationBuilder setMessageId(String messageId) {
    _messageId = messageId;
    return this;
  }

  NotificationBuilder setTitle(String title) {
    _title = title;
    return this;
  }

  NotificationBuilder setSubtitle(String subtitle) {
    _subtitle = subtitle;
    return this;
  }

  NotificationBuilder setSummary(String summary) {
    _summary = summary;
    return this;
  }

  NotificationBuilder setBody(String body) {
    _body = body;
    return this;
  }

  NotificationBuilder setPlatform(PlatformType platform) {
    if (platform != PlatformType.android && platform != PlatformType.ios) {
      throw ArgumentError("Platform must be either 'android' or 'ios'.");
    }
    _platform = platform;
    return this;
  }

  NotificationBuilder setChannel(String channel) {
    _channel = channel;
    return this;
  }

  NotificationBuilder setImage(String image) {
    _image = image;
    if (image.isNotEmpty && image.startsWith('http')) {
      _image = Uri.encodeFull(image);
    }
    return this;
  }

  NotificationBuilder setUrl(String url) {
    _url = url;
    return this;
  }

  NotificationBuilder setButtons(String buttons) {
    _buttons = buttons;
    return this;
  }

  NotificationBuilder setButtonId(String buttonId) {
    _buttonId = buttonId;
    return this;
  }

  NotificationData build() {
    if (_title.isEmpty || _body.isEmpty || _platform != null) {
      throw Exception("Title, message, and platform are required fields.");
    }
    return NotificationData(
      messageId: _messageId,
      title: _title,
      subtitle: _subtitle,
      summary: _summary,
      body: _body,
      platform: _platform!.name,
      channel: _channel,
      image: _image,
      url: _url,
      actions: _buttons,
      categoryId: _buttonId,
    );
  }
}
