import 'package:almashe_game/online/services/user_data_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/firebase_init_service.dart';
import 'auth_service.dart' as _auth;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // يمكنك تركها فارغة على أندرويد، أو تمرير Client ID على iOS/Web
    scopes: <String>[
      'email',
    ],
  );

  // ✅ تسجيل الدخول بحساب Google
  Future<User?> signInWithGoogle() async {
    try {
      // تسجيل الدخول بجوجل
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently() ??
          await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❕ تم إلغاء تسجيل الدخول من المستخدم');
        return null;
      }

      // الحصول على توكن جوجل
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // ملاحظة: accessToken تم إزالته، استخدم فقط idToken
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('✅ تسجيل الدخول بحساب Google: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول عبر Google: $e');
      return null;
    }
  }

  // ✅ تسجيل مستخدم جديد
  Future<User?> signUpWithEmail(String email, String password, String? phone) async {
    try {
      if (email.isEmpty || password.isEmpty) throw 'البريد الإلكتروني وكلمة المرور مطلوبان';
      if (password.length < 6) throw 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      print('✅ تم إنشاء حساب جديد: ${result.user!.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ في التسجيل: ${e.code}');
      throw _getErrorMessage(e);
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      throw 'حدث خطأ غير متوقع';
    }
  }

  // ✅ تسجيل الدخول
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) throw 'البريد الإلكتروني وكلمة المرور مطلوبان';
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      print('✅ تم تسجيل الدخول: ${result.user!.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ في الدخول: ${e.code}');
      throw _getErrorMessage(e);
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      throw 'حدث خطأ غير متوقع';
    }
  }

  // ✅ الدخول كضيف
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      print('✅ تم الدخول كضيف: ${result.user?.uid}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ في الدخول كضيف: ${e.code} - ${e.message}');

      // معالجة الأخطاء المختلفة
      switch (e.code) {
        case 'admin-restricted-operation':
          throw 'المصادقة المجهولة غير مفعلة. يرجى التواصل مع الدعم.';
        case 'network-request-failed':
          throw 'تحقق من اتصال الإنترنت';
        case 'too-many-requests':
          throw 'طلبات كثيرة جداً، حاول لاحقاً';
        default:
          throw 'حدث خطأ: ${e.message}';
      }
    } catch (e) {
      print('❌ خطأ غير متوقع في الدخول كضيف: $e');
      throw 'حدث خطأ غير متوقع';
    }
  }

  Future<User?> signInAnonymouslyAndSync() async {
    try {
      final user = await signInAnonymously();
      if (user != null) {
        await _syncUserData(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ دالة الربط الأساسية
  Future<void> _syncUserData(User user) async {
    try {
      print('🔄 بدء مزامنة بيانات المستخدم: ${user.uid}');

      // 1. تهيئة بيانات المستخدم في Firestore
      await UserDataService.initializeUserData(user);

      // 2. تحديث حالة الاتصال
      await _updateUserOnlineStatus(user.uid, true);

      // 3. مزامنة البيانات من السحابة إذا كانت موجودة
      await UserDataService.syncDataFromCloud(user);

      print('✅ تمت مزامنة بيانات المستخدم بنجاح');
    } catch (e) {
      print('❌ خطأ في مزامنة بيانات المستخدم: $e');
    }
  }

  // ✅ تحديث حالة الاتصال
  Future<void> _updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ خطأ في تحديث حالة الاتصال: $e');
    }
  }

  // تسجيل الدخول برقم هاتف
  Future<void> verifyPhoneNumber(
      String phoneNumber, {
        required Function(String, int?) onCodeSent,
        required Function(FirebaseAuthException) onVerificationFailed,
      }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      codeSent: onCodeSent,
      verificationFailed: onVerificationFailed,
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: Duration(seconds: 60),
    );
  }

  Future<User?> signInWithPhoneNumber(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      print('✅ تم تسجيل الدخول بالهاتف: ${result.user?.phoneNumber}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ في تسجيل الدخول بالهاتف: ${e.code}');
      throw _getErrorMessage(e);
    }
  }

  // ✅ دالة محسنة للتحقق من إعدادات الهاتف
  Future<void> checkPhoneAuthAvailability() async {
    try {
      // محاولة إرسال رمز تحقق لرقم اختبار
      String testPhone = '+16505551234'; // رقم اختبار Firebase

      await _auth.verifyPhoneNumber(
        phoneNumber: testPhone,
        verificationCompleted: (credential) {},
        verificationFailed: (e) {
          print('📞 حالة خدمة الهاتف: ${e.code} - ${e.message}');
        },
        codeSent: (verificationId, resendToken) {
          print('✅ خدمة الهاتف تعمل بشكل صحيح');
        },
        codeAutoRetrievalTimeout: (verificationId) {},
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      print('❌ خطأ في التحقق من خدمة الهاتف: $e');
    }
  }

  // ✅ طريقة بديلة للتحقق من الهاتف
  Future<void> verifyPhoneNumberEnhanced(
      String phoneNumber, {
        required Function(String, int?) onCodeSent,
        required Function(FirebaseAuthException) onVerificationFailed,
      }) async {
    try {
      // إعادة تعيين إعدادات المصادقة
      await _auth.setLanguageCode("en");

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // التحقق التلقائي إذا كان ممكنًا
          try {
            await _auth.signInWithCredential(credential);
            print('✅ تم التحقق التلقائي');
          } catch (e) {
            print('❌ فشل التحقق التلقائي: $e');
          }
        },
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ انتهت مهلة استرجاع الرمز');
        },
        timeout: Duration(seconds: 120),
        forceResendingToken: null,
      );
    } catch (e) {
      print('❌ خطأ في verifyPhoneNumberEnhanced: $e');
      rethrow;
    }
  }

  // ✅ تسجيل الدخول بحساب Facebook
  Future<User?> signInWithFacebook() async {
    try {
      // TODO: إضافة تنفيذ Facebook الحقيقي
      // هذا تنفيذ مؤقت للاختبار
      await Future.delayed(Duration(seconds: 2));

      // محاكاة نجاح التسجيل
      final UserCredential userCredential = await _auth.signInAnonymously();
      print('✅ تسجيل الدخول بحساب Facebook (مؤقت)');
      return userCredential.user;
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول عبر Facebook: $e');
      throw 'فشل التسجيل بحساب Facebook';
    }
  }

  // ✅ تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('✅ تم تسجيل الخروج بنجاح');
    } catch (e) {
      print('❌ خطأ أثناء تسجيل الخروج: $e');
    }
  }

  // ✅ ترجمة أخطاء Firebase
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email': return 'بريد إلكتروني غير صحيح';
      case 'weak-password': return 'كلمة المرور ضعيفة';
      case 'user-not-found': return 'المستخدم غير موجود';
      case 'wrong-password': return 'كلمة المرور خاطئة';
      case 'network-request-failed': return 'تحقق من اتصال الإنترنت';
      case 'operation-not-allowed': return 'تسجيل الدخول بالهاتف غير مفعل. يرجى تفعيله في Firebase Console';
      default: return 'حدث خطأ: ${e.message}';
    }
  }

  // ✅ تسجيل الدخول مع ربط بيانات اللعبة
  Future<User?> signInWithEmailAndSync(String email, String password) async {
    try {
      final user = await signInWithEmail(email, password);
      if (user != null) {
        await UserDataService.initializeUserData(user); // ✅ هذا السطر مهم
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ إنشاء حساب مع ربط بيانات اللعبة
  Future<User?> signUpWithEmailAndSync(String email, String password, String? phone) async {
    try {
      final user = await signUpWithEmail(email, password, phone);
      if (user != null) {
        await _syncUserData(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ إنشاء حساب مع الاسم والمزامنة
  Future<User?> signUpWithEmailAndNameAndSync(
      String email,
      String password,
      String firstName,
      String lastName,
      ) async {
    try {
      final user = await signUpWithEmail(email, password, null);
      if (user != null) {
        // ✅ تحديث الاسم في Firebase Auth
        await user.updateDisplayName('$firstName $lastName');
        await user.reload();

        // ✅ تهيئة البيانات في Firestore
        await UserDataService.initializeUserData(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ تسجيل الدخول بحساب Google مع ربط بيانات اللعبة
  Future<User?> signInWithGoogleAndSync() async {
    try {
      final user = await signInWithGoogle();
      if (user != null) {
        await UserDataService.initializeUserData(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ تسجيل الدخول بحساب Facebook مع ربط بيانات اللعبة
  Future<User?> signInWithFacebookAndSync() async {
    try {
      final user = await signInWithFacebook();
      if (user != null) {
        await UserDataService.initializeUserData(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ دالة مساعدة لمزامنة بيانات اللعبة
  Future<void> _syncUserGameData(User user) async {
    try {
      print('🔄 بدء مزامنة بيانات اللعبة للمستخدم: ${user.uid}');

      // التحقق من اتصال Firebase
      final isConnected = await UserDataService.checkFirebaseConnection();

      if (isConnected) {
        // مزامنة البيانات من السحابة إلى الجهاز
        await UserDataService.syncDataFromCloud(user);

        // رفع البيانات المحلية إلى السحابة
        await UserDataService.syncDataToCloud(user);

        print('✅ تمت مزامنة بيانات اللعبة بنجاح');
      } else {
        print('⚠️ لا يوجد اتصال، سيتم استخدام البيانات المحلية');
      }
    } catch (e) {
      print('❌ خطأ في مزامنة بيانات اللعبة: $e');
      // لا نرمي الخطأ هنا حتى لا نؤثر على تجربة المستخدم
    }
  }

  // ✅ Stream لتتبع حالة المستخدم
  Stream<User?> get userStream => _auth.authStateChanges();

  // ✅ الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // ✅ التحقق من حالة المصادقة
  bool get isLoggedIn => _auth.currentUser != null;
}
