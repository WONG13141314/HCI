enum ConservationStatus { 
  critical, 
  endangered, 
  vulnerable, 
  threatened, 
  rare 
}

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
      case ConservationStatus.critical:
        return 'Critically Endangered';
      case ConservationStatus.endangered:
        return 'Endangered';
      case ConservationStatus.vulnerable:
        return 'Vulnerable';
      case ConservationStatus.threatened:
        return 'Near Threatened';
      case ConservationStatus.rare:
        return 'Rare';
    }
  }

  String get statusDescription {
    switch (status) {
      case ConservationStatus.critical:
        return 'Facing an extremely high risk of extinction';
      case ConservationStatus.endangered:
        return 'Facing a very high risk of extinction';
      case ConservationStatus.vulnerable:
        return 'Facing a high risk of extinction';
      case ConservationStatus.threatened:
        return 'Likely to become endangered soon';
      case ConservationStatus.rare:
        return 'Small population with limited distribution';
    }
  }
}

const List<Species> allSpecies = [
  Species(
    id: 1,
    name: 'Siamang Gibbon',
    latin: 'Symphalangus syndactylus',
    icon: '🦍',
    status: ConservationStatus.endangered,
    points: 150,
    desc: "The largest gibbon species, renowned for their powerful calls that can travel up to 2 miles through the rainforest. These magnificent primates are critical seed dispersers in Genting's ancient 130-million-year-old rainforest ecosystem.",
    facts: [
      'Can swing up to 40 feet between trees using their powerful arms',
      'Live in close-knit family groups of 2-6 individuals',
      'Inflate their throat sac to amplify territorial calls at dawn',
      'Diet consists primarily of fruits, leaves, and flowers',
      'Form lifelong monogamous pairs'
    ],
    conservation:
        'Habitat loss due to deforestation is the main threat. Genting Nature Adventures protects over 10,000 acres of pristine habitat and monitors populations in partnership with FRIM (Forest Research Institute Malaysia).',
  ),
  Species(
    id: 2,
    name: 'Scarlet-rumped Trogon',
    latin: 'Harpactes duvaucelii',
    icon: '🦜',
    status: ConservationStatus.threatened,
    points: 100,
    desc: 'A stunning highland bird with spectacular plumage featuring vibrant scarlet patches. Males display their magnificent coloring during territorial displays and produce melodious whistling calls at dawn.',
    facts: [
      'Nest in tree cavities 3-8 meters above ground',
      'Feed on insects, fruits, and small lizards',
      'Most active during dawn and dusk twilight hours',
      'Highly territorial during March-June breeding season',
      'Can remain motionless for long periods while hunting'
    ],
    conservation:
        "Protected within Genting's conservation zones as part of the 254+ monitored bird species. Highland forest preservation is critical for their survival.",
  ),
  Species(
    id: 3,
    name: 'Thismia Fairy Lantern',
    latin: 'Thismia limkokthayi',
    icon: '🏵️',
    status: ConservationStatus.critical,
    points: 200,
    desc: 'An extraordinary fairy lantern plant discovered at Genting in 2024! This remarkable species relies entirely on fungi for survival and was named in honor of Tan Sri Lim Kok Thay for his conservation efforts.',
    facts: [
      'Only 5 cm tall - incredibly easy to miss in the forest',
      'Lives completely underground except when flowering',
      'Discovered by Eddie Chan, GNA Conservation Manager',
      'First species of its kind documented in Malaysia',
      'Has no chlorophyll - depends on fungal partners'
    ],
    conservation:
        'Critically endangered with extremely limited habitat. GNA operates a specialized tissue culture laboratory for conservation propagation and research.',
  ),
  Species(
    id: 4,
    name: 'Highland Pitcher Plant',
    latin: 'Nepenthes gracillima',
    icon: '🌿',
    status: ConservationStatus.vulnerable,
    points: 80,
    desc: 'A fascinating carnivorous plant perfectly adapted to poor highland soils. The pitcher-shaped trap contains digestive fluid that breaks down insects to provide essential nutrients.',
    facts: [
      'Grows exclusively above 2000 meters elevation',
      'Each pitcher can hold up to 200 ml of digestive fluid',
      'Attracts prey with sweet-smelling nectar around the rim',
      'Some specimens can live for over 100 years',
      'Different pitcher shapes specialize in catching different insects'
    ],
    conservation: 
        'Protected in Montane Forests within GNA conservation boundaries. Climate change and habitat loss pose significant threats to highland species.',
  ),
  Species(
    id: 5,
    name: 'Chinese Swamp Orchid',
    latin: 'Phaius callosus',
    icon: '🌸',
    status: ConservationStatus.rare,
    points: 90,
    desc: 'A beautiful terrestrial orchid found in Montane Oak Forests. This species serves as an important indicator of forest health and ecosystem balance.',
    facts: [
      'Blooms March-June with vibrant, long-lasting flowers',
      'Individual flowers can last up to 3 weeks',
      'Pollinated by specific native bee species',
      'Serves as an indicator species for ecosystem health',
      'Requires pristine forest conditions to thrive'
    ],
    conservation: 
        'Protected under GNA-FRIM biodiversity monitoring programs. Habitat preservation and native pollinator conservation are key to survival.',
  ),
  Species(
    id: 6,
    name: 'Great Hornbill',
    latin: 'Buceros bicornis',
    icon: '🦅',
    status: ConservationStatus.vulnerable,
    points: 120,
    desc: 'A majestic bird with a distinctive casque on its enormous bill. As a vital seed disperser for large-seeded trees, the Great Hornbill is a flagship species for rainforest conservation.',
    facts: [
      'Impressive wingspan reaching up to 1.5 meters',
      'Females seal themselves inside tree cavities while nesting',
      'Can live up to 50 years in the wild',
      'Diet consists primarily of figs and large forest fruits',
      'Pairs mate for life and return to the same nesting sites'
    ],
    conservation:
        'Regularly spotted in the Batang Kali-Genting conservation corridor. Protected under Malaysian wildlife acts. Requires large, mature trees for nesting.',
  ),
];