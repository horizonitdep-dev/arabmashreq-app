import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  const ShareHelper._();

  static const MethodChannel _nativeShareChannel =
      MethodChannel('com.arabmashreq.mobile/share');

  static Future<void> shareText(
    BuildContext context, {
    required String text,
    String? subject,
    String failureMessage =
        '\u062a\u0639\u0630\u0631 \u0641\u062a\u062d \u0646\u0627\u0641\u0630\u0629 \u0627\u0644\u0645\u0634\u0627\u0631\u0643\u0629 \u062d\u0627\u0644\u064a\u0627\u064b.',
  }) async {
    final normalizedText = text.trim();
    final normalizedSubject = subject?.trim();
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (normalizedText.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            '\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u062d\u062a\u0648\u0649 \u0635\u0627\u0644\u062d \u0644\u0644\u0645\u0634\u0627\u0631\u0643\u0629.',
          ),
        ),
      );
      return;
    }

    try {
      await Share.share(
        normalizedText,
        subject: normalizedSubject == null || normalizedSubject.isEmpty
            ? null
            : normalizedSubject,
        sharePositionOrigin: _shareOriginFor(context),
      );
      return;
    } catch (_) {
      // Fall back to a tiny native channel for older share_plus/iPad behavior.
    }

    try {
      await _nativeShareChannel.invokeMethod('shareText', <String, dynamic>{
        'text': normalizedText,
        if (normalizedSubject != null && normalizedSubject.isNotEmpty)
          'subject': normalizedSubject,
      });
      return;
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  static Rect? _shareOriginFor(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final size = renderObject.size;
    if (size.isEmpty) return null;
    return renderObject.localToGlobal(Offset.zero) & size;
  }
}
