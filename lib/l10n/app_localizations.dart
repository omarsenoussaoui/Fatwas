import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'فتاوى الشيخ بن حنيفية زين العابدين'**
  String get appTitle;

  /// No description provided for @sheikhName.
  ///
  /// In ar, this message translates to:
  /// **'الشيخ بن حنيفية زين العابدين'**
  String get sheikhName;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @upload.
  ///
  /// In ar, this message translates to:
  /// **'رفع الملفات'**
  String get upload;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @uploadFiles.
  ///
  /// In ar, this message translates to:
  /// **'رفع ملفات صوتية'**
  String get uploadFiles;

  /// No description provided for @selectAudioFiles.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الملفات الصوتية'**
  String get selectAudioFiles;

  /// No description provided for @selectFiles.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الملفات'**
  String get selectFiles;

  /// No description provided for @transcribe.
  ///
  /// In ar, this message translates to:
  /// **'تحويل إلى نص'**
  String get transcribe;

  /// No description provided for @transcribing.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحويل...'**
  String get transcribing;

  /// No description provided for @download.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get download;

  /// No description provided for @downloadAll.
  ///
  /// In ar, this message translates to:
  /// **'تحميل الكل'**
  String get downloadAll;

  /// No description provided for @downloadDocx.
  ///
  /// In ar, this message translates to:
  /// **'تحميل DOCX'**
  String get downloadDocx;

  /// No description provided for @downloadPdf.
  ///
  /// In ar, this message translates to:
  /// **'تحميل PDF'**
  String get downloadPdf;

  /// No description provided for @clearAll.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get clearAll;

  /// No description provided for @clearAllConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من مسح جميع الفتاوى؟'**
  String get clearAllConfirm;

  /// No description provided for @clearAllDescription.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف جميع الفتاوى نهائياً'**
  String get clearAllDescription;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذه الفتوى؟'**
  String get deleteConfirm;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @fatwaNumber.
  ///
  /// In ar, this message translates to:
  /// **'فتوى رقم {number}'**
  String fatwaNumber(int number);

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @author.
  ///
  /// In ar, this message translates to:
  /// **'المؤلف'**
  String get author;

  /// No description provided for @noFatwas.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فتاوى بعد'**
  String get noFatwas;

  /// No description provided for @noFatwasDescription.
  ///
  /// In ar, this message translates to:
  /// **'ارفع ملفات صوتية لبدء التحويل'**
  String get noFatwasDescription;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'في الانتظار'**
  String get pending;

  /// No description provided for @transcribingStatus.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحويل'**
  String get transcribingStatus;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get done;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @apiKey.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح Groq API'**
  String get apiKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مفتاح Groq API'**
  String get apiKeyHint;

  /// No description provided for @testKey.
  ///
  /// In ar, this message translates to:
  /// **'اختبار المفتاح'**
  String get testKey;

  /// No description provided for @testKeySuccess.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح صالح ✓'**
  String get testKeySuccess;

  /// No description provided for @testKeyFailed.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح غير صالح ✗'**
  String get testKeyFailed;

  /// No description provided for @testingKey.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاختبار...'**
  String get testingKey;

  /// No description provided for @usingDefaultKey.
  ///
  /// In ar, this message translates to:
  /// **'يتم استخدام المفتاح الافتراضي'**
  String get usingDefaultKey;

  /// No description provided for @usingCustomKey.
  ///
  /// In ar, this message translates to:
  /// **'يتم استخدام مفتاح مخصص'**
  String get usingCustomKey;

  /// No description provided for @resetToDefault.
  ///
  /// In ar, this message translates to:
  /// **'إعادة للافتراضي'**
  String get resetToDefault;

  /// No description provided for @filesSelected.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملفات محددة'**
  String filesSelected(int count);

  /// No description provided for @transcriptionComplete.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل التحويل'**
  String get transcriptionComplete;

  /// No description provided for @transcriptionFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحويل'**
  String get transcriptionFailed;

  /// No description provided for @exportSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التصدير بنجاح'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التصدير'**
  String get exportFailed;

  /// No description provided for @noApiKey.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال مفتاح API في الإعدادات'**
  String get noApiKey;

  /// No description provided for @fileLimitWarning.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك اختيار من 1 إلى 10 ملفات فقط'**
  String get fileLimitWarning;

  /// No description provided for @retryTranscription.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryTranscription;

  /// No description provided for @allFatwas.
  ///
  /// In ar, this message translates to:
  /// **'جميع الفتاوى'**
  String get allFatwas;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'الأمس'**
  String get yesterday;

  /// No description provided for @playAudio.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الصوت'**
  String get playAudio;

  /// No description provided for @pauseAudio.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pauseAudio;

  /// No description provided for @audioNotFound.
  ///
  /// In ar, this message translates to:
  /// **'ملف الصوت غير موجود'**
  String get audioNotFound;

  /// No description provided for @speed.
  ///
  /// In ar, this message translates to:
  /// **'السرعة'**
  String get speed;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @searchFatwas.
  ///
  /// In ar, this message translates to:
  /// **'البحث في الفتاوى...'**
  String get searchFatwas;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get category;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'جميع التصنيفات'**
  String get allCategories;

  /// No description provided for @catWorship.
  ///
  /// In ar, this message translates to:
  /// **'العبادات'**
  String get catWorship;

  /// No description provided for @catTransactions.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات'**
  String get catTransactions;

  /// No description provided for @catFamily.
  ///
  /// In ar, this message translates to:
  /// **'الأسرة'**
  String get catFamily;

  /// No description provided for @catCreed.
  ///
  /// In ar, this message translates to:
  /// **'العقيدة'**
  String get catCreed;

  /// No description provided for @catManners.
  ///
  /// In ar, this message translates to:
  /// **'الأخلاق والآداب'**
  String get catManners;

  /// No description provided for @catContemporary.
  ///
  /// In ar, this message translates to:
  /// **'معاصرة'**
  String get catContemporary;

  /// No description provided for @catOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get catOther;

  /// No description provided for @noCategory.
  ///
  /// In ar, this message translates to:
  /// **'بدون تصنيف'**
  String get noCategory;

  /// No description provided for @fatwaTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الفتوى'**
  String get fatwaTitle;

  /// No description provided for @editTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get editTitle;

  /// No description provided for @titleHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان الفتوى'**
  String get titleHint;

  /// No description provided for @words.
  ///
  /// In ar, this message translates to:
  /// **'{count} كلمة'**
  String words(int count);

  /// No description provided for @shareText.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة النص'**
  String get shareText;

  /// No description provided for @copiedToClipboard.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get copiedToClipboard;

  /// No description provided for @autoFormat.
  ///
  /// In ar, this message translates to:
  /// **'تنسيق تلقائي بالذكاء الاصطناعي'**
  String get autoFormat;

  /// No description provided for @autoFormatDesc.
  ///
  /// In ar, this message translates to:
  /// **'إضافة علامات الترقيم وتنظيم النص'**
  String get autoFormatDesc;

  /// No description provided for @formatting.
  ///
  /// In ar, this message translates to:
  /// **'جاري التنسيق...'**
  String get formatting;

  /// No description provided for @formatSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التنسيق بنجاح'**
  String get formatSuccess;

  /// No description provided for @formatFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التنسيق'**
  String get formatFailed;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
