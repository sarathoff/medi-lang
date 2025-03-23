import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final cameras = await availableCameras();
  runApp(MedicineAnalyzerApp(cameras: cameras));
}

class MedicineAnalyzerApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const MedicineAnalyzerApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
          secondary: const Color(0xFF625B71),
          tertiary: const Color(0xFF7D5260),
          surface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.dmSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7F2FA),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            backgroundColor: const Color(0xFF6750A4),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFF6750A4), width: 1.5),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1C1B1F),
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), 
          brightness: Brightness.dark,
          secondary: const Color(0xFFCCC2DC),
          tertiary: const Color(0xFFEFB8C8),
          surface: const Color(0xFF1C1B1F),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        scaffoldBackgroundColor: const Color(0xFF1C1B1F),
        cardTheme: CardTheme(
          elevation: 0,
          color: const Color(0xFF2D2C31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), Locale('hi', ''), Locale('es', ''), Locale('fr', ''),
      ],
      home: MedicineAnalyzerScreen(cameras: cameras),
    );
  }
}

class MedicineAnalyzerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const MedicineAnalyzerScreen({super.key, required this.cameras});

  @override
  State<MedicineAnalyzerScreen> createState() => _MedicineAnalyzerScreenState();
}

class _MedicineAnalyzerScreenState extends State<MedicineAnalyzerScreen> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  File? _imageFile;
  Uint8List? _webImage;
  String _analysisResult = "Take or upload a photo to analyze the medicine";
  bool _isAnalyzing = false;
  bool _isCameraInitialized = false;
  Locale _selectedLocale = const Locale('en', '');
  late TabController _tabController;
  final List<String> _analysisHistory = [];
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.cameras.isNotEmpty) {
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    }).catchError((error) {
      setState(() => _isCameraInitialized = false);
    });
  }

  @override
  void dispose() {
    if (widget.cameras.isNotEmpty) {
      _controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized) return;
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final imageBytes = await image.readAsBytes();
      _processImage(imageBytes, image.path);
    } catch (e) {
      _showError("Error taking picture: $e");
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        _processImage(imageBytes, image.path);
      }
    } catch (e) {
      _showError("Error selecting image: $e");
    }
  }

  void _processImage(Uint8List imageBytes, String path) {
    setState(() {
      _imageFile = File(path);
      _webImage = imageBytes;
      _analysisResult = "Analyzing medicine...";
      _isAnalyzing = true;
    });
    _analyzeMedicineImage(imageBytes);
  }

 Future<void> _analyzeMedicineImage(Uint8List imageBytes) async {
  try {
    String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _showError("API key is missing. Please check your .env file.");
      return;
    }

    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    
    // Updated prompt to request natural language output instead of JSON
    final content = [
      Content.multi([
        TextPart("You are an AI assistant designed to explain medicine prescriptions or medical reports in the simplest and most understandable way possible, especially for individuals with limited education or literacy.\n\nAnalyze the image of medicine or prescription and provide information in ${_getLanguageName(_selectedLocale)}. Focus on:\n\n1. The name of the medicine or test shown in the image\n2. What the medicine is used for, or what the test measures\n3. Important information about usage or purpose\n\nWrite in simple, direct language that anyone can understand. Avoid medical jargon. Format your response as readable text with appropriate line breaks between sections. Do not use JSON formatting.\n\nRemember to emphasize that this is general information only and not a substitute for a doctor's advice."),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await model.generateContent(content);
    final result = response.text ?? "Could not analyze the medicine.";
    
    // Process result: If it still returns JSON despite instructions, try to parse and format it nicely
    String formattedResult = result.replaceAll('*', ''); // Remove unwanted asterisks
    if (result.trim().startsWith('{') && result.trim().endsWith('}')) {
      try {
      // Parse the JSON and format it in a readable way
      final Map<String, dynamic> jsonResult = json.decode(result);
      if (jsonResult.containsKey('summary') && jsonResult['summary'] is List) {
        final List<dynamic> summary = jsonResult['summary'];
        formattedResult = '';
        
        for (var item in summary) {
        if (item.containsKey('item_name') && item.containsKey('simple_explanation')) {
          formattedResult += '${item['item_name']}:\n${item['simple_explanation']}\n\n';
        }
        }
      }
      } catch (e) {
      // If JSON parsing fails, keep the original result
      formattedResult = result.replaceAll('*', ''); // Remove unwanted asterisks
      }
    }
    
    setState(() {
      _analysisResult = formattedResult;
      _analysisHistory.insert(0, formattedResult);
      _isAnalyzing = false;
    });
  } catch (e) {
    _showError("Error analyzing image: $e");
  }
}

// Helper function to get language name from locale
String _getLanguageName(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return 'English';
    case 'hi': return 'Hindi';
    case 'es': return 'Spanish';
    case 'fr': return 'French';
    case 'ta': return 'Tamil';
    case 'te': return 'Telugu';
    case 'kn': return 'Kannada';
    case 'ml': return 'Malayalam';
    case 'mr': return 'Marathi';
    case 'gu': return 'Gujarati';
    default: return 'English';
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      // In a real app, you would use a state management solution to persist this
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MediScan',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Scan',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'History',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ],
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
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
      floatingActionButton: _tabController.index == 0 && _imageFile == null
          ? FloatingActionButton.extended(
              onPressed: _isAnalyzing ? null : _takePicture,
              label: Text(
                'Capture',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w300),
              ),
              icon: const Icon(Icons.camera_alt),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLanguageSelector() {
  final theme = Theme.of(context);
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.language,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Select Analysis Language',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildLanguageOption(const Locale('en', ''), 'English'),
            _buildLanguageOption(const Locale('ta', ''), 'தமிழ்'),
            _buildLanguageOption(const Locale('hi', ''), 'हिंदी'),
            _buildLanguageOption(const Locale('es', ''), 'Español'),
            _buildLanguageOption(const Locale('fr', ''), 'Français'),
            _buildLanguageOption(const Locale('te', ''), 'తెలుగు'),
            _buildLanguageOption(const Locale('kn', ''), 'ಕನ್ನಡ'),
            _buildLanguageOption(const Locale('ml', ''), 'മലയാളം'),
            _buildLanguageOption(const Locale('mr', ''), 'मराठी'),
            _buildLanguageOption(const Locale('gu', ''), 'ગુજરાતી'),

          ],
        ),
      ],
    ),
  );
}

  Widget _buildLanguageOption(Locale locale, String label) {
  final theme = Theme.of(context);
  final isSelected = _selectedLocale.languageCode == locale.languageCode;
  
  return InkWell(
    onTap: () => _changeLanguage(locale),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
    ),
  );
}

