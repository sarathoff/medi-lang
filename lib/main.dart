// main.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timeago/timeago.dart' as timeago;

// --- Entry Point ---
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  // Get available cameras
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint("Error finding cameras: ${e.description}");
    // Handle error, maybe inform the user camera functionality won't work
  }

  runApp(MedicineAnalyzerApp(cameras: cameras));
}

// --- Main App Widget ---
class MedicineAnalyzerApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MedicineAnalyzerApp({super.key, required this.cameras});

  @override
  State<MedicineAnalyzerApp> createState() => _MedicineAnalyzerAppState();
}

class _MedicineAnalyzerAppState extends State<MedicineAnalyzerApp> {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- Theme Definition (Well-structured, kept as is) ---
    const seedColor = Color(0xFF6750A4);
    final baseTextTheme = GoogleFonts.dmSansTextTheme();
    final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    final buttonPadding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        surface: Colors.white,
        surfaceVariant: const Color(0xFFE7E0EC),
        background: const Color(0xFFF7F2FA),
      ),
      useMaterial3: true,
      textTheme: baseTextTheme.apply(bodyColor: const Color(0xFF1C1B1F), displayColor: const Color(0xFF1C1B1F)),
      scaffoldBackgroundColor: const Color(0xFFF7F2FA),
      cardTheme: CardThemeData(
        elevation: 0.8,
        color: Colors.white,
        shape: cardShape,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 1,
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: seedColor.withOpacity(0.7), width: 1.5),
          foregroundColor: seedColor,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: seedColor,
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B1F),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: const Color(0xFF1C1B1F),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: seedColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: seedColor,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade300, thickness: 0.8, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: GoogleFonts.dmSans(color: Colors.white),
        actionTextColor: seedColor,
      ),
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1B1F),
        surfaceVariant: const Color(0xFF2D2C31),
        background: const Color(0xFF141317),
        onPrimary: Colors.white,
        onBackground: const Color(0xFFE6E1E5),
        onSurface: const Color(0xFFE6E1E5),
      ),
      useMaterial3: true,
      textTheme: baseTextTheme.apply(bodyColor: const Color(0xFFE6E1E5), displayColor: const Color(0xFFE6E1E5)),
      scaffoldBackgroundColor: const Color(0xFF141317),
      cardTheme: CardThemeData(
        elevation: 0.5,
        color: const Color(0xFF2D2C31),
        shape: cardShape,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 1,
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: seedColor.withOpacity(0.8), width: 1.5),
          foregroundColor: seedColor.withOpacity(0.9),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: seedColor,
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2D2C31),
        foregroundColor: const Color(0xFFE6E1E5),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: const Color(0xFFE6E1E5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade400,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade700, thickness: 0.8, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFFE0E0E0),
        contentTextStyle: GoogleFonts.dmSans(color: Colors.black87),
        actionTextColor: seedColor,
      ),
    );

    return MaterialApp(
      title: 'MediLang',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), Locale('hi', ''), Locale('es', ''), Locale('fr', ''),
        Locale('ta', ''), Locale('te', ''), Locale('kn', ''), Locale('ml', ''),
        Locale('mr', ''), Locale('gu', ''),
      ],
      home: MedicineAnalyzerScreen(
        cameras: widget.cameras,
        currentThemeMode: _themeMode,
        onChangeTheme: _changeThemeMode,
      ),
    );
  }
}

// --- Screen and State Logic ---
class MedicineAnalyzerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onChangeTheme;

  const MedicineAnalyzerScreen({
    super.key,
    required this.cameras,
    required this.currentThemeMode,
    required this.onChangeTheme,
  });

  // Helper maps for language selection
  static const Map<String, String> supportedLanguages = {
    'en': 'English', 'ta': 'தமிழ்', 'hi': 'हिंदी', 'es': 'Español',
    'fr': 'Français', 'te': 'తెలుగు', 'kn': 'ಕನ್ನಡ', 'ml': 'മലയാളം',
    'mr': 'मराठी', 'gu': 'ગુજરાતી',
  };

  static String getLanguageName(Locale locale) {
    return supportedLanguages[locale.languageCode] ?? 'Unknown';
  }

  static String getBcp47LanguageTag(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'en-US';
      case 'hi': return 'hi-IN';
      case 'es': return 'es-ES';
      case 'fr': return 'fr-FR';
      case 'ta': return 'ta-IN';
      case 'te': return 'te-IN';
      case 'kn': return 'kn-IN';
      case 'ml': return 'ml-IN';
      case 'mr': return 'mr-IN';
      case 'gu': return 'gu-IN';
      default: return 'en-US';
    }
  }

  @override
  State<MedicineAnalyzerScreen> createState() => _MedicineAnalyzerScreenState();
}

