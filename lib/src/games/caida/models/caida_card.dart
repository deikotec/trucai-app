// src/games/caida/models/caida_card.dart
class CaidaCard {
  final String id;
  final String rank;
  final String suit;
  final int numericValue;
  final String displayRank;

  const CaidaCard({
    required this.id,
    required this.rank,
    required this.suit,
    required this.numericValue,
    required this.displayRank,
  });

  static const Map<String, String> _rankToImg = {
    '1':'1','2':'2','3':'3','4':'4','5':'5','6':'6','7':'7','S':'10','C':'11','R':'12'
  };

  String get imageUrl {
    const base = 'https://res.cloudinary.com/teributu/image/upload/';
    return '$base${_rankToImg[rank]}${suit.toLowerCase()}.jpg';
  }
}
