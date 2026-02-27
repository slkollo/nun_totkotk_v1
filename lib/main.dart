import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:io';

// කැමරා ලිස්ට් එක ගන්න Global Variable එකක්
List<CameraDescription> cameras = [];

// =====================================================================
// OVERLAY ENTRY POINT (වෙනත් ඇප් උඩින් පෙනෙන කොටස)
// =====================================================================
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TrueOverlayScreen(),
    ),
  );
}

class TrueOverlayScreen extends StatefulWidget {
  const TrueOverlayScreen({super.key});

  @override
  State<TrueOverlayScreen> createState() => _TrueOverlayScreenState();
}

class _TrueOverlayScreenState extends State<TrueOverlayScreen> {
  String _kidName = 'Kid';
  String _appLanguage = 'en';

  final Map<String, Map<String, String>> _t = {
    'en': {'waitSec': 'Wait a second', 'tooClose': 'Too close to eyes!', 'moveAway': 'Please move the phone further away.'},
    'ko': {'waitSec': '잠깐만', 'tooClose': '눈에 너무 가까워요!', 'moveAway': '휴대폰을 더 멀리 떨어뜨려 주세요.'},
    'zh': {'waitSec': '等一下', 'tooClose': '离眼睛太近了！', 'moveAway': '请把手机移远一点。'},
    'ja': {'waitSec': 'ちょっと待って', 'tooClose': '目に近すぎます！', 'moveAway': '電話をもう少し離してください。'},
    'fr': {'waitSec': 'Attends une seconde', 'tooClose': 'Trop près des yeux !', 'moveAway': 'Éloignez le téléphone s\'il te plaît.'},
    'de': {'waitSec': 'Warte eine Sekunde', 'tooClose': 'Zu nah an den Augen!', 'moveAway': 'Bitte halte das Telefon weiter weg.'},
    'es': {'waitSec': 'Espera un segundo', 'tooClose': '¡Demasiado cerca de los ojos!', 'moveAway': 'Por favor, aleja más el teléfono.'},
    'pt': {'waitSec': 'Espere um segundo', 'tooClose': 'Muito perto dos olhos!', 'moveAway': 'Por favor, afaste mais o telefone.'},
    'ru': {'waitSec': 'Подожди секунду', 'tooClose': 'Слишком близко к глазам!', 'moveAway': 'Пожалуйста, отодвиньте телефон дальше.'},
    'ar': {'waitSec': 'انتظر ثانية', 'tooClose': 'قريب جداً من العينين!', 'moveAway': 'يرجى إبعاد الهاتف أكثر.'},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _kidName = prefs.getString('kid_name') ?? 'Kid';
        _appLanguage = prefs.getString('app_language') ?? 'en';
      });
    } catch (e) {
      debugPrint("Overlay load data error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t[_appLanguage] ?? _t['en']!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity, height: double.infinity,
        color: Colors.white.withOpacity(0.95),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  "${t['waitSec']} $_kidName!",
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.redAccent, decoration: TextDecoration.none),
                  textAlign: TextAlign.center
              ),
              const SizedBox(height: 30),
              Image.asset('assets/eye_warning.gif', width: 160, height: 160),
              const SizedBox(height: 30),
              Text(
                  t['tooClose']!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, decoration: TextDecoration.none),
                  textAlign: TextAlign.center
              ),
              const SizedBox(height: 10),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                      t['moveAway']!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54, decoration: TextDecoration.none),
                      textAlign: TextAlign.center
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Camera error: $e");
  }

  await Future.delayed(const Duration(seconds: 3));

  final prefs = await SharedPreferences.getInstance();
  final bool isSetupDone = prefs.getString('kid_name') != null;

  runApp(MyApp(isSetupDone: isSetupDone));
}

class MyApp extends StatelessWidget {
  final bool isSetupDone;
  const MyApp({super.key, required this.isSetupDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nun Toktok',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5A2D81)),
      ),
      home: isSetupDone ? const MainDashboardScreen() : const WelcomeScreen(),
    );
  }
}

