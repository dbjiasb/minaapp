import 'decrypt.dart';
/// Apis 安全相关字符串常量（运行时解密）
abstract final class Apis {
  Apis._();
  static late final String security_convertContentToVoice = decrypt('8PLjYNXFUrTsqsjv62yeOzH/YLdVkKrSp+0JbulN+JM=');
  static late final String security_deblockingMessage = decrypt('YqstYPhdkC7PItKpYzv8CSDRCu2YEXlz40Pf49h6Pqg=');
  static late final String security_deleteAccount = decrypt('yFGlRUUBWmqZaiyLdIRuIA==');
  static late final String security_dial = decrypt('F1eSuwIKuWmzDys+gTE/pA==');
  static late final String security_endCall = decrypt('j5IgYo2EMQ3AknbgTSPaaw==');
  static late final String security_fetchBalance = decrypt('bTFBU++xSgOXP0Ipyr9GnQ==');
  static late final String security_fetchTipOffOptions = decrypt('xpYrRkjeH25YaN4Zdj7ZwPaR/k3zycxWdHcTsl4H+04=');
  static late final String security_fetchUserData = decrypt('jEtu9jijGMJOzj4TyTocAg==');
  static late final String security_fetchUsers = decrypt('dBYtKPBILaPzxWN6MSLRXQ==');
  static late final String security_fetchVerificationCode = decrypt('FF/ShYO7U41NBTQRwRxJEvq7x+3Kz48/xheLCC20eHo=');
  static late final String security_fullConfirmPurchase = decrypt('r6tih6WK7ABpx2jmcx54tK7Iq8TTtAIUIkpHOcneOyQ=');
  static late final String security_generateImage = decrypt('I/2wwmd9QDXcrzHVbyudTw==');
  static late final String security_giveUp = decrypt('y3FPCWqgpQXGy/VxSJhdiA==');
  static late final String security_obtainCosConfig = decrypt('qIzGfxXLRj861YiwR54eCw==');
  static late final String security_queryInspirationWords = decrypt('uaoXixsrBpn3bb5Oa/DulbBp8np8T2TKbhDjm6ao0Z4=');
  static late final String security_queryMyPremiumInfo = decrypt('9KgQy9khZN9chE8WUTg3/KLCdU0ahiJ69b6BGX0MhF8=');
  static late final String security_queryPhotoPrompts = decrypt('JCreIa8HZ9cT372XQwVxiJUfKdNIowp733vfggCBoNM=');
  static late final String security_queryPropList = decrypt('2XVrEBoIn9UL9eJmhGvnow==');
  static late final String security_replaceMsg = decrypt('lj1BGZUeivAQM/M177nOBw==');
  static late final String security_sayHello = decrypt('s3VFQZ5SII2Lv0/SbuyLFg==');
  static late final String security_sendChatMsg = decrypt('99yQBKlx8j8HjlhrZXmYwg==');
  static late final String security_sendData = decrypt('bJXuxgiU/sCcSQa9lU7BxA==');
  static late final String security_sendGift = decrypt('H+vXc9SEohlcR3wvQT5W7A==');
  static late final String security_signIn = decrypt('aoJn5/nBQcr1FsukGG7yTQ==');
  static late final String security_star = decrypt('b0bnmhjXCwrbhWRFjNU3IA==');
  static late final String security_syncChatHistory = decrypt('1jI0D7JNf0YnikSWAvNxRg==');
  static late final String security_tipOffUser = decrypt('BWVFUc77bJQxQ45hQ6nlNA==');
  static late final String security_updateUserInfo = decrypt('K2Ugzki8NhQDW8JLo4ykMg==');
  static late final String security_answer = decrypt('GpEweQNZkkwLVWxeClt8cQ=='); // answer
  static late final String security_getUserStarList = decrypt('28GWDHsZlZ2Usctsti/BFg=='); // getUserStarList
  static late final String security_reject = decrypt('CJyE5tly0WP+ePxXzY+uKw=='); // reject
  static late final String security_acquireAppConfig = decrypt('CAf7vhF6CoM6Pis17CG5yzLiqg8bmhPh0RYabymJ76A='); // acquireAppConfig
  static late final String security_getSystemNoticeHistory = decrypt('c4hADydMf9ZhbhqY9fg8K/ejtpWYMExTXeLXCuyEfZY='); // getSystemNoticeHistory
  static late final String security_getUserInfo = decrypt('X66GmfhRzO7e8aqcoL71+A=='); // getUserInfo
  static late final String security_getMediaFree = decrypt('n+8yPTtcZz/OZEYRyWq9DQ=='); // getMediaFree
  static late final String security_getAdConfig = decrypt('MoIKG4u4TPaT2B6hkosYVA=='); // getAdConfig
  static late final String security_getBalanceAdAward = decrypt('0e6eLxRaaBbUmbjfoAgxYMLBjI9bBreHzVqRuKxLOgs='); // getBalanceAdAward
  static late final String security_getRechargeItemV2 = decrypt('kk3NrW08Kq8jDEU3xp/X4rckNCVWBxC21VB3rr+kcjk='); // getRechargeItemV2
  static late final String security_grantAdAward = decrypt('WSKNjo1P6CEnKuZXwzkoug=='); // grantAdAward
  static late final String security_recharge = decrypt('cNmdipyMmqO70ANGb2FwAw=='); // recharge
  static late final String security_rechargeCallback = decrypt('cgSdIPCHTmBAg/uJf/Mx12viC0nf21b3iY42MKfg+6Y='); // rechargeCallback
  static late final String security_aiResetMsg = decrypt('+wdk+8xE/h3GkSjdZLd2SQ=='); // aiResetMsg
  static late final String security_batchDeleteUserMsg = decrypt('EUezEM8GggKYsBSnWWwrnj1ZMyM7LnbcSkYqHpmHqlY='); // batchDeleteUserMsg
  static late final String security_choseLangTranslateText = decrypt('66nbfX6hDVnpkjpQNL21xuBcd+YUa6SyGRFrWX1Kgts='); // choseLangTranslateText
  static late final String security_deleteSession = decrypt('n9qGPfdqPrCQNMRKeTELVA=='); // deleteSession
  static late final String security_getChatModelList = decrypt('f4qkgPMh6tn/J69CAUNucVbyclZuA230AJz11rb99nA='); // getChatModelList
  static late final String security_getGroupConfig = decrypt('G4VVWHA6qvlXL+cGz7+QDQ=='); // getGroupConfig
  static late final String security_getUserSettings = decrypt('2rJG79+JWCcDc+V4g1gccg=='); // getUserSettings
  static late final String security_resetAiModel = decrypt('iXFsIwvMJVrS063hD4KsYQ=='); // resetAiModel
  static late final String security_slidePendingList = decrypt('7+dsjya7eihvDGuGVaGBewG+6IRcY9RBlcqWd6sm9xw='); // slidePendingList
  static late final String security_switchChatModel = decrypt('e06LpYO6BSuB+uvpkW8KNw=='); // switchChatModel
  static late final String security_updateUserSettings = decrypt('zcQYcvVxm+0zaqZxwTmLVzU1YiAHIkKoUOeCS2KX3tg='); // updateUserSettings
  static late final String security_registerFcmPushToken = decrypt('RUhYQzdyX12st7ppdX7zr76KMoAlFiVdq9BtJwCqSzM='); // registerFcmPushToken
  static late final String security_chatScriptAction = decrypt('HzWJn/NgDKFLksFLzwuNgntvF7cv0iikh/eyiz1JtzU='); // chatScriptAction
  static late final String security_createGroup = decrypt('hU/5AdgwHBiak5TAEq4S3w=='); // createGroup
  static late final String security_disbandGroup = decrypt('2XpOC1aV6SdeGhoWcmMkgw=='); // disbandGroup
  static late final String security_getCharacterSelectList = decrypt('SJxY2U6IJe4HySd1geJR7tU6U9LVVKl8a2u5GjMM/0w='); // getCharacterSelectList
  static late final String security_getChatScript = decrypt('edmifAXP6mdglmdN/Lw+OA=='); // getChatScript
  static late final String security_getGroupInfo = decrypt('CiRNDI0svzCRpcSJXJaWUg=='); // getGroupInfo
  static late final String security_getGroupList = decrypt('QRshXUz24rCsTWeuPO2QwQ=='); // getGroupList
  static late final String security_searchUser = decrypt('3PKcGRoXlbIwklOs0YXqzA=='); // searchUser
  static late final String security_updateGroupInfo = decrypt('dCnARzkxLMgf2lixpsSh9w=='); // updateGroupInfo
  static late final String security_aiContinueToSendMsg = decrypt('AD9EN/VK4LqJ5/i8K/wPXz/5HAdBTT+qt97fdB5TX/A='); // aiContinueToSendMsg
  static late final String security_deleteCustomRole = decrypt('Yk9BRqjidYOwam+RuAXNqyNapvtEwxRD/pNj1XEPQC4='); // deleteCustomRole
  static late final String security_blockUserAction = decrypt('YNmhuA44CPk7lmiagY9M8w=='); // blockUserAction
  static late final String security_getUserMoreSettings = decrypt('gTV0uiZ4KWZD0P7l0YUMmV67WGoP/tfROv3Er5yU7bw='); // getUserMoreSettings
  static late final String security_generateCustomRoleTemplate = decrypt('Qg0+9oBBK/mxsvw69xfXQ/9OeL888FgJDrBpKfAxEU0='); // generateCustomRoleTemplate
  static late final String security_getROperationalConfig = decrypt('4FciJcjIjulkWZ7Cmvw3Br0F5TZ2sHE4OS8GyclYf+Y='); // getROperationalConfig
  static late final String security_getUserRedPointCount = decrypt('VXTIdDDRMvw+RzUTBmIrVXk+6/Y/1XOJ1d6LD+XSKA4='); // getUserRedPointCount
  static late final String security_followUserAction = decrypt('fBXJq+3xaSVem32eLq0jEXbCTAFs1l7Sr/6tEE9OWvI='); // followUserAction
  static late final String security_getUserRelationList = decrypt('EKxOAeDCL/ZImliKXrQXFOLdrIZgiLMz0uAUjuPcbBA='); // getUserRelationList
  static late final String security_cancelVideoCallMatch = decrypt('AdJt15vcm9wdE9WL31/27SMqt4HKmYBr26sPm8qy+PY='); // cancelVideoCallMatch
  static late final String security_collectAction = decrypt('hbYRizSdHoln+am6XKS7VQ=='); // collectAction
  static late final String security_commentMoment = decrypt('4STQjwXnPEZ3s2a5BrFfbQ=='); // commentMoment
  static late final String security_confirmVideoCallMatchResult = decrypt('B38HNyZ1jNFrjGu7mv1Cgh8+ae6cHZCez86OyPXQv3U='); // confirmVideoCallMatchResult
  static late final String security_createMoment = decrypt('F6qMFcs3KuCu74EwXWE4lA=='); // createMoment
  static late final String security_createResource = decrypt('XNbzppfzd9XhRpvyC8MR/A=='); // createResource
  static late final String security_deleteMoment = decrypt('zXbQfNZEkDOjzEtW1wB2Bg=='); // deleteMoment
  static late final String security_generatePostContent = decrypt('Sfci2ibuaN8q/GQd7JSAQtr1DumGfXQsym6uDGt++qs='); // generatePostContent
  static late final String security_generateVideoV2 = decrypt('e4Q0djXfiyue8cqWelAnlQ=='); // generateVideoV2
  static late final String security_getCollectStatus = decrypt('SiohvExKNSts5aTz96YfsS9Zf3AvYbrfdvUXtgKO0gw='); // getCollectStatus
  static late final String security_getCreationResourceConfig = decrypt('F8bOfHcfR1w6Da8GH8wH/uIy93aZMrwNUCK748s/sVo='); // getCreationResourceConfig
  static late final String security_getGenerateVideoConfig = decrypt('1nKk5SMv//OXZIXaVHYt0EjvHADR/PqIGU7o6RtM+6U='); // getGenerateVideoConfig
  static late final String security_getMainUserList = decrypt('9jPPqYft3tkvE0WKRLHv+g=='); // getMainUserList
  static late final String security_getMatchTaskProcess = decrypt('Xmn5QeSZfsJvEWsOKNaTNStNsg92EDV6jsMlGBltAmg='); // getMatchTaskProcess
  static late final String security_getMomentDetail = decrypt('GfI+W9In6ZrfmA0TvtGg3Q=='); // getMomentDetail
  static late final String security_getMomentInfoList = decrypt('MWrwyJhj0m4D3VLimCgtJI/d+Mk1XAV/IxXHzd9+ehU='); // getMomentInfoList
  static late final String security_getReportConfig = decrypt('f0IndtuCO7i1/rg85wAWHA=='); // getReportConfig
  static late final String security_getTagConfig = decrypt('bYYOiOtKc7yNH0DKm+gVgQ=='); // getTagConfig
  static late final String security_getUserCreationRecord = decrypt('mJOZv4FzXobHWJ7fku5+PVTiEk6AJUnehYA7FQfqeHw='); // getUserCreationRecord
  static late final String security_getVideoCallMatchConfig = decrypt('8lFhYFRUH4v6WXzHrHeK781KtoIUFsjRXWNt968qFAg='); // getVideoCallMatchConfig
  static late final String security_getVideoCallMatchInfo = decrypt('8lFhYFRUH4v6WXzHrHeK71I7N/HxpNbfuzL30VBb8GA='); // getVideoCallMatchInfo
  static late final String security_likeMomentAction = decrypt('3Q3VVU1mz1AavqxKgFOH08rknXwwBze1xo/F2DiuYGU='); // likeMomentAction
  static late final String security_reloadCreationResource = decrypt('iGtCYLUMjivU0bZuFw+FKUk1QUwHAHNKbfcB2huuh8E='); // reloadCreationResource
  static late final String security_report = decrypt('mhkR92UAc5Oi1QqNkutJiA=='); // report
  static late final String security_rightSlideList = decrypt('XS01TnUcGU8kMvSkeMjiiA=='); // rightSlideList
  static late final String security_slideLet = decrypt('1cehIy8xEmS+QnWIfppaGg=='); // slideLet
  static late final String security_slideRight = decrypt('uGKas5RMj2Fil/p1dkebVw=='); // slideRight
  static late final String security_startVideoCallMatch = decrypt('iwecVbdb0G5G1JKUb0t71gEfjFozVp7aPKK2lM9Ujqo='); // startVideoCallMatch
  static late final String security_getMsgDetail = decrypt('Lv9z2gmDLyj27Kshsk/v1w=='); // getMsgDetail
}