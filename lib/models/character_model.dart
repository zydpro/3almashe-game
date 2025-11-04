// lib/models/character_model.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GameCharacter {
  final int id;
  final String name;
  final String nameEn;
  final String imagePath;
  final double price; // ✅ تغيير من int إلى double
  bool isLocked;
  final Color color;
  final List<String> animations;
  final String description;
  final String descriptionEn;
  final String type;
  final List<String> abilities;
  final String characterKey;

  // نظام الهجمات الجديد
  final String attackName;
  final String attackNameEn;
  final String attackDescription;
  final String attackDescriptionEn;
  final AttackType attackType;
  final int attackDamage;
  final double attackSpeed;
  final double attackCooldown;
  final List<String> attackEffects;
  final String attackSound;

  GameCharacter({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.imagePath,
    required this.price, // ✅ الآن double
    required this.isLocked,
    required this.color,
    required this.animations,
    required this.description,
    required this.descriptionEn,
    required this.type,
    required this.abilities,
    required this.characterKey,

    // نظام الهجمات
    required this.attackName,
    required this.attackNameEn,
    required this.attackDescription,
    required this.attackDescriptionEn,
    required this.attackType,
    required this.attackDamage,
    required this.attackSpeed,
    required this.attackCooldown,
    required this.attackEffects,
    required this.attackSound,
  });

  // ✅ دالة للحصول على السعر بتنسيق .99
  String get formattedPrice {
    return '${price.toStringAsFixed(2)}'; // سيظهر مثل 1499.99
  }

  // ✅ دالة للحصول على السعر بدون كسور للعرض
  String get displayPrice {
    return '${price.toInt()}.99'; // سيظهر مثل 1499.99
  }

  // ✅ دالة للحصول على السعر كرقم صحيح للعمليات الحسابية
  int get integerPrice {
    return price.toInt();
  }

  // دوال الترجمة
  String getName(String language) {
    return language == 'ar' ? name : nameEn;
  }

  String getDescription(String language) {
    return language == 'ar' ? description : descriptionEn;
  }

  String getAttackName(String language) {
    return language == 'ar' ? attackName : attackNameEn;
  }

  String getAttackDescription(String language) {
    return language == 'ar' ? attackDescription : attackDescriptionEn;
  }

  String getAnimationFrame(String animationState, int frameNumber) {
    final frame = frameNumber.clamp(1, 4);
    return 'assets/images/characters/$characterKey/${characterKey}_${animationState}_$frame.png';
  }

  List<String> getAnimationFrames(String animationState) {
    return List.generate(4, (index) => getAnimationFrame(animationState, index + 1));
  }

  // الحصول على فريمات الهجوم
  List<String> getAttackFrames() {
    return List.generate(4, (index) =>
    'assets/images/attacks/${_getAttackFolderName()}/${_getAttackFolderName()}_${index + 1}.png');
  }

  String _getAttackFolderName() {
    switch (attackType) {
      case AttackType.almashePackage:
        return 'almashe';
      case AttackType.rainbowBeam:
        return 'rainbow';
      case AttackType.arabicFalcon:
        return 'arabic';
      case AttackType.medievalMud:
        return 'medieval';
      case AttackType.greekLightning:
        return 'greek';
      case AttackType.snowySnowball:
        return 'snowy';
      case AttackType.fieryFireball:
        return 'fiery';
      case AttackType.technoHack:
        return 'techno';
      case AttackType.vikingHammer:
        return 'viking';
      case AttackType.comicsPow:
        return 'comics';
      case AttackType.zombieSpit:
        return 'zombie';
      case AttackType.warriorBullet:
        return 'warrior';
      default:
        return 'almashe';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'imagePath': imagePath,
      'price': price, // ✅ الآن double
      'isLocked': isLocked,
      'color': color.value,
      'animations': animations,
      'description': description,
      'descriptionEn': descriptionEn,
      'type': type,
      'abilities': abilities,
      'characterKey': characterKey,

      // نظام الهجمات
      'attackName': attackName,
      'attackNameEn': attackNameEn,
      'attackDescription': attackDescription,
      'attackDescriptionEn': attackDescriptionEn,
      'attackType': attackType.index,
      'attackDamage': attackDamage,
      'attackSpeed': attackSpeed,
      'attackCooldown': attackCooldown,
      'attackEffects': attackEffects,
      'attackSound': attackSound,
    };
  }

  factory GameCharacter.fromJson(Map<String, dynamic> json) {
    return GameCharacter(
      id: json['id'],
      name: json['name'],
      nameEn: json['nameEn'],
      imagePath: json['imagePath'],
      price: (json['price'] as num).toDouble(), // ✅ تحويل إلى double
      isLocked: json['isLocked'],
      color: Color(json['color']),
      animations: List<String>.from(json['animations']),
      description: json['description'],
      descriptionEn: json['descriptionEn'],
      type: json['type'],
      abilities: List<String>.from(json['abilities']),
      characterKey: json['characterKey'] ?? 'almashe',

      // نظام الهجمات
      attackName: json['attackName'] ?? 'هجوم',
      attackNameEn: json['attackNameEn'] ?? 'Attack',
      attackDescription: json['attackDescription'] ?? 'هجوم أساسي',
      attackDescriptionEn: json['attackDescriptionEn'] ?? 'Basic attack',
      attackType: AttackType.values[json['attackType'] ?? 0],
      attackDamage: json['attackDamage'] ?? 10,
      attackSpeed: json['attackSpeed'] ?? 0.025,
      attackCooldown: json['attackCooldown'] ?? 0.5,
      attackEffects: List<String>.from(json['attackEffects'] ?? []),
      attackSound: json['attackSound'] ?? 'sounds/effects/package_throw.wav',
    );
  }

  static GameCharacter getDefaultCharacter() {
    return GameCharacter(
      id: 1,
      name: 'عالماشي',
      nameEn: '3almaShe',
      imagePath: 'assets/images/characters/almashe/almashe_icon.png',
      price: 0.0, // ✅ مجاني
      isLocked: false,
      color: Colors.blue,
      animations: ['run', 'jump', 'attack', 'duck', 'idle'],
      description: 'شخصية عالماشي الأساسية الشجاعة تمتلك جميع الحركات الأساسية',
      descriptionEn: 'The brave basic 3almaShe character with all basic movements',
      type: 'أساسي',
      abilities: ['متوازن', 'جميع الحركات', 'سرعة متوسطة', 'قفز جيد'],
      characterKey: 'almashe',

      // نظام الهجمات
      attackName: 'صندوق عالماشي',
      attackNameEn: '3almaShe Package',
      attackDescription: 'يطلق صندوقًا يسبب ضررًا عند الاصطدام',
      attackDescriptionEn: 'Launches a box that causes damage on impact',
      attackType: AttackType.almashePackage,
      attackDamage: 15,
      attackSpeed: 0.025,
      attackCooldown: 0.5,
      attackEffects: ['ضرر مباشر'],
      attackSound: 'sounds/effects/package_throw.wav',
    );
  }

  static List<GameCharacter> getAllCharacters() {
    try {
      List<GameCharacter> characters = [];

      // ✅ إضافة جميع الشخصيات مرتبة من الأقل سعراً إلى الأعلى

      // 1. عالماشي - الصندوق الأساسي (مجاني)
      characters.add(getDefaultCharacter());

      // 2. العصور الوسطى - كرات الطين (الأقل سعراً)
      characters.add(GameCharacter(
        id: 4,
        name: 'العصور وسطى',
        nameEn: 'Medieval',
        imagePath: 'assets/images/characters/medieval/medieval_icon.png',
        price: 999.99, // ✅ سعر منخفض
        isLocked: true,
        color: Colors.orange,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية من العصور الوسطى بدرع وفروسية',
        descriptionEn: 'Medieval character with armor and chivalry',
        type: 'تاريخي',
        abilities: ['قوة دفاع', 'حركات ثقيلة', 'صلابة', 'هجمات قوية'],
        characterKey: 'medieval',

        // نظام الهجمات
        attackName: 'كرات الطين',
        attackNameEn: 'Mud Balls',
        attackDescription: 'يطلق كرات طين من الأرض لتسبب ضررًا وتبطئ حركة العدو',
        attackDescriptionEn: 'Launches mud balls from the ground that cause damage and slow enemies',
        attackType: AttackType.medievalMud,
        attackDamage: 16,
        attackSpeed: 0.022,
        attackCooldown: 0.8,
        attackEffects: ['ضرر مباشر', 'إبطاء الحركة'],
        attackSound: 'sounds/attacks/mud_throw.wav',
      ));

      // 3. ألوان الطيف - شعاع قوس قزح
      characters.add(GameCharacter(
        id: 2,
        name: 'الوان الطيف',
        nameEn: 'Rainbow Colors',
        imagePath: 'assets/images/characters/rainbow/rainbow_icon.png',
        price: 1499.99, // ✅ سعر متوسط
        isLocked: true,
        color: Colors.pink,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية ملونة زاهية تمتلك حركات متنوعة وجميلة مع تأثيرات قوس قزح',
        descriptionEn: 'Colorful vibrant character with various beautiful movements and rainbow effects',
        type: 'ألوان',
        abilities: ['قفز عالي', 'حركات سريعة', 'ألوان زاهية', 'تأثيرات ملونة'],
        characterKey: 'rainbow',

        // نظام الهجمات
        attackName: 'شعاع قوس قزح',
        attackNameEn: 'Rainbow Beam',
        attackDescription: 'يطلق شعاع قوس قزح يسبب ضررًا',
        attackDescriptionEn: 'Launches a rainbow beam that causes damage',
        attackType: AttackType.rainbowBeam,
        attackDamage: 18,
        attackSpeed: 0.03,
        attackCooldown: 0.6,
        attackEffects: ['ضرر مباشر', 'تأثير ملون'],
        attackSound: 'sounds/attacks/rainbow_beam.wav',
      ));

      // 4. إغريقي - صاعقة زيوس
      characters.add(GameCharacter(
        id: 5,
        name: 'أغريقي',
        nameEn: 'Greek',
        imagePath: 'assets/images/characters/greek/greek_icon.png',
        price: 1499.99, // ✅ سعر متوسط
        isLocked: true,
        color: Colors.blue.shade800,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية من الحضارة الإغريقية القديمة تمتاز بالقوة والصلابة',
        descriptionEn: 'Character from ancient Greek civilization known for strength and solidity',
        type: 'تاريخي',
        abilities: ['قوة هجوم', 'حركات تاريخية', 'دفاع قوي', 'صلابة'],
        characterKey: 'greek',

        // نظام الهجمات
        attackName: 'صاعقة زيوس',
        attackNameEn: 'Zeus Lightning',
        attackDescription: 'تطلق صاعقة زيوس كهربة على العدو تسبب ضررًا',
        attackDescriptionEn: 'Releases Zeus lightning that electrocutes the enemy and causes damage',
        attackType: AttackType.greekLightning,
        attackDamage: 22,
        attackSpeed: 0.035,
        attackCooldown: 0.9,
        attackEffects: ['ضرر عالي', 'تأثير كهربائي'],
        attackSound: 'sounds/attacks/lightning_strike.wav',
      ));

      // 5. عربي - الصقر العربي
      characters.add(GameCharacter(
        id: 3,
        name: 'عربي',
        nameEn: 'Arabic',
        imagePath: 'assets/images/characters/arabic/arabic_icon.png',
        price: 1699.99, // ✅ سعر فوق المتوسط
        isLocked: true,
        color: Colors.green,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية عربية تقليدية بلمسة عصرية تعكس التراث العربي الأصيل',
        descriptionEn: 'Traditional Arabic character with modern touch reflecting authentic Arab heritage',
        type: 'تراثي',
        abilities: ['قوة تحمل', 'حركات تراثية', 'ثبات عالي', 'دفاع قوي'],
        characterKey: 'arabic',

        // نظام الهجمات
        attackName: 'الصقر العربي',
        attackNameEn: 'Arabic Falcon',
        attackDescription: 'يطلق صقرًا يتجه نحو العدو ويسبب ضررًا',
        attackDescriptionEn: 'Launches a falcon that heads towards the enemy and causes damage',
        attackType: AttackType.arabicFalcon,
        attackDamage: 20,
        attackSpeed: 0.028,
        attackCooldown: 0.7,
        attackEffects: ['تتبع العدو', 'ضرر متوسط'],
        attackSound: 'sounds/attacks/falcon_call.wav',
      ));

      // 6. ثلجي - كرة الثلج
      characters.add(GameCharacter(
        id: 6,
        name: 'ثلجي',
        nameEn: 'Snowy',
        imagePath: 'assets/images/characters/snowy/snowy_icon.png',
        price: 1799.99, // ✅ سعر فوق المتوسط
        isLocked: true,
        color: Colors.cyan,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية ثلجية باردة مع تأثيرات جليدية وانزلاقية فريدة',
        descriptionEn: 'Snowy cold character with unique ice effects and sliding movements',
        type: 'طبيعي',
        abilities: ['مقاومة البرد', 'حركات انزلاقية', 'سرعة متوسطة', 'تأثيرات ثلجية'],
        characterKey: 'snowy',

        // نظام الهجمات
        attackName: 'كرة الثلج',
        attackNameEn: 'Snowball',
        attackDescription: 'تطلق كرة ثلج تسبب ضررًا وتجميدًا بسيطًا',
        attackDescriptionEn: 'Launches a snowball that causes damage and slight freezing',
        attackType: AttackType.snowySnowball,
        attackDamage: 14,
        attackSpeed: 0.026,
        attackCooldown: 0.6,
        attackEffects: ['ضرر مباشر', 'تجميد تراكمي'],
        attackSound: 'sounds/attacks/snowball_throw.wav',
      ));

      // 7. ناري - كرات النار
      characters.add(GameCharacter(
        id: 7,
        name: 'ناري',
        nameEn: 'Fiery',
        imagePath: 'assets/images/characters/fiery/fiery_icon.png',
        price: 1899.99, // ✅ سعر مرتفع
        isLocked: true,
        color: Colors.orange,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية نارية مشتعلة بالقوة والطاقة مع تأثيرات لهب حارقة',
        descriptionEn: 'Fiery character burning with power and energy with hot flame effects',
        type: 'عنصري',
        abilities: ['قوة نارية', 'هجمات سريعة', 'حركات سريعة', 'تأثيرات نارية'],
        characterKey: 'fiery',

        // نظام الهجمات
        attackName: 'كرات النار',
        attackNameEn: 'Fireballs',
        attackDescription: 'تطلق كرات نار تسبب ضررًا حارقًا مع ضرر إضافي مستمر',
        attackDescriptionEn: 'Launches fireballs that cause burning damage with additional damage over time',
        attackType: AttackType.fieryFireball,
        attackDamage: 18,
        attackSpeed: 0.029,
        attackCooldown: 0.7,
        attackEffects: ['ضرر مباشر', 'حرق مستمر'],
        attackSound: 'sounds/attacks/fireball_throw.wav',
      ));

      // 8. تقني - موجة التهكير
      characters.add(GameCharacter(
        id: 8,
        name: 'تقني',
        nameEn: 'Techno',
        imagePath: 'assets/images/characters/techno/techno_icon.png',
        price: 1999.99, // ✅ سعر مرتفع
        isLocked: true,
        color: Colors.purple,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية تكنولوجية متطورة بتقنيات حديثة وتأثيرات رقمية',
        descriptionEn: 'Advanced technological character with modern tech and digital effects',
        type: 'مستقبلي',
        abilities: ['سرعة تقنية', 'حركات دقيقة', 'هجمات دقيقة', 'تأثيرات رقمية'],
        characterKey: 'techno',

        // نظام الهجمات
        attackName: 'موجة التهكير',
        attackNameEn: 'Hack Wave',
        attackDescription: 'تطلق موجة من الأرقام الثنائية تشوش العدو وتسبب ضررًا',
        attackDescriptionEn: 'Launches a wave of binary numbers that disrupt the enemy and cause damage',
        attackType: AttackType.technoHack,
        attackDamage: 16,
        attackSpeed: 0.032,
        attackCooldown: 0.8,
        attackEffects: ['ضرر مباشر', 'تعطيل المهارات'],
        attackSound: 'sounds/attacks/hack_wave.wav',
      ));

      // 9. فايكنج - مطرقة ثور
      characters.add(GameCharacter(
        id: 9,
        name: 'محاربي الفايكنج',
        nameEn: 'Viking Warrior',
        imagePath: 'assets/images/characters/viking/viking_icon.png',
        price: 2199.99, // ✅ سعر مرتفع جداً
        isLocked: true,
        color: Colors.brown,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'محارب فايكنج قوي من الشمال يتميز بالشراسة والقوة البدنية',
        descriptionEn: 'Strong Viking warrior from the north known for ferocity and physical strength',
        type: 'محارب',
        abilities: ['قوة المحارب', 'هجمات قوية', 'دفاع ممتاز', 'شراسة'],
        characterKey: 'viking',

        // نظام الهجمات
        attackName: 'مطرقة ثور',
        attackNameEn: "Thor's Hammer",
        attackDescription: 'تطلق مطرقة ثور دوارة لتسبب ضررًا ودفع العدو للخلف',
        attackDescriptionEn: "Launches Thor's spinning hammer that causes damage and pushes enemies back",
        attackType: AttackType.vikingHammer,
        attackDamage: 24,
        attackSpeed: 0.024,
        attackCooldown: 1.0,
        attackEffects: ['ضرر عالي', 'دفع للخلف'],
        attackSound: 'sounds/attacks/hammer_throw.wav',
      ));

      // 10. كوميكس - كلمة POW
      characters.add(GameCharacter(
        id: 10,
        name: 'كوميكس',
        nameEn: 'Comics',
        imagePath: 'assets/images/characters/comics/comics_icon.png',
        price: 2299.99, // ✅ سعر مرتفع جداً
        isLocked: true,
        color: Colors.red,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية كوميكس ملونة ومليئة بالحركة والمرونة الكوميدية',
        descriptionEn: 'Colorful comics character full of movement and comedic flexibility',
        type: 'كوميكس',
        abilities: ['حركات كوميدية', 'قفزات مرنة', 'مرونة عالية', 'تأثيرات كاريكاتير'],
        characterKey: 'comics',

        // نظام الهجمات
        attackName: 'POW!',
        attackNameEn: 'POW!',
        attackDescription: 'تطلق كلمة "POW!" ملونة تجاه العدو لتسبب ضررًا كبيرًا وارتدادًا',
        attackDescriptionEn: 'Launches a colorful "POW!" word towards the enemy causing massive damage and knockback',
        attackType: AttackType.comicsPow,
        attackDamage: 28,
        attackSpeed: 0.027,
        attackCooldown: 1.2,
        attackEffects: ['ضرر كبير', 'ارتداد قوي'],
        attackSound: 'sounds/attacks/pow_sound.wav',
      ));

      // 11. زومبي - كرة اللعاب
      characters.add(GameCharacter(
        id: 11,
        name: 'زومبي',
        nameEn: 'Zombie',
        imagePath: 'assets/images/characters/zombie/zombie_icon.png',
        price: 2499.99, // ✅ سعر مميز
        isLocked: true,
        color: Colors.green.shade800,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية زومبي مرعبة مع حركات خاصة ومقاومة خارقة للضرر',
        descriptionEn: 'Scary zombie character with special movements and super damage resistance',
        type: 'رعب',
        abilities: ['مقاومة عالية', 'حركات مرعبة', 'قوة خارقة', 'تحمل الضرب'],
        characterKey: 'zombie',

        // نظام الهجمات
        attackName: 'كرة اللعاب',
        attackNameEn: 'Spit Ball',
        attackDescription: 'تبصق كرة لعاب معدية تسبب ضررًا مستمرًا مع الوقت',
        attackDescriptionEn: 'Spits an infectious saliva ball that causes damage over time',
        attackType: AttackType.zombieSpit,
        attackDamage: 12,
        attackSpeed: 0.021,
        attackCooldown: 0.9,
        attackEffects: ['ضرر مستمر', 'تسميم'],
        attackSound: 'sounds/attacks/zombie_spit.wav',
      ));

      // 12. المحارب - رصاصة M4 (الأعلى سعراً)
      characters.add(GameCharacter(
        id: 12,
        name: 'مُطلق النار',
        nameEn: 'Shooter',
        imagePath: 'assets/images/characters/warrior/warrior_icon.png',
        price: 2999.99, // ✅ الأعلى سعراً
        isLocked: true,
        color: Colors.grey.shade700,
        animations: ['run', 'jump', 'attack', 'duck', 'idle'],
        description: 'شخصية مقاتل محترف مع حركات تكتيكية وتصويب دقيق',
        descriptionEn: 'Professional fighter character with tactical movements and precise aiming',
        type: 'تكتيكي',
        abilities: ['تصويب دقيق', 'حركات تكتيكية', 'سرعة رد فعل', 'هجمات سريعة'],
        characterKey: 'warrior',

        // نظام الهجمات
        attackName: 'رصاصة M4',
        attackNameEn: 'M4 Bullet',
        attackDescription: 'تطلق رصاصة من بندقية (M4) لتسبب ضررًا مباشرًا وعاليًا',
        attackDescriptionEn: 'Fires a bullet from an M4 rifle causing direct and high damage',
        attackType: AttackType.warriorBullet,
        attackDamage: 26,
        attackSpeed: 0.038,
        attackCooldown: 0.4,
        attackEffects: ['ضرر عالي', 'سرعة إطلاق عالية'],
        attackSound: 'sounds/attacks/gun_shot.wav',
      ));

      // ✅ ترتيب القائمة حسب السعر من الأقل إلى الأعلى
      characters.sort((a, b) => a.price.compareTo(b.price));

      print('✅ تم تحميل ${characters.length} شخصية بنجاح مع نظام الهجمات والأسعار');
      print('📊 ترتيب الأسعار:');
      for (var character in characters) {
        print('   - ${character.name}: ${character.displayPrice}');
      }

      return characters;

    } catch (e) {
      print('❌ خطأ في تحميل الشخصيات: $e');
      return [getDefaultCharacter()];
    }
  }

  static List<GameCharacter> getAllCharactersSync() {
    return getAllCharacters();
  }

  static GameCharacter getCharacterById(int id) {
    try {
      return getAllCharacters().firstWhere(
            (character) => character.id == id,
        orElse: () => getDefaultCharacter(),
      );
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصية بالرقم $id: $e');
      return getDefaultCharacter();
    }
  }

  // ✅ دالة للحصول على الشخصيات مرتبة حسب السعر
  static List<GameCharacter> getCharactersSortedByPrice({bool ascending = true}) {
    try {
      final characters = getAllCharacters();
      characters.sort((a, b) => ascending
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price));
      return characters;
    } catch (e) {
      print('❌ خطأ في ترتيب الشخصيات حسب السعر: $e');
      return [getDefaultCharacter()];
    }
  }

  // ✅ دالة للحصول على الشخصيات المتاحة للشراء مرتبة حسب السعر
  static List<GameCharacter> getPurchasableCharactersSorted(List<GameCharacter> allCharacters, List<GameCharacter> ownedCharacters) {
    try {
      final purchasable = allCharacters.where((character) =>
      character.isLocked && !ownedCharacters.any((owned) => owned.id == character.id)
      ).toList();

      purchasable.sort((a, b) => a.price.compareTo(b.price));
      return purchasable;
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات المتاحة للشراء: $e');
      return [];
    }
  }

  // دوال مساعدة
  bool get isDefault => id == 1;
  String get iconPath => imagePath;
  String get displayImage => animations.isNotEmpty ? getAnimationFrame(animations[0], 1) : imagePath;

  // الحصول على معلومات الهجوم كخريطة
  Map<String, dynamic> getAttackInfo(String language) {
    return {
      'name': getAttackName(language),
      'description': getAttackDescription(language),
      'damage': attackDamage,
      'speed': attackSpeed,
      'cooldown': attackCooldown,
      'effects': attackEffects,
      'type': attackType.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GameCharacter &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GameCharacter{id: $id, name: $name, price: $displayPrice, characterKey: $characterKey}';
  }
}