class _MedicineAnalyzerScreenState extends State<MedicineAnalyzerScreen> with SingleTickerProviderStateMixin {
  // State variables
  late final TabController _tabController;
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Uint8List? _imageBytes;
  String _analysisResult = "Take or upload a photo to analyze the medicine";
  bool _isAnalyzing = false;
  bool _isCameraInitialized = false;
  bool _cameraAvailable = false;
  Locale _selectedLocale = const Locale('en', '');
  final List<Map<String, dynamic>> _analysisHistory = [];

  // TTS State
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cameraAvailable = widget.cameras.isNotEmpty;

    if (_cameraAvailable) {
      _initializeCamera(widget.cameras[0]);
    }
    _initTts();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // --- Core Methods: Camera, Analysis, TTS ---

  void _initializeCamera(CameraDescription cameraDescription) {
    if (_controller != null) {
      _controller!.dispose().catchError((e) => debugPrint("Error disposing controller: $e"));
    }
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    if (mounted) setState(() => _isCameraInitialized = false);

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (mounted) setState(() => _isCameraInitialized = true);
    }).catchError((error) {
      if (mounted) {
        _showError("Could not initialize camera: ${error is CameraException ? error.description : error}");
        setState(() {
          _isCameraInitialized = false;
          _cameraAvailable = false;
        });
      }
    });
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        _showError("Text-to-speech error occurred.");
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<void> _speak(String text, Locale locale) async {
    if (text.isEmpty || _isSpeaking) return;

    final langTag = MedicineAnalyzerScreen.getBcp47LanguageTag(locale);
    var isLangAvailable = await _flutterTts.isLanguageAvailable(langTag);

    // Simplified availability check
    if ((isLangAvailable is bool && !isLangAvailable) || (isLangAvailable is Map && isLangAvailable.isEmpty)) {
      _showError("Voice data for '${MedicineAnalyzerScreen.getLanguageName(locale)}' may not be installed on your device.");
      return;
    }

    try {
      setState(() => _isSpeaking = true);
      await _flutterTts.setLanguage(langTag);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
    } catch (e) {
      _showError("Could not start text-to-speech.");
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    var result = await _flutterTts.stop();
    if (result == 1 && mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _processImageAndAnalyze(Uint8List imageBytes) async {
    await _stopSpeaking();
    if (mounted) {
      setState(() {
        _imageBytes = imageBytes;
        _analysisResult = "Analyzing your image...";
        _isAnalyzing = true;
        _isSpeaking = false;
      });
      _analyzeImage(imageBytes);
    }
  }
  
  // Cleaned up prompt and API logic
  Future<void> _analyzeImage(Uint8List imageBytes) async {
      try {
          final apiKey = dotenv.env['GEMINI_API_KEY'];
          if (apiKey == null || apiKey.isEmpty) {
              throw Exception("API key is missing. Ensure .env file is set up.");
          }

          final model = GenerativeModel(model: 'gemini-2.5-pro', apiKey: apiKey);
          
          final languageName = MedicineAnalyzerScreen.getLanguageName(_selectedLocale);
          final prompt = TextPart(
              "You are an AI assistant designed to explain medicine prescriptions or medical reports in simple terms, especially for individuals with limited literacy.\n\n"
              "Analyze the attached image and provide information in **$languageName**.\n\n"
              "Focus on these key points:\n"
              "1.  **Medicine/Test Name:** Identify the name of the medicine or test.\n"
              "2.  **Purpose:** Clearly explain what it is for (e.g., 'This is for blood pressure').\n"
              "3.  **Key Instructions:** Mention any important usage instructions shown (e.g., 'Take with food').\n\n"
              "**IMPORTANT RULES:**\n"
              "- Use simple, direct language. Avoid all medical jargon.\n"
              "- Format the response as readable text with clear paragraphs.\n"
              "- **Do not** use Markdown (like '*' or '**') or JSON formatting.\n"
              "- Conclude with a clear disclaimer: 'This is for informational purposes only. Always follow your doctor’s advice.'"
          );
          
          final imagePart = DataPart('image/jpeg', imageBytes);
          final content = [Content.multi([prompt, imagePart])];

          final response = await model.generateContent(content);
          final resultText = response.text?.trim() ?? "Could not analyze the image. Please try again with a clearer picture.";
          
          if (mounted) {
              setState(() {
                  _analysisResult = resultText;
                  _isAnalyzing = false;
                  _analysisHistory.insert(0, {
                      'result': resultText,
                      'timestamp': DateTime.now(),
                      'language': _selectedLocale.languageCode,
                  });
              });
          }
      } on GenerativeAIException catch (e) {
          _showError("Analysis failed: ${e.message}");
          if (mounted) {
              setState(() {
                  _analysisResult = "Analysis failed. Please check the image quality and your connection, then try again.";
                  _isAnalyzing = false;
              });
          }
      } catch (e) {
          _showError("An unexpected error occurred during analysis.");
          if (mounted) {
              setState(() {
                  _analysisResult = "Analysis failed due to an unexpected error. Please restart the app.";
                  _isAnalyzing = false;
              });
          }
      }
  }


  // --- UI Actions ---
  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null || _controller!.value.isTakingPicture) return;

    try {
      await HapticFeedback.lightImpact(); // Haptic feedback
      final XFile image = await _controller!.takePicture();
      _processImageAndAnalyze(await image.readAsBytes());
    } catch (e) {
      _showError("Failed to take picture. Please try again.");
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      await HapticFeedback.lightImpact(); // Haptic feedback
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        _processImageAndAnalyze(await image.readAsBytes());
      }
    } catch (e) {
      _showError("Failed to select image from gallery.");
    }
  }

  void _resetScan() {
    _stopSpeaking();
    setState(() {
      _imageBytes = null;
      _analysisResult = "Take or upload a photo to analyze the medicine";
      _isAnalyzing = false;
    });
  }

  void _changeLanguage(Locale locale) {
    if (_selectedLocale == locale) return;
    _stopSpeaking();
    setState(() => _selectedLocale = locale);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Analysis language set to ${MedicineAnalyzerScreen.getLanguageName(locale)}'),
      duration: const Duration(seconds: 2),
    ));
  }
  
  void _deleteHistoryItem(int index) {
      HapticFeedback.mediumImpact();
      setState(() {
          _analysisHistory.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('History item deleted.'),
      ));
  }


  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }
  
  void _copyToClipboard(String text, String confirmationMessage) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(confirmationMessage),
    ));
  }
  
  void _shareResult(String text) {
    HapticFeedback.lightImpact();
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      text,
      subject: 'MediLang Analysis Result',
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediLang'),
        actions: [
          // Theme switcher button
          IconButton(
            icon: Icon(widget.currentThemeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: widget.currentThemeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => widget.onChangeTheme(widget.currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_outlined, size: 20), SizedBox(width: 8), Text('Scan')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_outlined, size: 20), SizedBox(width: 8), Text('History')])),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- SCANNER TAB ---
          _ScannerTabBody(
            // Pass state and callbacks to the child widget
            imageBytes: _imageBytes,
            isAnalyzing: _isAnalyzing,
            isCameraInitialized: _isCameraInitialized,
            cameraAvailable: _cameraAvailable,
            controller: _controller,
            initializeControllerFuture: _initializeControllerFuture,
            analysisResult: _analysisResult,
            selectedLocale: _selectedLocale,
            isSpeaking: _isSpeaking,
            onTakePicture: _takePicture,
            onSelectFromGallery: _selectFromGallery,
            onResetScan: _resetScan,
            onChangeLanguage: _changeLanguage,
            onSpeak: () => _speak(_analysisResult, _selectedLocale),
            onStopSpeaking: _stopSpeaking,
            onCopyToClipboard: () => _copyToClipboard(_analysisResult, 'Result copied to clipboard!'),
            onShareResult: () => _shareResult(_analysisResult),
          ),
          
          // --- HISTORY TAB ---
          _HistoryTabBody(
            analysisHistory: _analysisHistory,
            onDelete: _deleteHistoryItem,
            onSpeak: _speak,
            onGoToScanTab: () => _tabController.animateTo(0),
            onCopyToClipboard: (text) => _copyToClipboard(text, 'History item copied!'),
          )
        ],
      ),
    );
  }
}

