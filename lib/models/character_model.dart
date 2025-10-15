import 'dart:ui';
import 'package:flutter/material.dart';

class GameCharacter {
  final int id;
  final String name;
  final String nameEn;
  final String imagePath;
  final int price;
  bool isLocked;
  final Color color;
  final List<String> animations;
  final String description;
  final String descriptionEn;
  final String type;
  final List<String> abilities;

  GameCharacter({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.imagePath,
    required this.price,
    required this.isLocked,
    required this.color,
    required this.animations,
    required this.description,
    required this.descriptionEn,
    required this.type,
    required this.abilities,
  });

  String getName(String language) {
    return language == 'ar' ? name : nameEn;
  }

  String getDescription(String language) {
    return language == 'ar' ? description : descriptionEn;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'imagePath': imagePath,
      'price': price,
      'isLocked': isLocked,
      'color': color.value,
      'animations': animations,
      'description': description,
      'descriptionEn': descriptionEn,
      'type': type,
      'abilities': abilities,
    };
  }

  factory GameCharacter.fromJson(Map<String, dynamic> json) {
    return GameCharacter(
      id: json['id'],
      name: json['name'],
      nameEn: json['nameEn'],
      imagePath: json['imagePath'],
      price: json['price'],
      isLocked: json['isLocked'],
      color: Color(json['color']),
      animations: List<String>.from(json['animations']),
      description: json['description'],
      descriptionEn: json['descriptionEn'],
      type: json['type'],
      abilities: List<String>.from(json['abilities']),
    );
  }

  // ✅ الشخصية الافتراضية (عالماشي الأساسي)
  static GameCharacter getDefaultCharacter() {
    return GameCharacter(
      id: 1,
      name: 'عالماشي',
      nameEn: '3almaShe',
      imagePath: 'assets/images/characters/almashe_icon.png',
      price: 0,
      isLocked: false,
      color: Colors.blue,
      animations: [
        'assets/images/characters/almashe_run.png',
        'assets/images/characters/almashe_jump.png',
        'assets/images/characters/almashe_attack.png',
        'assets/images/characters/almashe_duck.png',
        'assets/images/characters/almashe_idle.png',
      ],
      description: 'شخصية عالماشي الأساسية الشجاعة تمتلك جميع الحركات الأساسية',
      descriptionEn: 'The brave basic 3almaShe character with all basic movements',
      type: 'أساسي',
      abilities: ['متوازن', 'جميع الحركات', 'سرعة متوسطة', 'قفز جيد'],
    );
  }

  // ✅ دالة محسنة وآمنة للحصول على جميع الشخصيات
  static List<GameCharacter> getAllCharacters() {
    try {
      List<GameCharacter> characters = [];

      // ✅ الشخصية الأساسية (عالماشي)
      characters.add(getDefaultCharacter());

      // ✅ شخصية ألوان الطيف
      characters.add(GameCharacter(
        id: 2,
        name: 'الوان الطيف',
        nameEn: 'Rainbow Colors',
        imagePath: 'assets/images/characters/rainbow_icon.png',
        price: 500,
        isLocked: true,
        color: Colors.pink,
        animations: [
          'assets/images/characters/rainbow_run.png',
          'assets/images/characters/rainbow_jump.png',
          'assets/images/characters/rainbow_attack.png',
          'assets/images/characters/rainbow_duck.png',
          'assets/images/characters/rainbow_idle.png',
        ],
        description: 'شخصية ملونة زاهية تمتلك حركات متنوعة وجميلة مع تأثيرات قوس قزح',
        descriptionEn: 'Colorful vibrant character with various beautiful movements and rainbow effects',
        type: 'ألوان',
        abilities: ['قفز عالي', 'حركات سريعة', 'ألوان زاهية', 'تأثيرات ملونة'],
      ));

      // ✅ الشخصية العربية
      characters.add(GameCharacter(
        id: 3,
        name: 'عربي',
        nameEn: 'Arabic',
        imagePath: 'assets/images/characters/arabic_icon.png',
        price: 1000,
        isLocked: true,
        color: Colors.green,
        animations: [
          'assets/images/characters/arabic_run.png',
          'assets/images/characters/arabic_jump.png',
          'assets/images/characters/arabic_attack.png',
          'assets/images/characters/arabic_duck.png',
          'assets/images/characters/arabic_idle.png',
        ],
        description: 'شخصية عربية تقليدية بلمسة عصرية تعكس التراث العربي الأصيل',
        descriptionEn: 'Traditional Arabic character with modern touch reflecting authentic Arab heritage',
        type: 'تراثي',
        abilities: ['قوة تحمل', 'حركات تراثية', 'ثبات عالي', 'دفاع قوي'],
      ));

      // ✅ الشخصية العصور الوسطى
      characters.add(GameCharacter(
        id: 4,
        name: 'العصور وسطى',
        nameEn: 'medieval',
        imagePath: 'assets/images/characters/medieval_icon.png',
        price: 1000,
        isLocked: true,
        color: Colors.orange,
        animations: [
          'assets/images/characters/medieval_run.png',
          'assets/images/characters/medieval_jump.png',
          'assets/images/characters/medieval_attack.png',
          'assets/images/characters/medieval_duck.png',
          'assets/images/characters/medieval_idle.png',
        ],
        description: 'A character from the Middle Ages',
        descriptionEn: 'A character from the Middle Ages',
        type: 'طبيعي',
        abilities: ['قوة طبيعية', 'حركات قديمة', 'تأثيرات حركية'],
      ));

      // ✅ الشخصية الإغريقية
      characters.add(GameCharacter(
        id: 5,
        name: 'أغريقي',
        nameEn: 'Greek',
        imagePath: 'assets/images/characters/greek_icon.png',
        price: 1000,
        isLocked: true,
        color: Colors.blue.shade800,
        animations: [
          'assets/images/characters/greek_run.png',
          'assets/images/characters/greek_jump.png',
          'assets/images/characters/greek_attack.png',
          'assets/images/characters/greek_duck.png',
          'assets/images/characters/greek_idle.png',
        ],
        description: 'شخصية من الحضارة الإغريقية القديمة تمتاز بالقوة والصلابة',
        descriptionEn: 'Character from ancient Greek civilization known for strength and solidity',
        type: 'تاريخي',
        abilities: ['قوة هجوم', 'حركات تاريخية', 'دفاع قوي', 'صلابة'],
      ));

      // ✅ الشخصية الثلجية
      characters.add(GameCharacter(
        id: 6,
        name: 'ثلجي',
        nameEn: 'Snowy',
        imagePath: 'assets/images/characters/snowy_icon.png',
        price: 1100,
        isLocked: true,
        color: Colors.cyan,
        animations: [
          'assets/images/characters/snowy_run.png',
          'assets/images/characters/snowy_jump.png',
          'assets/images/characters/snowy_attack.png',
          'assets/images/characters/snowy_duck.png',
          'assets/images/characters/snowy_idle.png',
        ],
        description: 'شخصية ثلجية باردة مع تأثيرات جليدية وانزلاقية فريدة',
        descriptionEn: 'Snowy cold character with unique ice effects and sliding movements',
        type: 'طبيعي',
        abilities: ['مقاومة البرد', 'حركات انزلاقية', 'سرعة متوسطة', 'تأثيرات ثلجية'],
      ));

      // ✅ الشخصية النارية
      characters.add(GameCharacter(
        id: 7,
        name: 'ناري',
        nameEn: 'Fiery',
        imagePath: 'assets/images/characters/fiery_icon.png',
        price: 1200,
        isLocked: true,
        color: Colors.orange,
        animations: [
          'assets/images/characters/fiery_run.png',
          'assets/images/characters/fiery_jump.png',
          'assets/images/characters/fiery_attack.png',
          'assets/images/characters/fiery_duck.png',
          'assets/images/characters/fiery_idle.png',
        ],
        description: 'شخصية نارية مشتعلة بالقوة والطاقة مع تأثيرات لهب حارقة',
        descriptionEn: 'Fiery character burning with power and energy with hot flame effects',
        type: 'عنصري',
        abilities: ['قوة نارية', 'هجمات سريعة', 'حركات سريعة', 'تأثيرات نارية'],
      ));

      // ✅ الشخصية التقنية
      characters.add(GameCharacter(
        id: 8,
        name: 'تقني',
        nameEn: 'Techno',
        imagePath: 'assets/images/characters/techno_icon.png',
        price: 1500,
        isLocked: true,
        color: Colors.purple,
        animations: [
          'assets/images/characters/techno_run.png',
          'assets/images/characters/techno_jump.png',
          'assets/images/characters/techno_attack.png',
          'assets/images/characters/techno_duck.png',
          'assets/images/characters/techno_idle.png',
        ],
        description: 'شخصية تكنولوجية متطورة بتقنيات حديثة وتأثيرات رقمية',
        descriptionEn: 'Advanced technological character with modern tech and digital effects',
        type: 'مستقبلي',
        abilities: ['سرعة تقنية', 'حركات دقيقة', 'هجمات دقيقة', 'تأثيرات رقمية'],
      ));

      // ✅ محارب الفايكنج
      characters.add(GameCharacter(
        id: 9,
        name: 'محاربي الفايكنج',
        nameEn: 'Viking Warrior',
        imagePath: 'assets/images/characters/viking_icon.png',
        price: 1800,
        isLocked: true,
        color: Colors.brown,
        animations: [
          'assets/images/characters/viking_run.png',
          'assets/images/characters/viking_jump.png',
          'assets/images/characters/viking_attack.png',
          'assets/images/characters/viking_duck.png',
          'assets/images/characters/viking_idle.png',
        ],
        description: 'محارب فايكنج قوي من الشمال يتميز بالشراسة والقوة البدنية',
        descriptionEn: 'Strong Viking warrior from the north known for ferocity and physical strength',
        type: 'محارب',
        abilities: ['قوة المحارب', 'هجمات قوية', 'دفاع ممتاز', 'شراسة'],
      ));

      // ✅ شخصية الكوميكس
      characters.add(GameCharacter(
        id: 10,
        name: 'كوميكس',
        nameEn: 'Comics',
        imagePath: 'assets/images/characters/comics_icon.png',
        price: 2000,
        isLocked: true,
        color: Colors.red,
        animations: [
          'assets/images/characters/comics_run.png',
          'assets/images/characters/comics_jump.png',
          'assets/images/characters/comics_attack.png',
          'assets/images/characters/comics_duck.png',
          'assets/images/characters/comics_idle.png',
        ],
        description: 'شخصية كوميكس ملونة ومليئة بالحركة والمرونة الكوميدية',
        descriptionEn: 'Colorful comics character full of movement and comedic flexibility',
        type: 'كوميكس',
        abilities: ['حركات كوميدية', 'قفزات مرنة', 'مرونة عالية', 'تأثيرات كاريكاتير'],
      ));

      // ✅ شخصية الزومبي
      characters.add(GameCharacter(
        id: 11,
        name: 'زومبي',
        nameEn: 'Zombie',
        imagePath: 'assets/images/characters/zombie_icon.png',
        price: 2500,
        isLocked: true,
        color: Colors.green.shade800,
        animations: [
          'assets/images/characters/zombie_run.png',
          'assets/images/characters/zombie_jump.png',
          'assets/images/characters/zombie_attack.png',
          'assets/images/characters/zombie_duck.png',
          'assets/images/characters/zombie_idle.png',
        ],
        description: 'شخصية زومبي مرعبة مع حركات خاصة ومقاومة خارقة للضرر',
        descriptionEn: 'Scary zombie character with special movements and super damage resistance',
        type: 'رعب',
        abilities: ['مقاومة عالية', 'حركات مرعبة', 'قوة خارقة', 'تحمل الضرب'],
      ));

      print('✅ تم تحميل ${characters.length} شخصية بنجاح');
      return characters;

    } catch (e) {
      print('❌ خطأ في تحميل الشخصيات: $e');
      // ✅ العودة للشخصية الافتراضية فقط في حالة الخطأ
      return [getDefaultCharacter()];
    }
  }

  // ✅ دالة بديلة أكثر أماناً
  static List<GameCharacter> getAllCharactersSync() {
    return getAllCharacters();
  }

  // ✅ دالة للحصول على الشخصية بواسطة الـ ID
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

  // ✅ دالة للتحقق إذا كانت الشخصية هي الافتراضية
  bool get isDefault => id == 1;

  // ✅ دالة للحصول على أيقونة الشخصية
  String get iconPath => imagePath;

  // ✅ دالة للحصول على صورة العرض الرئيسية (أول حركة)
  String get displayImage => animations.isNotEmpty ? animations[0] : imagePath;

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
    return 'GameCharacter{id: $id, name: $name, isLocked: $isLocked}';
  }
}