// enum لأنواع الهجمات
enum AttackType {
  almashePackage,
  rainbowBeam,
  arabicFalcon,
  medievalMud,
  greekLightning,
  snowySnowball,
  fieryFireball,
  technoHack,
  vikingHammer,
  comicsPow,
  zombieSpit,
  warriorBullet
}

// مدير الشخصيات مع دعم نظام الهجمات والأسعار
class CharacterManager {
  static List<GameCharacter> getLockedCharacters(List<GameCharacter> allCharacters) {
    try {
      final locked = allCharacters.where((character) => character.isLocked).toList();
      locked.sort((a, b) => a.price.compareTo(b.price)); // ✅ ترتيب حسب السعر
      return locked;
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات المقفلة: $e');
      return [];
    }
  }

  static List<GameCharacter> getUnlockedCharacters(List<GameCharacter> allCharacters) {
    try {
      final unlocked = allCharacters.where((character) => !character.isLocked).toList();
      unlocked.sort((a, b) => a.price.compareTo(b.price)); // ✅ ترتيب حسب السعر
      return unlocked;
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات المفتوحة: $e');
      return [GameCharacter.getDefaultCharacter()];
    }
  }

  static List<GameCharacter> getPurchasableCharacters(List<GameCharacter> allCharacters, List<GameCharacter> ownedCharacters) {
    try {
      final purchasable = allCharacters.where((character) =>
      character.isLocked && !ownedCharacters.any((owned) => owned.id == character.id)
      ).toList();

      purchasable.sort((a, b) => a.price.compareTo(b.price)); // ✅ ترتيب حسب السعر
      return purchasable;
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات المتاحة للشراء: $e');
      return [];
    }
  }

