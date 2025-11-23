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

class _QRScannerPageState extends State<QRScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool isProcessing = false;
  bool isTorchOn = false;
  final supabase = Supabase.instance.client;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      // Parse the QR code data
      int buildingId;

      if (qrData.startsWith('building:')) {
        buildingId = int.parse(qrData.split(':')[1]);
      } else {
        buildingId = int.parse(qrData);
      }

      // Fetch building data from Supabase
      final response = await supabase
          .from('Building')
          .select('building_id, building_name')
          .eq('building_id', buildingId)
          .single();

      if (!mounted) return;

      // Show success feedback
      _showSuccessOverlay();

      // Wait a moment before navigating
      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to building details page
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
      if (!mounted) return;

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 28,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Scan Failed',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to process this QR code. Please make sure it\'s a valid building QR code.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Data: $qrData',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => isProcessing = false);
              },
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  color: Color(0xFFFF8C00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A31C8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[400],
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'QR Code Detected!',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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

          // Dark overlay with cutout
          CustomPaint(size: Size.infinite, painter: ScannerOverlayPainter()),

          // Header
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan QR Code',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Position QR within the frame',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scanning frame with animation
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Animated scan line
                  if (!isProcessing)
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanLineAnimation.value * 280,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFFFF8C00),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(
                                    0xFFFF8C00,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Corner decorations with gradient
                  _buildCorner(
                    top: 0,
                    left: 0,
                    topBorder: true,
                    leftBorder: true,
                  ),
                  _buildCorner(
                    top: 0,
                    right: 0,
                    topBorder: true,
                    rightBorder: true,
                  ),
                  _buildCorner(
                    bottom: 0,
                    left: 0,
                    bottomBorder: true,
                    leftBorder: true,
                  ),
                  _buildCorner(
                    bottom: 0,
                    right: 0,
                    bottomBorder: true,
                    rightBorder: true,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Status indicator
                  if (isProcessing)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A31C8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Color(0xFFFF8C00),
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Ready to Scan',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hold steady for best results',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 24),

                  // Flashlight toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: isTorchOn
                          ? Color(0xFFFF8C00)
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: isTorchOn
                          ? [
                              BoxShadow(
                                color: Color(0xFFFF8C00).withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
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
                        size: 28,
                      ),
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool topBorder = false,
    bool bottomBorder = false,
    bool leftBorder = false,
    bool rightBorder = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A31C8), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: topBorder && leftBorder
                ? Radius.circular(24)
                : Radius.zero,
            topRight: topBorder && rightBorder
                ? Radius.circular(24)
                : Radius.zero,
            bottomLeft: bottomBorder && leftBorder
                ? Radius.circular(24)
                : Radius.zero,
            bottomRight: bottomBorder && rightBorder
                ? Radius.circular(24)
                : Radius.zero,
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: topBorder ? 4 : 0,
            bottom: bottomBorder ? 4 : 0,
            left: leftBorder ? 4 : 0,
            right: rightBorder ? 4 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: topBorder && leftBorder
                  ? Radius.circular(20)
                  : Radius.zero,
              topRight: topBorder && rightBorder
                  ? Radius.circular(20)
                  : Radius.zero,
              bottomLeft: bottomBorder && leftBorder
                  ? Radius.circular(20)
                  : Radius.zero,
              bottomRight: bottomBorder && rightBorder
                  ? Radius.circular(20)
                  : Radius.zero,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for the scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final double scanAreaSize = 280;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
          Radius.circular(24),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
