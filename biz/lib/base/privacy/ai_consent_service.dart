import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/alert.dart';
import '../../shared/app_theme.dart';
import '../app_info/app_manager.dart';
import '../crypt/copywriting.dart';
import '../crypt/security.dart';
import '../preferences/preferences.dart';
import '../router/router_names.dart';

enum AIConsentFeature {
  chat('messages you send'),
  aiCall('voice conversations you have'),
  imageUpload('images you upload'),
  videoUpload('videos you upload'),
  imageGeneration('image generation requests'),
  videoGeneration('video generation requests');

  const AIConsentFeature(this.label);

  final String label;
}

class AIConsentService {
  AIConsentService._();

  static const String _consentKey = 'ai_data_processing_consent_v1';
  static Future<bool>? _pendingRequest;

  static bool get hasConsent => Preferences.instance.getBool(_consentKey);

  static Future<bool> ensureConsent({required AIConsentFeature feature}) async {
    if (!Preferences.instance.isRv || hasConsent) {
      return true;
    }
    if (_pendingRequest != null) {
      return _pendingRequest!;
    }

    final future = _showConsentDialog(feature);
    _pendingRequest = future;
    try {
      return await future;
    } finally {
      _pendingRequest = null;
    }
  }

  static void promptForEntryIfNeeded({required AIConsentFeature feature}) {
    if (hasConsent || _pendingRequest != null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasConsent || _pendingRequest != null || Get.isDialogOpen == true) {
        return;
      }
      ensureConsent(feature: feature);
    });
  }

  static Future<bool> _showConsentDialog(AIConsentFeature feature) async {
    final result = await showCustomAlert(_AIConsentDialog(feature: feature));
    final agreed = result == true;
    if (agreed) {
      await Preferences.instance.setBool(_consentKey, true);
    }
    return agreed;
  }
}

class _AIConsentDialog extends StatelessWidget {
  const _AIConsentDialog({required this.feature});

  final AIConsentFeature feature;

  void _openPrivacyPolicy() {
    Get.toNamed(
      Routers.webView,
      arguments: {
        Security.security_title: Copywriting.security_privacy_policy,
        Security.security_url: AppManager.instance.privacyHtml,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(
      color: Color(0xFFB9B9B9),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.45,
    );
    const linkStyle = TextStyle(
      color: AppColors.primary,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 520),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF333333),
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI Data Permission',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: RichText(
                      text: TextSpan(
                        style: bodyStyle,
                        children: [
                          TextSpan(
                            text:
                                'Before you continue, we need your permission to process ${feature.label} with our AI features.\n\n',
                          ),
                          const TextSpan(
                            text:
                                'Data sent for processing may include the text you enter, images, audio or video you upload, generation prompts, and the basic account or device identifiers needed to complete the request.\n\n',
                          ),
                          const TextSpan(
                            text:
                                'This data is sent to backend services operated by the developer and may be shared with OpenAI, which provides the ChatGPT model used for AI response generation. It may also be used for safety review and abuse prevention. The app will not send this AI request data until you tap Agree.\n\n',
                          ),
                          const TextSpan(
                            text: 'You can review the full details in our ',
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: linkStyle,
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = _openPrivacyPolicy,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back(result: false);
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Not Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back(result: true);
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Text(
                            'Agree',
                            style: TextStyle(
                              color: AppColors.mainDarkColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
