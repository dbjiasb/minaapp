import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/entities/order_update_entity.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:get/get.dart';

import '../../../base/crypt/security.dart';
import '../../../base/ui/user_card_view.dart';
import '../../../core/util/cached_image.dart';
import '../constant_state.dart';
import '../moment_service.dart';

class ReorderResGridView extends StatefulWidget {
  final RxList<Map> resInfoList;

  final GestureTapCallback? onAddMoreTap;

  const ReorderResGridView(this.resInfoList, {this.onAddMoreTap, super.key});

  @override
  State<ReorderResGridView> createState() => _ReorderResGridViewState();
}

class _ReorderResGridViewState extends State<ReorderResGridView> {
  final ScrollController _scrollController = ScrollController();

  void reOrderImage(int oldIndex, int newIndex) {
    final oldItem = widget.resInfoList.removeAt(oldIndex);
    widget.resInfoList.insert(newIndex, oldItem);
  }

  final gridViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollable(
      viewportBuilder:
          (context, position) => MouseRegion(
            onEnter: (e) {
              setState(() {});
            },
            child: ReorderableBuilder(
              key: Key(gridViewKey.toString()),
              scrollController: _scrollController,
              enableDraggable: false,
              enableScrollingWhileDragging: false,
              dragChildBoxDecoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, spreadRadius: 1)]),
              onReorder: (List<OrderUpdateEntity> orderUpdateEntities) {
                for (final orderUpdateEntity in orderUpdateEntities) {
                  reOrderImage(orderUpdateEntity.oldIndex, orderUpdateEntity.newIndex);
                }
              },
              longPressDelay: const Duration(milliseconds: 100),
              builder: (children) {
                return GridView(
                  key: gridViewKey,
                  controller: _scrollController,
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 三列
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1, // 正方形格子
                  ),
                  children: children,
                );
              },
              children:
                  widget.resInfoList.map<Widget>((e) {
                    return Stack(
                      key: ValueKey(e[Security.security_url]),
                      children: [
                        AspectRatio(aspectRatio: 1.0 / 1.0, child: _buildResView(e)),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Listener(
                            onPointerDown: (_) {
                              _removeItem(e);
                            },
                            child: CachedImage(imageUrl: MomentRes.base+'iic_pics_remove.webp', width: 16, height: 16),
                          ),
                        ),
                      ],
                    );
                  }).toList() +
                  (widget.resInfoList.length >= 9
                      ? []
                      : [
                        AspectRatio(
                          aspectRatio: 1.0 / 1.0,
                          key: Key(Security.security_selector),
                          child: GestureDetector(
                            onTap: widget.onAddMoreTap,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: const Color(0xFF1B1E25), borderRadius: BorderRadius.circular(12)),
                              child: CachedImage(imageUrl: MomentRes.base+'iic_pic_add.webp', width: 24, height: 24),
                            ),
                          ),
                        ),
                      ]),
            ),
          ),
    );
  }

  Widget _buildResView(Map resInfo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:
          resInfo[Security.security_type] == EMomentResType.VIDEO
              ? VideoView(videoUrl: resInfo[Security.security_url] ?? '',)
              : CachedImage(
                imageUrl: resInfo[Security.security_url] ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
                errorWidget: (context, url, error) {
                  return Container(
                    color: Colors.grey,
                    width: double.infinity,
                  );
                },
                placeholder: (context, url) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(color: Color(0xFF2F3137), borderRadius: BorderRadius.circular(16)),
                  );
                },
              ),
    );
  }

  void _removeItem(Map e) {
    widget.resInfoList.remove(e);
  }
}
