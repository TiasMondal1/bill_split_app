import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/bill_item.dart';

class OCRService {
  final TextRecognizer _textRecognizer;

  OCRService() : _textRecognizer = TextRecognizer();

  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  /// Process receipt image and extract bill information
  Future<OCRResult> processReceipt(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return _parseReceiptText(recognizedText.text);
    } catch (e) {
      return OCRResult(
        restaurantName: '',
        items: [],
        subtotal: 0.0,
        tax: 0.0,
        total: 0.0,
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }

  OCRResult _parseReceiptText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return OCRResult(
        restaurantName: '',
        items: [],
        subtotal: 0.0,
        tax: 0.0,
        total: 0.0,
        confidence: 0.0,
        error: 'No text detected',
      );
    }

    // Extract restaurant name (first 2 lines)
    String restaurantName = lines.length > 0 ? lines[0].trim() : '';
    if (lines.length > 1 && restaurantName.length < 20) {
      restaurantName += ' ${lines[1].trim()}';
    }

    // Extract items and amounts
    List<ParsedItem> items = [];
    double? subtotal;
    double? tax;
    double? total;

    // Regex patterns
    final pricePattern = RegExp(r'\$?(\d+\.\d{2})');
    final itemPattern = RegExp(r'^(.+?)\s+\$?(\d+\.\d{2})$');

    for (var line in lines) {
      line = line.trim();

      // Skip header lines (first 2-3 lines)
      if (lines.indexOf(line) < 2) continue;

      // Check for keywords
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('subtotal')) {
        final match = pricePattern.firstMatch(line);
        if (match != null) {
          subtotal = double.tryParse(match.group(1)!);
        }
      } else if (lowerLine.contains('tax')) {
        final match = pricePattern.firstMatch(line);
        if (match != null) {
          tax = double.tryParse(match.group(1)!);
        }
      } else if (lowerLine.contains('total')) {
        final match = pricePattern.firstMatch(line);
        if (match != null) {
          total = double.tryParse(match.group(1)!);
        }
      } else {
        // Try to parse as item
        final match = itemPattern.firstMatch(line);
        if (match != null) {
          final itemName = match.group(1)!.trim();
          final price = double.tryParse(match.group(2)!);
          if (price != null && itemName.isNotEmpty) {
            items.add(ParsedItem(name: itemName, price: price));
          }
        } else {
          // Try simple price pattern at end of line
          final priceMatch = pricePattern.firstMatch(line);
          if (priceMatch != null) {
            final price = double.tryParse(priceMatch.group(1)!);
            if (price != null && price > 0 && price < 1000) {
              // Likely an item
              final itemName = line.substring(0, priceMatch.start).trim();
              if (itemName.isNotEmpty) {
                items.add(ParsedItem(name: itemName, price: price));
              }
            }
          }
        }
      }
    }

    // Calculate confidence (simple heuristic)
    double confidence = 0.5;
    if (restaurantName.isNotEmpty) confidence += 0.1;
    if (items.isNotEmpty) confidence += 0.2;
    if (total != null) confidence += 0.2;

    return OCRResult(
      restaurantName: restaurantName,
      items: items,
      subtotal: subtotal ?? 0.0,
      tax: tax ?? 0.0,
      total: total ?? 0.0,
      confidence: confidence,
    );
  }
}

class OCRResult {
  final String restaurantName;
  final List<ParsedItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final double confidence;
  final String? error;

  OCRResult({
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.confidence,
    this.error,
  });

  bool get isValid => error == null && confidence >= 0.5;
}

class ParsedItem {
  final String name;
  final double price;

  ParsedItem({required this.name, required this.price});
}
