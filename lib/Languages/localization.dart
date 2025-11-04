import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      "PrivacyPolicy": "سياسة الخصوصية",
      "ReadOurPrivacyPolicy": "اطلع على سياسة الخصوصية",
      'gameTitle': 'عالماشي .كوم',
      'play': 'العب',
      'levels': 'المراحل',
      'settings': 'الإعدادات',
      'about': 'حول اللعبة',
      'store': 'المتجر',
      'score': 'النقاط',
      'highScore': 'أعلى نقاط',
      'coins': 'العملات',
      'totalCoins': 'إجمالي العملات',
      'unlockedLevels': 'المراحل المفتوحة',
      'currentLevel': 'المرحلة الحالية',
      'target': 'الهدف',
      'progress': 'التقدم',
      'time': 'الوقت',
      'lives': 'الأرواح',
      'health': 'الصحة',
      'shield': 'الدرع',
      'slowMotion': 'ابطاء الزمن',
      'doublePoints': 'نقاط مزدوجة',
      'gameOver': 'انتهت اللعبة',
      'levelComplete': 'اكتملت المرحلة!',
      'congratulations': 'تهانينا!',
      'wellDone': 'أحسنت!',
      'bossWarning': 'استعد! الزعيم يقترب...',
      'bossAppear': 'الزعيم يظهر!',
      'bossDefeated': 'تم هزيمة الزعيم!',
      'resume': 'استئناف اللعبة',
      'restart': 'إعادة اللعبة',
      'restartLevel': 'إعادة المرحلة',
      'nextLevel': 'المرحلة التالية',
      'mainMenu': 'القائمة الرئيسية',
      'levelsMenu': 'قائمة المراحل',
      'chooseLevel': 'اختر المرحلة',
      'watchAdToContinue': 'استمر (شاهد إعلان)',
      'loadingAd': 'جاري تحميل الإعلان...',
      'adPlaying': 'يتم عرض الإعلان...',
      'sound': 'الأصوات',
      'music': 'الموسيقى',
      'vibration': 'الاهتزاز',
      'notifications': 'الإشعارات',
      'tutorialJump': 'اسحب للأعلى للقفز',
      'tutorialDuck': 'اسحب لأسفل للانحناء',
      'tutorialAttack': 'انقر لرمي الطرود',
      'combo': 'كومبو!',
      "flash": "الوميض الأصفر",
      'newRecord': 'رقم قياسي جديد!',
      'loading': 'جاري التحميل...',
      'loadingGame': 'جاري تحميل اللعبة...',
      'loadingLevels': 'جاري تحميل المراحل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',
      'adError': 'فشل في تحميل الإعلان',
      "share": "شارك اللعبة مع أصدقائك",
      "aboutGame": 'حول اللعبة',
      "aboutGameSubject1": "لعبة جري لا نهائية ممتعة تتميز بشخصية عالماشي المحبوبة. تجنب العقبات، اجمع النقاط، وتقدم عبر المراحل المختلفة!",
      "aboutGameSubject2": "هذه لعبة ترفيهية تابعة لموقع التسوق الأضخم في سوريا موقع عالماشي يمكنكم زيارتنا على الموقع ونشر إعلاناتكم مجانا",
      "VisitWebsite": "زورونا على موقعنا:",
      "version": "الأصدار:",
      "developer": "المطور:",
      "aboutDesecration": "وصف اللعبة",
      "aboutTheWebsite": "الموقع الإلكتروني",
      "aboutLanguage": "اللغة",
      "aboutOpenWebsite": "سيتم فتح موقع عالماشي في المتصفح",
      "aboutCancel": "إلغاء",
      "aboutOpenLink": "فتح الرابط",
      "SettingsStatistics": "إحصائيات اللعبة",
      "SettingsApplicationProcedures": "إجراءات التطبيق",
      "SettingsGameRating": "قيم اللعبة",
      "SettingsYourReview": "ساعدنا بتقييمك في المتجر",
      "SettingsShareWithFriends": "شارك اللعبة مع أصدقائك",
      "SettingsResetData": "إعادة تعيين البيانات",
      "SettingsDeleteAllData": "حذف جميع البيانات والبدء من جديد",
      "almaSheTeam": "فريق عالماشي",
      "TermsOfUse": "شروط الاستخدام",
      "ReadTheTermsOfUse": "اطلع على شروط الاستخدام",
      "close": "إغلاق",
      "lastUpdate": "آخر تحديث",
      "welcomeToGame": "مرحبًا بك في لعبة",
      "gameName": "عالماشي اركض",
      "we": "نحن",
      "theGame": "اللعبة",
      "developmentTeam": "فريق التطوير",
      "privacyPolicyIntro": "نحن نحترم خصوصيتك ونسعى لحماية بياناتك أثناء استخدامك للعبة. تم إعداد هذه السياسة لتوضيح طريقة جمع البيانات واستخدامها وحمايتها.",
      "dataWeCollect": "البيانات التي نجمعها",
      "privacyPoint1": "اللعبة لا تطلب أي معلومات شخصية مباشرة مثل الاسم أو البريد الإلكتروني، إلا في الحالات التالية:",
      "privacyPoint2": "عند الاتصال بالدعم الفني أو إرسال ملاحظات (قد تُرسل بريدك الإلكتروني اختياريًا).",
      "privacyPoint3": "بيانات الاستخدام العامة (مثل الوقت الذي تلعب فيه وعدد النقاط والمستوى الذي وصلت إليه).",
      "privacyPoint4": "بيانات إعلانية مجهولة الهوية تُستخدم عبر خدمات مثل Unity Ads أو Google AdMob لتحسين تجربة الإعلانات.",
      "adsAndThirdParties": "الإعلانات والجهات الخارجية",
      "adsPoint1": "قد تحتوي اللعبة على إعلانات من أطراف ثالثة مثل Unity Ads أو Google AdMob.",
      "adsPoint2": "تلك الخدمات قد تستخدم معرفات مجهولة (مثل معرف الإعلانات) لتخصيص الإعلانات وتحليل الأداء.",
      "inAppPurchases": "المشتريات داخل اللعبة",
      "purchasesPoint1": "إذا تضمنت اللعبة عمليات شراء (مثل شراء شخصيات جديدة أو عناصر إضافية)، فإن الدفع يتم من خلال متجر Google Play أو Apple App Store.",
      "dataSecurity": "أمان البيانات",
      "securityPoint1": "نستخدم وسائل حماية رقمية لتقليل خطر الوصول غير المصرح به إلى بيانات اللعبة.",
      "securityPoint2": "لكن لا توجد وسيلة نقل عبر الإنترنت أو تخزين إلكتروني آمنة بنسبة 100٪، لذا لا يمكننا ضمان الأمان المطلق.",
      "childrenPrivacy": "خصوصية الأطفال",
      "childrenPoint1": "اللعبة مخصصة لجميع الأعمار، لكننا لا نجمع عمدًا أي بيانات شخصية من الأطفال دون سن 13 عامًا.",
      "childrenPoint2": "إذا كنت والدًا أو وصيًا وتعتقد أن طفلك قد زودنا بمعلومات شخصية، يمكنك التواصل معنا لحذفها فورًا.",
      "policyChanges": "التغييرات على سياسة الخصوصية",
      "changesPoint1": "قد نقوم بتحديث هذه السياسة من وقت لآخر.",
      "changesPoint2": "سيتم نشر أي تعديل جديد داخل اللعبة أو على صفحتها الرسمية، مع تحديث تاريخ \"آخر تحديث\" أعلاه.",
      "contactUs": "الاتصال بنا",
      "contactPoint1": "إذا كانت لديك أي أسئلة أو ملاحظات حول سياسة الخصوصية، يمكنك التواصل معنا عبر البريد الإلكتروني:",

      "termsAcceptance": "قبول الشروط",
      "termsLicense": "الترخيص والاستخدام",
      "termsContent": "المحتوى داخل اللعبة",
      "termsAds": "الإعلانات والخدمات الخارجية",
      "termsUpdates": "التحديثات والتغييرات",
      "termsDisclaimer": "إخلاء المسؤولية",
      "termsTermination": "إنهاء الاستخدام",
      "termsLaw": "القانون المعمول به",
      "rate": "تقييم اللعبة",
      "rateYouHappy": "هل تستمتع بلعبة عالماشي؟",
      "rateHelpUs": "ساعدنا بتقييمك في المتجر!",
      "later": "لاحقاً",
      "rateNow": "قيم الآن",
      "shareOnly": "مشاركة",
      "shareWithFriends": "جرب لعبة عالماشي الممتعة!\n\nحمل اللعبة من المتجر واستمتع بالتحدي.",
      "resetWillDelet": "هل أنت متأكد من حذف جميع بيانات اللعبة؟ سيتم فقدان جميع النقاط والعملات والمراحل المفتوحة.",
      "resetDone": "تم إعادة تعيين البيانات بنجاح",
      "delete": "حذف",
      "levelName1": "البداية",
      "levelName2": "التحدي الأول",
      "levelName3": "المدينة المزدحمة",
      "levelName4": "الليل المظلم",
      "levelName5": "العاصفة",
      "levelName6": "الصحراء الحارة",
      "levelName7": "الجبال الثلجية",
      "levelName8": "الغابة المطيرة",
      "levelName9": "المحيط الهائج",
      "levelName10": "الفضاء الخارجي",
      "levelName11": "المتاهة",
      "levelName12": "القلعة القديمة",
      "levelName13": "البركان",
      "levelName14": "الوادي السري",
      "levelName15": "المختبر",
      "levelName16": "المدينة المستقبلية",
      "levelName17": "الحديقة الجوراسية",
      "levelName18": "المعبد الضائع",
      "levelName19": "القطب الشمالي",
      "levelName20": "الصحراء الغامضة",
      "levelDesc1": "تعلم أساسيات اللعبة",
      "levelDesc2": "عقبات أسرع وأكثر",
      "levelDesc3": "تجنب الحشود",
      "levelDesc4": "رؤية محدودة",
      "levelDesc5": "تحدي الخبراء",
      "levelDesc6": "حرارة عالية",
      "levelDesc7": "ثلوج وبرودة",
      "levelDesc8": "أمطار وغابات",
      "levelDesc9": "أمواج عاتية",
      "levelDesc10": "انعدام الجاذبية",
      "levelDesc11": "طرق متشابكة",
      "levelDesc12": "أجواء تاريخية",
      "levelDesc13": "حمم بركانية",
      "levelDesc14": "أسرار مخفية",
      "levelDesc15": "تجارب علمية",
      "levelDesc16": "تكنولوجيا متطورة",
      "levelDesc17": "ديناصورات عملاقة",
      "levelDesc18": "كنوز قديمة",
      "levelDesc19": "جليد أبدي",
      "levelDesc20": "أساطير الصحراء",
      "pauseTitle": "اللعبة متوقفة",
      "pauseResumeDesc": "استكمال المرحلة من حيث توقفت",
      "pauseRestartDesc": "شاهد إعلان ثم حاول من جديد",
      "pauseMainMenuDesc": "شاهد إعلان ثم ارجع للقائمة",
      "pauseLanguage": "اللغة",
      "pauseAdRestart": "بعد انتهاء الإعلان ستبدأ المرحلة من جديد",
      "pauseAdMainMenu": "بعد انتهاء الإعلان ستعود للقائمة الرئيسية",
      "speed": "سرعة",
      "slow": "إبطاء",
      "levelCompleteCongratulations": "تهانينا!",
      "levelCompleteMessage": "لقد أكملت %s",
      "levelCompleteUnlocked": "تم فتح المرحلة %d",
      "gameOverSuccess": "أحسنت!",
      "gameOverLevelCompleted": "تم إنجاز المرحلة بنجاح!",
      "gameOverCoinsEarned": "العملات المكتسبة",
      "gameOverContinue": "استمر (شاهد إعلان)",
      "gameOverContinueDesc": "استمر من حيث توقفت",
      "gameOverNextLevelDesc": "انتقل للمرحلة التالية",
      "gameOverRestartDesc": "حاول مرة أخرى",
      "gameOverLevelsDesc": "اختر مرحلة أخرى",
      "gameOverMainMenuDesc": "العودة للقائمة الرئيسية",
      "gameOverAdTitle": "إعلان مكافأة",
      "gameOverAdDesc": "ستستمر اللعبة بعد انتهاء الإعلان",
      "gameOverLoadError": "تعذر تحميل المرحلة التالية",
      "gameOverCongratulations": "مبروك!",
      "gameOverAllLevelsCompleted": "لقد أكملت جميع المراحل!",
      "gameOverChampion": "أنت بطل اللعبة! 🏆",
      "gameOverAwesome": "رائع!",
      "tutorialTitle": "طريقة التحكم الجديدة",
      "tutorialDragHorizontal": "اسحب أفقياً",
      "tutorialDragHorizontalDesc": "تحريك لليمين واليسار",
      "tutorialDragUpSmall": "اسحب للأعلى قليلاً",
      "tutorialDragUpSmallDesc": "قفزة صغيرة",
      "tutorialDragUpLarge": "اسحب للأعلى بشكل كبير",
      "tutorialDragUpLargeDesc": "قفزة عالية",
      "tutorialDragDown": "اسحب للأسفل أثناء القفز",
      "tutorialDragDownDesc": "تسريع الهبوط",
      "tutorialFullControl": "حرك في أي اتجاه",
      "tutorialFullControlDesc": "تحكم كامل في الحركة",
      "tutorialTapAnywhere": "انقر في أي مكان لمتابعة اللعب!",
      "tutorialAutoHide": "ستختفي هذه التعليمات تلقائياً بعد 6 ثواني",
      "bossNotification": "⚡ الزعيم يقترب!",
      "gameSlogan": "عالماشي .كوم - المعركة بين يديك",
      "characterStore": "المتجر",
      "yourPoints": "العملات التي لديك",
      "buyPoints": "شراء عملات جديدة",
      "watchAd": "شاهد إعلان",
      "purchasedSuccessfully": "تم الشراء",
      "insufficientPoints": "عملات غير كافية",
      "watchAdForPoints": "شاهد إعلان للحصول على 50 عملة مجانية",
      "selectCharacter": "اختيار الشخصية",
      "characterSelected": "تم اختيار الشخصية",
      "characterOwned": "مملوكة",
      "characterLocked": "مقفلة",
      "pointsPackage": "باقة العملات",
      "freePoints": "عملات مجانية",
      "myCharacters": "شخصياتي",
      "purchaseNow": "اشتري الان",
      "goToStore": "اذهب للمتجر",
      "ownedCharacters": "الشخصيات المملوكة",
      "availableForPurchase": "متاحة للشراء",
      "noCharactersOwned": "لا تمتلك أي شخصيات بعد",
      "allCharactersOwned": "جميع الشخصيات مملوكة",
      "buyCoinsNow": "اشتري عملات",
      "choseCharacter": "قائمة الشخصيات",
      "choseAnotherCharacter": "اختر شخصية اخرى من القائمة",
      "purchaseConfirmation": "هل تريد شراء %s بـ %d نقطة؟",
      "characterAlreadyOwned": "هذه الشخصية مملوكة بالفعل!",
      "purchaseSuccess": "✅ تم شراء %s بنجاح!",
      "purchaseFailed": "❌ فشل في الشراء",
      "owned": "مملوكة",
      "selected": "مختارة ✓",
      "buyNow": "اشتري الان",
      "select": "اختر",
      "characters": "الشخصيات",
      "loadingCharacters": "جاري تحميل الشخصيات...",
      "noCharactersAvailable": "لا توجد شخصيات متاحة",
      "characterLoadError": "حدث خطأ في تحميل الشخصيات",
      "goToCharacters": "👥 قائمة الشخصيات",
      "watchAdForCoins": "شاهد إعلان للحصول على 20 عملة مجانية",
      "coinsAdded": "🎉 حصلت على %d عملة مجانية!",
      "adFailed": "❌ فشل تحميل الإعلان، حاول مرة أخرى",
      "buyCoins": "شراء عملات",
      "yourCoins": "العملات التي لديك",
      "confirm": "تأكيد",
      "cancel": "إلغاء",
      "characterDetails": "تفاصيل الشخصية",
      "characterType": "النوع",
      "characterAbilities": "القدرات",
      "allCharactersPurchased": "لقد اشتريت جميع الشخصيات!",
      "goToMarketplace": " اذهب للمتجر",
      "tapToThrow": "انقر لرمي الطرود! 📦",
      "tapToFight": "انقر للقتال! ⚔️",
      "tapToAttack": "انقر لمهاجمة الأعداء! 🎯",
      "levelCompleteTransfer": "جاري الانتقال...",
      "gameCompleteTitle": "مبروك! لقد قمت بتختيم اللعبة! 🎉",
      "gameCompleteMessage": "خذ صورة لأنك قمت بتختيم اللعبة وأرسلها لنا على موقع عالماشي.كوم",
      "gameCompleteReward": "🎁 جائزتك: تمييز إعلانك على موقعنا مجاناً لمدة شهر!",
      "gameCompleteInstructions": "💚 فقط أرسل الصورة لنا عبر مواقع التواصل الاجتماعي أو عبر حسابك على موقعنا وأخبرنا ماهو الإعلان الذي تريد تمييزه ليظهر بأول سجلات البحث",
      "returnToMainMenu": "العودة للقائمة الرئيسية",
      "gameError": "حدث خطأ في تحميل اللعبة",
      "pleaseTryAgain": "يرجى المحاولة مرة أخرى",
      "points": "النقاط",
      "level": "المرحلة",
      "timeSpent": "الوقت المستغرق",
      'adsRemoval': 'إزالة الإعلانات',
      'removeAds': 'إزالة الإعلانات',
      'adsRemovalDescription': 'استمتع بتجربة لعب خالية من الإعلانات',
      'currentAdsStatus': 'حالة الإعلانات الحالية',
      'adsEnabled': 'الإعلانات مفعلة',
      'adsDisabled': 'الإعلانات معطلة',
      'removeAdsFor': 'إزالة الإعلانات لمدة',
      'hours': 'ساعات',
      'days': 'أيام',
      'months': 'أشهر',
      'years': 'سنوات',
      'lifetime': 'مدى الحياة',
      'purchase': 'شراء',
      'purchaseSuccessful': 'تم الشراء بنجاح',
      'remainingTime': 'الوقت المتبقي',
      'active': 'نشط',
      'expired': 'منتهي',
      'confirmPurchase': 'تأكيد الشراء',
      "purchaseConfirmationAds": "هل تريد شراء إزالة الإعلانات لمدة %duration% بسعر %price%؟",
      'purchaseSuccessMessage': 'تمت إزالة الإعلانات بنجاح! استمتع بتجربة لعب أفضل.',
      'purchaseErrorMessage': 'حدث خطأ أثناء عملية الشراء. يرجى المحاولة مرة أخرى.',
      'noAdsEnjoy': 'لا توجد إعلانات - استمتع باللعب!',
      'watchAdToRemove': 'شاهد إعلان لإزالة الإعلانات لمدة',
      'removeAdsTemporarily': 'إزالة مؤقتة للإعلانات',
      'weeks': 'أسابيع',
      'minutes': 'دقائق',
      "termsIntro1": "باستخدامك للعبة، فإنك توافق على الالتزام بهذه الشروط والأحكام. يرجى قراءتها بعناية قبل البدء في اللعب.",
      "termsPoint1": "باستخدام اللعبة أو تثبيتها، فإنك تقر بأنك قد قرأت وفهمت هذه الشروط وتوافق على الالتزام بها. إذا كنت لا توافق على أي جزء من هذه الشروط، يرجى عدم استخدام اللعبة.",
      "termsPoint2": "نمنحك ترخيصًا محدودًا، غير حصري، وغير قابل للتحويل، لاستخدام اللعبة فقط للأغراض الشخصية والترفيهية. يُحظر تمامًا:\n• تعديل أو نسخ أو إعادة بيع اللعبة أو أي جزء منها.\n• استخدام اللعبة لأي غرض تجاري غير مصرح به.\n• محاولة الوصول إلى الكود المصدري أو تجاوز الحماية.",
      "termsPoint3": "قد تحتوي اللعبة على عناصر يمكن شراؤها أو فتحها أثناء التقدم في اللعب. كل العناصر الافتراضية (مثل الشخصيات أو النقاط أو العملات داخل اللعبة) ليس لها قيمة مالية حقيقية ولا يمكن استبدالها بأموال حقيقية.",
      "termsPoint4": "اللعبة قد تعرض إعلانات أو تستخدم خدمات طرف ثالث مثل Unity Ads أو Google AdMob. نحن غير مسؤولين عن محتوى أو دقة أي إعلان أو رابط خارجي يظهر داخل اللعبة.",
      "termsPoint5": "نحتفظ بالحق في تحديث اللعبة أو تعديلها أو إيقافها مؤقتًا أو نهائيًا في أي وقت دون إشعار مسبق. قد تتطلب بعض التحديثات إعادة تنزيل أو تثبيت اللعبة.",
      "termsPoint6": "اللعبة مقدمة كما هي \"AS IS\" بدون أي ضمانات صريحة أو ضمنية. لا نتحمل مسؤولية أي ضرر مباشر أو غير مباشر ينتج عن استخدامك للعبة، بما في ذلك فقدان البيانات أو الأعطال.",
      "termsPoint7": "نحتفظ بالحق في إيقاف وصولك إلى اللعبة في أي وقت إذا خالفت هذه الشروط أو استخدمت اللعبة بطريقة غير قانونية.",
      "termsPoint8": "تخضع هذه الشروط وتُفسَّر وفقًا للقوانين المعمول بها في بلد مطوّر اللعبة، دون النظر إلى تعارض القوانين.",
      "termsPoint9": "لأي استفسار أو ملاحظات حول شروط الاستخدام، يمكنك التواصل معنا عبر البريد الإلكتروني:\n📧 support@3almashe.com",
      "manageAds": "إدارة الإعلانات",
      "adFailedMessage": "تعذر تحميل الإعلان. حاول مرة أخرى لاحقاً.",
      'tapAnywhereToAim': 'انقر في أي مكان لتطلق باتجاهه! 🎯',
      'aimAttackDescription': 'يمكنك الآن توجيه الهجمات بدقة - انقر في أي مكان على الشاشة لتطلق باتجاه النقر',
      'adsStatus': 'حالة الإعلانات',
      'powerUpHealth': 'زيادة الصحة',
      'powerUpSpeedBoost': 'زيادة السرعة',
      'powerUpSlowEnemies': 'إبطاء الأعداء',
      'powerUpCoin': 'عملة ذهبية',
      'powerUpPoints': 'نقاط سريعة',
      'powerUpShield': 'درع واقي',
      'powerUpSlowMotion': 'تباطؤ زمني',
      'powerUpDoublePoints': 'نقاط مزدوجة',
      'powerUpSlowCharacter': 'تبطيء مؤقت',
      'powerUpHealthDesc': 'يعيد 25% من الصحة المفقودة',
      'powerUpSpeedBoostDesc': 'يزيد سرعة الحركة 50%',
      'powerUpSlowEnemiesDesc': 'يبطئ حركة الأعداء 60%',
      'powerUpCoinDesc': 'عملة واحدة للمتجر + 3 نقاط',
      'powerUpPointsDesc': 'يمنح 8 نقاط فورية',
      'powerUpShieldDesc': 'حماية كاملة من الضرر',
      'powerUpSlowMotionDesc': 'يبطئ الوقت 70%',
      'powerUpDoublePointsDesc': 'مضاعفة النقاط المكتسبة',
      'powerUpSlowCharacterDesc': 'يبطئ حركة الشخصية 40%',
      'powerUpHealthEffect': '+25% صحة',
      'powerUpSpeedBoostEffect': '+50% سرعة',
      'powerUpSlowEnemiesEffect': '-60% سرعة الأعداء',
      'powerUpCoinEffect': '+1 عملة +3 نقاط',
      'powerUpPointsEffect': '+8 نقاط',
      'powerUpShieldEffect': 'حماية كاملة',
      'powerUpSlowMotionEffect': '-70% سرعة الوقت',
      'powerUpDoublePointsEffect': '×2 نقاط',
      'powerUpSlowCharacterEffect': '-40% سرعة الشخصية',
      'powerUpRarity': 'الندرة',
      'powerUpRarityCommon': 'شائع',
      'powerUpRarityUncommon': 'غير شائع',
      'powerUpRarityRare': 'نادر',
      'powerUpRarityLegendary': 'أسطوري',
      'powerUpEffect': 'التأثير',
      'powerUpEffectInstant': 'فوري',
      'powerUpSeconds': 'ثانية',
      'powerUpTotalCollected': 'إجمالي الباور أب المجموعة',
      'powerUpTotalEffectTime': 'إجمالي وقت التأثير',
      'powerUpCollected': 'مجموعة',
      'powerUpSpawned': 'منتشرة',
      "powerUpDuration": "المدة",
      "powerUpActivated": "تفعيل الباور أب",
      "powerUpExpired": "انتهى الباور أب",
      "paymentNotAvailable": "نظام الدفع غير متاح",
      "paymentReady": "نظام الدفع جاهز"
    },
    'en': {
      "PrivacyPolicy": "Privacy Policy",
      "ReadOurPrivacyPolicy": "Read our privacy policy",
      'gameTitle': '3almaShe.com',
      'play': 'Play',
      'levels': 'Levels',
      'settings': 'Settings',
      'about': 'About',
      'store': 'Marketplace',
      'score': 'Score',
      'highScore': 'High Score',
      'coins': 'Coins',
      'totalCoins': 'Total Coins',
      'unlockedLevels': 'Unlocked Levels',
      'currentLevel': 'Current Level',
      'target': 'Target',
      'progress': 'Progress',
      'time': 'Time',
      'lives': 'Lives',
      'health': 'Health',
      'shield': 'Shield',
      'slowMotion': 'Slow Motion',
      'doublePoints': 'Double Points',
      'gameOver': 'Game Over',
      'levelComplete': 'Level Complete!',
      'congratulations': 'Congratulations!',
      'wellDone': 'Well Done!',
      'bossWarning': 'Get ready! Boss is approaching...',
      'bossAppear': 'Boss appears!',
      'bossDefeated': 'Boss defeated!',
      'resume': 'Resume Game',
      'restart': 'Restart Game',
      'restartLevel': 'Restart Level',
      'nextLevel': 'Next Level',
      'mainMenu': 'Main Menu',
      'levelsMenu': 'Levels Menu',
      'chooseLevel': 'Choose Level',
      'watchAdToContinue': 'Continue (Watch Ad)',
      'loadingAd': 'Loading Ad...',
      'adPlaying': 'Playing Ad...',
      'sound': 'Sound',
      'music': 'Music',
      'vibration': 'Vibration',
      'notifications': 'Notifications',
      'tutorialJump': 'Swipe up to jump',
      'tutorialDuck': 'Swipe down to duck',
      'tutorialAttack': 'Tap to throw packages',
      'combo': 'Combo!',
      'newRecord': 'New Record!',
      'loading': 'Loading...',
      "flash": "The yellow flash",
      'loadingGame': 'Loading Game...',
      'loadingLevels': 'Loading Levels...',
      'error': 'Error',
      'retry': 'Retry',
      'adError': 'Failed to load ad',
      "share": "Share the game with your friends",
      "aboutGame": 'About the game',
      "aboutGameSubject1": "A fun endless runner game featuring the beloved character Al-Mashy. Avoid obstacles, collect points, and advance through different levels!",
      "aboutGameSubject2": "This is an entertainment game affiliated with Syria's largest shopping website, Alamashi. You can visit our website and post your ads for free.",
      "VisitWebsite": "Visit us on our website:",
      "version": "Version:",
      "developer": "Developer:",
      "aboutDesecration": "Game Description",
      "aboutTheWebsite": "Website",
      "aboutLanguage": "Language",
      "aboutOpenWebsite": "3almaShe website will open in your browser.",
      "aboutCancel": "Cancel",
      "aboutOpenLink": "Open Link",
      "SettingsStatistics": "Game statistics",
      "SettingsApplicationProcedures": "Application procedures",
      "SettingsGameRating": "Game Rating",
      "SettingsYourReview": "Help us with your review in the store",
      "SettingsShareWithFriends": "Share the game with your friends",
      "SettingsResetData": "Reset Data",
      "SettingsDeleteAllData": "Delete all data and start over",
      "almaSheTeam": "3almaShe Team",
      "TermsOfUse": "Terms of Use",
      "ReadTheTermsOfUse": "Read the Terms of Use",
      "close": "Close",
      "lastUpdate": "Last Update",
      "welcomeToGame": "Welcome to",
      "gameName": "3almaShe Run",
      "we": "We",
      "theGame": "The Game",
      "developmentTeam": "Development Team",
      "privacyPolicyIntro": "We respect your privacy and strive to protect your data while using the game. This policy is prepared to clarify how data is collected, used, and protected.",
      "dataWeCollect": "Data We Collect",
      "privacyPoint1": "The game does not request any direct personal information such as name or email, except in the following cases:",
      "privacyPoint2": "When contacting technical support or sending feedback (you may optionally send your email).",
      "privacyPoint3": "General usage data (such as play time, score count, and reached level).",
      "privacyPoint4": "Anonymous advertising data used through services like Unity Ads or Google AdMob to improve ad experience.",
      "adsAndThirdParties": "Ads and Third Parties",
      "adsPoint1": "The game may contain ads from third parties like Unity Ads or Google AdMob.",
      "adsPoint2": "These services may use anonymous identifiers (like ad IDs) to customize ads and analyze performance.",
      "inAppPurchases": "In-App Purchases",
      "purchasesPoint1": "If the game includes purchases (such as buying new characters or additional items), payment is processed through Google Play Store or Apple App Store.",
      "dataSecurity": "Data Security",
      "securityPoint1": "We use digital protection means to reduce the risk of unauthorized access to game data.",
      "securityPoint2": "However, there are no 100% secure online transmission or electronic storage methods, so we cannot guarantee absolute security.",
      "childrenPrivacy": "Children Privacy",
      "childrenPoint1": "The game is suitable for all ages, but we do not intentionally collect any personal data from children under 13 years old.",
      "childrenPoint2": "If you are a parent or guardian and believe your child has provided us with personal information, you can contact us to delete it immediately.",
      "policyChanges": "Policy Changes",
      "changesPoint1": "We may update this policy from time to time.",
      "changesPoint2": "Any new updates will be published within the game or on its official page, with the \"Last Update\" date updated above.",
      "contactUs": "Contact Us",
      "contactPoint1": "If you have any questions or comments about the privacy policy, you can contact us via email:",

      "termsAcceptance": "Acceptance of Terms",
      "termsLicense": "License and Use",
      "termsContent": "In-Game Content",
      "termsAds": "Ads and External Services",
      "termsUpdates": "Updates and Modifications",
      "termsDisclaimer": "Disclaimer",
      "termsTermination": "Termination",
      "termsLaw": "Governing Law",
      "rate": "Game Rating",
      "rateYouHappy": "Do you enjoy playing 3lamasShe?",
      "rateHelpUs": "Help us with your review in the store!",
      "later": "Later",
      "rateNow": "Rate Now",
      "shareOnly": "Share",
      "shareWithFriends": "Try the fun game 3almaShe!\\n\\nDownload the game from the store and enjoy the challenge.",
      "resetWillDelet": "Are you sure you want to delete all game data? All points, coins, and unlocked levels will be lost.",
      "resetDone": "Data has been successfully reset",
      "delete": "Delete",

      "levelName1": "The Beginning",
      "levelName2": "First Challenge",
      "levelName3": "Busy City",
      "levelName4": "Dark Night",
      "levelName5": "The Storm",
      "levelName6": "Hot Desert",
      "levelName7": "Snowy Mountains",
      "levelName8": "Rainforest",
      "levelName9": "Raging Ocean",
      "levelName10": "Outer Space",
      "levelName11": "The Maze",
      "levelName12": "Ancient Castle",
      "levelName13": "Volcano",
      "levelName14": "Secret Valley",
      "levelName15": "Laboratory",
      "levelName16": "Future City",
      "levelName17": "Jurassic Park",
      "levelName18": "Lost Temple",
      "levelName19": "Arctic Pole",
      "levelName20": "Mysterious Desert",

      "levelDesc1": "Learn the basics of the game",
      "levelDesc2": "Faster and more obstacles",
      "levelDesc3": "Avoid crowds",
      "levelDesc4": "Limited vision",
      "levelDesc5": "Expert challenge",
      "levelDesc6": "High temperature",
      "levelDesc7": "Snow and cold",
      "levelDesc8": "Rain and forests",
      "levelDesc9": "Raging waves",
      "levelDesc10": "Zero gravity",
      "levelDesc11": "Intertwined paths",
      "levelDesc12": "Historical atmosphere",
      "levelDesc13": "Volcanic lava",
      "levelDesc14": "Hidden secrets",
      "levelDesc15": "Scientific experiments",
      "levelDesc16": "Advanced technology",
      "levelDesc17": "Giant dinosaurs",
      "levelDesc18": "Ancient treasures",
      "levelDesc19": "Eternal ice",
      "levelDesc20": "Desert legends",
      "pauseTitle": "Game Paused",
      "pauseResumeDesc": "Continue the level from where you left off",
      "pauseRestartDesc": "Watch an ad then try again",
      "pauseMainMenuDesc": "Watch an ad then return to main menu",
      "pauseLanguage": "Language",
      "pauseAdRestart": "After the ad ends, the level will restart",
      "pauseAdMainMenu": "After the ad ends, you will return to main menu",
      "speed": "speed",
      "slow": "slow",

      "levelCompleteCongratulations": "Congratulations!",
      "levelCompleteMessage": "You have completed %s",
      "levelCompleteUnlocked": "Level %d unlocked",
      "gameOverSuccess": "Well Done!",
      "gameOverLevelCompleted": "Level completed successfully!",
      "gameOverCoinsEarned": "Coins Earned",
      "gameOverContinue": "Continue (Watch Ad)",
      "gameOverContinueDesc": "Continue from where you left off",
      "gameOverNextLevelDesc": "Go to next level",
      "gameOverRestartDesc": "Try again",
      "gameOverLevelsDesc": "Choose another level",
      "gameOverMainMenuDesc": "Return to main menu",
      "gameOverAdTitle": "Reward Ad",
      "gameOverAdDesc": "The game will continue after the ad ends",
      "gameOverLoadError": "Failed to load next level",
      "gameOverCongratulations": "Congratulations!",
      "gameOverAllLevelsCompleted": "You have completed all levels!",
      "gameOverChampion": "You are the champion! 🏆",
      "gameOverAwesome": "Awesome!",
      "tutorialTitle": "New Control Method",
      "tutorialDragHorizontal": "Drag horizontally",
      "tutorialDragHorizontalDesc": "Move left and right",
      "tutorialDragUpSmall": "Swipe up slightly",
      "tutorialDragUpSmallDesc": "Small jump",
      "tutorialDragUpLarge": "Swipe up largely",
      "tutorialDragUpLargeDesc": "High jump",
      "tutorialDragDown": "Swipe down while jumping",
      "tutorialDragDownDesc": "Accelerate falling",
      "tutorialFullControl": "Move in any direction",
      "tutorialFullControlDesc": "Full control in movement",
      "tutorialTapAnywhere": "Tap anywhere to continue playing!",
      "tutorialAutoHide": "This tutorial will auto-hide after 6 seconds",
      "bossNotification": "⚡ Boss is approaching!",
      "gameSlogan": "3almaShe.com - The Battle in Your Hands",
      "characterStore": "Marketplace",
      "yourPoints": "Your Coins",
      "buyPoints": "Buy Coins",
      "watchAd": "Watch Ad",
      "purchasedSuccessfully": "Purchased",
      "insufficientPoints": "Insufficient Coins",
      "watchAdForPoints": "Watch ad to get 50 free Coins",
      "selectCharacter": "Select Character",
      "characterSelected": "Character Selected",
      "characterOwned": "Owned",
      "characterLocked": "Locked",
      "pointsPackage": "Coins Package",
      "freePoints": "Free Coins",
      "myCharacters": "My Characters",
      "purchaseNow": "Purchase Now",
      "goToStore": "Go to Store",
      "ownedCharacters": "Owned Characters",
      "availableForPurchase": "Available for Purchase",
      "noCharactersOwned": "No characters owned yet",
      "allCharactersOwned": "All characters owned",
      "buyCoinsNow": "Buy Coins Now",
      "choseCharacter": "List of characters",
      "choseAnotherCharacter": "Select another character from the list",
      "confirmPurchase": "Confirm Purchase",
      "purchaseConfirmation": "Do you want to purchase %s for %d coins?",
      "characterAlreadyOwned": "This character is already owned!",
      "purchaseSuccess": "✅ Successfully purchased %s!",
      "purchaseFailed": "❌ Failed to purchase",
      "owned": "Owned",
      "selected": "Selected ✓",
      "buyNow": "Buy Now",
      "select": "Select",
      "characters": "Characters",
      "loadingCharacters": "Loading characters...",
      "noCharactersAvailable": "No characters available",
      "characterLoadError": "Error loading characters",
      "goToCharacters": "👥 Characters List",
      "watchAdForCoins": "Watch ad to get 20 free coins",
      "coinsAdded": "🎉 You got %d free coins!",
      "adFailed": "❌ Failed to load ad, please try again",
      "buyCoins": "Buy Coins",
      "yourCoins": "Your Coins",
      "confirm": "Confirm",
      "cancel": "Cancel",
      "characterDetails": "Character Details",
      "characterType": "Type",
      "characterAbilities": "Abilities",
      "allCharactersPurchased": "You've purchased all characters!",
      "goToMarketplace": "Go to Store",
      "levelCompleteTransfer": "Transferring...",
      "gameCompleteTitle": "Congratulations! You completed the game! 🎉",
      "gameCompleteMessage": "Take a screenshot of your completion and send it to us at 3almaShe.com",
      "gameCompleteReward": "🎁 Your reward: Highlight your ad on our website for free for one month!",
      "gameCompleteInstructions": "💚 Just send the picture to us via social media or through your account on our website and tell us which ad you want to highlight to appear at the top of search results",
      "returnToMainMenu": "Return to Main Menu",
      "gameError": "Error loading game",
      "pleaseTryAgain": "Please try again",
      "points": "Points",
      "level": "Level",
      "tapToThrow": "Tap to throw packages! 📦",
      "tapToFight": "Tap to fight! ⚔️",
      "tapToAttack": "Tap to attack enemies! 🎯",
      "timeSpent": "Time taken",
      "adsRemoval": "Remove Ads",
      "removeAds": "Remove Ads",
      "adsRemovalDescription": "Enjoy ad-free gaming experience",
      "currentAdsStatus": "Current Ads Status",
      "adsEnabled": "Ads Enabled",
      "adsDisabled": "Ads Disabled",
      "removeAdsFor": "Remove Ads for",
      "hours": "hours",
      "days": "days",
      "months": "months",
      "years": "years",
      "lifetime": "Lifetime",
      "purchase": "Purchase",
      "purchaseSuccessful": "Purchase Successful",
      "remainingTime": "Remaining Time",
      "active": "Active",
      "expired": "Expired",
      "purchaseConfirmationAds":  "Do you want to purchase ad removal for %duration% at %price%?",
      "purchaseSuccessMessage": "Ads removed successfully! Enjoy better gaming experience.",
      "purchaseErrorMessage": "An error occurred during purchase. Please try again.",
      "noAdsEnjoy": "No Ads - Enjoy Playing!",
      "watchAdToRemove": "Watch ad to remove ads for",
      "removeAdsTemporarily": "Temporary Ad Removal",
      'weeks': 'weeks',
      'minutes': 'minutes',
      "termsIntro1": "By using the game, you agree to comply with these terms and conditions. Please read them carefully before starting to play.",
      "termsPoint1": "By installing or using the game, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree with any part of the terms, please do not use the game.",
      "termsPoint2": "We grant you a limited, non-exclusive, non-transferable license to use the game solely for personal entertainment purposes. The following is strictly prohibited:\n• Modifying, copying, or reselling the game or any part of it.\n• Using the game for unauthorized commercial purposes.\n• Attempting to access the source code or bypass security measures.",
      "termsPoint3": "The game may contain items that can be purchased or unlocked during gameplay. All virtual items (such as characters, points, or in-game currency) have no real monetary value and cannot be exchanged for real money.",
      "termsPoint4": "The game may display advertisements or use third-party services such as Unity Ads or Google AdMob. We are not responsible for the content or accuracy of any advertisements or external links that appear within the game.",
      "termsPoint5": "We reserve the right to update, modify, or temporarily or permanently suspend the game at any time without prior notice. Some updates may require re-downloading or reinstalling the game.",
      "termsPoint6": "The game is provided \"AS IS\" without any express or implied warranties. We are not liable for any direct or indirect damages resulting from your use of the game, including data loss or malfunctions.",
      "termsPoint7": "We reserve the right to suspend your access to the game at any time if you violate these terms or use the game unlawfully.",
      "termsPoint8": "These terms are governed by and interpreted in accordance with the laws of the game developer's country, without regard to conflict of law principles.",
      "termsPoint9": "For any inquiries or feedback regarding the terms of use, you can contact us via email:\n📧 support@3almashe.com",
      "manageAds": "Manage Ads",
      "adFailedMessage": "The ad could not be loaded. Please try again later.",
      'tapAnywhereToAim': 'Tap anywhere to aim and attack! 🎯',
      'aimAttackDescription': 'You can now aim attacks precisely - tap anywhere on screen to attack in that direction',
      'adsStatus': 'Ads Status',
      'powerUpHealth': 'Health Boost',
      'powerUpSpeedBoost': 'Speed Boost',
      'powerUpSlowEnemies': 'Slow Enemies',
      'powerUpCoin': 'Golden Coin',
      'powerUpPoints': 'Quick Points',
      'powerUpShield': 'Protective Shield',
      'powerUpSlowMotion': 'Slow Motion',
      'powerUpDoublePoints': 'Double Points',
      'powerUpSlowCharacter': 'Temporary Slow',

      'powerUpHealthDesc': 'Restores 25% of missing health',
      'powerUpSpeedBoostDesc': 'Increases movement speed by 50%',
      'powerUpSlowEnemiesDesc': 'Slows enemy movement by 60%',
      'powerUpCoinDesc': 'One coin for shop + 3 points',
      'powerUpPointsDesc': 'Grants 8 instant points',
      'powerUpShieldDesc': 'Complete damage protection',
      'powerUpSlowMotionDesc': 'Slows time by 70%',
      'powerUpDoublePointsDesc': 'Doubles points earned',
      'powerUpSlowCharacterDesc': 'Slows character movement by 40%',
      'powerUpHealthEffect': '+25% health',
      'powerUpSpeedBoostEffect': '+50% speed',
      'powerUpSlowEnemiesEffect': '-60% enemy speed',
      'powerUpCoinEffect': '+1 coin +3 points',
      'powerUpPointsEffect': '+8 points',
      'powerUpShieldEffect': 'Full protection',
      'powerUpSlowMotionEffect': '-70% time speed',
      'powerUpDoublePointsEffect': '×2 points',
      'powerUpSlowCharacterEffect': '-40% character speed',
      'powerUpRarity': 'Rarity',
      'powerUpRarityCommon': 'Common',
      'powerUpRarityUncommon': 'Uncommon',
      'powerUpRarityRare': 'Rare',
      'powerUpRarityLegendary': 'Legendary',
      'powerUpEffect': 'Effect',
      'powerUpEffectInstant': 'Instant',
      'powerUpSeconds': 'seconds',
      'powerUpTotalCollected': 'Total Power-ups Collected',
      'powerUpTotalEffectTime': 'Total Effect Time',
      'powerUpCollected': 'Collected',
      'powerUpSpawned': 'Spawned',
      "powerUpDuration": "Duration",
      "powerUpActivated": "PowerUp Activated",
      "powerUpExpired": "PowerUp Expired",
      "paymentNotAvailable": "Payment system not available",
      "paymentReady": "Payment system ready"
    },
  };

  // جميع الـ getters
  String get paymentNotAvailable => _localizedValues[locale.languageCode]!['paymentNotAvailable']!;
  String get paymentReady => _localizedValues[locale.languageCode]!['paymentReady']!;
  String get powerUpDuration => _localizedValues[locale.languageCode]!['powerUpDuration']!;
  String get powerUpActivated => _localizedValues[locale.languageCode]!['powerUpActivated']!;
  String get powerUpExpired => _localizedValues[locale.languageCode]!['powerUpExpired']!;
  String get adsStatus => _localizedValues[locale.languageCode]!['adsStatus']!;
  String get manageAds => _localizedValues[locale.languageCode]!['manageAds']!;
  String get adFailedMessage => _localizedValues[locale.languageCode]!['adFailedMessage']!;
  String get weeks => _localizedValues[locale.languageCode]!['weeks']!;
  String get minutes => _localizedValues[locale.languageCode]!['minutes']!;
  String get confirmPurchase => _localizedValues[locale.languageCode]!['confirmPurchase']!;
  String get purchaseConfirmationAds => _localizedValues[locale.languageCode]!['purchaseConfirmationAds']!;
  String purchaseConfirmation(String characterName, int price) => _localizedValues[locale.languageCode]!['purchaseConfirmation']!.replaceFirst('%s', characterName).replaceFirst('%d', price.toString());
  String get characterAlreadyOwned => _localizedValues[locale.languageCode]!['characterAlreadyOwned']!;
  String purchaseSuccess(String characterName) => _localizedValues[locale.languageCode]!['purchaseSuccess']!.replaceFirst('%s', characterName);
  String get purchaseFailed => _localizedValues[locale.languageCode]!['purchaseFailed']!;
  String get owned => _localizedValues[locale.languageCode]!['owned']!;
  String get selected => _localizedValues[locale.languageCode]!['selected']!;
  String get buyNow => _localizedValues[locale.languageCode]!['buyNow']!;
  String get select => _localizedValues[locale.languageCode]!['select']!;
  String get characters => _localizedValues[locale.languageCode]!['characters']!;
  String get loadingCharacters => _localizedValues[locale.languageCode]!['loadingCharacters']!;
  String get noCharactersAvailable => _localizedValues[locale.languageCode]!['noCharactersAvailable']!;
  String get characterLoadError => _localizedValues[locale.languageCode]!['characterLoadError']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get goToCharacters => _localizedValues[locale.languageCode]!['goToCharacters']!;
  String get watchAdForCoins => _localizedValues[locale.languageCode]!['watchAdForCoins']!;
  String coinsAdded(int coins) => _localizedValues[locale.languageCode]!['coinsAdded']!.replaceFirst('%d', coins.toString());
  String get adFailed => _localizedValues[locale.languageCode]!['adFailed']!;
  String get buyCoins => _localizedValues[locale.languageCode]!['buyCoins']!;
  String get watchAd => _localizedValues[locale.languageCode]!['watchAd']!;
  String get yourCoins => _localizedValues[locale.languageCode]!['yourCoins']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get characterDetails => _localizedValues[locale.languageCode]!['characterDetails']!;
  String get characterType => _localizedValues[locale.languageCode]!['characterType']!;
  String get characterAbilities => _localizedValues[locale.languageCode]!['characterAbilities']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get allCharactersPurchased => _localizedValues[locale.languageCode]!['allCharactersPurchased']!;
  String get goToMarketplace => _localizedValues[locale.languageCode]!['goToMarketplace']!;
  String get choseAnotherCharacter => _localizedValues[locale.languageCode]!['choseAnotherCharacter']!;
  String get choseCharacter => _localizedValues[locale.languageCode]!['choseCharacter']!;
  String get gameOverSuccess => _localizedValues[locale.languageCode]!['gameOverSuccess']!;
  String get gameOverLevelCompleted => _localizedValues[locale.languageCode]!['gameOverLevelCompleted']!;
  String get gameOverCoinsEarned => _localizedValues[locale.languageCode]!['gameOverCoinsEarned']!;
  String get gameOverContinue => _localizedValues[locale.languageCode]!['gameOverContinue']!;
  String get gameOverContinueDesc => _localizedValues[locale.languageCode]!['gameOverContinueDesc']!;
  String get gameOverNextLevelDesc => _localizedValues[locale.languageCode]!['gameOverNextLevelDesc']!;
  String get gameOverRestartDesc => _localizedValues[locale.languageCode]!['gameOverRestartDesc']!;
  String get gameOverLevelsDesc => _localizedValues[locale.languageCode]!['gameOverLevelsDesc']!;
  String get gameOverMainMenuDesc => _localizedValues[locale.languageCode]!['gameOverMainMenuDesc']!;
  String get gameOverAdTitle => _localizedValues[locale.languageCode]!['gameOverAdTitle']!;
  String get gameOverAdDesc => _localizedValues[locale.languageCode]!['gameOverAdDesc']!;
  String get gameOverLoadError => _localizedValues[locale.languageCode]!['gameOverLoadError']!;
  String get gameOverCongratulations => _localizedValues[locale.languageCode]!['gameOverCongratulations']!;
  String get gameOverAllLevelsCompleted => _localizedValues[locale.languageCode]!['gameOverAllLevelsCompleted']!;
  String get gameOverChampion => _localizedValues[locale.languageCode]!['gameOverChampion']!;
  String get gameOverAwesome => _localizedValues[locale.languageCode]!['gameOverAwesome']!;
  String get levelComplete => _localizedValues[locale.languageCode]!['levelComplete']!;
  String get levelCompleteCongratulations => _localizedValues[locale.languageCode]!['levelCompleteCongratulations']!;
  String levelCompleteMessage(String levelName) => _localizedValues[locale.languageCode]!['levelCompleteMessage']!.replaceFirst('%s', levelName);
  String levelCompleteUnlocked(int levelNumber) => _localizedValues[locale.languageCode]!['levelCompleteUnlocked']!.replaceFirst('%d', levelNumber.toString());
  String get slow => _localizedValues[locale.languageCode]!['slow']!;
  String get speed => _localizedValues[locale.languageCode]!['speed']!;
  String get resetWillDelet => _localizedValues[locale.languageCode]!['resetWillDelet']!;
  String get resetDone => _localizedValues[locale.languageCode]!['resetDone']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get shareWithFriends => _localizedValues[locale.languageCode]!['shareWithFriends']!;
  String get shareOnly => _localizedValues[locale.languageCode]!['shareOnly']!;
  String get later => _localizedValues[locale.languageCode]!['later']!;
  String get rateNow => _localizedValues[locale.languageCode]!['rateNow']!;
  String get rate => _localizedValues[locale.languageCode]!['rate']!;
  String get rateYouHappy => _localizedValues[locale.languageCode]!['rateYouHappy']!;
  String get rateHelpUs => _localizedValues[locale.languageCode]!['rateHelpUs']!;
  String get termsLaw => _localizedValues[locale.languageCode]!['termsLaw']!;
  String get termsTermination => _localizedValues[locale.languageCode]!['termsTermination']!;
  String get termsDisclaimer => _localizedValues[locale.languageCode]!['termsDisclaimer']!;
  String get termsUpdates => _localizedValues[locale.languageCode]!['termsUpdates']!;
  String get termsAds => _localizedValues[locale.languageCode]!['termsAds']!;
  String get termsContent => _localizedValues[locale.languageCode]!['termsContent']!;
  String get termsLicense => _localizedValues[locale.languageCode]!['termsLicense']!;
  String get termsAcceptance => _localizedValues[locale.languageCode]!['termsAcceptance']!;
  String get lastUpdate => _localizedValues[locale.languageCode]!['lastUpdate']!;
  String get welcomeToGame => _localizedValues[locale.languageCode]!['welcomeToGame']!;
  String get gameName => _localizedValues[locale.languageCode]!['gameName']!;
  String get we => _localizedValues[locale.languageCode]!['we']!;
  String get theGame => _localizedValues[locale.languageCode]!['theGame']!;
  String get developmentTeam => _localizedValues[locale.languageCode]!['developmentTeam']!;
  String get privacyPolicyIntro => _localizedValues[locale.languageCode]!['privacyPolicyIntro']!;
  String get dataWeCollect => _localizedValues[locale.languageCode]!['dataWeCollect']!;
  String get privacyPoint1 => _localizedValues[locale.languageCode]!['privacyPoint1']!;
  String get privacyPoint2 => _localizedValues[locale.languageCode]!['privacyPoint2']!;
  String get privacyPoint3 => _localizedValues[locale.languageCode]!['privacyPoint3']!;
  String get privacyPoint4 => _localizedValues[locale.languageCode]!['privacyPoint4']!;
  String get adsAndThirdParties => _localizedValues[locale.languageCode]!['adsAndThirdParties']!;
  String get adsPoint1 => _localizedValues[locale.languageCode]!['adsPoint1']!;
  String get adsPoint2 => _localizedValues[locale.languageCode]!['adsPoint2']!;
  String get inAppPurchases => _localizedValues[locale.languageCode]!['inAppPurchases']!;
  String get purchasesPoint1 => _localizedValues[locale.languageCode]!['purchasesPoint1']!;
  String get dataSecurity => _localizedValues[locale.languageCode]!['dataSecurity']!;
  String get securityPoint1 => _localizedValues[locale.languageCode]!['securityPoint1']!;
  String get securityPoint2 => _localizedValues[locale.languageCode]!['securityPoint2']!;
  String get childrenPrivacy => _localizedValues[locale.languageCode]!['childrenPrivacy']!;
  String get childrenPoint1 => _localizedValues[locale.languageCode]!['childrenPoint1']!;
  String get childrenPoint2 => _localizedValues[locale.languageCode]!['childrenPoint2']!;
  String get policyChanges => _localizedValues[locale.languageCode]!['policyChanges']!;
  String get changesPoint1 => _localizedValues[locale.languageCode]!['changesPoint1']!;
  String get changesPoint2 => _localizedValues[locale.languageCode]!['changesPoint2']!;
  String get contactUs => _localizedValues[locale.languageCode]!['contactUs']!;
  String get contactPoint1 => _localizedValues[locale.languageCode]!['contactPoint1']!;
  String get PrivacyPolicy => _localizedValues[locale.languageCode]!['PrivacyPolicy']!;
  String get ReadOurPrivacyPolicy => _localizedValues[locale.languageCode]!['ReadOurPrivacyPolicy']!;
  String get TermsOfUse => _localizedValues[locale.languageCode]!['TermsOfUse']!;
  String get ReadTheTermsOfUse => _localizedValues[locale.languageCode]!['ReadTheTermsOfUse']!;
  String get gameTitle => _localizedValues[locale.languageCode]!['gameTitle']!;
  String get play => _localizedValues[locale.languageCode]!['play']!;
  String get levels => _localizedValues[locale.languageCode]!['levels']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get store => _localizedValues[locale.languageCode]!['store']!;
  String get score => _localizedValues[locale.languageCode]!['score']!;
  String get highScore => _localizedValues[locale.languageCode]!['highScore']!;
  String get coins => _localizedValues[locale.languageCode]!['coins']!;
  String get totalCoins => _localizedValues[locale.languageCode]!['totalCoins']!;
  String get unlockedLevels => _localizedValues[locale.languageCode]!['unlockedLevels']!;
  String get currentLevel => _localizedValues[locale.languageCode]!['currentLevel']!;
  String get target => _localizedValues[locale.languageCode]!['target']!;
  String get progress => _localizedValues[locale.languageCode]!['progress']!;
  String get time => _localizedValues[locale.languageCode]!['time']!;
  String get lives => _localizedValues[locale.languageCode]!['lives']!;
  String get health => _localizedValues[locale.languageCode]!['health']!;
  String get shield => _localizedValues[locale.languageCode]!['shield']!;
  String get slowMotion => _localizedValues[locale.languageCode]!['slowMotion']!;
  String get doublePoints => _localizedValues[locale.languageCode]!['doublePoints']!;
  String get gameOver => _localizedValues[locale.languageCode]!['gameOver']!;
  String get congratulations => _localizedValues[locale.languageCode]!['congratulations']!;
  String get wellDone => _localizedValues[locale.languageCode]!['wellDone']!;
  String get bossWarning => _localizedValues[locale.languageCode]!['bossWarning']!;
  String get bossAppear => _localizedValues[locale.languageCode]!['bossAppear']!;
  String get bossDefeated => _localizedValues[locale.languageCode]!['bossDefeated']!;
  String get resume => _localizedValues[locale.languageCode]!['resume']!;
  String get restart => _localizedValues[locale.languageCode]!['restart']!;
  String get restartLevel => _localizedValues[locale.languageCode]!['restartLevel']!;
  String get nextLevel => _localizedValues[locale.languageCode]!['nextLevel']!;
  String get mainMenu => _localizedValues[locale.languageCode]!['mainMenu']!;
  String get levelsMenu => _localizedValues[locale.languageCode]!['levelsMenu']!;
  String get chooseLevel => _localizedValues[locale.languageCode]!['chooseLevel']!;
  String get watchAdToContinue => _localizedValues[locale.languageCode]!['watchAdToContinue']!;
  String get loadingAd => _localizedValues[locale.languageCode]!['loadingAd']!;
  String get adPlaying => _localizedValues[locale.languageCode]!['adPlaying']!;
  String get sound => _localizedValues[locale.languageCode]!['sound']!;
  String get music => _localizedValues[locale.languageCode]!['music']!;
  String get share => _localizedValues[locale.languageCode]!['share']!;
  String get vibration => _localizedValues[locale.languageCode]!['vibration']!;
  String get notifications => _localizedValues[locale.languageCode]!['notifications']!;
  String get tutorialJump => _localizedValues[locale.languageCode]!['tutorialJump']!;
  String get tutorialDuck => _localizedValues[locale.languageCode]!['tutorialDuck']!;
  String get tutorialAttack => _localizedValues[locale.languageCode]!['tutorialAttack']!;
  String get combo => _localizedValues[locale.languageCode]!['combo']!;
  String get flash => _localizedValues[locale.languageCode]!['flash']!;
  String get aboutGame => _localizedValues[locale.languageCode]!['aboutGame']!;
  String get newRecord => _localizedValues[locale.languageCode]!['newRecord']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get loadingGame => _localizedValues[locale.languageCode]!['loadingGame']!;
  String get loadingLevels => _localizedValues[locale.languageCode]!['loadingLevels']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get adError => _localizedValues[locale.languageCode]!['adError']!;
  String get aboutGameSubject1 => _localizedValues[locale.languageCode]!['aboutGameSubject1']!;
  String get aboutGameSubject2 => _localizedValues[locale.languageCode]!['aboutGameSubject2']!;
  String get VisitWebsite => _localizedValues[locale.languageCode]!['VisitWebsite']!;
  String get version => _localizedValues[locale.languageCode]!['version']!;
  String get developer => _localizedValues[locale.languageCode]!['developer']!;
  String get aboutDesecration => _localizedValues[locale.languageCode]!['aboutDesecration']!;
  String get aboutTheWebsite => _localizedValues[locale.languageCode]!['aboutTheWebsite']!;
  String get aboutLanguage => _localizedValues[locale.languageCode]!['aboutLanguage']!;
  String get aboutOpenWebsite => _localizedValues[locale.languageCode]!['aboutOpenWebsite']!;
  String get aboutCancel => _localizedValues[locale.languageCode]!['aboutCancel']!;
  String get aboutOpenLink => _localizedValues[locale.languageCode]!['aboutOpenLink']!;
  String get SettingsStatistics => _localizedValues[locale.languageCode]!['SettingsStatistics']!;
  String get SettingsApplicationProcedures => _localizedValues[locale.languageCode]!['SettingsApplicationProcedures']!;
  String get SettingsGameRating => _localizedValues[locale.languageCode]!['SettingsGameRating']!;
  String get SettingsYourReview => _localizedValues[locale.languageCode]!['SettingsYourReview']!;
  String get SettingsShareWithFriends => _localizedValues[locale.languageCode]!['SettingsShareWithFriends']!;
  String get SettingsDeleteAllData => _localizedValues[locale.languageCode]!['SettingsDeleteAllData']!;
  String get SettingsResetData => _localizedValues[locale.languageCode]!['SettingsResetData']!;
  String get almaSheTeam => _localizedValues[locale.languageCode]!['almaSheTeam']!;
  String get levelName1 => _localizedValues[locale.languageCode]!['levelName1']!;
  String get levelName2 => _localizedValues[locale.languageCode]!['levelName2']!;
  String get levelName3 => _localizedValues[locale.languageCode]!['levelName3']!;
  String get levelName4 => _localizedValues[locale.languageCode]!['levelName4']!;
  String get levelName5 => _localizedValues[locale.languageCode]!['levelName5']!;
  String get levelName6 => _localizedValues[locale.languageCode]!['levelName6']!;
  String get levelName7 => _localizedValues[locale.languageCode]!['levelName7']!;
  String get levelName8 => _localizedValues[locale.languageCode]!['levelName8']!;
  String get levelName9 => _localizedValues[locale.languageCode]!['levelName9']!;
  String get levelName10 => _localizedValues[locale.languageCode]!['levelName10']!;
  String get levelName11 => _localizedValues[locale.languageCode]!['levelName11']!;
  String get levelName12 => _localizedValues[locale.languageCode]!['levelName12']!;
  String get levelName13 => _localizedValues[locale.languageCode]!['levelName13']!;
  String get levelName14 => _localizedValues[locale.languageCode]!['levelName14']!;
  String get levelName15 => _localizedValues[locale.languageCode]!['levelName15']!;
  String get levelName16 => _localizedValues[locale.languageCode]!['levelName16']!;
  String get levelName17 => _localizedValues[locale.languageCode]!['levelName17']!;
  String get levelName18 => _localizedValues[locale.languageCode]!['levelName18']!;
  String get levelName19 => _localizedValues[locale.languageCode]!['levelName19']!;
  String get levelName20 => _localizedValues[locale.languageCode]!['levelName20']!;
  String get levelDesc1 => _localizedValues[locale.languageCode]!['levelDesc1']!;
  String get levelDesc2 => _localizedValues[locale.languageCode]!['levelDesc2']!;
  String get levelDesc3 => _localizedValues[locale.languageCode]!['levelDesc3']!;
  String get levelDesc4 => _localizedValues[locale.languageCode]!['levelDesc4']!;
  String get levelDesc5 => _localizedValues[locale.languageCode]!['levelDesc5']!;
  String get levelDesc6 => _localizedValues[locale.languageCode]!['levelDesc6']!;
  String get levelDesc7 => _localizedValues[locale.languageCode]!['levelDesc7']!;
  String get levelDesc8 => _localizedValues[locale.languageCode]!['levelDesc8']!;
  String get levelDesc9 => _localizedValues[locale.languageCode]!['levelDesc9']!;
  String get levelDesc10 => _localizedValues[locale.languageCode]!['levelDesc10']!;
  String get levelDesc11 => _localizedValues[locale.languageCode]!['levelDesc11']!;
  String get levelDesc12 => _localizedValues[locale.languageCode]!['levelDesc12']!;
  String get levelDesc13 => _localizedValues[locale.languageCode]!['levelDesc13']!;
  String get levelDesc14 => _localizedValues[locale.languageCode]!['levelDesc14']!;
  String get levelDesc15 => _localizedValues[locale.languageCode]!['levelDesc15']!;
  String get levelDesc16 => _localizedValues[locale.languageCode]!['levelDesc16']!;
  String get levelDesc17 => _localizedValues[locale.languageCode]!['levelDesc17']!;
  String get levelDesc18 => _localizedValues[locale.languageCode]!['levelDesc18']!;
  String get levelDesc19 => _localizedValues[locale.languageCode]!['levelDesc19']!;
  String get levelDesc20 => _localizedValues[locale.languageCode]!['levelDesc20']!;
  String get pauseTitle => _localizedValues[locale.languageCode]!['pauseTitle']!;
  String get tapToThrow => _localizedValues[locale.languageCode]!['tapToThrow']!;
  String get tapToFight => _localizedValues[locale.languageCode]!['tapToFight']!;
  String get tapToAttack => _localizedValues[locale.languageCode]!['tapToAttack']!;
  String get pauseResumeDesc => _localizedValues[locale.languageCode]!['pauseResumeDesc']!;
  String get pauseRestartDesc => _localizedValues[locale.languageCode]!['pauseRestartDesc']!;
  String get pauseMainMenuDesc => _localizedValues[locale.languageCode]!['pauseMainMenuDesc']!;
  String get pauseLanguage => _localizedValues[locale.languageCode]!['pauseLanguage']!;
  String get pauseAdRestart => _localizedValues[locale.languageCode]!['pauseAdRestart']!;
  String get pauseAdMainMenu => _localizedValues[locale.languageCode]!['pauseAdMainMenu']!;
  String get tutorialTitle => _localizedValues[locale.languageCode]!['tutorialTitle']!;
  String get tutorialDragHorizontal => _localizedValues[locale.languageCode]!['tutorialDragHorizontal']!;
  String get tutorialDragHorizontalDesc => _localizedValues[locale.languageCode]!['tutorialDragHorizontalDesc']!;
  String get tutorialDragUpSmall => _localizedValues[locale.languageCode]!['tutorialDragUpSmall']!;
  String get tutorialDragUpSmallDesc => _localizedValues[locale.languageCode]!['tutorialDragUpSmallDesc']!;
  String get tutorialDragUpLarge => _localizedValues[locale.languageCode]!['tutorialDragUpLarge']!;
  String get tutorialDragUpLargeDesc => _localizedValues[locale.languageCode]!['tutorialDragUpLargeDesc']!;
  String get tutorialDragDown => _localizedValues[locale.languageCode]!['tutorialDragDown']!;
  String get tutorialDragDownDesc => _localizedValues[locale.languageCode]!['tutorialDragDownDesc']!;
  String get tutorialFullControl => _localizedValues[locale.languageCode]!['tutorialFullControl']!;
  String get tutorialFullControlDesc => _localizedValues[locale.languageCode]!['tutorialFullControlDesc']!;
  String get tutorialTapAnywhere => _localizedValues[locale.languageCode]!['tutorialTapAnywhere']!;
  String get tutorialAutoHide => _localizedValues[locale.languageCode]!['tutorialAutoHide']!;
  String get bossNotification => _localizedValues[locale.languageCode]!['bossNotification']!;
  String get gameSlogan => _localizedValues[locale.languageCode]!['gameSlogan']!;
  String get characterStore => _localizedValues[locale.languageCode]!['characterStore']!;
  String get yourPoints => _localizedValues[locale.languageCode]!['yourPoints']!;
  String get buyPoints => _localizedValues[locale.languageCode]!['buyPoints']!;
  String get purchasedSuccessfully => _localizedValues[locale.languageCode]!['purchasedSuccessfully']!;
  String get insufficientPoints => _localizedValues[locale.languageCode]!['insufficientPoints']!;
  String get watchAdForPoints => _localizedValues[locale.languageCode]!['watchAdForPoints']!;
  String get selectCharacter => _localizedValues[locale.languageCode]!['selectCharacter']!;
  String get characterSelected => _localizedValues[locale.languageCode]!['characterSelected']!;
  String get characterOwned => _localizedValues[locale.languageCode]!['characterOwned']!;
  String get characterLocked => _localizedValues[locale.languageCode]!['characterLocked']!;
  String get pointsPackage => _localizedValues[locale.languageCode]!['pointsPackage']!;
  String get freePoints => _localizedValues[locale.languageCode]!['freePoints']!;
  String get myCharacters => _localizedValues[locale.languageCode]!['myCharacters']!;
  String get purchaseNow => _localizedValues[locale.languageCode]!['purchaseNow']!;
  String get goToStore => _localizedValues[locale.languageCode]!['goToStore']!;
  String get ownedCharacters => _localizedValues[locale.languageCode]!['ownedCharacters']!;
  String get availableForPurchase => _localizedValues[locale.languageCode]!['availableForPurchase']!;
  String get noCharactersOwned => _localizedValues[locale.languageCode]!['noCharactersOwned']!;
  String get allCharactersOwned => _localizedValues[locale.languageCode]!['allCharactersOwned']!;
  String get buyCoinsNow => _localizedValues[locale.languageCode]!['buyCoinsNow']!;
  String get levelCompleteTransfer => _localizedValues[locale.languageCode]!['levelCompleteTransfer']!;
  String get gameCompleteTitle => _localizedValues[locale.languageCode]!['gameCompleteTitle']!;
  String get gameCompleteMessage => _localizedValues[locale.languageCode]!['gameCompleteMessage']!;
  String get gameCompleteReward => _localizedValues[locale.languageCode]!['gameCompleteReward']!;
  String get gameCompleteInstructions => _localizedValues[locale.languageCode]!['gameCompleteInstructions']!;
  String get returnToMainMenu => _localizedValues[locale.languageCode]!['returnToMainMenu']!;
  String get gameError => _localizedValues[locale.languageCode]!['gameError']!;
  String get pleaseTryAgain => _localizedValues[locale.languageCode]!['pleaseTryAgain']!;
  String get points => _localizedValues[locale.languageCode]!['points']!;
  String get level => _localizedValues[locale.languageCode]!['level']!;
  String get timeSpent => _localizedValues[locale.languageCode]!['timeSpent']!;
  String get adsRemoval => _localizedValues[locale.languageCode]!['adsRemoval']!;
  String get removeAds => _localizedValues[locale.languageCode]!['removeAds']!;
  String get adsRemovalDescription => _localizedValues[locale.languageCode]!['adsRemovalDescription']!;
  String get currentAdsStatus => _localizedValues[locale.languageCode]!['currentAdsStatus']!;
  String get adsEnabled => _localizedValues[locale.languageCode]!['adsEnabled']!;
  String get adsDisabled => _localizedValues[locale.languageCode]!['adsDisabled']!;
  String get removeAdsFor => _localizedValues[locale.languageCode]!['removeAdsFor']!;
  String get hours => _localizedValues[locale.languageCode]!['hours']!;
  String get days => _localizedValues[locale.languageCode]!['days']!;
  String get months => _localizedValues[locale.languageCode]!['months']!;
  String get years => _localizedValues[locale.languageCode]!['years']!;
  String get lifetime => _localizedValues[locale.languageCode]!['lifetime']!;
  String get purchase => _localizedValues[locale.languageCode]!['purchase']!;
  String get purchaseSuccessful => _localizedValues[locale.languageCode]!['purchaseSuccessful']!;
  String get remainingTime => _localizedValues[locale.languageCode]!['remainingTime']!;
  String get active => _localizedValues[locale.languageCode]!['active']!;
  String get expired => _localizedValues[locale.languageCode]!['expired']!;
  String get purchaseSuccessMessage => _localizedValues[locale.languageCode]!['purchaseSuccessMessage']!;
  String get purchaseErrorMessage => _localizedValues[locale.languageCode]!['purchaseErrorMessage']!;
  String get noAdsEnjoy => _localizedValues[locale.languageCode]!['noAdsEnjoy']!;
  String get watchAdToRemove => _localizedValues[locale.languageCode]!['watchAdToRemove']!;
  String get removeAdsTemporarily => _localizedValues[locale.languageCode]!['removeAdsTemporarily']!;
  String get termsIntro1 => _localizedValues[locale.languageCode]!['termsIntro1']!;
  String get termsPoint1 => _localizedValues[locale.languageCode]!['termsPoint1']!;
  String get termsPoint2 => _localizedValues[locale.languageCode]!['termsPoint2']!;
  String get termsPoint3 => _localizedValues[locale.languageCode]!['termsPoint3']!;
  String get termsPoint4 => _localizedValues[locale.languageCode]!['termsPoint4']!;
  String get termsPoint5 => _localizedValues[locale.languageCode]!['termsPoint5']!;
  String get termsPoint6 => _localizedValues[locale.languageCode]!['termsPoint6']!;
  String get termsPoint7 => _localizedValues[locale.languageCode]!['termsPoint7']!;
  String get termsPoint8 => _localizedValues[locale.languageCode]!['termsPoint8']!;
  String get termsPoint9 => _localizedValues[locale.languageCode]!['termsPoint9']!;
  String get day => _localizedValues[locale.languageCode]!['day']!;
  String get hour => _localizedValues[locale.languageCode]!['hour']!;
  String get minute => _localizedValues[locale.languageCode]!['minute']!;
  String get tapAnywhereToAim => _localizedValues[locale.languageCode]!['tapAnywhereToAim']!;
  String get aimAttackDescription => _localizedValues[locale.languageCode]!['aimAttackDescription']!;
  // جميع الـ getters للباور أب
  String get powerUpHealth => _localizedValues[locale.languageCode]!["powerUpHealth"]!;
  String get powerUpSpeedBoost => _localizedValues[locale.languageCode]!["powerUpSpeedBoost"]!;
  String get powerUpSlowEnemies => _localizedValues[locale.languageCode]!["powerUpSlowEnemies"]!;
  String get powerUpCoin => _localizedValues[locale.languageCode]!["powerUpCoin"]!;
  String get powerUpPoints => _localizedValues[locale.languageCode]!["powerUpPoints"]!;
  String get powerUpShield => _localizedValues[locale.languageCode]!["powerUpShield"]!;
  String get powerUpSlowMotion => _localizedValues[locale.languageCode]!["powerUpSlowMotion"]!;
  String get powerUpDoublePoints => _localizedValues[locale.languageCode]!["powerUpDoublePoints"]!;
  String get powerUpSlowCharacter => _localizedValues[locale.languageCode]!["powerUpSlowCharacter"]!;