// ========== REFACTORED WIDGETS ==========

// --- SCANNER TAB BODY ---
class _ScannerTabBody extends StatelessWidget {
    // Input properties
    final Uint8List? imageBytes;
    final bool isAnalyzing;
    final bool isCameraInitialized;
    final bool cameraAvailable;
    final CameraController? controller;
    final Future<void>? initializeControllerFuture;
    final String analysisResult;
    final Locale selectedLocale;
    final bool isSpeaking;

    // Callbacks
    final VoidCallback onTakePicture;
    final VoidCallback onSelectFromGallery;
    final VoidCallback onResetScan;
    final Function(Locale) onChangeLanguage;
    final VoidCallback onSpeak;
    final VoidCallback onStopSpeaking;
    final VoidCallback onCopyToClipboard;
    final VoidCallback onShareResult;

  const _ScannerTabBody({
      this.imageBytes,
      required this.isAnalyzing,
      required this.isCameraInitialized,
      required this.cameraAvailable,
      this.controller,
      this.initializeControllerFuture,
      required this.analysisResult,
      required this.selectedLocale,
      required this.isSpeaking,
      required this.onTakePicture,
      required this.onSelectFromGallery,
      required this.onResetScan,
      required this.onChangeLanguage,
      required this.onSpeak,
      required this.onStopSpeaking,
      required this.onCopyToClipboard,
      required this.onShareResult,
  });

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 16.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // Conditionally show language selector
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, child: child)),
            child: imageBytes == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _LanguageSelector(
                    supportedLanguages: MedicineAnalyzerScreen.supportedLanguages,
                    selectedLocale: selectedLocale,
                    onChangeLanguage: onChangeLanguage,
                  ),
                )
              : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Preview Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _ImagePreviewArea(
              imageBytes: imageBytes,
              cameraAvailable: cameraAvailable,
              isCameraInitialized: isCameraInitialized,
              controller: controller,
              initializeControllerFuture: initializeControllerFuture,
              selectedLocale: selectedLocale,
              onResetScan: onResetScan,
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons or Analysis Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: imageBytes == null
                ? _CaptureButtons(
                    key: const ValueKey('capture_buttons'),
                    canCapture: cameraAvailable && isCameraInitialized && !isAnalyzing,
                    isAnalyzing: isAnalyzing,
                    onTakePicture: onTakePicture,
                    onSelectFromGallery: onSelectFromGallery,
                  )
                : _AnalysisCard(
                    key: const ValueKey('analysis_card'),
                    isAnalyzing: isAnalyzing,
                    analysisResult: analysisResult,
                    selectedLocale: selectedLocale,
                    isSpeaking: isSpeaking,
                    onSpeak: onSpeak,
                    onStopSpeaking: onStopSpeaking,
                    onCopyToClipboard: onCopyToClipboard,
                    onShareResult: onShareResult,
                  ),
            ),
          )
        ],
      ),
    );
  }
}

