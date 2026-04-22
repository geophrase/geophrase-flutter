/// Fully-resolved address returned in client mode.
/// Field names mirror the Geophrase REST API response shape.
class GeophraseAddress {
  final String phrase;
  final String verifiedAccountMobileNum;
  final String addressType;
  final String contactFullName;
  final String contactMobileNum;
  final String addressLineOne;
  final String addressLineTwo;
  final String landmark;
  final String city;
  final String state;
  final int postalCode;
  final double latitude;
  final double longitude;
  final String digiPin;
  final String qrCode;

  /// Unmodified API response. Use this to read fields that may be added
  /// to the API before the SDK exposes them as typed getters.
  final Map<String, dynamic> rawData;

  GeophraseAddress({
    required this.phrase,
    required this.verifiedAccountMobileNum,
    required this.addressType,
    required this.contactFullName,
    required this.contactMobileNum,
    required this.addressLineOne,
    required this.addressLineTwo,
    required this.landmark,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.digiPin,
    required this.qrCode,
    required this.rawData,
  });

  factory GeophraseAddress.fromJson(Map<String, dynamic> json) {
    return GeophraseAddress(
      phrase: json['phrase'] as String,
      verifiedAccountMobileNum: json['verified_account_mobile_num'] as String,
      addressType: json['address_type'] as String,
      contactFullName: json['contact_full_name'] as String,
      contactMobileNum: json['contact_mobile_num'] as String,
      addressLineOne: json['address_line_one'] as String,
      addressLineTwo: json['address_line_two'] as String,
      landmark: json['landmark'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: (json['postal_code'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      digiPin: json['digi_pin'] as String,
      qrCode: json['qr_code'] as String,
      rawData: json,
    );
  }
}

/// Short-lived opaque token returned in server mode.
/// Forward to your backend to exchange for a [GeophraseAddress].
class GeophraseToken {
  final String token;
  GeophraseToken({required this.token});
}

class GeophraseError {
  /// Either `'API_ERROR'` or `'NETWORK_ERROR'`.
  final String type;
  final String message;
  final int? status;
  GeophraseError({required this.type, required this.message, this.status});
}

/// Undocumented override for staging/QA environments.
class GeophraseEndpoints {
  final String? widgetOrigin;
  final String? apiBase;
  const GeophraseEndpoints({this.widgetOrigin, this.apiBase});
}
