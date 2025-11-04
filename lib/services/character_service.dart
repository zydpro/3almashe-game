// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/character_model.dart';
//
// class CharacterService {
//   static const String _ownedCharactersKey = 'owned_characters';
//   static const String _selectedCharacterKey = 'selected_character';
//   static const String _userCoinsKey = 'user_coins';
//
//   static Future<List<GameCharacter>> getOwnedCharacters() async {
//     final prefs = await SharedPreferences.getInstance();
//     final ownedCharactersJson = prefs.getStringList(_ownedCharactersKey) ?? [];
//
//     List<GameCharacter> ownedCharacters = [];
//
//     // الشخصية الافتراضية دائماً مملوكة
//     final defaultCharacter = GameCharacter.getDefaultCharacter();
//     defaultCharacter.isLocked = false;
//     if (!ownedCharacters.any((char) => char.id == defaultCharacter.id)) {
//       ownedCharacters.add(defaultCharacter);
//     }
//
//     for (var jsonString in ownedCharactersJson) {
//       try {
//         final character = GameCharacter.fromJson(jsonString as Map<String, dynamic>);
//         if (!ownedCharacters.any((char) => char.id == character.id)) {
//           ownedCharacters.add(character);
//         }
//       } catch (e) {
//         continue;
//       }
//     }
//
//     return ownedCharacters;
//   }
//
//   static Future<void> saveOwnedCharacters(List<GameCharacter> characters) async {
//     final prefs = await SharedPreferences.getInstance();
//     final charactersJson = characters.map((character) => character.toJson()).toList();
//     await prefs.setStringList(_ownedCharactersKey, charactersJson.cast<String>());
//   }
//
//   static Future<void> purchaseCharacter(GameCharacter character) async {
//     final ownedCharacters = await getOwnedCharacters();
//
//     if (!ownedCharacters.any((c) => c.id == character.id)) {
//       character.isLocked = false;
//       ownedCharacters.add(character);
//       await saveOwnedCharacters(ownedCharacters);
//     }
//   }
//
//   static Future<GameCharacter?> getSelectedCharacter() async {
//     final prefs = await SharedPreferences.getInstance();
//     final selectedId = prefs.getInt(_selectedCharacterKey);
//
//     if (selectedId != null) {
//       final ownedCharacters = await getOwnedCharacters();
//       return ownedCharacters.firstWhere(
//             (character) => character.id == selectedId,
//         orElse: () => GameCharacter.getDefaultCharacter(),
//       );
//     }
//
//     return GameCharacter.getDefaultCharacter();
//   }
//
//   static Future<void> setSelectedCharacter(GameCharacter character) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(_selectedCharacterKey, character.id);
//   }
//
//   static Future<int> getUserCoins() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt(_userCoinsKey) ?? 1000;
//   }
//
//   static Future<void> setUserCoins(int coins) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(_userCoinsKey, coins);
//   }
//
//   static Future<bool> spendCoins(int amount) async {
//     final currentCoins = await getUserCoins();
//     if (currentCoins >= amount) {
//       await setUserCoins(currentCoins - amount);
//       return true;
//     }
//     return false;
//   }
//
//   static Future<void> addCoins(int amount) async {
//     final currentCoins = await getUserCoins();
//     await setUserCoins(currentCoins + amount);
//   }
//
//   static Future<bool> isCharacterOwned(int characterId) async {
//     final ownedCharacters = await getOwnedCharacters();
//     return ownedCharacters.any((character) => character.id == characterId);
//   }
//
//   static Future<List<GameCharacter>> getAvailableCharacters() async {
//     final allCharacters = GameCharacter.getAllCharacters();
//     final ownedCharacters = await getOwnedCharacters();
//
//     return allCharacters.where((character) {
//       return !ownedCharacters.any((owned) => owned.id == character.id);
//     }).toList();
//   }
//
//   static Future<void> resetCharacters() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_ownedCharactersKey);
//     await prefs.remove(_selectedCharacterKey);
//     await setUserCoins(1000);
//   }
// }