  static void unlockCharacter(GameCharacter character, List<GameCharacter> ownedCharacters) {
    try {
      character.isLocked = false;
      if (!ownedCharacters.any((c) => c.id == character.id)) {
        ownedCharacters.add(character);
        print('✅ تم فتح الشخصية: ${character.name} بسعر ${character.displayPrice} مع هجوم ${character.attackName}');
      }
    } catch (e) {
      print('❌ خطأ في فتح الشخصية: $e');
    }
  }

  static bool canPurchaseCharacter(GameCharacter character, int userCoins) {
    try {
      return character.isLocked && userCoins >= character.integerPrice;
    } catch (e) {
      print('❌ خطأ في التحقق من إمكانية الشراء: $e');
      return false;
    }
  }

  static GameCharacter getNextCharacter(GameCharacter current, List<GameCharacter> allCharacters) {
    try {
      final sortedCharacters = GameCharacter.getCharactersSortedByPrice();
      final currentIndex = sortedCharacters.indexWhere((c) => c.id == current.id);
      if (currentIndex == -1) return current;

      final nextIndex = (currentIndex + 1) % sortedCharacters.length;
      return sortedCharacters[nextIndex];
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصية التالية: $e');
      return current;
    }
  }

  static GameCharacter getPreviousCharacter(GameCharacter current, List<GameCharacter> allCharacters) {
    try {
      final sortedCharacters = GameCharacter.getCharactersSortedByPrice();
      final currentIndex = sortedCharacters.indexWhere((c) => c.id == current.id);
      if (currentIndex == -1) return current;

      final previousIndex = (currentIndex - 1) % sortedCharacters.length;
      return sortedCharacters[previousIndex < 0 ? sortedCharacters.length - 1 : previousIndex];
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصية السابقة: $e');
      return current;
    }
  }