class CharacterManager {
  // ✅ الحصول على الشخصيات المقفلة
  static List<GameCharacter> getLockedCharacters(List<GameCharacter> allCharacters) {
    try {
      return allCharacters.where((character) => character.isLocked).toList();
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات المقفلة: $e');
      return [];
    }
  }

  // ✅ الحصول على الشخصيات المفتوحة
  static List<GameCharacter> getUnlockedCharacters(List<GameCharacter> allCharacters) {
    try {
      return allCharacters.where((character) => !character.isLocked).toList();
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات المفتوحة: $e');
      return [GameCharacter.getDefaultCharacter()];
    }
  }

  // ✅ الحصول على الشخصيات المتاحة للشراء (مقفلة وغير مملوكة)
  static List<GameCharacter> getPurchasableCharacters(List<GameCharacter> allCharacters, List<GameCharacter> ownedCharacters) {
    try {
      return allCharacters.where((character) =>
      character.isLocked && !ownedCharacters.any((owned) => owned.id == character.id)
      ).toList();
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصيات المتاحة للشراء: $e');
      return [];
    }
  }

  // ✅ فتح شخصية
  static void unlockCharacter(GameCharacter character, List<GameCharacter> ownedCharacters) {
    try {
      character.isLocked = false;
      if (!ownedCharacters.any((c) => c.id == character.id)) {
        ownedCharacters.add(character);
        print('✅ تم فتح الشخصية: ${character.name}');
      }
    } catch (e) {
      print('❌ خطأ في فتح الشخصية: $e');
    }
  }