void _changeLanguage(Locale locale) {
  setState(() {
    _selectedLocale = locale;
  });
}

 Widget _buildScannerTab() {
  final theme = Theme.of(context);
  
  return SafeArea(
    child: SingleChildScrollView(
      child: Column(
        children: [
          // Language selector - moved above camera component
          if (_imageFile == null)
            _buildLanguageSelector(),
            
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _imageFile != null ? 400 : 300,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _imageFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_webImage!, fit: BoxFit.cover),
                        // Soft gradient overlay for better visibility
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                              stops: const [0.7, 1.0],
                            ),
                          ),
                        ),
                        // Reset button
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                  _webImage = null;
                                });
                              },
                            ),
                          ),
                        ),
                        // Language indicator on image
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.language, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  _getLanguageName(_selectedLocale),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _isCameraInitialized
                      ? Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: CameraPreview(_controller),
                            ),
                            // Camera overlay
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text(
                                  'Position medicine within the frame',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Language indicator on camera preview
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.language, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getLanguageName(_selectedLocale),
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: theme.colorScheme.surface,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 60,
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Camera not available",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
          
          // Upload from gallery button
          if (_imageFile == null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _selectFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  'Upload from Gallery',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),
            
          // Analysis result
          if (_imageFile != null || _isAnalyzing)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medication,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analysis Results',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getLanguageName(_selectedLocale),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _isAnalyzing
                        ? Center(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 48,
                                  width: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Analyzing your medicine...',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This might take a moment',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _analysisResult,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.content_copy,
                                    label: 'Copy',
                                    onTap: () {
                                      // Copy functionality
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Result copied to clipboard',
                                            style: GoogleFonts.dmSans(),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildActionButton(
                                    icon: Icons.share,
                                    label: 'Share',
                                    onTap: () {
                                      // Share functionality
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final theme = Theme.of(context);
    
    if (_analysisHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Scan History',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your medicine scan results will appear here',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.camera_alt),
              label: Text(
                'Take Your First Scan',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _analysisHistory.length,
      itemBuilder: (context, index) {
        final result = _analysisHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Scan #${_analysisHistory.length - index}',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${DateTime.now().difference(DateTime.now().subtract(Duration(minutes: index * 5))).inMinutes}m ago',
                      style: GoogleFonts.dmSans(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Divider(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    result.length > 200 ? '${result.substring(0, 200)}...' : result,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.content_copy,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        // Copy functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Result copied to clipboard',
                              style: GoogleFonts.dmSans(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () {
                        setState(() {
                          _analysisHistory.removeAt(index);
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        // Implement view full details
                      },
                      child: Text(
                        'View Full Details',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
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
}