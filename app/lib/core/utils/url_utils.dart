import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  /// Builds official VEX Events / RobotEvents web URL for an event SKU
  static String getVexEventsUrl(String sku) {
    final cleanSku = sku.trim().toUpperCase();
    return 'https://events.vex.com/events/$cleanSku';
  }

  /// Launch the official VEX Events page in the user's browser
  static Future<bool> openVexEventsPage(String sku) async {
    final urlStr = getVexEventsUrl(sku);
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching VEX Events URL: $e');
    }
    return false;
  }

  /// Launch email client for public contact or forwarding relay
  static Future<bool> openEmail({
    required String recipientEmail,
    String? subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: recipientEmail.trim(),
      queryParameters: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching mailto: $e');
    }
    return false;
  }

  /// Launch telephone dialer for public phone contact
  static Future<bool> openPhone(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching tel: $e');
    }
    return false;
  }
}