// أوصاف الباور أب
  String get powerUpHealthDesc => _localizedValues[locale.languageCode]!["powerUpHealthDesc"]!;
  String get powerUpSpeedBoostDesc => _localizedValues[locale.languageCode]!["powerUpSpeedBoostDesc"]!;
  String get powerUpSlowEnemiesDesc => _localizedValues[locale.languageCode]!["powerUpSlowEnemiesDesc"]!;
  String get powerUpCoinDesc => _localizedValues[locale.languageCode]!["powerUpCoinDesc"]!;
  String get powerUpPointsDesc => _localizedValues[locale.languageCode]!["powerUpPointsDesc"]!;
  String get powerUpShieldDesc => _localizedValues[locale.languageCode]!["powerUpShieldDesc"]!;
  String get powerUpSlowMotionDesc => _localizedValues[locale.languageCode]!["powerUpSlowMotionDesc"]!;
  String get powerUpDoublePointsDesc => _localizedValues[locale.languageCode]!["powerUpDoublePointsDesc"]!;
  String get powerUpSlowCharacterDesc => _localizedValues[locale.languageCode]!["powerUpSlowCharacterDesc"]!;
// تأثيرات الباور أب
  String get powerUpHealthEffect => _localizedValues[locale.languageCode]!["powerUpHealthEffect"]!;
  String get powerUpSpeedBoostEffect => _localizedValues[locale.languageCode]!["powerUpSpeedBoostEffect"]!;
  String get powerUpSlowEnemiesEffect => _localizedValues[locale.languageCode]!["powerUpSlowEnemiesEffect"]!;
  String get powerUpCoinEffect => _localizedValues[locale.languageCode]!["powerUpCoinEffect"]!;
  String get powerUpPointsEffect => _localizedValues[locale.languageCode]!["powerUpPointsEffect"]!;
  String get powerUpShieldEffect => _localizedValues[locale.languageCode]!["powerUpShieldEffect"]!;
  String get powerUpSlowMotionEffect => _localizedValues[locale.languageCode]!["powerUpSlowMotionEffect"]!;
  String get powerUpDoublePointsEffect => _localizedValues[locale.languageCode]!["powerUpDoublePointsEffect"]!;
  String get powerUpSlowCharacterEffect => _localizedValues[locale.languageCode]!["powerUpSlowCharacterEffect"]!;
