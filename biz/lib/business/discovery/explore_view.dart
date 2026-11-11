import 'package:flutter/material.dart';

import '../../base/api_service/api_request.dart';
import '../../base/api_service/api_service.dart';
import '../../base/crypt/apis.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/crypt/security.dart';
import '../../base/event_center/event_center.dart';
import '../../base/preferences/preferences.dart';
import '../../core/util/cached_image.dart';
import '../../shared/app_theme.dart';
import 'discovery_swipe_deck.dart';
import 'explore_item_view.dart';

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final _users = <Map>[];
  final _listedIds = <String>{};
  int _nextPage = 0;
  int _currentIndex = 0;
  int _generation = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _isRv = Preferences.instance.isRv;

  @override
  void initState() {
    super.initState();
    EventCenter.instance.addListener(
      Preferences.kDicChangedAppConfig,
      _onConfigChanged,
    );
    _load(reset: true);
  }

  void _onConfigChanged(Event event) {
    final isRv = Preferences.instance.isRv;
    if (_isRv == isRv) return;
    _isRv = isRv;
    _load(reset: true);
  }

  @override
  void dispose() {
    EventCenter.instance.removeListener(
      Preferences.kDicChangedAppConfig,
      _onConfigChanged,
    );
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loadingMore || !_hasMore)) return;
    if (reset) {
      _generation++;
      setState(() {
        _loading = true;
        _users.clear();
        _listedIds.clear();
        _nextPage = 0;
        _currentIndex = 0;
        _hasMore = true;
      });
    }
    final generation = _generation;
    final page = _nextPage;
    setState(() => _loadingMore = true);
    try {
      final response = await ApiService.instance.sendRequest(
        ApiRequest(
          Apis.security_slidePendingList,
          params: {
            Security.security_limit: 30,
            Security.security_pageNumber: page,
          },
        ),
      );
      if (!mounted || generation != _generation) return;
      if (response.isSuccess) {
        final batch = ((response.data[Security.security_list] ?? []) as List)
            .cast<Map>();
        setState(() {
          for (final user in batch) {
            final id = user[Security.security_uid]?.toString();
            if (id != null && !_listedIds.add(id)) continue;
            _users.add(user);
          }
          _nextPage = page + 1;
          final more = response.data[Security.security_hasMore];
          _hasMore = more == null
              ? batch.length >= 30
              : more == true || more == 1;
        });
        _preloadImages(_currentIndex);
      }
    } catch (_) {
      // Keep the current deck and allow another request from the empty state.
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onIndexChanged(int index) {
    _currentIndex = index;
    _preloadImages(index);
    if (_users.length - index < 8) _load();
  }

  void _preloadImages(int index) {
    for (final user in _users.skip(index).take(3)) {
      final mission = user[Security.security_recommendMission];
      final photos = user[Security.security_photos] as List?;
      final urls = [
        if (mission is Map) mission[Security.security_backgroundUrl],
        if (mission is Map) mission[Security.security_characterPngUrl],
        if (photos != null && photos.isNotEmpty) photos.first,
      ];
      for (final url in urls.whereType<String>().where(
        (url) => url.isNotEmpty,
      )) {
        precacheImage(CachedImageProvider(url), context);
      }
    }
  }

  Future<bool> _onDecision(int index, bool liked) async {
    final id = int.tryParse(_users[index][Security.security_uid].toString());
    if (id == null) return false;
    try {
      final response = await ApiService.instance.sendRequest(
        ApiRequest(
          liked ? Apis.security_slideRight : Apis.security_slideLet,
          params: {Security.security_otherUid: id},
        ),
      );
      if (response.isSuccess) return true;
    } catch (_) {
      // A failed decision must not remove the card.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Copywriting.security_network_error__please_try_again_later,
          ),
        ),
      );
    }
    return false;
  }

  Widget _emptyView(BuildContext context) {
    if (_loadingMore) return _progress();
    return Center(
      child: TextButton(
        onPressed: () => _load(reset: !_hasMore || _users.isEmpty),
        child: Text(
          Copywriting.security_no_datas__click_to_retry_,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _progress() => const Center(
    child: CircularProgressIndicator(color: AppColors.accentText),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return _progress();
    return DiscoverySwipeDeck(
      key: ValueKey(_generation),
      itemCount: _users.length,
      itemBuilder: (context, index) =>
          ExploreItemView(_users[index], showChatButton: false),
      onDecision: _onDecision,
      onChat: (index) => ExploreItemView.openChat(_users[index]),
      onIndexChanged: _onIndexChanged,
      exhaustedBuilder: _emptyView,
      chatLabel: Security.security_Chat,
      likeLabel: Security.security_like,
      dislikeLabel: Security.security_dislike,
    );
  }
}
