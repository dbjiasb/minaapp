import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/assets/image_path.dart';
import '../../base/assets/image_view.dart';
import '../../base/crypt/constants.dart';
import '../../base/crypt/security.dart';
import '../../base/router/route_helper.dart';
import '../../core/util/cached_image.dart';
import '../../shared/widget/app_widgets.dart';

abstract class RoleItem {
  late final Map info;

  RoleItem(this.info);

  factory RoleItem.fromMap(Map info) {
    int type = info[Constants.acType];
    switch (type) {
      case 1:
        return VirtualRoleItem(info);
      default:
        return VirtualRoleItem(info);
    }
  }

  Widget builder(BuildContext context);

  static String shortStringForCount(int count) {
    if (count >= 1000000) {
      double wan = count / 1000000;
      return '${wan.toStringAsFixed(1)}m';
    } else if (count >= 1000) {
      double wan = count / 1000;
      return '${wan.toStringAsFixed(1)}k';
    } else {
      return count.toString();
    }
  }
}

class VirtualRoleItem extends RoleItem {
  VirtualRoleItem(super.info);

  String get coverUrl => info[Security.security_coverUrl] ?? '';

  String get nickname => info[Security.security_nickname] ?? '';

  String get bio => info[Security.security_bio] ?? '';

  int get accountType => info[Constants.acType] ?? 0;

  bool get isReal => accountType == 0;

  String get masterName => info[Security.security_robotInfo]?[Security.security_masterInfo]?[Security.security_nickName] ?? '';

  String get linkNum => RoleItem.shortStringForCount(info[Security.security_heatInfo]?[Security.security_connectors] ?? 0);

  String get heatNum => RoleItem.shortStringForCount(info[Security.security_heatInfo]?[Security.security_heatValue] ?? 0);

  List get tags => info[Security.security_tags] ?? [];
  bool get showTags => tags.isNotEmpty && Preferences.instance.showListCardTags;

  void _onItemClicked() {
    RH.toChat(
      id: info[Security.security_uid].toString(),
      name: info[Security.security_nickname] ?? '',
      avatar: info[Security.security_avatarUrl] ?? '',
      coverUrl: info[Security.security_coverUrl] ?? '',
      accountType: info[Security.security_accountType] ?? 0,
    );
  }

  @override
  Widget builder(BuildContext context) {
    return GestureDetector(
      onTap: _onItemClicked,
      child: AspectRatio(
        aspectRatio: 168 / 260,
        child: Container(
          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8))),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(image: CachedImageProvider(coverUrl), fit: BoxFit.cover),
            ),
            child: Column(
              children: [
                Spacer(),
                Container(
                  // constraints: BoxConstraints(minHeight: 48),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF252230).withValues(alpha: 0.5), Color(0xFF2F253B).withValues(alpha: 0.9)],
                    ),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nickname,
                              maxLines: 1,
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppWidgets.userTag(accountType),
                        ],
                      ),
                      if (bio.isNotEmpty) Text(bio, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 3),
                      if (showTags) SizedBox(height: 4),
                      if (showTags)
                        Wrap(
                          spacing: 3,
                          children:
                              tags
                                  .take(3)
                                  .map(
                                    (e) => Container(
                                      margin: EdgeInsets.only(top: 4),
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        e[Security.security_name] ?? '',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      if (!isReal) SizedBox(height: 8),
                      if (!isReal)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                masterName.isEmpty ? '' : '@$masterName',
                                style: TextStyle(color: Color(0xFFBEBFC5), fontSize: 8, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Row(
                              children: [
                                ImageView(Images.security_linknum_webp, width: 12, height: 12).marginOnly(right: 2),
                                Text(linkNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                                SizedBox(width: 4),
                                ImageView(Images.security_heart_count_webp, width: 12, height: 12).marginOnly(right: 2),
                                Text(heatNum, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
