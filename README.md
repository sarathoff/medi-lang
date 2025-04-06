# MediLang

MediLang is a Flutter-based application designed to analyze medicine prescriptions or medical reports and provide simplified explanations in multiple languages. It uses Gemini LLm to give AI-powered analysis and text-to-speech (TTS) capabilities to make medical information more accessible to users with limited literacy or technical knowledge.

## Features

- **AI-Powered Analysis**: Analyze images of prescriptions or medicines using Google Generative AI
- **Multi-Language Support**: Provides explanations in multiple languages, including English, Hindi, Tamil, and more
- **Text-to-Speech**: Converts analysis results into audio for better accessibility
- **Camera and Gallery Integration**: Capture images using the camera or select from the gallery
- **Dark and Light Themes**: Supports theme switching for better user experience
- **History Management**: View and manage past analysis results

## Installation

### Prerequisites

- Flutter SDK installed ([Flutter Installation Guide](https://flutter.dev/docs/get-started/install))
- Android Studio or Visual Studio Code for development
- A valid Google Cloud API key for Text-to-Speech and Generative AI

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/medi-lang.git
   cd medi-lang
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables:
   - Create a `.env` file in the root directory
   - Add the following keys:
     ```
     GEMINI_API_KEY=your_generative_ai_key
     GOOGLE_CLOUD_TTS_API_KEY=your_google_cloud_tts_key
     ```

4. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. Launch the app on your device or emulator
2. Use the **Scan** tab to capture or upload an image of a prescription or medicine
3. View the analysis results in text or listen to them using the **Listen** button
4. Switch languages using the language selector
5. Access past results in the **History** tab

## Project Structure

```
medi-lang/
├── android/                # Android-specific files
├── ios/                    # iOS-specific files
├── lib/                    # Main Flutter application code
│   ├── main.dart           # Entry point of the app
│   ├── widgets/            # Custom widgets
│   ├── screens/            # App screens (e.g., Scanner, History)
│   └── utils/              # Utility functions and helpers
├── assets/                 # Images, fonts, and other assets
├── .env                    # Environment variables (not included in the repo)
├── pubspec.yaml            # Flutter dependencies
└── README.md               # Project documentation
```

## Dependencies

- **Flutter SDK**: Framework for building the app
- **google_generative_ai**: For AI-powered analysis
- **flutter_tts**: For text-to-speech functionality
- **audioplayers**: For playing audio files
- **camera**: For camera integration
- **image_picker**: For selecting images from the gallery
- **share_plus**: For sharing analysis results
- **google_fonts**: For custom fonts
- **timeago**: For relative time formatting

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a new branch:
   ```bash
   git checkout -b feature-name
   ```
3. Make your changes and commit them:
   ```bash
   git commit -m "Add feature-name"
   ```
4. Push to your fork:
   ```bash
   git push origin feature-name
   ```
5. Open a pull request

## License

MIT License

Copyright (c) 2025 Sarath Ramesh

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Acknowledgments

- Google's Gemini API for AI-powered analysis
- Flutter for providing a robust framework for cross-platform development

## Additional Notes

- Ensure that sensitive information like API keys is not committed to the repository. Use `.gitignore` to exclude the `.env` file
- Test the app thoroughly on both Android and iOS devices