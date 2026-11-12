import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/webview/web_view.dart';
import 'package:flutter/material.dart';

class GenerateVideoWebSheet extends StatelessWidget {
  const GenerateVideoWebSheet({super.key, required this.uri});

  final Uri uri;

  static Uri? parseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !WebView.isSupportedEmbeddedUrl(uri) ||
        uri.queryParameters['external'] == '1') {
      return null;
    }
    return uri;
  }

  static Uri buildUrl(
    Uri uri, {
    required int toUid,
    int msgId = 0,
    String prompt = '',
    String imageUrl = '',
  }) {
    return uri.replace(
      queryParameters: {
        ...uri.queryParametersAll,
        Security.security_toUid: '$toUid',
        Security.security_msgId: '$msgId',
        Security.security_prompt: prompt,
        Security.security_imageUrl: imageUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 5 / 6,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: WebView(url: uri.toString(), embedded: true),
      ),
    );
  }
}
