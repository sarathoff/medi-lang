import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      title: 'Medicine Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
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

class _MedicineAnalyzerScreenState extends State<MedicineAnalyzerScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  File? _imageFile;
  Uint8List? _webImage;
  String _analysisResult = "Take or upload a photo to analyze the medicine";
  bool _isAnalyzing = false;
  bool _isCameraInitialized = false;
  Locale _selectedLocale = const Locale('en', '');

  @override
  void initState() {
    super.initState();
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
      final content = [
        Content.multi([
          TextPart("Identify this medicine and describe its use case and short description in ${_selectedLocale.languageCode}."),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      setState(() {
        _analysisResult = response.text ?? "Could not analyze the medicine.";
        _isAnalyzing = false;
      });
    } catch (e) {
      _showError("Error analyzing image: $e");
    }
  }

  void _showError(String message) {
    setState(() {
      _analysisResult = message;
      _isAnalyzing = false;
    });
  }

  void _changeLanguage(Locale locale) {
    setState(() => _selectedLocale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Analyzer'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<Locale>(
              value: _selectedLocale,
              icon: const Icon(Icons.language),
              underline: const SizedBox(),
              onChanged: (Locale? newValue) {
                if (newValue != null) _changeLanguage(newValue);
              },
              items: const [
                DropdownMenuItem(value: Locale('en', ''), child: Text('EN')),
                DropdownMenuItem(value: Locale('hi', ''), child: Text('HI')),
                DropdownMenuItem(value: Locale('es', ''), child: Text('ES')),
                DropdownMenuItem(value: Locale('fr', ''), child: Text('FR')),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageFile != null
                      ? Image.memory(_webImage!, fit: BoxFit.cover)
                      : _isCameraInitialized
                          ? CameraPreview(_controller)
                          : const Center(child: Text("Camera not available")),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _selectFromGallery,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload'),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isAnalyzing
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _analysisResult,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}