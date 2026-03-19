import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/ui/user_card_view.dart';
import 'package:biz/shared/widget/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/router/route_helper.dart';
import '../../base/router/router_names.dart';
import '../../core/util/collections_util.dart';

class ExploreItemView extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const ExploreItemView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        RouteHelper.toPage(
          Routers.person,
          args: {
            Security.security_personInfo: {
              Security.security_userInfo: {
                Security.security_baseInfo: {
                  Security.security_uid: data[Security.security_uid],
                  Security.security_nickName: data[Security.security_nickname],
                  Security.security_avatarUrl: data[Security.security_avatar],
                  Security.security_accountType: data[Security.security_accountType],
                },
              },
            },
          },
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            UserCardView(
              defaultUrl: (data[Security.security_photos] as List?).firstOrNull(),
              videoUrl: data[Security.security_hoverUrl],
              userBgUrl: data[Security.security_recommendMission]?[Security.security_backgroundUrl],
              userCardUrl: data[Security.security_recommendMission]?[Security.security_characterPngUrl],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC000000)]),
                ),
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 0, top: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Text(
                              data[Security.security_nickname] ?? "",
                              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        AppWidgets.userTag(data[Security.security_accountType] ?? 0),
                        const SizedBox(width: 4),
                      ],
                    ),
                    (data[Security.security_bio] ?? "").isEmpty
                        ? Container()
                        : Text(
                          data[Security.security_bio] ?? "",
                          style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF)),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ).marginOnly(top: 8),
                    _buildTagsList(),
                    _buildButtons(),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsList() {
    List<dynamic> tags = data[Security.security_characters] ?? [];
    if (tags.isEmpty) return const SizedBox();
    if (tags.length > 3) tags = tags.sublist(0, 3);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          tags
              .map(
                (e) =>
                    e.isEmpty
                        ? const SizedBox()
                        : Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1affffff),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
              )
              .toList() ??
          [],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            _onItemClicked(call: true);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFFFFF288), Color(0xFFF9C07D)]),
            ),
            child: ImageView("discovery_call.webp", width: 48, height: 48),
          ),
        ),
        Expanded(child: _buildItemButton()),
      ],
    );
  }

  Widget _buildItemButton() {
    return InkWell(
      onTap: () {
        _onItemClicked();
      },
      child: Container(
        alignment: Alignment.center,
        height: 48,
        margin: const EdgeInsets.only(top: 12, bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFFFFEA55), Color(0xFFFF911A)]),
        ),
        child: Text(Copywriting.security_start_Chat, style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w900)),
      ),
    );
  }

  void _onItemClicked({bool call = false}) {
    String strUid = data[Security.security_uid].toString();
    String nickname = data[Security.security_nickname] ?? '';
    int accType = data[Security.security_accountType] ?? 0;
    String avatar = data[Security.security_avatar] ?? '';
    String coverUrl = (data[Security.security_photos] as List?).firstOrNull() ?? '';

    if (call) {
      Map args = {
        Security.security_callReason: Security.security_toCall,
        Security.security_session: {
          Security.security_id: strUid,
          Security.security_name: nickname,
          Security.security_avatar: avatar,
          Security.security_backgroundUrl: coverUrl,
          Security.security_accountType: accType,
        },
        Security.security_type: accType == 0 ? 0 : 1,
        Security.security_ai: accType == 0 ? 0 : 1,
      };

      RH.toCallOut(args);
    } else {
      RH.toChat(id: strUid, name: nickname, avatar: avatar, coverUrl: coverUrl, accountType: accType);
    }
  }
}
