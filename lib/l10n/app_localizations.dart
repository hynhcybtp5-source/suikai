import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';
import 'app_localizations_shn.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my'),
    Locale('shn'),
    Locale('th'),
  ];

  /// No description provided for @tagline.
  ///
  /// In th, this message translates to:
  /// **'ซื้อขายง่าย ใกล้คุณ'**
  String get tagline;

  /// No description provided for @priceRange.
  ///
  /// In th, this message translates to:
  /// **'ช่วงวงเงินที่ต้องการหา'**
  String get priceRange;

  /// No description provided for @all.
  ///
  /// In th, this message translates to:
  /// **'ทั้งหมด'**
  String get all;

  /// No description provided for @latestListings.
  ///
  /// In th, this message translates to:
  /// **'ประกาศล่าสุด'**
  String get latestListings;

  /// No description provided for @viewAllProducts.
  ///
  /// In th, this message translates to:
  /// **'ดูสินค้าทั้งหมด  ›'**
  String get viewAllProducts;

  /// No description provided for @advertisement.
  ///
  /// In th, this message translates to:
  /// **'พื้นที่โฆษณา'**
  String get advertisement;

  /// No description provided for @featuredPromotions.
  ///
  /// In th, this message translates to:
  /// **'โปรโมชันและร้านค้าแนะนำ'**
  String get featuredPromotions;

  /// No description provided for @home.
  ///
  /// In th, this message translates to:
  /// **'หน้าแรก'**
  String get home;

  /// No description provided for @search.
  ///
  /// In th, this message translates to:
  /// **'ค้นหา'**
  String get search;

  /// No description provided for @stores.
  ///
  /// In th, this message translates to:
  /// **'ร้านค้า'**
  String get stores;

  /// No description provided for @post.
  ///
  /// In th, this message translates to:
  /// **'ลงประกาศ'**
  String get post;

  /// No description provided for @map.
  ///
  /// In th, this message translates to:
  /// **'แผนที่'**
  String get map;

  /// No description provided for @profile.
  ///
  /// In th, this message translates to:
  /// **'จัดการของฉัน'**
  String get profile;

  /// No description provided for @available.
  ///
  /// In th, this message translates to:
  /// **'พร้อมขาย'**
  String get available;

  /// No description provided for @reserved.
  ///
  /// In th, this message translates to:
  /// **'จอง'**
  String get reserved;

  /// No description provided for @sold.
  ///
  /// In th, this message translates to:
  /// **'ขายแล้ว'**
  String get sold;

  /// No description provided for @openStore.
  ///
  /// In th, this message translates to:
  /// **'เปิดร้าน'**
  String get openStore;

  /// No description provided for @storeInfo.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลร้านค้า'**
  String get storeInfo;

  /// No description provided for @contactInfo.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลติดต่อ'**
  String get contactInfo;

  /// No description provided for @storeAddress.
  ///
  /// In th, this message translates to:
  /// **'ที่อยู่ร้านค้า'**
  String get storeAddress;

  /// No description provided for @confirm.
  ///
  /// In th, this message translates to:
  /// **'ยืนยัน'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In th, this message translates to:
  /// **'ย้อนกลับ'**
  String get back;

  /// No description provided for @next.
  ///
  /// In th, this message translates to:
  /// **'ถัดไป'**
  String get next;

  /// No description provided for @price.
  ///
  /// In th, this message translates to:
  /// **'ราคา'**
  String get price;

  /// No description provided for @category.
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get category;

  /// No description provided for @location.
  ///
  /// In th, this message translates to:
  /// **'ตำแหน่ง'**
  String get location;

  /// No description provided for @call.
  ///
  /// In th, this message translates to:
  /// **'โทร'**
  String get call;

  /// No description provided for @viber.
  ///
  /// In th, this message translates to:
  /// **'Viber'**
  String get viber;

  /// No description provided for @save.
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In th, this message translates to:
  /// **'แก้ไข'**
  String get edit;

  /// No description provided for @outOfStock.
  ///
  /// In th, this message translates to:
  /// **'สินค้าหมด'**
  String get outOfStock;

  /// No description provided for @deleted.
  ///
  /// In th, this message translates to:
  /// **'ลบแล้ว'**
  String get deleted;

  /// No description provided for @addStoreProduct.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มสินค้าเข้าร้าน'**
  String get addStoreProduct;

  /// No description provided for @productImages.
  ///
  /// In th, this message translates to:
  /// **'รูปสินค้า'**
  String get productImages;

  /// No description provided for @firstImageIsMain.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มได้สูงสุด 5 รูป รูปแรกเป็นรูปหลัก'**
  String get firstImageIsMain;

  /// No description provided for @addImage.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มรูป'**
  String get addImage;

  /// No description provided for @mainImage.
  ///
  /// In th, this message translates to:
  /// **'รูปหลัก'**
  String get mainImage;

  /// No description provided for @productNameRequired.
  ///
  /// In th, this message translates to:
  /// **'ชื่อสินค้า *'**
  String get productNameRequired;

  /// No description provided for @productNameValidation.
  ///
  /// In th, this message translates to:
  /// **'กรุณาใส่ชื่อสินค้า'**
  String get productNameValidation;

  /// No description provided for @productDescriptionOptional.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียดสินค้า (ไม่บังคับ)'**
  String get productDescriptionOptional;

  /// No description provided for @priceRequired.
  ///
  /// In th, this message translates to:
  /// **'ราคา *'**
  String get priceRequired;

  /// No description provided for @priceValidation.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกราคาที่ถูกต้อง'**
  String get priceValidation;

  /// No description provided for @currency.
  ///
  /// In th, this message translates to:
  /// **'สกุลเงิน'**
  String get currency;

  /// No description provided for @productStatus.
  ///
  /// In th, this message translates to:
  /// **'สถานะสินค้า'**
  String get productStatus;

  /// No description provided for @saving.
  ///
  /// In th, this message translates to:
  /// **'กำลังบันทึก...'**
  String get saving;

  /// No description provided for @imageValidation.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเพิ่มรูปสินค้าอย่างน้อย 1 รูป'**
  String get imageValidation;

  /// No description provided for @justPosted.
  ///
  /// In th, this message translates to:
  /// **'เพิ่งลงประกาศ'**
  String get justPosted;

  /// No description provided for @saveFailed.
  ///
  /// In th, this message translates to:
  /// **'บันทึกไม่สำเร็จ กรุณาลองใหม่'**
  String get saveFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my', 'shn', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
    case 'shn':
      return AppLocalizationsShn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
