// Removed unused import 'dart:io'
import 'dart:typed_data';
import 'dart:ui'; // Might not be explicitly needed anymore, but keep for potential future use
import 'package:flutter/services.dart'; // Required for Clipboard and ClipboardData
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timeago/timeago.dart' as timeago; // Import timeago

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
    // Consider showing a startup error message or exiting gracefully
  }

  // Get available cameras
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Error finding cameras: $e");
    // Handle error, maybe inform the user camera functionality won't work
  }

  runApp(MedicineAnalyzerApp(cameras: cameras));
}

class MedicineAnalyzerApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MedicineAnalyzerApp({super.key, required this.cameras});

  @override
  State<MedicineAnalyzerApp> createState() => _MedicineAnalyzerAppState();
}

class _MedicineAnalyzerAppState extends State<MedicineAnalyzerApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default to light mode

  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- Theme Definition ---
    const seedColor = Color(0xFF6750A4); // Primary color
    final baseTextTheme = GoogleFonts.dmSansTextTheme(); // Consistent Font
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), // Softer corners
      // Use dividerColor for subtle borders
      // side: BorderSide(color: Colors.grey.shade200, width: 1),
    );
     final buttonPadding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20);
     final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)); // Consistent button shape

    // --- Light Theme ---
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        secondary: const Color(0xFF625B71),
        tertiary: const Color(0xFF7D5260),
        surface: Colors.white, // Explicit surface
        surfaceVariant: const Color(0xFFE7E0EC), // For containers
        onSurfaceVariant: const Color(0xFF49454F),
        background: const Color(0xFFF7F2FA), // Slightly off-white bg
        // Define other colors if needed (error, inversePrimary, etc.)
      ),
      useMaterial3: true,
      textTheme: baseTextTheme.apply(bodyColor: const Color(0xFF1C1B1F), displayColor: const Color(0xFF1C1B1F)),
      scaffoldBackgroundColor: const Color(0xFFF7F2FA),
      cardTheme: CardTheme(
        elevation: 0.5, // Subtle elevation
        color: Colors.white,
        shape: cardShape,
        surfaceTintColor: Colors.transparent, // Avoid tinting on elevation
        margin: EdgeInsets.zero, // Control margin where card is used
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 1, // Subtle elevation
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
       textButtonTheme: TextButtonThemeData( // Style TextButtons
          style: TextButton.styleFrom(
            foregroundColor: seedColor,
            textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
       ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white, // Or theme.colorScheme.surface
        foregroundColor: const Color(0xFF1C1B1F),
        centerTitle: true,
        elevation: 0, // Flat app bar
        scrolledUnderElevation: 1.0, // Subtle elevation when scrolled
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 20, // Adjust as needed
          color: const Color(0xFF1C1B1F),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: buttonShape.copyWith(borderRadius: BorderRadius.circular(16)), // Slightly different radius for FAB
        elevation: 2,
      ),
      tabBarTheme: TabBarTheme(
          labelColor: seedColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: seedColor,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
           labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
           unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
      ),
       dividerTheme: DividerThemeData( // Consistent dividers
         color: Colors.grey.shade300,
         thickness: 0.8,
         space: 1, // Default space (can be overridden)
       ),
       inputDecorationTheme: InputDecorationTheme( // Optional: Style text fields if added later
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
       ),
       snackBarTheme: SnackBarThemeData( // Consistent Snackbars
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
         backgroundColor: const Color(0xFF323232), // Dark background for contrast
         contentTextStyle: GoogleFonts.dmSans(color: Colors.white),
         actionTextColor: seedColor, // Match primary color for actions
       ),
    );

    // --- Dark Theme ---
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        secondary: const Color(0xFFCCC2DC),
        tertiary: const Color(0xFFEFB8C8),
        surface: const Color(0xFF1C1B1F), // Dark surface
        surfaceVariant: const Color(0xFF2D2C31), // Slightly lighter dark variant
        onSurfaceVariant: const Color(0xFFCAC4D0),
        background: const Color(0xFF141317), // Slightly darker background
        // Ensure contrast for text etc.
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onTertiary: Colors.black,
        onBackground: const Color(0xFFE6E1E5),
        onSurface: const Color(0xFFE6E1E5),
        onError: Colors.black,
      ),
      useMaterial3: true,
      textTheme: baseTextTheme.apply(bodyColor: const Color(0xFFE6E1E5), displayColor: const Color(0xFFE6E1E5)),
      scaffoldBackgroundColor: const Color(0xFF141317),
      cardTheme: CardTheme(
        elevation: 0.5,
        color: const Color(0xFF2D2C31), // Darker card color
        shape: cardShape,
        surfaceTintColor: Colors.transparent,
         margin: EdgeInsets.zero,
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 1,
          backgroundColor: seedColor, // Keep primary for main actions
          foregroundColor: Colors.white, // Or calculate contrast if needed
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
            foregroundColor: seedColor, // Keep primary for text button links
             textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
       ),
       appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2D2C31), // Darker AppBar
        foregroundColor: const Color(0xFFE6E1E5),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        surfaceTintColor: Colors.transparent,
         titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 20, // Adjust as needed
          color: const Color(0xFFE6E1E5),
        ),
      ),
       floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: buttonShape.copyWith(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
       tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
           labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
           unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
      ),
       dividerTheme: DividerThemeData(
         color: Colors.grey.shade700, // Darker divider
         thickness: 0.8,
         space: 1,
       ),
       inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade800,
          hintStyle: TextStyle(color: Colors.grey.shade500)
       ),
        snackBarTheme: SnackBarThemeData(
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
         backgroundColor: const Color(0xFFE0E0E0), // Light background for dark theme snackbar
         contentTextStyle: GoogleFonts.dmSans(color: Colors.black87), // Dark text
         actionTextColor: seedColor,
       ),
    );

    return MaterialApp(
      title: 'MediLang',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode, // Use state variable
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

  @override
  State<MedicineAnalyzerScreen> createState() => _MedicineAnalyzerScreenState();
}

