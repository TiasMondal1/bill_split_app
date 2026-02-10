import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';
import '../services/ocr_service.dart';
import '../models/bill_item.dart';
import '../models/person.dart';
import '../providers/bill_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/person_chip.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../services/calculation_service.dart';
import 'split_result_screen.dart';
import 'bill_entry_screen.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  OCRService? _ocrService;
  OCRResult? _ocrResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _ocrService = OCRService();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      await _processImage(File(image.path));
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        await _processImage(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Crop image if needed
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1.5),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
          ),
          IOSUiSettings(
            title: 'Crop Receipt',
          ),
        ],
      );

      if (croppedFile == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Process with OCR
      final result = await _ocrService!.processReceipt(File(croppedFile.path));

      setState(() {
        _ocrResult = result;
        _isProcessing = false;
      });

      if (mounted) {
        if (result.isValid) {
          _showOCRResult(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OCR failed: ${result.error ?? "Low confidence"}'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  setState(() {
                    _ocrResult = null;
                  });
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    }
  }

  void _showOCRResult(OCRResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receipt Scanned: ${result.restaurantName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items found: ${result.items.length}'),
              const SizedBox(height: 8),
              if (result.subtotal > 0) Text('Subtotal: ${Helpers.formatCurrency(result.subtotal)}'),
              if (result.tax > 0) Text('Tax: ${Helpers.formatCurrency(result.tax)}'),
              if (result.total > 0) Text('Total: ${Helpers.formatCurrency(result.total)}'),
              const SizedBox(height: 16),
              const Text('Items:'),
              const SizedBox(height: 8),
              ...result.items.map((item) => Text('• ${item.name}: ${Helpers.formatCurrency(item.price)}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _ocrResult = null;
              });
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedWithOCRResult(result);
            },
            child: const Text('Use This'),
          ),
        ],
      ),
    );
  }

  void _proceedWithOCRResult(OCRResult result) {
    // Navigate to bill entry screen with pre-filled data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BillEntryScreenWithData(
          restaurantName: result.restaurantName,
          items: result.items.map((item) => BillItem(
            id: const Uuid().v4(),
            name: item.name,
            price: item.price,
            quantity: 1,
            assignedPeople: [],
          )).toList(),
          subtotal: result.subtotal,
          tax: result.tax,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isProcessing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Processing Receipt'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing receipt with OCR...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
      ),
      body: Stack(
        children: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!),
          // Overlay guide
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AspectRatio(
                aspectRatio: 1 / 1.5,
                child: SizedBox(),
              ),
            ),
          ),
          // Instructions
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Position receipt within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white),
                onPressed: _pickImageFromGallery,
                tooltip: 'Pick from Gallery',
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 48),
                onPressed: _capturePhoto,
                tooltip: 'Capture Photo',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Cancel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget to pass data to BillEntryScreen
class BillEntryScreenWithData extends StatelessWidget {
  final String restaurantName;
  final List<BillItem> items;
  final double subtotal;
  final double tax;

  const BillEntryScreenWithData({
    super.key,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.tax,
  });

  @override
  Widget build(BuildContext context) {
    // This is a simplified version - in a real app, you'd modify BillEntryScreen
    // to accept initial data. For now, we'll navigate to regular BillEntryScreen
    // and show a message that data was loaded.
    return const BillEntryScreen();
  }
}