  // ✅ التحقق من إمكانية شراء الشخصية
  static bool canPurchaseCharacter(GameCharacter character, int userCoins) {
    try {
      return character.isLocked && userCoins >= character.price;
    } catch (e) {
      print('❌ خطأ في التحقق من إمكانية الشراء: $e');
      return false;
    }
  }

  // ✅ الحصول على الشخصية التالية (للتناوب في العرض)
  static GameCharacter getNextCharacter(GameCharacter current, List<GameCharacter> allCharacters) {
    try {
      final currentIndex = allCharacters.indexWhere((c) => c.id == current.id);
      if (currentIndex == -1) return current;

      final nextIndex = (currentIndex + 1) % allCharacters.length;
      return allCharacters[nextIndex];
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصية التالية: $e');
      return current;
    }
  }

  // ✅ الحصول على الشخصية السابقة (للتناوب في العرض)
  static GameCharacter getPreviousCharacter(GameCharacter current, List<GameCharacter> allCharacters) {
    try {
      final currentIndex = allCharacters.indexWhere((c) => c.id == current.id);
      if (currentIndex == -1) return current;

      final previousIndex = (currentIndex - 1) % allCharacters.length;
      return allCharacters[previousIndex < 0 ? allCharacters.length - 1 : previousIndex];
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصية السابقة: $e');
      return current;
    }
  }
}