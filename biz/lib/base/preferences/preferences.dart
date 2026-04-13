import 'package:biz/base/crypt/routes.dart';
//————————————————————shared_preferences————————————————————
// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class Preferences {
//   // 单例模式
//   static final Preferences _instance = Preferences._internal();
//
//   factory Preferences() => _instance;
//
//   Preferences._internal();
//
//   static Preferences get instance => _instance;
//
//   late SharedPreferences _store;
//
//   Future<void> init() async {
//     _store = await SharedPreferences.getInstance();
//   }
//
//   Future<bool> setString(key, value) {
//     return _store.setString(key, value);
//   }
//
//   String? getString(key) {
//     return _store.getString(key);
//   }
//
//   Future<bool> remove(key) {
//     return _store.remove(key);
//   }
//
//   Future<bool> clear() {
//     return _store.clear();
//   }
//
//   bool getBool(key) {
//     return _store.getBool(key) ?? false;
//   }
//
//   double getDouble(key) {
//     return _store.getDouble(key) ?? 0.0;
//   }
//
//   int getInt(key) {
//     return _store.getInt(key) ?? 0;
//   }
//
//   Map<String, dynamic> getMap(key) {
//     return json.decode(_store.getString(key) ?? '{}');
//   }
//
//   List<String> getStringList(key) {
//     return _store.getStringList(key) ?? [];
//   }
//
//   Future<bool> setBool(key, value) {
//     return _store.setBool(key, value);
//   }
//
//   Future<bool> setDouble(key, value) {
//     return _store.setDouble(key, value);
//   }
//
//   Future<bool> setInt(key, value) {
//     return _store.setInt(key, value);
//   }
//
//   Future<bool> setMap(key, value) {
//     return _store.setString(key, json.encode(value));
//   }
//
//   Future<bool> setStringList(key, value) {
//     return _store.setStringList(key, value);
//   }
// }

//————————————————————get_storage————————————————————
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/shared/alert.dart';

import '../../core/account/account_service.dart';
import '../../core/util/log_util.dart';
import '../api_service/api_request.dart';
import '../api_service/api_response.dart';
import '../api_service/api_service.dart';
import '../app_info/app_manager.dart';
import '../crypt/apis.dart';
import '../crypt/copywriting.dart';
import '../event_center/event_center.dart';

class Preferences {
  // 单例模式
  static final Preferences _instance = Preferences._internal();

  factory Preferences() => _instance;

  Preferences._internal();

  static Preferences get instance => _instance;

  late GetStorage _getStorage;

  bool isFirstLaunch = false;

  Future<void> init() async {
    await GetStorage.init();
    _getStorage = GetStorage();
    appConfig.value = getMap(kCachedKeyAppConfig);
    isRv = (appConfig[Security.security_app_adit] ?? '1') == '1';
    rpConfig.value = getMap(kRPConfig);

    checkLaunch();
  }

