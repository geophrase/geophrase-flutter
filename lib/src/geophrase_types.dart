class GeophraseAddress {
  final String phrase;
  final Map<String, dynamic> rawData;
  GeophraseAddress({required this.phrase, required this.rawData});
}

class GeophraseToken {
  final String token;
  GeophraseToken({required this.token});
}

class GeophraseError {
  final String type;
  final String message;
  final int? status;
  GeophraseError({required this.type, required this.message, this.status});
}