// --- LANGUAGE SELECTOR ---
class _LanguageSelector extends StatelessWidget {
  final Map<String, String> supportedLanguages;
  final Locale selectedLocale;
  final Function(Locale) onChangeLanguage;

  const _LanguageSelector({required this.supportedLanguages, required this.selectedLocale, required this.onChangeLanguage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Select Analysis Language', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.8,
              ),
              itemCount: supportedLanguages.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final localeCode = supportedLanguages.keys.elementAt(index);
                final label = supportedLanguages.values.elementAt(index);
                final isSelected = selectedLocale.languageCode == localeCode;

                return OutlinedButton(
                  onPressed: () => onChangeLanguage(Locale(localeCode)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.5) : null,
                    side: BorderSide(
                      color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- IMAGE PREVIEW AREA ---
class _ImagePreviewArea extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool cameraAvailable;
  final bool isCameraInitialized;
  final CameraController? controller;
  final Future<void>? initializeControllerFuture;
  final Locale selectedLocale;
  final VoidCallback onResetScan;

  const _ImagePreviewArea({this.imageBytes, required this.cameraAvailable, required this.isCameraInitialized, this.controller, this.initializeControllerFuture, required this.selectedLocale, required this.onResetScan});
  
  @override
  Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final screenHeight = MediaQuery.of(context).size.height;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: imageBytes != null ? screenHeight * 0.45 : screenHeight * 0.38,
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor)),
        clipBehavior: Clip.antiAlias, // Ensures child is clipped
        child: _buildContent(context),
      );
  }
  
  Widget _buildContent(BuildContext context) {
    if (imageBytes != null) {
      return _buildImageView(context);
    }
    if (cameraAvailable) {
      return _buildCameraPreview(context);
    }
    return _buildNoCameraView(context);
  }

  Widget _buildImageView(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(imageBytes!, fit: BoxFit.cover),
        Positioned(
          top: 12, right: 12,
          child: _buildOverlayButton(
            icon: Icons.refresh, tooltip: 'Scan New Image',
            onPressed: onResetScan,
          ),
        ),
        Positioned(
          top: 12, left: 12,
          child: _LanguageIndicatorPill(selectedLocale: selectedLocale),
        ),
      ],
    );
  }
  
  Widget _buildCameraPreview(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && isCameraInitialized && controller != null) {
              return Stack(
                fit: StackFit.expand,
                children: [
                    AspectRatio(
                      aspectRatio: controller!.value.aspectRatio,
                      child: CameraPreview(controller!),
                    ),
                    // Focusing Frame
                    Center(child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.5,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                    )),
                    // Overlay info
                    Positioned(bottom: 16, left: 16, right: 16,
                      child: Center(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                          child: const Text('Position medicine inside the frame', style: TextStyle(color: Colors.white, fontSize: 13)),
                      )),
                    ),
                    Positioned(top: 12, left: 12,
                      child: _LanguageIndicatorPill(selectedLocale: selectedLocale),
                    ),
                ],
              );
          }
          if (snapshot.hasError) {
              return Center(child: Text("Camera error: Check permissions.", style: TextStyle(color: theme.colorScheme.error)));
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
  }

  Widget _buildNoCameraView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("Camera not available", style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

// --- ANALYSIS CARD ---
class _AnalysisCard extends StatelessWidget {
    final bool isAnalyzing;
    final String analysisResult;
    final Locale selectedLocale;
    final bool isSpeaking;
    final VoidCallback onSpeak;
    final VoidCallback onStopSpeaking;
    final VoidCallback onCopyToClipboard;
    final VoidCallback onShareResult;

    const _AnalysisCard({super.key, required this.isAnalyzing, required this.analysisResult, required this.selectedLocale, required this.isSpeaking, required this.onSpeak, required this.onStopSpeaking, required this.onCopyToClipboard, required this.onShareResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValidResult = analysisResult.isNotEmpty && !isAnalyzing && !analysisResult.contains("failed");

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.science_outlined, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text('Analysis Result', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                _LanguageIndicatorPill(selectedLocale: selectedLocale, isCompact: true),
              ],
            ),
            const Divider(height: 24),
            // Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isAnalyzing
                ? const _AnalysisProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        analysisResult,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: theme.colorScheme.onSurface.withOpacity(0.9)),
                      ),
                      if (hasValidResult) ...[
                        const SizedBox(height: 24),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(context,
                                icon: isSpeaking ? Icons.stop_rounded : Icons.volume_up_outlined,
                                label: isSpeaking ? 'Stop' : 'Listen',
                                onTap: isSpeaking ? onStopSpeaking : onSpeak,
                                color: isSpeaking ? theme.colorScheme.error : theme.colorScheme.primary
                            ),
                            const SizedBox(width: 8),
                             _buildActionButton(context,
                                icon: Icons.copy_outlined,
                                label: 'Copy',
                                onTap: onCopyToClipboard,
                             ),
                            const SizedBox(width: 8),
                            _buildActionButton(context,
                                icon: Icons.share_outlined,
                                label: 'Share',
                                onTap: onShareResult
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
            )
          ],
        ),
      ),
    );
  }
}

