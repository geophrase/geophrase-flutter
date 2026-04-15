class GeophraseAddress {
  final String phrase;
  final Map<String, dynamic> rawData;
  GeophraseAddress({required this.phrase, required this.rawData});
}

class GeophraseError {
  final String type;
  final String message;
  final int? status;
  GeophraseError({required this.type, required this.message, this.status});
}
