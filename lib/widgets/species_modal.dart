import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/species.dart';

class SpeciesModal extends StatelessWidget {
  final Species species;
  final bool isNew;
  final VoidCallback onClose;

  const SpeciesModal({
    Key? key,
    required this.species,
    required this.isNew,
    required this.onClose,
  }) : super(key: key);

  Color get _statusColor {
    switch (species.status) {
      case ConservationStatus.critical:
        return const Color(0xFFdc2626);
      case ConservationStatus.endangered:
        return const Color(0xFFf97316);
      case ConservationStatus.vulnerable:
        return const Color(0xFFeab308);
      case ConservationStatus.threatened:
        return const Color(0xFFfbbf24);
      case ConservationStatus.rare:
        return const Color(0xFF8b5cf6);
    }
  }

  void _share() {
    Share.share(
      '🌿 I just discovered ${species.name} (${species.latin}) at Genting using WildTrack AR!\n\n'
      '${species.icon} Status: ${species.statusLabel}\n\n'
      'Join me in learning about endangered wildlife and conservation efforts!\n\n'
      '#WildTrackAR #GentingConservation #EndangeredSpecies',
      subject: 'WildTrack AR Discovery - ${species.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Material(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.all(isSmallScreen ? 12 : 20),
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: screenSize.height * 0.92,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, isSmallScreen),
                    _buildBody(context, isSmallScreen),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10b981),
            const Color(0xFF059669),
            const Color(0xFF047857),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        isSmall ? 28 : 36,
        24,
        isSmall ? 24 : 32,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Icon with glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  species.icon,
                  style: TextStyle(fontSize: isSmall ? 70 : 85),
                ),
              ),
              
              SizedBox(height: isSmall ? 16 : 20),
              
              // Name
              Text(
                species.name,
                style: TextStyle(fontFamily: 'Roboto', 
                  fontSize: isSmall ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmall ? 6 : 8),
              
              // Latin name
              Text(
                species.latin,
                style: TextStyle(fontFamily: 'Roboto', 
                  fontSize: isSmall ? 14 : 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmall ? 14 : 18),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      species.statusLabel.toUpperCase(),
                      style: TextStyle(fontFamily: 'Roboto', 
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Close button
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isSmall) {
    return Padding(
      padding: EdgeInsets.all(isSmall ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New discovery banner
          if (isNew) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmall ? 20 : 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFf093fb),
                    Color(0xFFf5576c),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf093fb).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        'NEW DISCOVERY!',
                        style: TextStyle(fontFamily: 'Roboto', 
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '+${species.points}',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: isSmall ? 46 : 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'CONSERVATION POINTS',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  delay: 200.ms,
                  curve: Curves.elasticOut,
                ),
            SizedBox(height: isSmall ? 20 : 24),
          ],

          // About section
          _buildSection(
            icon: '📖',
            title: 'About',
            child: Text(
              species.desc,
              style: TextStyle(fontFamily: 'Roboto', 
                fontSize: isSmall ? 13 : 14,
                height: 1.7,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            isSmall: isSmall,
          ),

          SizedBox(height: isSmall ? 20 : 24),

          // Facts section
          _buildSection(
            icon: '✨',
            title: 'Fascinating Facts',
            child: Column(
              children: species.facts.asMap().entries.map((entry) {
                return Container(
                  margin: EdgeInsets.only(
                    bottom: entry.key < species.facts.length - 1 ? 12 : 0,
                  ),
                  padding: EdgeInsets.all(isSmall ? 14 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFF10b981),
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(fontFamily: 'Roboto', 
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10b981),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(fontFamily: 'Roboto', 
                            fontSize: isSmall ? 12 : 13,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            isSmall: isSmall,
          ),

          SizedBox(height: isSmall ? 20 : 24),

          // Conservation section
          Container(
            padding: EdgeInsets.all(isSmall ? 18 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3b82f6).withOpacity(0.15),
                  const Color(0xFF2563eb).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF3b82f6).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3b82f6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🌍', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Conservation Efforts',
                      style: TextStyle(fontFamily: 'Roboto', 
                        fontSize: isSmall ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF60a5fa),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  species.conservation,
                  style: TextStyle(fontFamily: 'Roboto', 
                    fontSize: isSmall ? 12 : 13,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmall ? 24 : 28),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    'Share',
                    style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF374151),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmall ? 14 : 16,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmall ? 14 : 16,
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFF10b981).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Keep Exploring',
                        style: TextStyle(fontFamily: 'Roboto', 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('🌿', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required Widget child,
    required bool isSmall,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontFamily: 'Roboto', 
                fontSize: isSmall ? 17 : 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}