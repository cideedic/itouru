import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../maps_assets/routing_service.dart';

class GateSelectionDialog extends StatefulWidget {
  final List<CampusGate> gates;
  final LatLng userLocation;
  final LatLng destinationLocation;
  final CampusGate? recommendedGate;

  const GateSelectionDialog({
    super.key,
    required this.gates,
    required this.userLocation,
    required this.destinationLocation,
    this.recommendedGate,
  });

  @override
  State<GateSelectionDialog> createState() => _GateSelectionDialogState();
}

class _GateSelectionDialogState extends State<GateSelectionDialog> {
  Map<String, String?> _gateDurations = {};
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _calculateAllGateDurations();
  }

  Future<void> _calculateAllGateDurations() async {
    setState(() {
      _isCalculating = true;
    });

    for (var gate in widget.gates) {
      final duration = await RoutingService.calculateRouteDurationViaGate(
        userLocation: widget.userLocation,
        destination: widget.destinationLocation,
        gate: gate,
      );

      if (mounted) {
        setState(() {
          _gateDurations[gate.id] = duration;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.door_sliding,
                      size: 32,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Select Starting Gate',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You are off-campus',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isCalculating
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFF8C00)),
                          SizedBox(height: 16),
                          Text(
                            'Calculating optimal routes...',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: widget.gates.length,
                      itemBuilder: (context, index) {
                        final gate = widget.gates[index];
                        final isRecommended =
                            widget.recommendedGate?.id == gate.id;
                        final duration = _gateDurations[gate.id];

                        return _buildGateOption(
                          gate: gate,
                          isRecommended: isRecommended,
                          duration: duration,
                        );
                      },
                    ),
            ),

            // Cancel button
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateOption({
    required CampusGate gate,
    required bool isRecommended,
    String? duration,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, gate),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRecommended ? Colors.orange[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRecommended ? Colors.orange : Colors.grey[200]!,
                width: isRecommended ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Gate icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isRecommended
                        ? Colors.orange[100]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.door_sliding,
                    color: isRecommended ? Colors.orange : Colors.green[700],
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),

                // Gate details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isRecommended) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Text(
                                'RECOMMENDED',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(width: 8),
                          Text(
                            gate.name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            duration ?? 'Calculating...',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
