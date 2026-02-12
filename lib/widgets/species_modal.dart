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
      case ConservationStatus.critical:   return const Color(0xFF991b1b);
      case ConservationStatus.endangered: return const Color(0xFFdc2626);
      case ConservationStatus.vulnerable: return const Color(0xFFeab308);
      case ConservationStatus.threatened: return const Color(0xFFf59e0b);
      case ConservationStatus.rare:       return const Color(0xFF8b5cf6);
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
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(22),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF10b981), Color(0xFF059669)],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 42, 32, 32),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Text(species.icon,
                                style: const TextStyle(fontSize: 105)),
                            const SizedBox(height: 22),
                            Text(species.name,
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 9),
                            Text(species.latin,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: _statusColor,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                species.statusLabel.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 13,
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
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.28),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // New discovery banner
                        if (isNew) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                const Text('🎉 New Discovery!',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white)),
                                const SizedBox(height: 9),
                                Text('+${species.points}',
                                    style: const TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // About
                        const Text('📖 About',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(species.desc,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.85,
                                color: Color(0xFF4a4a4a))),
                        const SizedBox(height: 28),

                        // Facts
                        const Text('✨ Facts',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...species.facts.map((f) => Container(
                              margin: const EdgeInsets.only(bottom: 11),
                              padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFf0fdf4),
                                borderRadius: BorderRadius.circular(12),
                                border: const Border(
                                    left: BorderSide(
                                        color: Color(0xFF10b981), width: 5)),
                              ),
                              child: Text(f,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1a4d2e),
                                      height: 1.65)),
                            )),
                        const SizedBox(height: 28),

                        // Conservation
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🌍 Conservation',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1e40af))),
                              const SizedBox(height: 13),
                              Text(species.conservation,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1e3a8a),
                                      height: 1.75)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _share,
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFe5e7eb),
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 19),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  textStyle: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onClose,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10b981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 19),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  textStyle: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Keep Hunting'),
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
