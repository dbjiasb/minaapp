import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/api_service/api_service_export.dart';
import 'package:biz/base/buffer_queue/buffer_queue.dart';

class SendGiftData {
  int giftId = 0;
  int giftCount = 1;
  int recipient = 0;
  int receiverStatus = 0;
  int currencyType = 0;
  int balance = 0;
}

class SendGiftResponse {
  bool isSuccess = true;
  int giftId = 0;
  int balance = 0;
  int currencyType = 0;
  String errorMsg = '';
}

class GiftManager {
  //生成单利
  static final GiftManager _instance = GiftManager._internal();

  factory GiftManager() => _instance;

  GiftManager._internal();

  static GiftManager get instance => _instance;

  BufferQueue cache = BufferQueue(10);

  Future<ApiResponse> queryGifts(int recipient) async {
    ApiResponse? value = cache.getObject(recipient);
    if (value != null) {
      return value;
    }

    ApiRequest request = ApiRequest(Apis.security_queryPropList, params: {Security.security_targetUid: recipient});

    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      cache.setObject(recipient, response);
    }

    return response;
  }

  Future<SendGiftResponse> sendGift(SendGiftData data) async {
    ApiRequest request = ApiRequest(
      Apis.security_sendGift,
      params: {
        Security.security_toUserId: data.recipient,
        Security.security_giftId: data.giftId,
        Security.security_giftCount: data.giftCount,
        Security.security_targetAccountStatus: data.receiverStatus,
      },
    );

    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      SendGiftResponse result = SendGiftResponse();
      result.isSuccess = true;
      result.giftId = data.giftId;
      result.balance = response.data[Security.security_balance];
      result.currencyType = data.currencyType;
      return result;
    } else {
      SendGiftResponse result = SendGiftResponse();
      result.isSuccess = false;
      result.errorMsg = response.data[Security.security_statusInfo]?[Security.security_msg] ?? Copywriting.security_failed_to_send_gift;
      result.currencyType = data.currencyType;
      result.balance = data.balance;
      result.giftId = data.giftId;
      return result;
    }
  }
}