  checkLaunch() async {
    int lastLaunchTs = getInt(Security.security_kLastLaunchTime);
    if (lastLaunchTs == 0) {
      isFirstLaunch = true;
    }
    _getStorage.write(Security.security_kLastLaunchTime, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> setString(key, value) {
    _getStorage.write(key, value);
    L.i('<<<<<<<<key: $key ,value = $value');
    return Future.value(true);
  }

  String? getString(key) {
    L.i('>>>>>>>>key: $key ,value = ${_getStorage.read<String>(key)}');
    return _getStorage.read<String>(key);
  }

  Future<bool> remove(key) {
    _getStorage.remove(key);
    return Future.value(true);
  }

  Future<bool> clear() {
    _getStorage.erase();
    return Future.value(true);
  }

  bool getBool(key, {bool defaultVale = false}) {
    return _getStorage.read<bool>(key) ?? defaultVale;
  }

  double getDouble(key) {
    return _getStorage.read<double>(key) ?? 0.0;
  }

  int getInt(key) {
    return _getStorage.read<int>(key) ?? 0;
  }

  Map<String, dynamic> getMap(key) {
    String jsonString = _getStorage.read<String>(key) ?? '{}';
    return json.decode(jsonString);
  }

  List<String> getStringList(key) {
    return _getStorage.read<List<String>>(key) ?? <String>[];
  }

  Future<bool> setBool(key, value) {
    _getStorage.write(key, value);
    return Future.value(true);
  }

  Future<bool> setDouble(key, value) {
    _getStorage.write(key, value);
    return Future.value(true);
  }

  Future<bool> setInt(key, value) {
    _getStorage.write(key, value);
    return Future.value(true);
  }

  Future<bool> setMap(key, value) {
    _getStorage.write(key, json.encode(value));
    return Future.value(true);
  }

  Future<bool> setStringList(key, value) {
    _getStorage.write(key, value);
    return Future.value(true);
  }

  static String kCachedKeyAppConfig = Security.security_kCachedKeyAppConfig;
  static String kDicChangedAppConfig = Security.security_kDicChangedAppConfig;
  static String kRPConfig = Security.security_kRPConfig;

  RxMap appConfig = RxMap({});
  Timer? _timer;
  final RxBool _isRv = true.obs;

  bool get isRv => _isRv.value;

  set isRv(bool value) {
    if (value == _isRv.value) return;
    _isRv.value = value;
  }

  initAppConfig() async {
    EventCenter.instance.addListener(kEventCenterUserDidLogin, (data) async {
      await refreshConfig();
      Future.delayed(const Duration(seconds: 10), () {
        if (!isRv) return;
        refreshConfig();
      });
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!AccountService.instance.loggedIn) refreshConfig();
    });

    startRefreshTimer();
  }

  startRefreshTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: isRv ? 25 : 2 * 60), (timer) {
      refreshConfig();
    });
  }

  refreshConfig() async {
    ApiResponse rsp = await ApiService.instance.sendRequest(ApiRequest(Apis.security_acquireAppConfig, params: {}));
    if (rsp.isSuccess) {
      appConfig.value = rsp.data[Security.security_configMap] ?? {};
      setMap(kCachedKeyAppConfig, appConfig);
      isRv = (appConfig[Security.security_app_adit] ?? '1') == '1';
      EventCenter.instance.sendEvent(kDicChangedAppConfig, appConfig);
      startRefreshTimer();

      if (!isRv) {
        queryRPConfig();
        checkIfNeedUpdate();
      }
    }
  }

  bool supportVeo(String sid) {
    if (isRv) return false;//审核模式不支持视频
    // int uid = int.tryParse(sid) ?? 0;
    // if (uid > 9999 && uid < 10040) {
    //   return true;
    // } else if (uid > 10060 && uid < 10200) {
    //   return true;
    // } else if (uid > 59999 && uid < 60010) {
    //   return true;
    // }
    return true;
  }

  bool supportGame(int uid) {
    if (!isRv) return true;
    String supportGameUids = appConfig[Security.security_support_game_uids] ?? '';
    if (supportGameUids.contains(uid.toString())) return true;
    return false;
  }

  String? get adUId {
    String key = Platform.isIOS ? Security.security_ad_unit_id_ios : Security.security_ad_unit_id;
    return appConfig[key];
  }

  String get dcLink {
    return appConfig[Security.security_dc_link] ?? AppManager.instance.feedBackUrl;
  }

  List get askPicTips {
    String tips =
        appConfig[Security.security_ask_pick_tips] ??
        Copywriting
            .security_send_me_a_pic_with_you_tucking_hair_behind_ear_in_sunset__Send_me_a_pic_with_you_touching_flower_petals_at_dusk__Send_me_a_pic_with_you_holding_teacup_by_rain_window__Send_me_a_pic_with_you_twirling_silk_scarf_by_the_lake__Send_me_a_pic_with_you_adjusting_shoelace_in_sunlight__Send_me_a_pic_with_you_skimming_calm_fountain_surface__Send_me_a_pic_with_you_wrapping_shawl_on_the_balcony;
    return tips.split('||');
  }

  String get replaceUserAgent {
    return appConfig[Security.security_replace_user_agent] ?? '';
  }

  String get addedUserAgent {
    return appConfig[Security.security_added_user_agent] ?? '';
  }


  String get coinUrl {
    String url = appConfig[Security.security_coin_url] ?? '';
    return url;
  }

  String get premiumUrl {
    String url = appConfig[Security.security_premium_url] ?? '';
    return url;
  }

  bool shownUpdateAlert = false;

  void checkIfNeedUpdate() async {
    String config = appConfig[Security.security_upgrade_config] ?? '';
    if (config.isEmpty) return;

    Map configMap = {};
    try {
      // configMap = {
      //   Security.security_title: 'New Version Available',
      //   Security.security_content: 'New Version Available',
      //   Security.security_url: 'https://www.pixiv.net/',
      //   Security.security_force: 0,
      //   Security.security_strategy: 0,
      //   Security.security_ver: '1.2.5',
      //   Security.security_platform: 1
      // };
      configMap = const JsonDecoder().convert(config) as Map;
    } catch (e) {}
    if (configMap.isEmpty) return;

    String newVersion = configMap[Security.security_ver] ?? ''; if (newVersion.isEmpty) return;
    String currentVersion = AppManager.instance.appVersion;
    bool needUpdate = false;
    List<String>? newVersionList = newVersion.split('.');
    List<String>? currentVersionList = currentVersion.split('.');
    for (int i = 0; i < newVersionList.length; i++) {
      int newVer = int.parse(newVersionList[i]);
      int curVer = int.parse(currentVersionList.length > i ? currentVersionList[i] : '0');
      needUpdate = needUpdate || (newVer > curVer);
    }
    if (!needUpdate) return;

    String title = configMap[Security.security_title] ?? '';
    String content = configMap[Security.security_content] ?? '';
    String url = configMap[Security.security_url] ?? '';
    int force = configMap[Security.security_force] ?? 0;

    /// 0表示每次启动/更新都弹，1表示当日只弹一次
    int strategy = configMap[Security.security_strategy] ?? 0;
    /// 0 store，1 office 默认1
    // int channel = configMap['channel'] ?? 1;
    /// 1 ios，2 android
    int platform = configMap[Security.security_platform] ?? 0;
    int curPlatform = Platform.isIOS ? 1 : 2;
    if (curPlatform != platform) {
      return;
    }

    String dateStr = '${newVersion}_${DateTime.now().toString().substring(0, 10)}';
    if (strategy == 1 && GetStorage().read(Security.security_kDidShowUpdateDate) == dateStr) {
      return;
    }

    if (shownUpdateAlert) return;
    shownUpdateAlert = true;
    GetStorage().write(Security.security_kDidShowUpdateDate, dateStr);

    showConfirmAlert(title, content, cancelText: Security.security_cancel, confirmText: Security.security_upgrade, onConfirm: () {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }, onCancel: () {
      if (force == 1) {
        exit(0);
      }
    });  }

  /// RRConfig

  RxMap rpConfig = {}.obs;

  String get rpUrl {
    try {
      Map infos = rpConfig[Security.security_rJumpInfoMap] ?? {};
      if (infos.isEmpty) return '';
      return infos['0'][Security.security_jumpUrl] ?? '';
    } catch (e) {
      return '';
    }
  }

  String get callGiftUrl {
    try {
      Map infos = rpConfig[Security.security_rJumpInfoMap] ?? {};
      if (infos.isEmpty) return '';
      return infos['1'][Security.security_jumpUrl] ?? '';
    } catch (e) {
      return '';
    }
  }

  void queryRPConfig() async {
    ApiResponse rsp = await ApiService.instance.sendRequest(ApiRequest(Apis.security_getROperationalConfig, params: {}));
    if (rsp.isSuccess) {
      rpConfig.value = rsp.data;
      setMap(kRPConfig, rsp.data);
    }
  }

  // bool get needGalleryWhileCreateOC {
  //   return (appConfig['create_oc_with_gallery'] ?? '1') == "1";
  // }

  String get generateVideoPromptHints {
    return appConfig[Security.security_generate_video_tips] ?? Copywriting.security_describe_what_you_want__e_g___A_barista_wipes_the_counter_of_a_small_caf__by_the_river__steam_rising_from_coffee_cups__boats_passing_slowly_outside_the_window__a_cat_napping_on_a_nearby_chair_;
  }

  List get generateVideoPrompts {
    String prompts = appConfig[Security.security_generate_video_prompts] ?? '';
    return prompts.isNotEmpty ? prompts.split('##') : [
      Copywriting.security_sit_by_the_window_with_soft_light_on_your_face__slowly_looking_at_me_,
      Copywriting.security_relax_on_a_couch__one_arm_resting_casually_as_you_smile_,
      Copywriting.security_lean_against_a_wall__arms_loosely_crossed__watching_me_,
      Copywriting.security_sit_at_a_table_with_a_drink_nearby__glancing_up_like_you_noticed_me_,
      Copywriting.security_stretch_slightly_in_your_seat__then_settle_back_comfortably_,
      Copywriting.security_sit_in_a_quiet_room__warm_light_behind_you__calm_and_unhurried_,
      Copywriting.security_rest_your_chin_on_your_hand__looking_at_me_thoughtfully_,
      Copywriting.security_sit_back_in_a_chair__legs_relaxed__eyes_steady_on_me_,
      Copywriting.security_turn_toward_me_slowly__like_I_just_arrived_,
      Copywriting.security_sit_close_to_the_camera__relaxed_and_at_ease_,
      Copywriting.security_sit_by_the_pool_in_a_swimsuit__holding_a_cocktail_and_smiling_,
      Copywriting.security_lounge_on_a_pool_chair__sunglasses_pushed_up_as_you_glance_over_,
      Copywriting.security_stand_near_the_pool__water_reflecting_while_you_take_a_slow_sip_,
      Copywriting.security_sit_at_an_outdoor_caf___one_hand_around_a_glass__relaxed_posture_,
      Copywriting.security_lean_against_a_bar_counter__drink_in_hand__shoulders_loose_,
      Copywriting.security_sit_on_a_balcony_at_night__city_lights_behind_you_,
      Copywriting.security_relax_on_a_sofa_in_the_evening__warm_lights_around_you_,
      Copywriting.security_sit_on_a_terrace__breeze_moving_slightly_as_you_look_over_,
      Copywriting.security_stand_near_a_railing__resting_one_arm_while_watching_quietly_,
      Copywriting.security_sit_in_a_softly_lit_room__body_relaxed__attention_forward_,
      Copywriting.security_brush_a_strand_of_hair_back_gently__eyes_soft_as_you_gaze_straight_at_me_,
      Copywriting.security_rest_one_elbow_on_the_table__fingers_tapping_lightly_as_you_smile_lazily_,
      Copywriting.security_lean_forward_a_little__head_tilted__listening_intently_with_a_calm_expression_,
      Copywriting.security_sit_on_the_edge_of_the_bed__bare_feet_on_the_carpet__looking_relaxed_and_quiet_,
      Copywriting.security_hold_a_book_loosely_in_your_hand__flipping_a_page_slowly_as_you_glance_up_,
      Copywriting.security_stand_by_the_floor_to_ceiling_window__silhouette_against_the_sky__staring_into_the_distance_softly_,
      Copywriting.security_wrap_your_arms_around_your_knees__sitting_curled_up_slightly__eyes_warm_on_me_,
      Copywriting.security_tilt_your_glass_slowly__swirling_the_drink_inside__watching_me_with_a_faint_smile_,
      Copywriting.security_lean_against_a_bookshelf__one_hand_brushing_the_spines__calm_and_unhurried_,
      Copywriting.security_sit_in_a_rattan_chair__rocking_it_gently__body_loose_and_eyes_peaceful_,
      Copywriting.security_stand_in_the_warm_sunlight__closing_your_eyes_briefly__then_opening_them_to_look_at_me_,
      Copywriting.security_rest_your_palms_flat_on_the_table__leaning_back_slightly__breathing_slowly_and_steadily_,
      Copywriting.security_sit_at_a_rooftop_bar__elbows_on_the_railing__looking_out_at_the_night_view_lazily_,
      Copywriting.security_hold_a_cup_of_warm_drink__blowing_on_it_softly_before_taking_a_small_sip_,
      Copywriting.security_lean_against_the_door_frame__one_leg_crossed_casually__smiling_as_you_watch_me_approach_,
      Copywriting.security_sit_on_a_garden_bench__surrounded_by_faint_floral_scent__hands_resting_on_the_sides_quietly_,
      Copywriting.security_stretch_your_arms_overhead_lazily__then_drop_them_down__slumping_comfortably_in_the_chair_,
      Copywriting.security_twist_the_ring_on_your_finger_gently__eyes_thoughtful_as_you_fix_your_gaze_on_me_,
      Copywriting.security_stand_in_a_dimly_lit_hallway__light_outlining_your_figure__looking_at_me_calmly_,
      Copywriting.security_rest_your_head_back_against_the_cushion__eyes_half_closed__relaxed_and_unguarded_
    ];
  }
}
