import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // ✅ تعريف الـ delegate كـ static const
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
      "resetWillDelet": "هل أنت متأكد من حذف جميع بيانات اللعبة؟\\n\\nسيتم فقدان جميع النقاط والعملات والمراحل المفتوحة.",
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
      "buyCoinsNow": "اشتري عملات الان",
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
      "resetWillDelet": "Are you sure you want to delete all game data?\\\\n\\\\nAll points, coins, and unlocked levels will be lost.",
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
      "buyCoinsNow": "Buy Coins Now"
    },
  };

  // ✅ تعريف الـ getters
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
  String get close => _localizedValues[locale.languageCode]!['close']!;
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
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
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
  String get watchAd => _localizedValues[locale.languageCode]!['watchAd']!;
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
}

// ✅ تعريف الـ Delegate بشكل منفصل
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