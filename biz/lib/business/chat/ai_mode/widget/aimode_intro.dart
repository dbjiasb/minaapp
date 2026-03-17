import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';

import '../../../../base/crypt/security.dart';
import '../../../../shared/widget/app_widgets.dart';
import '../service/ai_mode_service.dart';

class AIModeIntro extends StatelessWidget {
  final Map curMode;
  final GestureTapCallback? onBack;
  AIModeIntro(this.curMode, this.onBack);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            color: Color(0xFF5B1C9B),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
          ),
        ),
        Positioned.fill(
          child: Column(
            children: [
              SizedBox(height: 12,),
              Container(
                // margin: EdgeInsets.only(left: 16, right: 16),
                margin: const EdgeInsets.only(left: 16, right: 16),
                padding: EdgeInsets.only(right: 24),
                width: double.infinity,
                height: 48,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(
                      child: InkWell(
                      onTap: () {
                        onBack?.call();
                      },
                      child: Container(padding: const EdgeInsets.only(top: 4, bottom: 4), child: AppWidgets.backBtn(onPressed: () {
                        onBack?.call();
                      }),))
                    ),
                    Expanded(
                      child: Text(
                        curMode[Security.security_name] ?? "",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    // Image.asset("assets/images/ic_title_decoration_star.png", package: Security.security_app_common, width: 12, height: 12),
                  ],
                ),
              ),
              SizedBox(height: 12,),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    curMode[ES.dd] ?? "",
                    style: const TextStyle(
                        fontSize: 16, height: 1.5, color: Colors.white),
                  ),
                ),
              ),
              // _buildBackButton()
            ],
          ),
        ),
      ],
    );
  }
}