  // الحصول على الشخصيات حسب نوع الهجوم
  static List<GameCharacter> getCharactersByAttackType(List<GameCharacter> allCharacters, AttackType attackType) {
    try {
      final characters = allCharacters.where((character) => character.attackType == attackType).toList();
      characters.sort((a, b) => a.price.compareTo(b.price)); // ✅ ترتيب حسب السعر
      return characters;
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات حسب نوع الهجوم: $e');
      return [];
    }
  }

  // الحصول على أقوى هجوم
  static GameCharacter getStrongestAttackCharacter(List<GameCharacter> characters) {
    try {
      if (characters.isEmpty) return GameCharacter.getDefaultCharacter();

      characters.sort((a, b) => b.attackDamage.compareTo(a.attackDamage));
      return characters.first;
    } catch (e) {
      print('❌ خطأ في الحصول على أقوى هجوم: $e');
      return GameCharacter.getDefaultCharacter();
    }
  }

  // الحصول على أسرع هجوم
  static GameCharacter getFastestAttackCharacter(List<GameCharacter> characters) {
    try {
      if (characters.isEmpty) return GameCharacter.getDefaultCharacter();

      characters.sort((a, b) => b.attackSpeed.compareTo(a.attackSpeed));
      return characters.first;
    } catch (e) {
      print('❌ خطأ في الحصول على أسرع هجوم: $e');
      return GameCharacter.getDefaultCharacter();
    }
  }