// نظام الندرة
  String get powerUpRarity => _localizedValues[locale.languageCode]!["powerUpRarity"]!;
  String get powerUpRarityCommon => _localizedValues[locale.languageCode]!["powerUpRarityCommon"]!;
  String get powerUpRarityUncommon => _localizedValues[locale.languageCode]!["powerUpRarityUncommon"]!;
  String get powerUpRarityRare => _localizedValues[locale.languageCode]!["powerUpRarityRare"]!;
  String get powerUpRarityLegendary => _localizedValues[locale.languageCode]!["powerUpRarityLegendary"]!;
// مصطلحات عامة
  String get powerUpEffect => _localizedValues[locale.languageCode]!["powerUpEffect"]!;
  String get powerUpEffectInstant => _localizedValues[locale.languageCode]!["powerUpEffectInstant"]!;
  String get powerUpSeconds => _localizedValues[locale.languageCode]!["powerUpSeconds"]!;
// الإحصائيات
  String get powerUpTotalCollected => _localizedValues[locale.languageCode]!["powerUpTotalCollected"]!;
  String get powerUpTotalEffectTime => _localizedValues[locale.languageCode]!["powerUpTotalEffectTime"]!;
  String get powerUpCollected => _localizedValues[locale.languageCode]!["powerUpCollected"]!;
  String get powerUpSpawned => _localizedValues[locale.languageCode]!["powerUpSpawned"]!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}