// src/games/caida/models/caida_card.dart
// Define la estructura de una carta del juego, incluyendo sus propiedades
// y los datos estáticos del mazo (palos, rangos, puntos, etc.).

class CaidaCard {
  final String id;
  final String rank; // '1', '2', ... 'S', 'C', 'R'
  final String suit; // 'O', 'C', 'E', 'B'
  final int numericValue;
  final String displayRank;

  // --- DATOS ESTÁTICOS DE LAS CARTAS ---

  static const Map<String, String> suits = {
    'O': 'Oros',
    'C': 'Copas',
    'E': 'Espadas',
    'B': 'Bastos',
  };

  static const Map<String, int> ranks = {
    '1': 1,
    '2': 2,
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    'S': 8,
    'C': 9,
    'R': 10,
  };

  static const Map<String, String> displayRanks = {
    '1': 'As',
    '2': '2',
    '3': '3',
    '4': '4',
    '5': '5',
    '6': '6',
    '7': '7',
    'S': 'Sota',
    'C': 'Caballo',
    'R': 'Rey',
  };

  static const Map<String, int> cardPointsCaida = {
    '1': 1,
    '2': 1,
    '3': 1,
    '4': 1,
    '5': 1,
    '6': 1,
    '7': 1,
    'S': 2,
    'C': 3,
    'R': 4,
  };

  static const Map<String, int> cantoPointsRonda = {
    '1': 1,
    '2': 1,
    '3': 1,
    '4': 1,
    '5': 1,
    '6': 1,
    '7': 1,
    'S': 2,
    'C': 3,
    'R': 4,
  };

  // Mapeo para obtener la URL de la imagen de la carta.
  static const Map<String, String> _rankToImg = {
    '1': '1',
    '2': '2',
    '3': '3',
    '4': '4',
    '5': '5',
    '6': '6',
    '7': '7',
    'S': '10',
    'C': '11',
    'R': '12',
  };

  // Constructor que deriva las propiedades a partir del rango y el palo.
  CaidaCard({required this.rank, required this.suit})
    : id = '$rank$suit',
      numericValue = ranks[rank]!,
      displayRank = displayRanks[rank]!;

  // Genera la URL de la imagen de la carta desde Cloudinary.
  String get imageUrl {
    const base = 'https://res.cloudinary.com/teributu/image/upload/';
    final imgRank = _rankToImg[rank];
    final imgSuit = suit.toLowerCase();
    return '$base$imgRank$imgSuit.jpg';
  }

  // Constructor para crear una carta a partir de un mapa (útil para Firestore).
  CaidaCard.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      rank = map['rank'],
      suit = map['suit'],
      numericValue = map['numericValue'],
      displayRank = map['displayRank'];

  // Convierte la carta a un mapa (útil para Firestore).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rank': rank,
      'suit': suit,
      'numericValue': numericValue,
      'displayRank': displayRank,
    };
  }
}