// ==========================================
// STEP 1 & 2: Welcome Screen
// ==========================================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  final Color backgroundColorTop = const Color(0xFFF3E5FF);
  final Color backgroundColorBottom = const Color(0xFFE1D3FF);
  final Color textColorDark = const Color(0xFF5A2D81);
  final Color buttonColorLeft = const Color(0xFFB499FF);
  final Color buttonColorRight = const Color(0xFFDFA0FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColorTop, backgroundColorBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                Text("Welcome!", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColorDark, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Text("Please allow permissions for eye health.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textColorDark.withOpacity(0.8))),
                const Spacer(flex: 1),
                Image.asset('assets/alon.png', width: MediaQuery.of(context).size.width * 0.6, fit: BoxFit.contain),
                const Spacer(flex: 2),
                Container(
                  width: double.infinity, height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [buttonColorRight, buttonColorLeft], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: buttonColorLeft.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const PermissionScreen()));
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: const Center(child: Text("GET STARTED (시작하기)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// STEP 3: Permission Screen
// ==========================================
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text("App Permissions", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5A2D81))),
              const SizedBox(height: 10),
              const Text("We need the following permissions to protect eye health.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPermissionItem(icon: Icons.camera_alt_outlined, title: "Take picture and record video", description: "Used to measure the distance between the face and the screen."),
                      const SizedBox(height: 25),
                      _buildPermissionItem(icon: Icons.mic_none_outlined, title: "Record audio", description: "Used for app specific voice features."),
                      const SizedBox(height: 25),
                      _buildPermissionItem(icon: Icons.layers_outlined, title: "Appear on top", description: "Used to show a warning screen when too close to the device."),
                      const SizedBox(height: 25),
                      _buildPermissionItem(icon: Icons.notifications_none_outlined, title: "Allow send to notification", description: "Used to send eye health alerts and daily summaries."),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDFA0FF), Color(0xFFB499FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: const Color(0xFFB499FF).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await [Permission.camera, Permission.microphone, Permission.notification].request();
                      if (!await Permission.systemAlertWindow.isGranted) {
                        await Permission.systemAlertWindow.request();
                      }
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const InitialSetupScreen()));
                      }
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: const Center(child: Text("ALLOW PERMISSIONS", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 35, color: const Color(0xFF5A2D81)),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A2D81))),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// STEP 4: Initial Setup Screen
// ==========================================
class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  String _selectedLang = 'en';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();
  final TextEditingController _secAnswerController = TextEditingController();

  final Color purpleTextColor = const Color(0xFF5A2D81);
  final Color inputFieldBorder = const Color(0xFFE0E0E0);
  final Color dropdownBg = const Color(0xFFF8F0FF);

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': 'en.png'},
    {'code': 'ko', 'name': '한국어', 'flag': 'ko.png'},
    {'code': 'zh', 'name': '简体中文', 'flag': 'zh.png'},
    {'code': 'ja', 'name': '日本語', 'flag': 'ja.png'},
    {'code': 'fr', 'name': 'Français', 'flag': 'fr.png'},
    {'code': 'de', 'name': 'Deutsch', 'flag': 'de.png'},
    {'code': 'es', 'name': 'Español', 'flag': 'es.png'},
    {'code': 'pt', 'name': 'Português', 'flag': 'pt.png'},
    {'code': 'ru', 'name': 'Русский', 'flag': 'ru.png'},
    {'code': 'ar', 'name': 'العربية', 'flag': 'ar.png'},
  ];

  final Map<String, Map<String, String>> _translations = {
    'en': {'title': 'Initial Setup', 'selectLang': 'Select Language', 'kidName': 'Enter Child\'s Name', 'pw': 'Parent Password (4 digits)', 'pwConfirm': 'Confirm Password', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': 'What is your mother\'s hometown?', 'answerHint': 'Enter Answer', 'saveBtn': 'SAVE SETTINGS'},
    'ko': {'title': '초기 설정', 'selectLang': '언어 선택', 'kidName': '아이 이름', 'pw': '비밀번호 4자리', 'pwConfirm': '비밀번호 확인', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': '어머니의 고향은 어디입니까?', 'answerHint': '정답 입력', 'saveBtn': '설정 저장'},
    'zh': {'title': '初始设置', 'selectLang': '选择语言', 'kidName': '输入孩子姓名', 'pw': '家长密码 (4位)', 'pwConfirm': '确认密码', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': '你母亲的故乡在哪里？', 'answerHint': '输入答案', 'saveBtn': '保存设置'},
    'ja': {'title': '初期設定', 'selectLang': '言語を選択', 'kidName': '子供の名前を入力', 'pw': '親のパスワード (4桁)', 'pwConfirm': 'パスワードの確認', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': '母親の出身地はどこですか？', 'answerHint': '回答を入力', 'saveBtn': '設定を保存'},
    'fr': {'title': 'Configuration Initiale', 'selectLang': 'Choisir la langue', 'kidName': 'Entrer le nom de l\'enfant', 'pw': 'Mot de passe (4 chiffres)', 'pwConfirm': 'Confirmer le mot de passe', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': 'Quelle est la ville natale de votre mère ?', 'answerHint': 'Entrer la réponse', 'saveBtn': 'SAUVEGARDER'},
    'de': {'title': 'Ersteinrichtung', 'selectLang': 'Sprache auswählen', 'kidName': 'Name des Kindes', 'pw': 'Eltern-Passwort (4-stellig)', 'pwConfirm': 'Passwort bestätigen', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': 'Was ist die Heimatstadt deiner Mutter?', 'answerHint': 'Antwort eingeben', 'saveBtn': 'SPEICHERN'},
    'es': {'title': 'Configuración Inicial', 'selectLang': 'Seleccionar idioma', 'kidName': 'Nombre del niño', 'pw': 'Contraseña (4 dígitos)', 'pwConfirm': 'Confirmar contraseña', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': '¿Cuál es la ciudad natal de tu madre?', 'answerHint': 'Ingrese respuesta', 'saveBtn': 'GUARDAR'},
    'pt': {'title': 'Configuração Inicial', 'selectLang': 'Selecione o idioma', 'kidName': 'Nome da criança', 'pw': 'Senha (4 dígitos)', 'pwConfirm': 'Confirmar senha', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': 'Qual é a cidade natal da sua mãe?', 'answerHint': 'Digite a resposta', 'saveBtn': 'SALVAR'},
    'ru': {'title': 'Начальная настройка', 'selectLang': 'Выберите язык', 'kidName': 'Имя ребенка', 'pw': 'Пароль (4 цифры)', 'pwConfirm': 'Подтвердите пароль', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': 'В каком городе родилась ваша мать?', 'answerHint': 'Введите ответ', 'saveBtn': 'СОХРАНИТЬ'},
    'ar': {'title': 'الإعداد الأولي', 'selectLang': 'اختر اللغة', 'kidName': 'أدخل اسم الطفل', 'pw': 'كلمة مرور (4 أرقام)', 'pwConfirm': 'تأكيد كلمة المرور', 'secQTitle': 'Q: What is your mother\'s hometown?', 'secQText': 'ما هي مسقط رأس والدتك؟', 'answerHint': 'أدخل الإجابة', 'saveBtn': 'حفظ الإعدادات'},
  };

  Future<void> _saveData() async {
    if (_nameController.text.isEmpty || _pwController.text.isEmpty || _pwConfirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields!')));
      return;
    }
    if (_pwController.text != _pwConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selectedLang);
    await prefs.setString('kid_name', _nameController.text);
    await prefs.setString('app_password', _pwController.text);
    await prefs.setString('security_answer', _secAnswerController.text);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainDashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _translations[_selectedLang]!;
    final isRTL = _selectedLang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF8E76A8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 35.0),
              decoration: BoxDecoration(color: const Color(0xFFF8F5FC), borderRadius: BorderRadius.circular(30)),
              child: Directionality(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Text(t['title']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87))),
                    const SizedBox(height: 25),
                    Text(t['selectLang']!, style: TextStyle(fontWeight: FontWeight.bold, color: purpleTextColor)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: dropdownBg, borderRadius: BorderRadius.circular(15), border: Border.all(color: purpleTextColor.withOpacity(0.3))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true, value: _selectedLang, icon: Icon(Icons.arrow_drop_down_circle_outlined, color: purpleTextColor),
                          items: _languages.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang['code'],
                              child: Row(
                                children: [
                                  ClipOval(child: Image.asset('assets/${lang['flag']}', width: 32, height: 32, fit: BoxFit.cover)),
                                  const SizedBox(width: 15),
                                  Expanded(child: Text(lang['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) => setState(() => _selectedLang = newValue!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(t['kidName']!, _nameController, false),
                    const SizedBox(height: 15),
                    _buildTextField(t['pw']!, _pwController, true, isNumber: true),
                    const SizedBox(height: 15),
                    _buildTextField(t['pwConfirm']!, _pwConfirmController, true, isNumber: true),
                    const SizedBox(height: 30),
                    Divider(color: purpleTextColor.withOpacity(0.2)),
                    const SizedBox(height: 20),
                    Text(t['secQTitle']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: purpleTextColor)),
                    const SizedBox(height: 8),
                    Text(t['secQText']!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 15),
                    _buildTextField(t['answerHint']!, _secAnswerController, false),
                    const SizedBox(height: 40),

                    Container(
                      width: double.infinity, height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFCFA7FF), Color(0xFF9C8EFF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: const Color(0xFF9C8EFF).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _saveData,
                          borderRadius: BorderRadius.circular(30),
                          child: Center(child: Text(t['saveBtn']!, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool isPassword, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: isNumber ? 4 : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true, fillColor: Colors.white, counterText: "",
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: inputFieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: purpleTextColor)),
      ),
    );
  }
}

// ==========================================
// STEP 5: Main Dashboard Screen & ADVANCED ML Kit Logic
// ==========================================
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> with SingleTickerProviderStateMixin {
  double _currentStep = 2;
  String _selectedVoice = 'default';
  String _selectedScreen = 'default';

  String _appLanguage = 'en';
  String _kidName = 'Kid';
  bool _isLoading = true;
  bool _isProtecting = false;

  late AnimationController _animController;

  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.1,
    ),
  );
  bool _isProcessingFrame = false;
  double _smoothedRatio = 0.0;
  int _lastFaceDetectedTime = 0;

  bool _isWarningActive = false;

  // 🔴 ලොකුම වෙනස: Overlay එක පාලනය කරන්න හැදුව ආරක්ෂිත අගුල (Safe Lock)
  bool _isOverlayWorking = false;

  final Map<String, Map<String, String>> _t = {
    'en': {'title': 'Safe Distance Settings', 'voiceTitle': 'Voice Notification Settings', 'defVoice': 'Default Voice', 'custVoice': 'Custom Voice', 'record': '● RECORD', 'screenTitle': 'Warning Screen Settings', 'defScreen': 'Default Screen', 'custPhoto': 'Custom Photo', 'pickPhoto': 'PICK PHOTO', 'start': 'START PROTECTION', 'stop': 'STOP PROTECTION', 'hide': 'HIDE APP', 'waitSec': 'Wait a second', 'tooClose': 'Too close to eyes!', 'moveAway': 'Please move the phone further away.'},
    'ko': {'title': '안전 거리 설정', 'voiceTitle': '음성 알림 설정', 'defVoice': '기본 음성', 'custVoice': '사용자 지정 음성', 'record': '● 녹음', 'screenTitle': '경고 화면 설정', 'defScreen': '기본 화면', 'custPhoto': '사용자 지정 사진', 'pickPhoto': '사진 선택', 'start': '보호 시작', 'stop': '보호 중지', 'hide': '앱 숨기기', 'waitSec': '잠깐만', 'tooClose': '눈에 너무 가까워요!', 'moveAway': '휴대폰을 더 멀리 떨어뜨려 주세요.'},
    'zh': {'title': '安全距离设置', 'voiceTitle': '语音通知设置', 'defVoice': '默认语音', 'custVoice': '自定义语音', 'record': '● 录音', 'screenTitle': '警告屏幕设置', 'defScreen': '默认屏幕', 'custPhoto': '自定义照片', 'pickPhoto': '选择照片', 'start': '开始保护', 'stop': '停止保护', 'hide': '隐藏应用', 'waitSec': '等一下', 'tooClose': '离眼睛太近了！', 'moveAway': '请把手机移远一点。'},
    'ja': {'title': '安全距離設定', 'voiceTitle': '音声通知設定', 'defVoice': 'デフォルト音声', 'custVoice': 'カスタム音声', 'record': '● 録音', 'screenTitle': '警告画面設定', 'defScreen': 'デフォルト画面', 'custPhoto': 'カスタム写真', 'pickPhoto': '写真を選択', 'start': '保護を開始', 'stop': '保護を停止', 'hide': 'アプリを隠す', 'waitSec': 'ちょっと待って', 'tooClose': '目に近すぎます！', 'moveAway': '電話をもう少し離してください。'},
    'fr': {'title': 'Paramètres de Distance', 'voiceTitle': 'Notification Vocale', 'defVoice': 'Voix par Défaut', 'custVoice': 'Voix Personnalisée', 'record': '● ENREGISTRER', 'screenTitle': 'Écran d\'Avertissement', 'defScreen': 'Écran par Défaut', 'custPhoto': 'Photo Personnalisée', 'pickPhoto': 'CHOISIR PHOTO', 'start': 'DÉMARRER LA PROTECTION', 'stop': 'ARRÊTER LA PROTECTION', 'hide': 'MASQUER L\'APP', 'waitSec': 'Attends une seconde', 'tooClose': 'Trop près des yeux !', 'moveAway': 'Éloignez le téléphone s\'il te plaît.'},
    'de': {'title': 'Sicherheitsabstand', 'voiceTitle': 'Sprachbenachrichtigung', 'defVoice': 'Standardstimme', 'custVoice': 'Eigene Stimme', 'record': '● AUFNEHMEN', 'screenTitle': 'Warnbildschirm', 'defScreen': 'Standardbildschirm', 'custPhoto': 'Eigenes Foto', 'pickPhoto': 'FOTO WÄHLEN', 'start': 'SCHUTZ STARTEN', 'stop': 'SCHUTZ BEENDEN', 'hide': 'APP VERSTECKEN', 'waitSec': 'Warte eine Sekunde', 'tooClose': 'Zu nah an den Augen!', 'moveAway': 'Bitte halte das Telefon weiter weg.'},
    'es': {'title': 'Distancia Segura', 'voiceTitle': 'Notificación de Voz', 'defVoice': 'Voz Predeterminada', 'custVoice': 'Voz Personalizada', 'record': '● GRABAR', 'screenTitle': 'Pantalla de Advertencia', 'defScreen': 'Pantalla Predeterminada', 'custPhoto': 'Foto Personalizada', 'pickPhoto': 'ELEGIR FOTO', 'start': 'INICIAR PROTECCIÓN', 'stop': 'DETENER PROTECCIÓN', 'hide': 'OCULTAR APLICACIÓN', 'waitSec': 'Espera un segundo', 'tooClose': '¡Demasiado cerca de los ojos!', 'moveAway': 'Por favor, aleja más el teléfono.'},
    'pt': {'title': 'Distância Segura', 'voiceTitle': 'Notificação de Voz', 'defVoice': 'Voz Padrão', 'custVoice': 'Voz Personalizada', 'record': '● GRAVAR', 'screenTitle': 'Tela de Aviso', 'defScreen': 'Tela Padrão', 'custPhoto': 'Foto Personalizada', 'pickPhoto': 'ESCOLHER FOTO', 'start': 'INICIAR PROTEÇÃO', 'stop': 'PARAR PROTEÇÃO', 'hide': 'OCULTAR O APP', 'waitSec': 'Espere um segundo', 'tooClose': 'Muito perto dos olhos!', 'moveAway': 'Por favor, afaste mais o telefone.'},
    'ru': {'title': 'Безопасное расстояние', 'voiceTitle': 'Голосовое уведомление', 'defVoice': 'Стандартный голос', 'custVoice': 'Свой голос', 'record': '● ЗАПИСЬ', 'screenTitle': 'Экран предупреждения', 'defScreen': 'Стандартный экран', 'custPhoto': 'Свое фото', 'pickPhoto': 'ВЫБРАТЬ ФОТО', 'start': 'НАЧАТЬ ЗАЩИТУ', 'stop': 'ОСТАНОВИТЬ ЗАЩИТУ', 'hide': 'СКРЫТЬ ПРИЛОЖЕНИЕ', 'waitSec': 'Подожди секунду', 'tooClose': 'Слишком близко к глазам!', 'moveAway': 'Пожалуйста, отодвиньте телефон дальше.'},
    'ar': {'title': 'إعدادات المسافة الآمنة', 'voiceTitle': 'الإشعارات الصوتية', 'defVoice': 'الصوت الافتراضي', 'custVoice': 'صوت مخصص', 'record': '● تسجيل', 'screenTitle': 'شاشة التحذير', 'defScreen': 'الشاشة الافتراضية', 'custPhoto': 'صورة مخصصة', 'pickPhoto': 'اختيار صورة', 'start': 'بدء الحماية', 'stop': 'إيقاف الحماية', 'hide': 'إخفاء التطبيق', 'waitSec': 'انتظر ثانية', 'tooClose': 'قريب جداً من العينين!', 'moveAway': 'يرجى إبعاد الهاتف أكثر.'},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appLanguage = prefs.getString('app_language') ?? 'en';
      _kidName = prefs.getString('kid_name') ?? 'Kid';
      _isLoading = false;
    });
  }

  // 🔴 ලොකුම වෙනස: Overlay එක Crash වෙන්නේ නැතුව පාලනය කරන Function එක
  Future<void> _manageOverlay(bool show) async {
    if (_isOverlayWorking) return;
    _isOverlayWorking = true;

    try {
      bool isActive = await FlutterOverlayWindow.isActive();
      if (show && !isActive) {
        bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
        if (isGranted) {
          await FlutterOverlayWindow.showOverlay(
            alignment: OverlayAlignment.center,
            flag: OverlayFlag.defaultFlag,
          );
        }
      } else if (!show && isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      debugPrint("Overlay error: $e");
    } finally {
      _isOverlayWorking = false;
    }
  }

  Future<void> _toggleProtection() async {
    if (_isProtecting) {
      await _stopProtection();
    } else {
      await _startProtection();
    }
  }

  Future<void> _stopProtection() async {
    setState(() {
      _isProtecting = false;
      _isWarningActive = false;
    });

    // ආරක්ෂිතව Overlay එක වහනවා
    _manageOverlay(false);

    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
  }

  Future<void> _startProtection() async {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera found!')));
      return;
    }

    setState(() => _isProtecting = true);
    final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _cameraController?.initialize();

    _cameraController?.startImageStream((CameraImage image) {
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController!.description;
      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ??
          (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

      final int bytesPerRow = image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize, rotation: imageRotation, format: inputImageFormat, bytesPerRow: bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      double currentThreshold = 0.45;
      if (_currentStep == 1) currentThreshold = 0.65;
      else if (_currentStep == 2) currentThreshold = 0.58;
      else if (_currentStep == 3) currentThreshold = 0.52;
      else if (_currentStep == 4) currentThreshold = 0.45;

      bool shouldWarn = false;

      if (faces.isEmpty) {
        if (_smoothedRatio > currentThreshold && currentTime - _lastFaceDetectedTime < 4000) {
          shouldWarn = true;
        } else {
          _smoothedRatio = 0.0;
          shouldWarn = false;
        }
      } else {
        _lastFaceDetectedTime = currentTime;
        final face = faces.first;

        final maxFaceDimension = math.max(face.boundingBox.width, face.boundingBox.height);
        final maxImageDimension = math.max(imageSize.width, imageSize.height);

        final ratio = maxFaceDimension / maxImageDimension;
        _smoothedRatio = (_smoothedRatio == 0.0) ? ratio : (_smoothedRatio * 0.8 + ratio * 0.2);

        if (_smoothedRatio > currentThreshold) {
          shouldWarn = true;
        } else {
          shouldWarn = false;
        }
      }

      // 💡 THE FLUTTER WAY FIX - කිසිම Race Condition එකක් නැතුව ආරක්ෂිතව Overlay එක කෝල් කිරීම
      if (shouldWarn && !_isWarningActive) {
        if (mounted) {
          setState(() {
            _isWarningActive = true;
          });
        }
        _manageOverlay(true);

      } else if (!shouldWarn && _isWarningActive) {
        if (mounted) {
          setState(() {
            _isWarningActive = false;
          });
        }
        _manageOverlay(false);
      }

    } catch (e) {
      print("Error: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFF3E5FF), body: Center(child: CircularProgressIndicator()));
    final t = _t[_appLanguage] ?? _t['en']!;

    return Scaffold(
      body: Stack(
        children: [
          Directionality(
            textDirection: _appLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              width: double.infinity, height: double.infinity,
              decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg_main_purple.png'), fit: BoxFit.cover)),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 55),
                          Column(
                            children: [
                              Text(t['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A2D81))),
                              Text("STEP ${_currentStep.toInt()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A2D81))),
                            ],
                          ),
                          Opacity(
                            opacity: _isProtecting ? 0.4 : 1.0,
                            child: InkWell(
                              onTap: _isProtecting ? null : () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOutQuart));
                                      return SlideTransition(position: animation.drive(tween), child: child);
                                    },
                                    transitionDuration: const Duration(milliseconds: 400),
                                  ),
                                ).then((_) => _loadData());
                              },
                              child: Image.asset('assets/ic_settings.png', width: 55, height: 55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: AbsorbPointer(
                        absorbing: _isProtecting,
                        child: Opacity(
                          opacity: _isProtecting ? 0.6 : 1.0,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF9C8EFF), inactiveTrackColor: const Color(0xFFE1D3FF),
                              thumbColor: Colors.white, trackHeight: 8.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                            ),
                            child: Slider(
                              value: _currentStep, min: 1, max: 4, divisions: 3,
                              onChanged: (value) => setState(() => _currentStep = value),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 300, height: 300,
                          child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                final t = _animController.value * 2 * math.pi;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(top: 20 + (math.cos(t * 2) * 10), left: 10 + (math.sin(t * 1) * 12), child: Image.asset('assets/ic_floating_shield.png', width: 60)),
                                    Positioned(top: 40 + (math.sin(t * 2) * 12), right: 10 + (math.cos(t * 1) * 10), child: Image.asset('assets/ic_floating_eye.png', width: 70)),
                                    Positioned(bottom: 60 + (math.cos(t * 1) * 10), left: 30 + (math.sin(t * 2) * 15), child: Image.asset('assets/ic_floating_location.png', width: 50)),
                                    Image.asset('assets/step_image_${_currentStep.toInt()}.png', width: 200, fit: BoxFit.contain),
                                  ],
                                );
                              }
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Column(
                        children: [
                          AbsorbPointer(
                            absorbing: _isProtecting,
                            child: Opacity(
                              opacity: _isProtecting ? 0.4 : 1.0,
                              child: Column(
                                children: [
                                  _buildSettingsCard(
                                    title: t['voiceTitle']!, icon: Icons.music_note,
                                    child: _buildDropdown(
                                      value: _selectedVoice,
                                      items: [{'value': 'default', 'text': t['defVoice']!, 'image': 'ic_voice_child.png'}, {'value': 'custom', 'text': t['custVoice']!, 'image': 'ic_mic_purple.png'}],
                                      onChanged: (val) => setState(() => _selectedVoice = val!),
                                    ),
                                    extraWidget: _selectedVoice == 'custom' ? _buildActionButton(t['record']!, [const Color(0xFFFF5E94), const Color(0xFFFF2A70)]) : null,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildSettingsCard(
                                    title: t['screenTitle']!, icon: Icons.image,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildDropdown(
                                            value: _selectedScreen,
                                            items: [{'value': 'default', 'text': t['defScreen']!, 'image': 'ic_warning_default.png'}, {'value': 'custom', 'text': t['custPhoto']!, 'image': 'ic_gallery_icon.png'}],
                                            onChanged: (val) => setState(() => _selectedScreen = val!),
                                          ),
                                        ),
                                        if (_selectedScreen == 'custom') ...[
                                          const SizedBox(width: 10),
                                          _buildActionButton(t['pickPhoto']!, [const Color(0xFFB499FF), const Color(0xFF9C8EFF)], isSmall: true),
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          _buildMainButton(
                            _isProtecting ? t['stop']! : t['start']!,
                            _isProtecting ? [const Color(0xFFFF5E94), const Color(0xFFFF2A70)] : [const Color(0xFF7FF77B), const Color(0xFF4DD849)],
                            onTap: _toggleProtection,
                          ),

                          const SizedBox(height: 15),
                          _buildGlassButton(t['hide']!),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isWarningActive)
            Positioned.fill(
              child: Material(
                color: Colors.white.withOpacity(0.65),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${t['waitSec']} $_kidName!", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.redAccent), textAlign: TextAlign.center),
                        const SizedBox(height: 30),
                        Image.asset('assets/eye_warning.gif', width: 160, height: 160),
                        const SizedBox(height: 30),
                        Text(t['tooClose']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(t['moveAway']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required IconData icon, required Widget child, Widget? extraWidget}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: const Color(0xFFF3E5FF), radius: 15, child: Icon(icon, size: 16, color: const Color(0xFF5A2D81))),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A2D81)))),
            ],
          ),
          const SizedBox(height: 15),
          child,
          if (extraWidget != null) ...[const SizedBox(height: 15), extraWidget],
        ],
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<Map<String, String>> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E0E0)), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, value: value, icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5A2D81)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Row(
                children: [
                  Image.asset('assets/${item['image']}', width: 24, height: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item['text']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, List<Color> colors, {bool isSmall = false}) {
    return Container(
      width: isSmall ? null : double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: colors[1].withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: isSmall ? const EdgeInsets.symmetric(horizontal: 15, vertical: 12) : const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(String text, List<Color> colors, {required VoidCallback onTap}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75, height: 55,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: colors[1].withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildGlassButton(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.50, height: 50,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              },
              borderRadius: BorderRadius.circular(30),
              child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// STEP 6: Settings Screen & Custom Popups
// ==========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appLanguage = 'en';
  bool _isLoading = true;

  final Map<String, Map<String, String>> _t = {
    'en': {'settings': 'Settings', 'lang': 'Language', 'resetPw': 'Reset Parent Password', 'unblock': 'Release Uninstall Block', 'unlockApp': 'Unlock App', 'enterPw': 'Enter Password', 'unlockBtn': 'UNLOCK APP', 'forgotPw': 'Forgot Password?', 'secVerify': 'Security Verification', 'secQ': 'What is your mother\'s hometown?', 'typeAns': 'Type your answer', 'verifyBtn': 'VERIFY NOW', 'wrongPw': 'Incorrect password!', 'wrongAns': 'Incorrect answer!'},
    'ko': {'settings': '설정', 'lang': '언어', 'resetPw': '부모 비밀번호 재설정', 'unblock': '삭제 차단 해제', 'unlockApp': '앱 잠금 해제', 'enterPw': '비밀번호 입력', 'unlockBtn': '잠금 해제', 'forgotPw': '비밀번호를 잊으셨나요?', 'secVerify': '보안 인증', 'secQ': '어머니의 고향은 어디입니까?', 'typeAns': '정답 입력', 'verifyBtn': '지금 인증', 'wrongPw': '잘못된 비밀번호입니다!', 'wrongAns': '잘못된 정답입니다!'},
    'zh': {'settings': '设置', 'lang': '语言', 'resetPw': '重置家长密码', 'unblock': '解除卸载拦截', 'unlockApp': '解锁应用', 'enterPw': '输入密码', 'unlockBtn': '解锁', 'forgotPw': '忘记密码？', 'secVerify': '安全验证', 'secQ': '你母亲的故乡在哪里？', 'typeAns': '输入你的答案', 'verifyBtn': '立即验证', 'wrongPw': '密码错误！', 'wrongAns': '答案错误！'},
    'ja': {'settings': '設定', 'lang': '言語', 'resetPw': '親のパスワードをリセット', 'unblock': 'アンインストールブロックを解除', 'unlockApp': 'アプリのロック解除', 'enterPw': 'パスワードを入力', 'unlockBtn': 'ロック解除', 'forgotPw': 'パスワードを忘れましたか？', 'secVerify': 'セキュリティ認証', 'secQ': '母親の出身地はどこですか？', 'typeAns': '答えを入力', 'verifyBtn': '今すぐ認証', 'wrongPw': 'パスワードが間違っています！', 'wrongAns': '答えが間違っています！'},
    'fr': {'settings': 'Paramètres', 'lang': 'Langue', 'resetPw': 'Réinitialiser le mot de passe', 'unblock': 'Débloquer la désinstallation', 'unlockApp': 'Déverrouiller l\'app', 'enterPw': 'Entrer le mot de passe', 'unlockBtn': 'DÉVERROUILLER', 'forgotPw': 'Mot de passe oublié ?', 'secVerify': 'Vérification de sécurité', 'secQ': 'Quelle est la ville natale de votre mère ?', 'typeAns': 'Tapez votre réponse', 'verifyBtn': 'VÉRIFIER', 'wrongPw': 'Mot de passe incorrect!', 'wrongAns': 'Réponse incorrecte!'},
    'de': {'settings': 'Einstellungen', 'lang': 'Sprache', 'resetPw': 'Eltern-Passwort zurücksetzen', 'unblock': 'Deinstallationssperre aufheben', 'unlockApp': 'App entsperren', 'enterPw': 'Passwort eingeben', 'unlockBtn': 'ENTSPERREN', 'forgotPw': 'Passwort vergessen?', 'secVerify': 'Sicherheitsüberprüfung', 'secQ': 'Was ist die Heimatstadt deiner Mutter?', 'typeAns': 'Antwort eingeben', 'verifyBtn': 'ÜBERPRÜFEN', 'wrongPw': 'Falsches Passwort!', 'wrongAns': 'Falsche Antwort!'},
    'es': {'settings': 'Ajustes', 'lang': 'Idioma', 'resetPw': 'Restablecer contraseña', 'unblock': 'Desbloquear desinstalación', 'unlockApp': 'Desbloquear App', 'enterPw': 'Introducir contraseña', 'unlockBtn': 'DESBLOQUEAR', 'forgotPw': '¿Olvidaste la contraseña?', 'secVerify': 'Verificación de seguridad', 'secQ': '¿Cuál es la ciudad natal de tu madre?', 'typeAns': 'Escribe tu respuesta', 'verifyBtn': 'VERIFICAR', 'wrongPw': '¡Contraseña incorrecta!', 'wrongAns': '¡Respuesta incorrecta!'},
    'pt': {'settings': 'Configurações', 'lang': 'Idioma', 'resetPw': 'Redefinir senha dos pais', 'unblock': 'Desbloquear desinstalação', 'unlockApp': 'Desbloquear App', 'enterPw': 'Digite a senha', 'unlockBtn': 'DESBLOQUEAR', 'forgotPw': 'Esqueceu a senha?', 'secVerify': 'Verificação de Segurança', 'secQ': 'Qual é a cidade natal da sua mãe?', 'typeAns': 'Digite sua resposta', 'verifyBtn': 'VERIFICAR', 'wrongPw': 'Senha incorreta!', 'wrongAns': 'Resposta incorreta!'},
    'ru': {'settings': 'Настройки', 'lang': 'Язык', 'resetPw': 'Сбросить пароль родителя', 'unblock': 'Снять блок удаления', 'unlockApp': 'Разблокировать', 'enterPw': 'Введите пароль', 'unlockBtn': 'РАЗБЛОКИРОВАТЬ', 'forgotPw': 'Забыли пароль?', 'secVerify': 'Проверка безопасности', 'secQ': 'В каком городе родилась ваша мать?', 'typeAns': 'Введите ваш ответ', 'verifyBtn': 'ПРОВЕРИТЬ', 'wrongPw': 'Неверный пароль!', 'wrongAns': 'Неверный ответ!'},
    'ar': {'settings': 'الإعدادات', 'lang': 'اللغة', 'resetPw': 'إعادة تعيين كلمة المرور', 'unblock': 'إلغاء حظر التثبيت', 'unlockApp': 'إلغاء قفل التطبيق', 'enterPw': 'أدخل كلمة المرور', 'unlockBtn': 'إلغاء القفل', 'forgotPw': 'هل نسيت كلمة المرور؟', 'secVerify': 'التحقق من الأمان', 'secQ': 'ما هي مسقط رأس والدتك؟', 'typeAns': 'اكتب إجابتك', 'verifyBtn': 'تحقق الآن', 'wrongPw': 'كلمة المرور غير صحيحة!', 'wrongAns': 'إجابة غير صحيحة!'},
  };

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': 'en.png'},
    {'code': 'ko', 'name': '한국어', 'flag': 'ko.png'},
    {'code': 'zh', 'name': '简体中文', 'flag': 'zh.png'},
    {'code': 'ja', 'name': '日本語', 'flag': 'ja.png'},
    {'code': 'fr', 'name': 'Français', 'flag': 'fr.png'},
    {'code': 'de', 'name': 'Deutsch', 'flag': 'de.png'},
    {'code': 'es', 'name': 'Español', 'flag': 'es.png'},
    {'code': 'pt', 'name': 'Português', 'flag': 'pt.png'},
    {'code': 'ru', 'name': 'Русский', 'flag': 'ru.png'},
    {'code': 'ar', 'name': 'العربية', 'flag': 'ar.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appLanguage = prefs.getString('app_language') ?? 'en';
      _isLoading = false;
    });
  }

  void _showLanguageDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "LanguageDialog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 250,
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final lang = _languages[index];
                      final isSelected = lang['code'] == _appLanguage;
                      return InkWell(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('app_language', lang['code']!);
                          setState(() => _appLanguage = lang['code']!);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: isSelected ? const Color(0xFFEBD9FF) : Colors.transparent,
                          child: Row(
                            children: [
                              ClipOval(child: Image.asset('assets/${lang['flag']}', width: 25, height: 25, fit: BoxFit.cover)),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(lang['name']!, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF5A2D81))),
                              ),
                              if (isSelected) const Icon(Icons.check, color: Color(0xFF5A2D81), size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: Curves.easeOutBack.transform(anim1.value), child: FadeTransition(opacity: anim1, child: child));
      },
    );
  }

  void _startResetPasswordFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final correctPw = prefs.getString('app_password') ?? '';
    final correctAns = prefs.getString('security_answer') ?? '';
    final t = _t[_appLanguage]!;

    while (true) {
      final result = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: "PasswordDialog",
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) => _CustomPopupDialog(
          title: t['unlockApp']!,
          hintText: t['enterPw']!,
          btnText: t['unlockBtn']!,
          bottomText: t['forgotPw']!,
          correctValue: correctPw,
          errorMsg: t['wrongPw']!,
          iconWidget: Image.asset('assets/ic_3d_lock.png', width: 90, height: 90, fit: BoxFit.contain),
          isPassword: true,
        ),
        transitionBuilder: _dialogTransition,
      );

      if (result == 'success') {
        _goToInitialSetup();
        break;
      } else if (result == 'bottom_action') {
        final secResult = await showGeneralDialog<String>(
          context: context,
          barrierDismissible: true,
          barrierLabel: "SecurityDialog",
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, anim1, anim2) => _CustomPopupDialog(
            title: t['secVerify']!,
            subTitle: t['secQ']!,
            hintText: t['typeAns']!,
            btnText: t['verifyBtn']!,
            correctValue: correctAns,
            errorMsg: t['wrongAns']!,
            iconWidget: Image.asset('assets/ic_3d_shield.png', width: 90, height: 90, fit: BoxFit.contain),
            isPassword: false,
          ),
          transitionBuilder: _dialogTransition,
        );

        if (secResult == 'success') {
          _goToInitialSetup();
          break;
        } else if (secResult == 'back' || secResult == null) {
          continue;
        }
      } else {
        break;
      }
    }
  }

  void _goToInitialSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const InitialSetupScreen()),
    );
  }

  Widget _dialogTransition(context, anim1, anim2, child) {
    return Transform.scale(scale: Curves.easeOutBack.transform(anim1.value), child: FadeTransition(opacity: anim1, child: child));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFEEDCFF), body: Center(child: CircularProgressIndicator()));

    final t = _t[_appLanguage]!;
    final isRTL = _appLanguage == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFEBD9FF),
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
                        child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5A2D81), size: 20),
                      ),
                    ),
                    Expanded(child: Center(child: Text(t['settings']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A2D81))))),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 25.0), child: Divider(color: const Color(0xFF5A2D81).withOpacity(0.2), thickness: 1)),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  children: [
                    _buildGlassMenuButton(iconPath: 'ic_world.png', title: t['lang']!, onTap: _showLanguageDialog),
                    _buildGlassMenuButton(iconPath: 'ic_lock_reset.png', title: t['resetPw']!, onTap: _startResetPasswordFlow),
                    _buildGlassMenuButton(iconPath: 'ic_uninstall.png', title: t['unblock']!, isRedText: true, onTap: () {}),
                  ],
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text("MJ Connection (Pvt) Ltd", style: TextStyle(color: Color(0xFFB499FF), fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassMenuButton({required String iconPath, required String title, required VoidCallback onTap, bool isRedText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              height: 75,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFF5A2D81).withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Image.asset('assets/$iconPath', width: 35, height: 35),
                  const SizedBox(width: 20),
                  Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isRedText ? const Color(0xFFD32F2F) : const Color(0xFF5A2D81)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Custom Popup Dialog (With Shake Animation & 3D Button) ---
class _CustomPopupDialog extends StatefulWidget {
  final String title;
  final String? subTitle;
  final String hintText;
  final String btnText;
  final String? bottomText;
  final String correctValue;
  final String errorMsg;
  final Widget iconWidget;
  final bool isPassword;

  const _CustomPopupDialog({
    required this.title, this.subTitle, required this.hintText, required this.btnText,
    this.bottomText, required this.correctValue, required this.errorMsg, required this.iconWidget, required this.isPassword,
  });

  @override
  State<_CustomPopupDialog> createState() => _CustomPopupDialogState();
}

class _CustomPopupDialogState extends State<_CustomPopupDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  void _verify() {
    if (_controller.text == widget.correctValue) {
      Navigator.pop(context, 'success');
    } else {
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.errorMsg), backgroundColor: Colors.redAccent));
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, 'back');
      },
      child: Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final sineValue = math.sin(_shakeController.value * 4 * math.pi);
              return Transform.translate(offset: Offset(sineValue * 10, 0), child: child);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.iconWidget,
                      const SizedBox(height: 15),
                      Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),

                      if (widget.subTitle != null) ...[
                        const SizedBox(height: 10),
                        Text(widget.subTitle!, style: const TextStyle(fontSize: 15, color: Color(0xFF5A2D81), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      ],

                      const SizedBox(height: 25),
                      TextField(
                        controller: _controller,
                        obscureText: widget.isPassword,
                        keyboardType: widget.isPassword ? TextInputType.number : TextInputType.text,
                        maxLength: widget.isPassword ? 4 : null,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF5A2D81))),
                        ),
                      ),
                      const SizedBox(height: 25),

                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE1D3FF), Color(0xFFC4B0FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF5A2D81).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _verify,
                            borderRadius: BorderRadius.circular(20),
                            child: Center(child: Text(widget.btnText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A2D81)))),
                          ),
                        ),
                      ),

                      if (widget.bottomText != null) ...[
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () => Navigator.pop(context, 'bottom_action'),
                          child: Text(widget.bottomText!, style: const TextStyle(color: Color(0xFF5A2D81), fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
