// lib/widgets/species_modal.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/species.dart';

class SpeciesModal extends StatelessWidget {
  final Species species;
  final bool isNew;
  final VoidCallback onClose;

  const SpeciesModal({
    super.key,
    required this.species,
    required this.isNew,
    required this.onClose,
  });

  Color get _statusColor {
    switch (species.status) {
      case ConservationStatus.critical:
        return Color(0xFF991b1b);
      case ConservationStatus.endangered:
        return Color(0xFFdc2626);
      case ConservationStatus.vulnerable:
        return Color(0xFFeab308);
      case ConservationStatus.threatened:
        return Color(0xFFf59e0b);
      case ConservationStatus.rare:
        return Color(0xFF8b5cf6);
    }
  }

  void _share() {
    Share.share(
      '🌿 Just discovered ${species.name} at Genting using WildTrack AR! ${species.icon}\n\n'
      '#WildTrackAR #GentingConservation',
      subject: 'WildTrack AR Discovery',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 20 : 40,
          ),
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: screenSize.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF10b981), Color(0xFF059669)],
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(24, isSmallScreen ? 30 : 40, 24, 24),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Text(species.icon, style: TextStyle(fontSize: isSmallScreen ? 80 : 100)),
                            SizedBox(height: 16),
                            Text(species.name,
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 26 : 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center),
                            SizedBox(height: 8),
                            Text(species.latin,
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 17,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white),
                                textAlign: TextAlign.center),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: _statusColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                species.statusLabel.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // New discovery banner
                        if (isNew) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 18 : 22),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text('🎉 New Discovery!',
                                    style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.white)),
                                SizedBox(height: 8),
                                Text('+${species.points}',
                                    style: TextStyle(
                                        fontSize: isSmallScreen ? 44 : 50,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],

                        // About
                        Text('📖 About',
                            style: TextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text(species.desc,
                            style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                height: 1.6,
                                color: Color(0xFF4a4a4a))),
                        SizedBox(height: 20),

                        // Facts
                        Text('✨ Facts',
                            style: TextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        ...species.facts.map((f) => Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                              decoration: BoxDecoration(
                                color: Color(0xFFf0fdf4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                    left: BorderSide(color: Color(0xFF10b981), width: 4)),
                              ),
                              child: Text(f,
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Color(0xFF1a4d2e),
                                      height: 1.5)),
                            )),
                        SizedBox(height: 20),

                        // Conservation
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🌍 Conservation',
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1e40af))),
                              SizedBox(height: 10),
                              Text(species.conservation,
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Color(0xFF1e3a8a),
                                      height: 1.6)),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _share,
                                icon: Icon(Icons.share, size: 18),
                                label: Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFe5e7eb),
                                  foregroundColor: Colors.black87,
                                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  textStyle: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 16,
                                      fontWeight: FontWeight.bold),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onClose,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF10b981),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  textStyle: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                child: Text('Keep Hunting'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
