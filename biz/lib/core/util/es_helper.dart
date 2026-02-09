import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';

import '../../base/app_info/app_manager.dart';

typedef EncHelper = Dic;

class Dic {
  static String get id => Security.security_id;

  static String get nm => Security.security_name;

  static String get avt => Security.security_avatar;

  static String get bgurl => Security.security_backgroundurl;

  ///upload
  static String get upl_tcKey => Security.security_ossFileKey; //costAmount
  static String get upl_tcUrl => Security.security_cdnFileUrl; //costCurrency

  static String get upl_tcId => Security.security_accessKeyId;

  static String get upl_tcSecret => Security.security_accessKeySecret;

  static String get upl_tcBucket => Security.security_bucketName;

  static String get upl_tcST => Security.security_securityToken;

  /// person info
  static String get ps_usif => Security.security_userInfo;

  static String get ps_bsif => Security.security_baseInfo;

  static String get ps_avturl => Security.security_avatarUrl;

  static String get ps_bg => Security.security_chatBackground;

  static String get ps_nn => Security.security_nickName;

  static String get ps_uid => Security.security_uid;

  static String get ps_fsc => Security.security_fansCount;

  static String get ps_foloc => Security.security_followCount;

  static String get ps_gdr => Security.security_gender;

  static String get ps_bfda => Security.security_birthday;

  static String get ps_ag => Security.security_age;

  static String get ps_cstat => Security.security_constellation;

  static String get ps_lct => Security.security_location;

  static String get ps_educat => Security.security_educations;

  static String get ps_bo => Security.security_bio;

  static String get ps_str => Security.security_star;

  static String get ps_act => Security.security_accountType;

  static String get psid => Security.security_personId;

  static String get ps_if => Security.security_personInfo;

  static String get ps_cvurl => Security.security_coverUrl;

  // /// chat
  // static String get exCon => Security.security_extraContent;
  //
  //
  // /// JS relate
  // static String get returnJSMethod => Security.security_receiveMessage; ///receiveMessage
  //
  /// Create
  static String get cr_pesi => Security.security_Pessimistic; //Pessimistic
  static String get cr_cfg => Security.security_configItemMap; //configItemMap
  static String get cr_dis_cfg => Security.security_displayConfig; //displayConfig
  static String get cr_apr => Security.security_appearance; //appearance
  static String get cr_exim => Security.security_expandItems; //expandItems
  static String get cr_tbs => Security.security_tagBgList; //tagBgList
  static String get cr_eurl => Security.security_exampleUrl; //exampleUrl
  // static String get cr_tvid => Security.security_ttsVid; //ttsVid
  static String get cr_tcfg => Security.security_ttsConfig; //ttsConfig
  static String get cr_piurl => Security.security_personalImageurl; //personalImageurl
  static String get cr_alts => Security.security_dialogueStyle; //dialogueStyle
  static String get cr_fields => Security.security_foldItems; //foldItems
  static String get cr_ownern => Security.security_masterName; //masterName
  static String get cr_imgpm => Security.security_imagePrompts; //imagePrompts
  static String get cr_bio => Security.security_introduction; //introduction
  static String get cr_caa => Copywriting.security_click_to_add; //Click to add
  static String get cr_cusri => Security.security_customRoleInfo; //customRoleInfo
  static String get cr_posinf => Security.security_positionInfo; //positionInfo
  static String get cr_defval2 => Security.security_defaultValueV2; //defaultValueV2
  static String get cr_img_prp => Copywriting.security_image_Prompt; //Image Prompt
  // static String get cr_synopsis => Security.security_Scenario; //Scenario
  static String get cr_dl_sl => Copywriting.security_dialogue_Style; //Dialogue Style

  // API 接口（每个单词插入不同混淆词）
  static String get cr_fod => Security.security_queryOcDraft; // queryOcDraft
  static String get cr_fpd => Security.security_queryPhysiqueDetails; // queryPhysiqueDetails
  static String get cr_ckpic => Security.security_checkPic; // checkPic
  static String get cr_opr => Security.security_operateOc; // operateOc = customRole
  static String get cr_askgen => Security.security_requestGen; // requestGen
  static String get cr_ask_gen_rsp => Security.security_requestGenResult; // requestGenResult
  static String get cr_fed => Security.security_queryEditInfo; // queryEditInfo

  // 参数映射（每个单词插入不同混淆词）
  static String get cr_img_url => Security.security_picUrl; // picUrl
  static String get cr_ro_in => Security.security_ocData; // ocData
  static String get cr_cr_code => Security.security_opCode; // opCode
  static String get cr_imgs => Security.security_pics; // pics
  static String get cr_rl_id => Security.security_replaceId; // replaceId
  static String get cr_cre_code => Security.security_genCode; // genCode
  static String get cr_cre_id => Security.security_genId; // genId
  static String get cr_cccid => Security.security_cid; // cid

  ///account view
  static String get ac_uid => Security.security_uid; // uid
  static String get ac_nn => Security.security_nickname; // nickname
  static String get ac_avt => Security.security_avatarUrl; // avatarUrl
  static String get ac_cvu => Security.security_coverUrl; // coverUrl