// --- HISTORY TAB BODY ---
class _HistoryTabBody extends StatelessWidget {
  final List<Map<String, dynamic>> analysisHistory;
  final Function(int) onDelete;
  final Function(String, Locale) onSpeak;
  final VoidCallback onGoToScanTab;
  final Function(String) onCopyToClipboard;
  
  const _HistoryTabBody({ required this.analysisHistory, required this.onDelete, required this.onSpeak, required this.onGoToScanTab, required this.onCopyToClipboard });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (analysisHistory.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu_outlined, size: 80, color: theme.colorScheme.secondary.withOpacity(0.7)),
                const SizedBox(height: 24),
                Text('No Scan History', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Your analyzed medicine details will appear here.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onGoToScanTab,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Scan Your First Medicine'),
                ),
              ],
            ),
          ),
        );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: analysisHistory.length,
      itemBuilder: (context, index) {
          final item = analysisHistory[index];
          final String result = item['result'];
          final DateTime timestamp = item['timestamp'];
          final String languageCode = item['language'];
          final String languageName = MedicineAnalyzerScreen.getLanguageName(Locale(languageCode));
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Header
                    Row(
                      children: [
                        Text('Scan #${analysisHistory.length - index}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Text(timeago.format(timestamp), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                const SizedBox(height: 2),
                                Text(languageName, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w500)),
                            ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    // Content Preview
                    Text(
                      result,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    ),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up_outlined, size: 22),
                            tooltip: 'Listen to result',
                            onPressed: () => onSpeak(result, Locale(languageCode)),
                            color: theme.colorScheme.secondary
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined, size: 22),
                            tooltip: 'Copy result',
                            onPressed: () => onCopyToClipboard(result),
                            color: theme.colorScheme.secondary
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 22),
                            tooltip: 'Delete item',
                            onPressed: () => _showDeleteConfirmation(context, index),
                            color: theme.colorScheme.error,
                          ),
                          TextButton(
                            onPressed: () => _showHistoryDetailsDialog(context, result, index),
                            child: const Text('View Full'),
                          )
                      ],
                    )
                ],
              ),
            ),
          );
      },
    );
  }

  void _showHistoryDetailsDialog(BuildContext context, String result, int index) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Scan #${analysisHistory.length - index} Details'),
              content: SingleChildScrollView(child: SelectableText(result)),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
      );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete History Item?'),
              content: const Text('This action cannot be undone.'),
              actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  TextButton(
                      onPressed: () {
                          Navigator.of(context).pop();
                          onDelete(index);
                      },
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Delete'),
                  ),
              ],
          ),
      );
  }
}

