import '../../base/api_service/api_config.dart';
import '../../base/app_info/app_manager.dart';

class EAiAuditStatus
{
  static const int AUDITING = 0;
  static const int PASS = 1;
  static const int NOT_PASS = 2;
}

class EMomentResType
{
  static const int IMAGE = 1;
  static const int VIDEO = 2;
}

class EShareState
{
  static const int PRIVATE = 0;
  static const int SHARED = 1;
}


class EMomentListType
{
  static const int MOMENT_LIST_RECOMMEND = 0;
  static const int MOMENT_LIST_FOLLOWED = 1;
  static const int MOMENT_LIST_USER = 2;
  static const int MOMENT_LIST_COLLECT = 3;
}

class ECreationType
{
  static const int IMAGE = 1;
  static const int VIDEO = 2;
}

class ECollectType
{
  static const int IMAGE = 1;
  static const int VIDEO = 2;
  static const int MOMENT = 3;
}

class ECurrencyType
{
  static const int COINS = 0;
  static const int GEMS = 1;
  static const int POINTS = 2;
  static const int POINTS_TRACE = 3;
  static const int GAME_COINS = 4;
  static const int PREMIUM = 5;
  static const int DOLLARS = 6;
  static const int VIDEO = 7;
  static const int BAI_SHUN_COINS = 8;
  static const int FREE_AI_AUDIO = 9;
  static const int FREE_MATCH_CARD = 10;
}

class MomentRes {
  static String base = '${ApiConfig.cdnApp}moment/';
}

