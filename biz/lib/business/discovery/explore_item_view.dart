import 'dart:ui';

import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/ui/user_card_view.dart';
import 'package:biz/shared/widget/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/router/route_helper.dart';
import '../../base/router/router_names.dart';
import '../../core/util/collections_util.dart';
import '../home_page_lists/list_item.dart';

class ExploreItemView extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const ExploreItemView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {

    String linkNum = RoleItem.shortStringForCount(data[Security.security_heatInfo]?[Security.security_connectors] ?? 0);
    String heatNum = RoleItem.shortStringForCount(data[Security.security_heatInfo]?[Security.security_heatValue] ?? 0);

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
              bottom: 12,
              left: 12,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 16),
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
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ImageView(Images.security_linknum_webp, width: 16, height: 16).marginOnly(right: 4),
                                Text(linkNum, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                SizedBox(width: 12),
                                ImageView(Images.security_heart_count_webp, width: 16, height: 16).marginOnly(right: 4),
                                Text(heatNum, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
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
                        _buildItemButton(),
                      ],
                    ),
                  ),
                ),
              )
              ,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsList() {
    if (Preferences.instance.isRv) return  SizedBox();
    List<dynamic> tags = data[Security.security_characters] ?? [];
    if (tags.isEmpty) return const SizedBox();
    // if (tags.length > 3) tags = tags.sublist(0, 3);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          tags
              .map(
                (e) =>
                    e.isEmpty
                        ? const SizedBox()
                        : Container(
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
    ).marginOnly(top: 8);
  }

  Widget _buildItemButton() {
    return InkWell(
      onTap: () {
        _onItemClicked();
      },
      child: Container(
        alignment: Alignment.center,
        height: 48,
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFF288), Color(0xFFF9C07D)],
          ),
        ),
        child: const Text(
          'Chat',
          style: TextStyle(
            color: Color(0xCC221600),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.15,
          ),
        ),
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
