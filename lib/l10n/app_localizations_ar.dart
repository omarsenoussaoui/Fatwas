// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'فتاوى الشيخ بن حنيفية زين العابدين';

  @override
  String get sheikhName => 'الشيخ بن حنيفية زين العابدين';

  @override
  String get home => 'الرئيسية';

  @override
  String get upload => 'رفع الملفات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get uploadFiles => 'رفع ملفات صوتية';

  @override
  String get selectAudioFiles => 'اختيار الملفات الصوتية';

  @override
  String get selectFiles => 'اختيار الملفات';

  @override
  String get transcribe => 'تحويل إلى نص';

  @override
  String get transcribing => 'جاري التحويل...';

  @override
  String get download => 'تحميل';

  @override
  String get downloadAll => 'تحميل الكل';

  @override
  String get downloadDocx => 'تحميل DOCX';

  @override
  String get downloadPdf => 'تحميل PDF';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get clearAllConfirm => 'هل أنت متأكد من مسح جميع الفتاوى؟';

  @override
  String get clearAllDescription => 'سيتم حذف جميع الفتاوى نهائياً';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get deleteConfirm => 'هل أنت متأكد من حذف هذه الفتوى؟';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String fatwaNumber(int number) {
    return 'فتوى رقم $number';
  }

  @override
  String get date => 'التاريخ';

  @override
  String get author => 'المؤلف';

  @override
  String get noFatwas => 'لا توجد فتاوى بعد';

  @override
  String get noFatwasDescription => 'ارفع ملفات صوتية لبدء التحويل';

  @override
  String get pending => 'في الانتظار';

  @override
  String get transcribingStatus => 'جاري التحويل';

  @override
  String get done => 'مكتمل';

  @override
  String get error => 'خطأ';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get apiKey => 'مفتاح Groq API';

  @override
  String get apiKeyHint => 'أدخل مفتاح Groq API';

  @override
  String get testKey => 'اختبار المفتاح';

  @override
  String get testKeySuccess => 'المفتاح صالح ✓';

  @override
  String get testKeyFailed => 'المفتاح غير صالح ✗';

  @override
  String get testingKey => 'جاري الاختبار...';

  @override
  String get usingDefaultKey => 'يتم استخدام المفتاح الافتراضي';

  @override
  String get usingCustomKey => 'يتم استخدام مفتاح مخصص';

  @override
  String get resetToDefault => 'إعادة للافتراضي';

  @override
  String filesSelected(int count) {
    return '$count ملفات محددة';
  }

  @override
  String get transcriptionComplete => 'اكتمل التحويل';

  @override
  String get transcriptionFailed => 'فشل التحويل';

  @override
  String get exportSuccess => 'تم التصدير بنجاح';

  @override
  String get exportFailed => 'فشل التصدير';

  @override
  String get noApiKey => 'الرجاء إدخال مفتاح API في الإعدادات';

  @override
  String get fileLimitWarning => 'يمكنك اختيار من 1 إلى 10 ملفات فقط';

  @override
  String get retryTranscription => 'إعادة المحاولة';

  @override
  String get allFatwas => 'جميع الفتاوى';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'الأمس';

  @override
  String get playAudio => 'تشغيل الصوت';

  @override
  String get pauseAudio => 'إيقاف مؤقت';

  @override
  String get audioNotFound => 'ملف الصوت غير موجود';

  @override
  String get speed => 'السرعة';

  @override
  String get search => 'بحث';

  @override
  String get searchFatwas => 'البحث في الفتاوى...';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get category => 'التصنيف';

  @override
  String get allCategories => 'جميع التصنيفات';

  @override
  String get catWorship => 'العبادات';

  @override
  String get catTransactions => 'المعاملات';

  @override
  String get catFamily => 'الأسرة';

  @override
  String get catCreed => 'العقيدة';

  @override
  String get catManners => 'الأخلاق والآداب';

  @override
  String get catContemporary => 'معاصرة';

  @override
  String get catOther => 'أخرى';

  @override
  String get noCategory => 'بدون تصنيف';

  @override
  String get fatwaTitle => 'عنوان الفتوى';

  @override
  String get editTitle => 'تعديل العنوان';

  @override
  String get titleHint => 'أدخل عنوان الفتوى';

  @override
  String words(int count) {
    return '$count كلمة';
  }

  @override
  String get shareText => 'مشاركة النص';

  @override
  String get copiedToClipboard => 'تم النسخ';

  @override
  String get autoFormat => 'تنسيق تلقائي بالذكاء الاصطناعي';

  @override
  String get autoFormatDesc => 'إضافة علامات الترقيم وتنظيم النص';

  @override
  String get formatting => 'جاري التنسيق...';

  @override
  String get formatSuccess => 'تم التنسيق بنجاح';

  @override
  String get formatFailed => 'فشل التنسيق';
}