  // تحميل معلومات الهجمات للعرض في الواجهة
  static Map<String, dynamic> getAttackStats(GameCharacter character) {
    return {
      'damage': character.attackDamage,
      'speed': character.attackSpeed,
      'cooldown': character.attackCooldown,
      'effects': character.attackEffects,
      'type': character.attackType.name,
      'sound': character.attackSound,
      'price': character.displayPrice, // ✅ إضافة السعر للعرض
    };
  }

  // ✅ دالة للحصول على فئات الأسعار
  static Map<String, List<GameCharacter>> getCharactersByPriceRange(List<GameCharacter> allCharacters) {
    try {
      final ranges = {
        'اقتصادية': allCharacters.where((c) => c.price > 0 && c.price <= 1500).toList(),
        'متوسطة': allCharacters.where((c) => c.price > 1500 && c.price <= 2000).toList(),
        'مميزة': allCharacters.where((c) => c.price > 2000 && c.price <= 2500).toList(),
        'فاخرة': allCharacters.where((c) => c.price > 2500).toList(),
      };

      // ترتيب كل فئة حسب السعر
      ranges.forEach((key, value) {
        value.sort((a, b) => a.price.compareTo(b.price));
      });

      return ranges;
    } catch (e) {
      print('❌ خطأ في تقسيم الشخصيات حسب فئات الأسعار: $e');
      return {};
    }
  }

