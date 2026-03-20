import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/core/util/collections_util.dart';
import 'package:biz/core/util/ui_util.dart';

import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_response.dart';
import '../../base/api_service/api_service.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/security.dart';
import '../../base/event_center/event_center.dart';
import '../../base/router/route_helper.dart';
import '../../shared/app_theme.dart';

class MyGroupView extends StatefulWidget {
  const MyGroupView({super.key});

  @override
  State<MyGroupView> createState() => _MyGroupViewState();
}

class _MyGroupViewState extends State<MyGroupView> {
  @override
  void initState() {
    EventCenter.instance.addListener(Security.security_kDidGroupInfoChange, onEvent);
    super.initState();
  }

  void onEvent(Event e) {
    setState(() {});
  }

  @override
  void dispose() {
    EventCenter.instance.removeListener(Security.security_kDidGroupInfoChange, onEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.base_background,
      child: UiUtils.buildFutureView<List<dynamic>?>(getDataList(), (
        data,
        context,
      ) {
        if ((data ?? []).isEmpty) {
          return UiUtils.buildCommonEmptyView();
        } else {
          return ListView.builder(
            itemCount: data!.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return _buildItem(data.safeGet(index, {}));
            },
          );
        }
      }),
    );
  }

  Widget _buildItem(dynamic info) {
    return InkWell(
      onTap: () {
        RouteHelper.toChat(
          id: (info[Security.security_sessionId] ?? ""),
          name: (info[Security.security_name] ?? ""),
          avatar: (info[Security.security_avatar] ?? ""),
          coverUrl: (info[Security.security_chatBackground] ?? ""),
          type: 2,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CachedImage.clipImage(
              imageUrl: info[Security.security_avatar] ?? '',
              fit: BoxFit.fitWidth,
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${info[Security.security_name]}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${info['memberCount']} Members',
                      style: TextStyle(
                        color: Color(0xFFABABAD),
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>?> getDataList() async {
    ApiRequest request = ApiRequest(Apis.security_getGroupList,
      params: {Security.security_pageSize: 100},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      return response.data[Security.security_param];
    }
    return null;
  }
}