  // UI Texts
  static String get rcg_titlCois => Security.security_Coins; // Coins
  static String get rcg_titlGms => Security.security_Gems; // Gems
  static String get rcg_coiBalns => Copywriting.security_coin_balance; // Coin balance
  static String get rcg_gmBalns => Copywriting.security_gem_balance; // Gem balance
  static String get rcg_btnRcg => Security.security_Recharge; // Recharge
  static String get rcg_btnSubs => Security.security_Subscribe; // Subscribe
  static String get rcg_fuAces => Copywriting.security_get_full_access_; // Get full access!
  static String get rcg_expOn => Copywriting.security_expires_on; // Expires on
  static String get rcg_err => Security.security_error; // error
  static String get rcg_prc => Security.security_price; // price
  static String get rcg_rcg => Security.security_Recharge; // Recharge
  static String get rcg_nm => Security.security_name; // name
  static String get rcg_chnlInfo => Security.security_channelInfo; // channelInfo
  static String get rcg_adrCnnl => '2'; // 2
  static String get rcg_iosChnnl => '3'; // 3
  static String get rcg_inapId => Security.security_inAppProductId; // inAppProductId
  static String get rcg_ov => Security.security_originalValue; // originalValue
  static String get rcg_dsct => Security.security_discount; // discount

  // Arhs
  static String get rcg_rcgItm => Security.security_rechargeItem; // rechargeItem
  static String get rcg_rcgTyp => Security.security_rcgType; // rechargeType
  static String get rcg_id => Security.security_id; // id
  static String get rcg_valu => Security.security_value; // value
  static String get rcg_ppt => Security.security_premiumPeriodType; // premiumPeriodType
  static String get rcg_bdesc => Security.security_benefitsDesc; // benefitsDesc
  static String get rcg_titl => Security.security_title; // title
  static String get rcg_url => Security.security_url; // url
  static String get rcg_cfg => Security.security_config; // config

  // Apis
  static String get rcg_apiGPV2 => Security.security_getPremiumInfoV2; // getPremiumInfoV2

  // Legal Texts
  static String get rcg_trmNotic =>
      Copywriting
          .security_by_clicking_Security_security_Subscribe__you_will_be_charged__and_your_subscription_will_automatically_renew_at_the_same_price_and_duration_until_canceled_through_PlayStore_settings__By_proceeding__you_agree_to_our_terms_;

  static String get rcg_trms => Copywriting.security_terms_of_Service; // Terms of Service
  static String get rcg_privacy => Copywriting.security_privacy_Policy; // Privacy Policy

  // Error Messages
  static String get rcg_errLoData => Copywriting.security_failed_to_load_subscription_data; // Failed to load subscription data
  static String get rcg_errSeleProd => Copywriting.security_please_select_a_product_to_recharge_; // Please select a product to recharge.
  static String get rcg_prchasDon => Copywriting.security_purchase_done; // Purchase done
  static String get rcg_errSrvic =>
      Copywriting.security_unable_to_get_recharge_service__please_retry_later_; // Unable to get recharge service, please retry later.
  static String get rcg_errPlafm => Copywriting.security_platform_not_supported_; // Platform not supported.
  static String get rcg_errRcg => Copywriting.security_recharge_failed_; // Recharge failed.
  static String get rcg_errSubs =>
      Copywriting.security_failed_to_process_subscription__please_try_again_later_; // Failed to process subscription, please try again later.

  // URLs
  static String get rcg_urlTrms => AppManager.instance.termsHtml;

  static String get rcg_urlPrivacy => AppManager.instance.privacyHtml;

  // IAP Products
  static String get rcg_iapWekly => '';

  static String get rcg_iapMthly => '';

  static String get rcg_iapYrly => '';

  static List get rcg_coiProds => [
    {Security.security_id: 'com.soulink.aibot.coin_1.99', Security.security_price: '\$1.99', Security.security_value: 200},
    {Security.security_id: 'com.soulink.aibot.coin_9.99', Security.security_price: '\$9.99', Security.security_value: 1000},
    {Security.security_id: 'com.soulink.aibot.coin_19.99', Security.security_price: '\$19.99', Security.security_value: 2000},
    {Security.security_id: 'com.soulink.aibot.coin_59.99', Security.security_price: '\$59.99', Security.security_value: 6000},
  ];

  static List get rcg_gmProds => [
    {Security.security_id: 'com.soulink.aibot.gems_9.99', Security.security_price: '\$9.99', Security.security_value: 80},
    {Security.security_id: 'com.soulink.aibot.gems_19.99', Security.security_price: '\$19.99', Security.security_value: 160},
    {Security.security_id: 'com.soulink.aibot.gems_59.99', Security.security_price: '\$59.99', Security.security_value: 480},
  ];

  // Helper Methods
  static String rcg_savPct(int pct) => 'Save $pct%';

  static String rcg_dailyPrc(double price) => '\$$price/day';

  static String rcg_geRcgBalns(int rcgType) => rcgType == 0 ? rcg_coiBalns : rcg_gmBalns;
}