  // ✅ دالة للحصول على إجمالي تكلفة جميع الشخصيات
  static double getTotalCharactersCost(List<GameCharacter> allCharacters) {
    try {
      double total = 0;
      for (var character in allCharacters) {
        if (character.isLocked) {
          total += character.price;
        }
      }
      return total;
    } catch (e) {
      print('❌ خطأ في حساب إجمالي التكلفة: $e');
      return 0;
    }
  }

  // ✅ دالة للحصول على الشخصيات الموصى بها حسب الميزانية
  static List<GameCharacter> getRecommendedCharacters(List<GameCharacter> allCharacters, int userCoins) {
    try {
      final affordable = allCharacters.where((character) =>
      character.isLocked && character.integerPrice <= userCoins
      ).toList();

      affordable.sort((a, b) => b.attackDamage.compareTo(a.attackDamage)); // ترتيب حسب القوة
      return affordable.take(3).toList(); // أفضل 3 شخصيات
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات الموصى بها: $e');
      return [];
    }
  }
  // ✅ دالة عامة للحصول على صورة افتراضية آمنة
  String getFallbackImage({String? animationState}) {
    final basePath = 'assets/images/characters/almashe/almashe';

    // ✅ استخدام animationState الممررة أو الصورة الافتراضية
    final state = animationState ?? 'run';

    switch (state) {
      case 'attack':
        return '${basePath}_attack_1.png';
      case 'duck':
        return '${basePath}_duck_1.png';
      case 'jump':
        return '${basePath}_jump_1.png';
      case 'run':
      default:
        return '${basePath}_run_1.png';
    }
  }
}