class _MedicineAnalyzerScreenState extends State<MedicineAnalyzerScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  // REMOVED: File? _imageFile; // Primarily use Uint8List for display and analysis
  Uint8List? _webImage; // Use this for image data
  String _analysisResult = "Take or upload a photo to analyze the medicine";
  bool _isAnalyzing = false;
  bool _isCameraInitialized = false;
  bool _cameraAvailable = false;
  Locale _selectedLocale = const Locale('en', '');
  late final TabController _tabController;
  final List<Map<String, dynamic>> _analysisHistory = [];
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false; // Tracks TTS state for the *current* analysis

  // Supported languages list for UI and mapping
  // Ensure keys match supportedLocales
  static const Map<String, String> _supportedLanguages = {
      'en': 'English', 'ta': 'தமிழ்', 'hi': 'हिंदी', 'es': 'Español',
      'fr': 'Français', 'te': 'తెలుగు', 'kn': 'ಕನ್ನಡ', 'ml': 'മലയാളം',
      'mr': 'मराठी', 'gu': 'ગુજરાતી',
  };

  // Helper to get BCP 47 language tag (more specific for TTS)
  String _getBcp47LanguageTag(Locale locale) {
    // Add country codes for better TTS engine compatibility
    switch (locale.languageCode) {
      case 'en': return 'en-US';
      case 'hi': return 'hi-IN';
      case 'es': return 'es-ES'; // Or es-MX, etc.
      case 'fr': return 'fr-FR';
      case 'ta': return 'ta-IN';
      case 'te': return 'te-IN';
      case 'kn': return 'kn-IN';
      case 'ml': return 'ml-IN';
      case 'mr': return 'mr-IN';
      case 'gu': return 'gu-IN';
      default: return 'en-US'; // Fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cameraAvailable = widget.cameras.isNotEmpty;
    if (_cameraAvailable) {
      // Initialize with the first camera (usually back camera)
      _initializeCamera(widget.cameras[0]);
    }
    _initTtsHandlers();
  }

  // Initialize TTS handlers
  Future<void> _initTtsHandlers() async {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      if (mounted) {
        setState(() => _isSpeaking = false);
         _showError("Text-to-speech error: $msg");
      }
    });
    // Set default properties (can be adjusted)
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Adjust for clarity
  }

  // Speak the current analysis result
  Future<void> _speakAnalysisResult() async {
    if (_analysisResult.isEmpty ||
        _isSpeaking ||
        _isAnalyzing || // Don't speak if still analyzing
        _analysisResult == "Take or upload a photo to analyze the medicine" ||
        _analysisResult.contains("Analysis failed") ||
        _analysisResult.contains("Could not analyze")) return;

    final String langTag = _getBcp47LanguageTag(_selectedLocale);
    debugPrint("Attempting TTS with langTag: $langTag");

    // Check language availability
    var isAvailable = await _flutterTts.isLanguageAvailable(langTag);
    // Some engines return Map<String, String>, others bool. Handle both.
    if (isAvailable is bool && !isAvailable) {
        debugPrint("TTS language $langTag not available (boolean check).");
        _showError("Voice data for '${_getLanguageName(_selectedLocale)}' might not be installed. Check your phone's Text-to-Speech settings.");
        return;
    } else if (isAvailable is Map && isAvailable.isEmpty) {
         debugPrint("TTS language $langTag not available (map check).");
        _showError("Voice data for '${_getLanguageName(_selectedLocale)}' might not be installed. Check your phone's Text-to-Speech settings.");
        return;
    }

     debugPrint("TTS language $langTag seems available.");

    setState(() => _isSpeaking = true);

    try {
      await _flutterTts.setLanguage(langTag);
      await _flutterTts.speak(_analysisResult);
    } catch (e) {
      debugPrint("TTS Speak Error: $e");
      _showError("Could not speak the result. $e");
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  // Stop TTS playback
  Future<void> _stopSpeaking() async {
     var result = await _flutterTts.stop();
     // `stop` might trigger completion handler, but set state here for immediate UI feedback
     if (result == 1 && mounted) { // 1 means success
       setState(() => _isSpeaking = false);
     }
  }

  // Initialize or switch camera
  void _initializeCamera(CameraDescription cameraDescription) {
    // Dispose existing controller safely
    if (_controller != null) {
       _controller!.dispose().catchError((e) {
         debugPrint("Error disposing previous controller: $e");
       }); // Dispose asynchronously and catch errors
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high, // Keep high resolution
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg, // Use JPEG
    );

    // Reset initialization flag before starting
    if (mounted) {
      setState(() => _isCameraInitialized = false);
    }

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
      debugPrint("Camera initialized successfully.");
    }).catchError((error) {
      debugPrint("Camera Initialization Error: $error");
      if (mounted) {
        setState(() => _isCameraInitialized = false);
        _showError("Could not initialize camera: ${error is CameraException ? error.description : error}");
      }
       // Prevent further camera operations if init failed
       _cameraAvailable = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController.dispose();
    _flutterTts.stop(); // Ensure TTS stops on dispose
    super.dispose();
  }

  // --- Image Capture/Selection ---

  Future<void> _takePicture() async {
    // Add more checks for robustness
    if (!_isCameraInitialized || _controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      _showError("Camera not ready or is busy. Please wait.");
      return;
    }

    // Ensure the initialization future is complete
    try {
      await _initializeControllerFuture;
    } catch (e) {
        _showError("Camera initialization failed. Cannot take picture.");
        return;
    }

    try {
      // Stop any TTS before taking picture
      await _stopSpeaking();

      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      _processImage(imageBytes); // Pass only bytes

    } on CameraException catch (e) {
        debugPrint("CameraException taking picture: ${e.code} - ${e.description}");
        _showError("Error taking picture: ${e.description}");
        setState(() => _isAnalyzing = false);
    } catch (e) {
      debugPrint("Error taking picture: $e");
      _showError("An unexpected error occurred while taking the picture.");
       setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _selectFromGallery() async {
    // Stop any TTS before picking from gallery
    await _stopSpeaking();

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        _processImage(imageBytes); // Pass only bytes
      } else {
         debugPrint("No image selected from gallery.");
      }
    } catch (e) {
      debugPrint("Error selecting image from gallery: $e");
      _showError("Error selecting image: $e");
       setState(() => _isAnalyzing = false);
    }
  }

  // Process image bytes (from camera or gallery)
  void _processImage(Uint8List imageBytes) {
     // Ensure TTS is stopped
     _stopSpeaking();
     // Update state to show image and analyzing status
     if (mounted) {
        setState(() {
           _webImage = imageBytes; // Store image bytes
           // _imageFile = null; // No longer needed primarily
           _analysisResult = "Analyzing medicine...";
           _isAnalyzing = true;
           _isSpeaking = false; // Reset speaking state for new analysis
        });
        // Start analysis
        _analyzeMedicineImage(imageBytes);
     }
  }

  // --- Analysis Logic ---

  Future<void> _analyzeMedicineImage(Uint8List imageBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API key is missing. Check your .env file.");
      }

      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

      // Refined Prompt
      final prompt = TextPart(
            "You are an AI assistant designed to explain medicine prescriptions or medical reports in the simplest and most understandable way possible, especially for individuals with limited education or literacy.\n\nAnalyze the image of medicine or prescription and provide information in ${tamil}. Focus on:\n\n1. The name of the medicine or test shown in the image\n2. What the medicine is used for, or what the test measures\n3. Important information about usage or purpose\n\nWrite in simple, direct language that anyone can understand. Avoid medical jargon. Format your response as readable text with appropriate line breaks between sections. Do not use JSON formatting.\n\nRemember to emphasize that this is general information only and not a substitute for a doctor's advice"
            "1. The name of the medicine or test shown in the image\n"
            "2. What the medicine is used for, or what the test measures\n"
            "3. Important information about usage or purpose\n\n"
            "Write in simple, direct language that anyone can understand. Avoid medical jargon. Format your response as readable text with appropriate line breaks between sections. Do not use JSON formatting.\n\n"
            "Remember to emphasize that this is general information only and not a substitute for a doctor's advice.");


      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [Content.multi([prompt, imagePart])];

      final response = await model.generateContent(content);
      final resultText = response.text?.trim() ?? "Could not analyze the image. Please try again.";

      // Basic cleanup (remove potential markdown the model might still add)
      String formattedResult = resultText
          .replaceAll('*', '')
          .replaceAll('_', '')
          .replaceAll('**', ''); // Remove bold markdown

      if (mounted) {
        setState(() {
          _analysisResult = formattedResult;
          _isAnalyzing = false;
          // Add to history
          _analysisHistory.insert(0, {
             'result': formattedResult,
             'timestamp': DateTime.now(),
             'language': _selectedLocale.languageCode, // Store the language used
          });
        });
      }
    } on GenerativeAIException catch (e) {
        debugPrint("Gemini API Error: ${e.message}");
        _showError("Analysis failed: ${e.message}");
        if (mounted) {
           setState(() {
              _analysisResult = "Analysis failed. Please check the image or try again.";
              _isAnalyzing = false;
           });
        }
    } catch (e) {
      debugPrint("Error analyzing image: $e");
      _showError("An unexpected error occurred during analysis: $e");
      if (mounted) {
        setState(() {
           _analysisResult = "Analysis failed due to an unexpected error.";
           _isAnalyzing = false;
        });
      }
    }
  }

  // --- UI Helpers ---

  String _getLanguageName(Locale locale) {
    return _supportedLanguages[locale.languageCode] ?? 'Unknown';
  }

  Future<void> _changeLanguage(Locale locale) async {
    if (_selectedLocale == locale) return;

    await _stopSpeaking(); // Stop TTS if playing in the old language

    setState(() {
      _selectedLocale = locale;
      // Optionally add a snackbar confirmation:
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Language set to ${_getLanguageName(locale)}'))
      // );
    });
    debugPrint("UI Language changed to: ${locale.languageCode}");
    // Note: Analysis language changes only on the *next* analysis.
  }

  void _showError(String message) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.dmSans()),
          backgroundColor: Theme.of(context).colorScheme.error,
          // Use theme's snackbar theme for margin/shape
        ),
      );
    }
  }

  void _resetScan() {
    _stopSpeaking(); // Ensure TTS is stopped
    if (mounted) {
      setState(() {
        _webImage = null; // Clear the displayed image
        _analysisResult = "Take or upload a photo to analyze the medicine"; // Reset analysis result
        _isAnalyzing = false; // Reset analyzing state
        _isSpeaking = false; // Reset speaking state
      });

      // Reinitialize the camera if available
      if (_cameraAvailable && _controller != null) {
        _initializeCamera(_controller!.description);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('MediLang'), // Title uses AppBarTheme styling
        actions: [
          IconButton(
            icon: Icon(widget.currentThemeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: widget.currentThemeMode == ThemeMode.dark
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () {
              widget.onChangeTheme(widget.currentThemeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark);
            },
          ),
          const SizedBox(width: 8), // Add spacing
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight), // Standard tab bar height
          child: Container( // Add container for potential background/border styling if needed
            // color: theme.appBarTheme.backgroundColor, // Match AppBar bg
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Scan'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('History'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

 // --- Scanner Tab ---
  Widget _buildScannerTab() {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: SingleChildScrollView( // Ensures content scrolls
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
             // Show language selector only when no image is loaded/analyzing
             // And add some vertical spacing
            if (_webImage == null && !_isAnalyzing)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: _buildLanguageSelector(),
               ),

            // Camera/Image Preview Area
            LayoutBuilder(
              builder: (context, constraints) {
                // Dynamic height adjustment based on content
                double previewHeight = _webImage != null
                    ? MediaQuery.of(context).size.height * 0.45 // Larger when image shown
                    : MediaQuery.of(context).size.height * 0.38; // Standard height
                previewHeight = previewHeight.clamp(280.0, 550.0); // Min/Max heights

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  height: previewHeight,
                  width: constraints.maxWidth,
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 16),
                  decoration: BoxDecoration(
                    // Use surfaceVariant for background, more subtle
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                      width: 1
                    ),
                    // Minimal shadow for depth
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.04),
                    //     blurRadius: 8, offset: const Offset(0, 2),
                    //   ),
                    // ],
                  ),
                  child: ClipRRect( // Clip the child (Image or CameraPreview)
                    borderRadius: BorderRadius.circular(24),
                    child: _buildPreviewContent(theme, screenWidth), // Extracted preview logic
                  ),
                );
              },
            ),

            // Action Buttons or Analysis Display
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: AnimatedSwitcher( // Animate transition between buttons and result
                 duration: const Duration(milliseconds: 300),
                 child: _webImage == null
                   ? _buildCaptureButtons(screenWidth) // Show capture/gallery buttons
                   : _buildAnalysisDisplay(theme, screenWidth), // Show analysis
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Language Selector Widget ---
  Widget _buildLanguageSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive grid columns
    final crossAxisCount = (screenWidth / 125).floor().clamp(2, 5);
    final theme = Theme.of(context);

    return Container(
      // Use Card styling implicitly via theme or explicitly
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        // Match card theme color or use surface
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
         // Subtle shadow
         boxShadow: [
           BoxShadow(
             color: theme.shadowColor.withOpacity(0.05),
             blurRadius: 10, offset: const Offset(0, 2),
           ),
         ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_outlined, size: 20, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'Select Analysis Language',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Bold title
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: crossAxisCount,
               crossAxisSpacing: 10,
               mainAxisSpacing: 10,
               childAspectRatio: 3.0, // Adjust for button height/width ratio
             ),
             itemCount: _supportedLanguages.length,
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             itemBuilder: (context, index) {
                final localeCode = _supportedLanguages.keys.elementAt(index);
                final label = _supportedLanguages.values.elementAt(index);
                return _buildLanguageOption(Locale(localeCode), label);
             },
          ),
        ],
      ),
    );
  }

  // --- Individual Language Option Button ---
  Widget _buildLanguageOption(Locale locale, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedLocale.languageCode == locale.languageCode;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell( // Provides ripple effect on tap
      onTap: () => _changeLanguage(locale),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          // Use primary container color if selected, else a subtle background
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3), // Use outline color
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  // --- Camera/Image Preview Content ---
  Widget _buildPreviewContent(ThemeData theme, double screenWidth) {
    // --- Display Image ---
    if (_webImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_webImage!, fit: BoxFit.cover),
          // Optional Gradient overlay for contrast with buttons
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.black.withOpacity(0.4)],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // --- Reset Button (FIX IMPLEMENTATION) ---
          Positioned(
            top: 12,
            right: 12,
            child: _buildOverlayButton(
              icon: Icons.refresh,
              tooltip: 'Scan New Image',
              onPressed: _resetScan, // *** Connect reset function here ***
              backgroundColor: Colors.black.withOpacity(0.5), // Darker background
              iconColor: Colors.white,
            ),
          ),
          // Language Indicator
          Positioned(
            top: 12,
            left: 12,
            child: _buildLanguageIndicatorPill(theme, screenWidth, backgroundOpacity: 0.5),
          ),
        ],
      );
    }
    // --- Display Camera Preview ---
    else if (_cameraAvailable) {
      return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          // Check controller validity rigorously
          final isReady = _controller != null &&
                           _controller!.value.isInitialized &&
                           snapshot.connectionState == ConnectionState.done &&
                           !snapshot.hasError;

          if (isReady) {
            try {
              return ClipRRect( // Ensure preview is clipped within bounds
                 borderRadius: BorderRadius.circular(24), // Match container radius
                 child: AspectRatio(
                   // Use preview aspect ratio, handle potential division by zero
                   aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16.0 / 9.0,
                   child: Stack(
                     fit: StackFit.expand,
                     children: [
                       CameraPreview(_controller!),
                       // Focusing Frame Guide
                       Center(
                         child: Container(
                           width: screenWidth * 0.7, // Larger frame
                           height: screenWidth * 0.5, // Adjust aspect ratio
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                             borderRadius: BorderRadius.circular(16),
                             // Optional: Add subtle background inside frame
                             // color: Colors.black.withOpacity(0.1),
                           ),
                         ),
                       ),
                       // Instruction Text
                       Positioned(
                         bottom: 16, left: 16, right: 16, // Add horizontal padding
                         child: Center(
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: Colors.black.withOpacity(0.5), // More contrast
                               borderRadius: BorderRadius.circular(10),
                             ),
                             child: Text(
                               'Position medicine inside the frame',
                               style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                               textAlign: TextAlign.center,
                             ),
                           ),
                         ),
                       ),
                       // Language Indicator (for camera view)
                       Positioned(
                         top: 12, left: 12,
                         child: _buildLanguageIndicatorPill(theme, screenWidth, backgroundOpacity: 0.5),
                       ),
                     ],
                   ),
                 ),
              );
            } catch (e) {
              debugPrint("Error building CameraPreview Widget: $e");
              return Center(child: Text("Error displaying camera.", style: TextStyle(color: theme.colorScheme.error)));
            }
          } else if (snapshot.connectionState == ConnectionState.waiting || _initializeControllerFuture != null && !snapshot.hasError) {
             // Show loading indicator while initializing
             return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          } else {
             // Show error if initialization failed or camera not available
             String errorMessage = "Camera not available.";
             if (snapshot.hasError) {
                 errorMessage = "Camera error: Check permissions.";
                 debugPrint("Camera FutureBuilder Error: ${snapshot.error}");
             } else if (!_cameraAvailable) {
                 errorMessage = "No camera detected on this device.";
             }
             return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
                    SizedBox(height: 16),
                    Text(errorMessage, style: TextStyle(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                  ],
                )
             );
          }
        },
      );
    }
    // --- Camera Not Available Message ---
    else {
      return Container(
        // color: theme.colorScheme.surfaceVariant.withOpacity(0.3), // Already set on parent
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: 60,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "Camera not available",
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }


 // --- Helper for Overlay Buttons (Reset) ---
  Widget _buildOverlayButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.black45,
    Color iconColor = Colors.white,
  }) {
     return Material( // Provides ink splash on tap
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
           onTap: onPressed,
           borderRadius: BorderRadius.circular(12),
           child: Padding(
              padding: const EdgeInsets.all(8.0), // Adjust padding
              child: Icon(icon, color: iconColor, size: 22),
           ),
        ),
     );
     // Tooltip can be wrapped around Material if needed:
     // return Tooltip(message: tooltip, child: Material(...));
  }

 // --- Helper for Language Indicator Pill ---
  Widget _buildLanguageIndicatorPill(ThemeData theme, double screenWidth, {double backgroundOpacity = 0.4}) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
           color: Colors.black.withOpacity(backgroundOpacity),
           borderRadius: BorderRadius.circular(16), // Pill shape
        ),
        child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
              Icon(Icons.translate, size: 14, color: Colors.white.withOpacity(0.8)),
              SizedBox(width: 6),
              Text(
                 _getLanguageName(_selectedLocale),
                 style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                 ),
              ),
           ],
        ),
     );
  }

  // --- Capture/Gallery Buttons Row ---
  Widget _buildCaptureButtons(double screenWidth) {
    bool canCapture = _cameraAvailable && _isCameraInitialized && !_isAnalyzing;
    return Padding(
       key: const ValueKey('capture_buttons'), // Key for AnimatedSwitcher
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canCapture ? _takePicture : null,
              icon: const Icon(Icons.camera_alt_outlined), // Use outlined icon
              label: Text('Capture'),
              style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16), // Larger tap target
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03), // Consistent spacing
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isAnalyzing ? null : _selectFromGallery,
              icon: const Icon(Icons.photo_library_outlined), // Use outlined icon
              label: Text('Gallery'),
               style: OutlinedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16), // Larger tap target
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Analysis Result Display Card ---
 Widget _buildAnalysisDisplay(ThemeData theme, double screenWidth) {
   // Use a ValueKey for AnimatedSwitcher to recognize this widget
   return Container(
      key: const ValueKey('analysis_display'),
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical margin
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20), // Match card theme shape
        boxShadow: [ // Subtle shadow
           BoxShadow(
             color: theme.shadowColor.withOpacity(0.05),
             blurRadius: 10, offset: const Offset(0, 3),
           ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container( // Icon background
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.science_outlined, // More general science/analysis icon
                          color: theme.colorScheme.primary, size: 22),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Analysis Result',
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Language indicator for this specific result
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(
                    _getLanguageName(_selectedLocale),
                    style: GoogleFonts.dmSans(
                       fontSize: 11,
                       fontWeight: FontWeight.w500,
                       color: theme.colorScheme.onSecondaryContainer,
                    ),
                 ),
              ),
            ],
          ),
          Divider(height: 24, color: theme.dividerTheme.color),

          // Content Area (Progress or Result)
          AnimatedSwitcher(
             duration: const Duration(milliseconds: 200),
             child: _isAnalyzing
                ? _buildAnalysisProgressIndicator(theme, screenWidth)
                : _buildAnalysisResultContent(theme, screenWidth),
          )
        ],
      ),
    );
  }

  // --- Progress Indicator ---
  Widget _buildAnalysisProgressIndicator(ThemeData theme, double screenWidth) {
    return Center(
      key: const ValueKey('progress'), // Key for AnimatedSwitcher
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            SizedBox(
              height: 40, width: 40, // Slightly larger indicator
              child: CircularProgressIndicator(strokeWidth: 3.5, color: theme.colorScheme.primary),
            ),
            SizedBox(height: 20),
            Text(
              'Analyzing your image...',
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Result Content (Text and Actions) ---
  Widget _buildAnalysisResultContent(ThemeData theme, double screenWidth) {
    bool hasValidResult = _analysisResult.isNotEmpty &&
                          !_analysisResult.contains("Analyzing medicine...") &&
                          !_analysisResult.contains("Analysis failed") &&
                          !_analysisResult.contains("Could not analyze");

    return Column(
      key: const ValueKey('result'), // Key for AnimatedSwitcher
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result Text
        SelectableText(
          _analysisResult,
          style: GoogleFonts.dmSans(fontSize: 15, height: 1.6, color: theme.colorScheme.onSurface), // Increased line height
          textAlign: TextAlign.start,
        ),
        SizedBox(height: 20), // Increased spacing before buttons

        // Action Buttons Row
        if(hasValidResult) // Only show buttons if there's a valid result
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: _isSpeaking ? Icons.stop_rounded : Icons.volume_up_outlined,
                label: _isSpeaking ? 'Stop' : 'Listen',
                onTap: _isSpeaking ? _stopSpeaking : _speakAnalysisResult,
                color: _isSpeaking ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.copy_outlined,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _analysisResult));
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Result copied!', style: GoogleFonts.dmSans())),
                   );
                },
              ),
              SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () async {
                    final box = context.findRenderObject() as RenderBox?;
                    await Share.share(
                      _analysisResult,
                      subject: 'MediLang Analysis Result',
                      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                    );
                 },
              ),
            ],
          ),
      ],
    );
  }

  // --- Reusable Action Button for Result Card ---
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary; // Default to primary

    return Material( // Provides splash effect
      color: buttonColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: buttonColor),
              SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600, // Bolder button text
                  color: buttonColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // --- History Tab ---
  Widget _buildHistoryTab() {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (_analysisHistory.isEmpty) {
      // --- Empty History State ---
      return Center(
        child: Padding(
           padding: const EdgeInsets.all(32.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container( // Circular background for icon
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.history_edu_outlined, size: 60, color: theme.colorScheme.onSecondaryContainer),
               ),
               SizedBox(height: 24),
               Text(
                  'No Scan History Yet',
                  style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.bold)
               ),
               SizedBox(height: 12),
               Text(
                 'Your analyzed medicine details will appear here after you scan them.',
                 style: GoogleFonts.dmSans(fontSize: 15, color: theme.colorScheme.onBackground.withOpacity(0.7)),
                 textAlign: TextAlign.center,
               ),
               SizedBox(height: 32),
               ElevatedButton.icon(
                 onPressed: () => _tabController.animateTo(0), // Go to Scanner tab
                 icon: const Icon(Icons.camera_alt_outlined, size: 18),
                 label: Text('Scan Your First Medicine'),
                 style: ElevatedButton.styleFrom(
                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                 ),
               ),
             ],
           ),
        ),
      );
    }

    // --- History List ---
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 16), // Add vertical padding
      itemCount: _analysisHistory.length,
      itemBuilder: (context, index) {
        final historyItem = _analysisHistory[index];
        final String result = historyItem['result'] as String? ?? 'No result';
        final DateTime timestamp = historyItem['timestamp'] as DateTime? ?? DateTime.now();
        // Use stored language, default to 'en' if missing
        final String languageCode = historyItem['language'] as String? ?? 'en';
        final String languageName = _getLanguageName(Locale(languageCode));

        final String relativeTime = timeago.format(timestamp); // 'timeago' formatting

        return Card( // Use Card for each history item
          margin: EdgeInsets.only(bottom: 16), // Space between cards
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Consistent shape
          elevation: 1, // Subtle elevation
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // History Item Header
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: theme.colorScheme.secondary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Scan #${_analysisHistory.length - index}', // Numbering
                       style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)
                     ),
                    const Spacer(),
                     // Relative time and language
                     Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           Text(
                              relativeTime,
                              style: GoogleFonts.dmSans(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                           ),
                           SizedBox(height: 2),
                           Text(
                             languageName, // Show language of the result
                             style: GoogleFonts.dmSans(color: theme.colorScheme.tertiary, fontSize: 11, fontWeight: FontWeight.w500),
                           ),
                        ],
                     ),
                  ],
                ),
                Divider(height: 20, color: theme.dividerTheme.color),

                // Result Preview (Truncated)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    // Truncate long results for preview
                    result.length > 120 ? '${result.substring(0, 120).trim()}...' : result,
                    style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.9)),
                    maxLines: 3, // Limit lines in preview
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Action Buttons for History Item
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                     // Listen Button (History) - Use dedicated BCP47 tag
                    _buildHistoryActionButton(
                      icon: Icons.volume_up_outlined,
                      tooltip: 'Listen to result',
                      onPressed: () async {
                         final historyLangTag = _getBcp47LanguageTag(Locale(languageCode));
                         var isLangAvailable = await _flutterTts.isLanguageAvailable(historyLangTag);
                         // Simplified check
                          if ((isLangAvailable is bool && !isLangAvailable) || (isLangAvailable is Map && isLangAvailable.isEmpty)) {
                            _showError("Voice data for '$languageName' might not be installed.");
                            return;
                          }

                         try {
                            await _flutterTts.stop();
                            await _flutterTts.setLanguage(historyLangTag);
                            await _flutterTts.speak(result);
                         } catch (e) {
                            debugPrint("History TTS Error: $e");
                            _showError("Could not play audio for this item.");
                         }
                      },
                    ),
                    _buildHistoryActionButton(
                      icon: Icons.copy_outlined,
                      tooltip: 'Copy result',
                      onPressed: () {
                         Clipboard.setData(ClipboardData(text: result));
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('History item copied', style: GoogleFonts.dmSans())),
                         );
                      },
                    ),
                     _buildHistoryActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete item',
                      color: theme.colorScheme.error, // Use error color
                      onPressed: () => _showDeleteConfirmationDialog(index), // Show confirmation
                    ),
                    // View Details Button (TextButton for less emphasis)
                    TextButton(
                      onPressed: () => _showHistoryDetailsDialog(result, index),
                      child: Text(
                         'View Details',
                         style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600, // Slightly bolder
                            fontSize: 13,
                         ),
                      ),
                      style: TextButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         minimumSize: Size.zero,
                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Show Full History Result Dialog ---
  void _showHistoryDetailsDialog(String result, int index) {
     final theme = Theme.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
           title: Text(
              'Scan Details (#${_analysisHistory.length - index})',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 18)
           ),
           content: SingleChildScrollView(
              child: SelectableText(result, style: GoogleFonts.dmSans(fontSize: 15, height: 1.5))
           ),
           actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           actions: [
              TextButton(
                 onPressed: () => Navigator.of(context).pop(),
                 child: Text('Close'), // Uses TextButtonTheme
              ),
           ],
        ),
      );
  }

   // --- Show Delete Confirmation Dialog ---
   void _showDeleteConfirmationDialog(int index) {
      final theme = Theme.of(context);
      showDialog(
         context: context,
         builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Delete History Item?', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            content: Text('Are you sure you want to delete this scan result? This action cannot be undone.', style: GoogleFonts.dmSans()),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
               TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7)), // Less prominent cancel
               ),
               TextButton(
                  onPressed: () {
                     Navigator.of(context).pop(); // Close dialog first
                     if (mounted) {
                       setState(() {
                          _analysisHistory.removeAt(index);
                       });
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('History item deleted', style: GoogleFonts.dmSans())),
                       );
                     }
                  },
                  child: Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error), // Error color for delete action
               ),
            ],
         ),
      );
   }

   // --- Reusable IconButton for History Card Actions (more compact) ---
   Widget _buildHistoryActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
   }) {
      final theme = Theme.of(context);
      // Use secondary color as default for history actions, unless specified
      final actionColor = color ?? theme.colorScheme.secondary;
      return IconButton(
         icon: Icon(icon, size: 20), // Slightly larger icon
         color: actionColor,
         tooltip: tooltip,
         onPressed: onPressed,
         constraints: const BoxConstraints(), // Keep compact
         padding: const EdgeInsets.all(8), // Consistent padding
         splashRadius: 22, // Standard splash radius
      );
   }
}