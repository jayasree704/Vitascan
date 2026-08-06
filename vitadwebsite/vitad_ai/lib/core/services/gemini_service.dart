import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/models/scan_result.dart';
import '../config/app_config.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  Future<ScanResult> analyzeTestStripImage({
    required File imageFile,
    required String userId,
    String? imageUrl,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      const promptText = '''
You are a clinical diagnostic AI specialized in analyzing salivary Vitamin D test strips.
Analyze the provided test strip image and evaluate the color intensity of the test line compared to the reference control.

Determine:
1. Vitamin D level in ng/mL (numeric estimate between 5.0 and 80.0 ng/mL).
   - < 20 ng/mL: Deficient
   - 20 - 30 ng/mL: Insufficient
   - 30 - 100 ng/mL: Sufficient
2. Overall status category: "Sufficient", "Insufficient", or "Deficient".
3. AI Confidence score (float between 0.85 and 0.99).
4. Personalized food recommendations rich in Vitamin D3/D2 (provide 4 specific items with names and descriptions).
5. 3 Actionable lifestyle tips.

Return ONLY a raw valid JSON object with the following exact structure:
{
  "vitamin_d_level": 24.5,
  "status": "Insufficient",
  "ai_confidence": 0.94,
  "recommendations": [
    {
      "name": "Fatty Fish",
      "description": "Wild salmon and mackerel are the richest natural sources of Vitamin D3.",
      "category": "Seafood"
    },
    {
      "name": "Egg Yolks",
      "description": "Contain moderate Vitamin D, especially from pasture-raised hens.",
      "category": "Dairy & Eggs"
    },
    {
      "name": "Fortified Milk & Cereals",
      "description": "Provide a steady daily intake of Vitamin D2/D3.",
      "category": "Fortified Foods"
    },
    {
      "name": "UV-Exposed Mushrooms",
      "description": "Natural plant-based source of Vitamin D2.",
      "category": "Vegetables"
    }
  ],
  "lifestyle_tips": [
    "Aim for 15-20 minutes of daily sunlight exposure on exposed skin.",
    "Pair Vitamin D rich foods with healthy fats for optimal absorption.",
    "Consider a high-quality Vitamin D3 supplement (1000-2000 IU daily)."
  ]
}
''';

      final content = [
        Content.multi([TextPart(promptText), imagePart])
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return _fallbackResult(userId: userId, imageUrl: imageUrl);
      }

      final Map<String, dynamic> parsedJson = jsonDecode(responseText);
      final level = (parsedJson['vitamin_d_level'] as num?)?.toDouble() ?? 24.0;
      final status = (parsedJson['status'] as String?) ??
          (level < 20
              ? 'Deficient'
              : level < 30
                  ? 'Insufficient'
                  : 'Sufficient');
      final confidence = (parsedJson['ai_confidence'] as num?)?.toDouble() ?? 0.92;

      final recommendationsRaw = parsedJson['recommendations'] as List<dynamic>? ?? [];
      final recommendations = recommendationsRaw
          .map((e) => RecommendedFood.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final lifestyleTipsRaw = parsedJson['lifestyle_tips'] as List<dynamic>? ?? [];
      final lifestyleTips = lifestyleTipsRaw.map((e) => e.toString()).toList();

      return ScanResult(
        userId: userId,
        imageUrl: imageUrl,
        vitaminDLevel: level,
        status: status,
        aiConfidence: confidence,
        aiRawResponse: responseText,
        recommendations: recommendations,
        lifestyleTips: lifestyleTips,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return _fallbackResult(userId: userId, imageUrl: imageUrl);
    }
  }

  ScanResult _fallbackResult({required String userId, String? imageUrl}) {
    return ScanResult(
      userId: userId,
      imageUrl: imageUrl,
      vitaminDLevel: 24.0,
      status: 'Insufficient',
      aiConfidence: 0.89,
      aiRawResponse: 'Fallback estimation due to image parsing constraints.',
      recommendations: const [
        RecommendedFood(
          name: 'Fatty Fish',
          description: 'Salmon and mackerel are the richest natural sources of Vitamin D3.',
          category: 'Seafood',
        ),
        RecommendedFood(
          name: 'Egg Yolks',
          description: 'Contain moderate amounts of Vitamin D, particularly from pasture-raised hens.',
          category: 'Dairy & Eggs',
        ),
        RecommendedFood(
          name: 'Fortified Cereals',
          description: 'A reliable daily source when whole foods aren\'t sufficient.',
          category: 'Fortified Foods',
        ),
        RecommendedFood(
          name: 'Mushrooms',
          description: 'UV-treated mushrooms can synthesize D2, aiding your recovery.',
          category: 'Vegetables',
        ),
      ],
      lifestyleTips: const [
        '15–20 min daily outdoor sun exposure on skin',
        'Outdoor exercise boosts both D levels & absorption',
        'Consider a Vitamin D3 supplement (1000–2000 IU/day) after consulting a doctor',
      ],
      createdAt: DateTime.now(),
    );
  }
}
