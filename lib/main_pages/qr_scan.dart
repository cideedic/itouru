// qr_scanner_page.dart - The QR Scanner Screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/building_content_pages/content.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool isProcessing = false;
  bool isTorchOn = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      print('=== QR CODE SCAN DEBUG ===');
      print('Raw QR Data: $qrData');

      // Parse the QR code data
      // Expected format: "building:123" or just "123"
      int buildingId;

      if (qrData.startsWith('building:')) {
        buildingId = int.parse(qrData.split(':')[1]);
      } else {
        buildingId = int.parse(qrData);
      }

      print('Parsed Building ID: $buildingId');

      // Fetch building data from Supabase
      print('Fetching from Supabase...');
      final response = await supabase
          .from('Building')
          .select('building_id, building_name')
          .eq('building_id', buildingId)
          .single();

      print('Response: $response');

      if (!mounted) return;

      // Navigate to building details page
      print('Navigating to building details...');
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BuildingDetailsPage(
            buildingId: response['building_id'],
            buildingName: response['building_name'],
            title: response['building_name'] ?? 'Building',
          ),
        ),
      );
    } catch (e) {
      print('=== ERROR IN QR SCAN ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');

      if (!mounted) return;

      // Show detailed error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'QR Code Error',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error Details:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'QR Data: $qrData',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                'Error: ${e.toString()}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => isProcessing = false);
              },
              child: Text('Try Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !isProcessing) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _handleQRCode(code);
                }
              }
            },
          ),

          // Scanning frame overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: -3,
                    left: -3,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFFF8C00), width: 6),
                          left: BorderSide(color: Color(0xFFFF8C00), width: 6),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFFF8C00), width: 6),
                          right: BorderSide(color: Color(0xFFFF8C00), width: 6),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    left: -3,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFFF8C00),
                            width: 6,
                          ),
                          left: BorderSide(color: Color(0xFFFF8C00), width: 6),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFFF8C00),
                            width: 6,
                          ),
                          right: BorderSide(color: Color(0xFFFF8C00), width: 6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (isProcessing)
                  CircularProgressIndicator(color: Color(0xFFFF8C00))
                else
                  Text(
                    'Point camera at QR code',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                SizedBox(height: 8),
                Text(
                  'Align QR code within the frame',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Toggle flash button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  controller.toggleTorch();
                  setState(() {
                    isTorchOn = !isTorchOn;
                  });
                },
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
