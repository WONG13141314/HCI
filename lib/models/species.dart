// lib/models/species.dart

enum ConservationStatus { critical, endangered, vulnerable, threatened, rare }

class Species {
  final int id;
  final String name;
  final String latin;
  final String icon;
  final ConservationStatus status;
  final int points;
  final String desc;
  final List<String> facts;
  final String conservation;

  const Species({
    required this.id,
    required this.name,
    required this.latin,
    required this.icon,
    required this.status,
    required this.points,
    required this.desc,
    required this.facts,
    required this.conservation,
  });

  String get statusLabel {
    switch (status) {
      case ConservationStatus.critical:    return 'Critically Endangered';
      case ConservationStatus.endangered:  return 'Endangered';
      case ConservationStatus.vulnerable:  return 'Vulnerable';
      case ConservationStatus.threatened:  return 'Near Threatened';
      case ConservationStatus.rare:        return 'Rare';
    }
  }
}

// ─── All 6 Genting species ───────────────────────────────────────────────────

const List<Species> allSpecies = [
  Species(
    id: 1,
    name: 'Siamang Gibbon',
    latin: 'Symphalangus syndactylus',
    icon: '🦍',
    status: ConservationStatus.endangered,
    points: 150,
    desc: "The largest gibbon, known for loud calls traveling 2 miles. "
          "Critical seed dispersers in Genting's 130-million-year-old rainforest.",
    facts: [
      'Swing up to 40 feet between trees with powerful arms',
      'Live in tight family groups of 2–6 individuals',
      'Inflate throat sac to amplify territorial calls',
      'Primarily eat fruits, leaves, and flowers',
    ],
    conservation:
        'Habitat loss is the main threat. Genting protects 10,000+ acres '
        'and monitors populations with FRIM.',
  ),
  Species(
    id: 2,
    name: 'Scarlet-rumped Trogon',
    latin: 'Harpactes duvaucelii',
    icon: '🦜',
    status: ConservationStatus.threatened,
    points: 100,
    desc: 'Highland bird with spectacular plumage. Males display scarlet rumps '
          'and melodious whistling calls at dawn.',
    facts: [
      'Nest in tree cavities 3–8 meters high',
      'Feed on insects, fruits, and small lizards',
      'Most active during dawn and dusk',
      'Territorial during March–June breeding',
    ],
    conservation:
        "Protected in Genting's zones as part of 254+ monitored bird species.",
  ),
  Species(
    id: 3,
    name: 'Thismia limkokthayi',
    latin: 'Thismia limkokthayi',
    icon: '🏵️',
    status: ConservationStatus.critical,
    points: 200,
    desc: 'Fairy lantern discovered at Genting in 2024! Relies entirely on fungi. '
          'Named after Tan Sri Lim Kok Thay.',
    facts: [
      'Only 5 cm tall — incredibly easy to miss',
      'Lives underground except when flowering',
      'Discovered by Eddie Chan, GNA Manager',
      'First of its kind in Malaysia',
    ],
    conservation:
        'Critically endangered. GNA operates tissue culture lab for cultivation.',
  ),
  Species(
    id: 4,
    name: 'Highland Pitcher Plant',
    latin: 'Nepenthes gracillima',
    icon: '🌿',
    status: ConservationStatus.vulnerable,
    points: 80,
    desc: 'Carnivorous plant adapted to poor highland soils. Pitcher traps '
          'digest insects for nutrients.',
    facts: [
      'Grows above 2000 meters elevation',
      'Holds up to 200 ml digestive fluid',
      'Attracts prey with sweet nectar',
      'Some specimens over 100 years old',
    ],
    conservation: 'Protected in Montane Forests within GNA boundaries.',
  ),
  Species(
    id: 5,
    name: 'Chinese Swamp Orchid',
    latin: 'Phaius callosus',
    icon: '🌸',
    status: ConservationStatus.rare,
    points: 90,
    desc: 'Beautiful terrestrial orchid in Montane Oak Forests. '
          'Indicator species for forest health.',
    facts: [
      'Blooms March–June with vibrant flowers',
      'Flowers last up to 3 weeks',
      'Pollinated by specific native bees',
      'Indicator for ecosystem health',
    ],
    conservation: 'Protected under GNA-FRIM biodiversity monitoring.',
  ),
  Species(
    id: 6,
    name: 'Great Hornbill',
    latin: 'Buceros bicornis',
    icon: '🦅',
    status: ConservationStatus.vulnerable,
    points: 120,
    desc: 'Majestic bird with distinctive casque. Vital seed disperser and '
          'flagship conservation species.',
    facts: [
      'Wingspan up to 1.5 meters',
      'Females seal inside tree cavities when nesting',
      'Live up to 50 years in wild',
      'Diet primarily figs and forest fruits',
    ],
    conservation:
        'Spotted regularly in Batang Kali–Genting zone. Protected under wildlife acts.',
  ),
];
