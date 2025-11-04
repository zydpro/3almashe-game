// import 'package:almashe_game/Languages/app_localizations.dart';import 'package:flutter/material.dart';
//
// class TestScreen extends StatelessWidget {
//   const TestScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         home: Scaffold(
//           backgroundColor: Colors.blue[100],
//           body: Stack(
//             children: [
//               // 1. خلفية
//               Container(
//                 width: double.infinity,
//                 height: double.infinity,
//                 color: Colors.lightBlue[100],
//               ),
//
//               // 2. أرض
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 height: 100,
//                 child: Container(
//                   color: Colors.brown,
//                   child: const Center(
//                     child: Text(
//                       'هذه أرض اللعبة',
//                       style: TextStyle(color: Colors.white, fontSize: 24),
//                     ),
//                   ),
//                 ),
//               ),
//
//               // 3. شخصية حمراء ضخمة
//               Positioned(
//                 bottom: 200,
//                 left: 150,
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: const BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black,
//                         blurRadius: 20,
//                         spreadRadius: 10,
//                       ),
//                     ],
//                   ),
//                   child: const Center(
//                     child: Text(
//                       '👤',
//                       style: TextStyle(fontSize: 50),
//                     ),
//                   ),
//                 ),
//               ),
//
//               // 4. نص تأكيد
//               const Positioned(
//                 top: 50,
//                 left: 0,
//                 right: 0,
//                 child: Center(
//                   child: Text(
//                     'إذا ترى هذا النص والدائرة الحمراء، فالمشكلة في game_screen.dart',
//                     style: TextStyle(fontSize: 18,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         localizationsDelegates: AppLocalizations.localizationsDelegates,
//         supportedLocales: AppLocalizations.supportedLocales
//     );
//   }
// }