// ========== HELPER AND MISCELLANEOUS WIDGETS ==========
class _LanguageIndicatorPill extends StatelessWidget {
    final Locale selectedLocale;
    final bool isCompact;

    const _LanguageIndicatorPill({ required this.selectedLocale, this.isCompact = false});

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final color = isCompact ? theme.colorScheme.secondaryContainer : Colors.black54;
      final onColor = isCompact ? theme.colorScheme.onSecondaryContainer : Colors.white;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompact) Icon(Icons.translate, size: 14, color: onColor.withOpacity(0.8)),
            if (!isCompact) const SizedBox(width: 6),
            Text(MedicineAnalyzerScreen.getLanguageName(selectedLocale),
              style: TextStyle(color: onColor, fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ],
        ),
      );
    }
}

class _CaptureButtons extends StatelessWidget {
    final bool canCapture;
    final bool isAnalyzing;
    final VoidCallback onTakePicture;
    final VoidCallback onSelectFromGallery;
    const _CaptureButtons({super.key, required this.canCapture, required this.isAnalyzing, required this.onTakePicture, required this.onSelectFromGallery});
    
    @override
    Widget build(BuildContext context) {
        return Row(
          children: [
            Expanded(child: ElevatedButton.icon(onPressed: canCapture ? onTakePicture : null, icon: const Icon(Icons.camera_alt), label: const Text('Capture'))),
            const SizedBox(width: 16),
            Expanded(child: OutlinedButton.icon(onPressed: isAnalyzing ? null : onSelectFromGallery, icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
          ],
        );
    }
}

Widget _buildOverlayButton({ required IconData icon, required String tooltip, required VoidCallback onPressed }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(icon, color: Colors.white, size: 22)),
          ),
      ),
    );
}

class _AnalysisProgressIndicator extends StatelessWidget {
    const _AnalysisProgressIndicator({super.key});
    
    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const SizedBox(height: 40, width: 40, child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            Text('Analyzing your image...', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('This may take a moment.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      );
    }
}

Widget _buildActionButton(BuildContext context, { required IconData icon, required String label, required VoidCallback onTap, Color? color }) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return Semantics(
      label: label,
      button: true,
      child: Material(
          color: buttonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Icon(icon, size: 20, color: buttonColor),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: buttonColor, fontSize: 13)),
              ]),
            ),
          ),
      ),
    );
}