/// Fully-resolved address returned in client mode.
/// Field names mirror the Geophrase REST API response shape.
class GeophraseAddress {
  /// A unique, human-readable identifier for the address.
  final String phrase;

  /// The verified mobile number of the account associated with this address.
  final String verifiedAccountMobileNum;

  /// The type of address. Possible values are HOUSE, OFFICE, OTHER.
  final String addressType;

  /// The full name of the contact person at the address.
  final String contactFullName;

  /// The unverified mobile number of the contact person at the address.
  final String contactMobileNum;

  /// The first line of the address, typically including the house number and street name.
  final String addressLineOne;

  /// The second line of the address, for additional details. Can be an empty string if user left it empty.
  final String addressLineTwo;

  /// A nearby landmark to help locate the address. Can be an empty string if user left it empty.
  final String landmark;

  /// The city where the address is located.
  final String city;

  /// State or union territory name.
  final String state;

  /// 6-digit Indian postal code.
  final int postalCode;

  /// Latitude of the address coordinate.
  final double latitude;

  /// Longitude of the address coordinate.
  final double longitude;

  /// India Post DIGIPIN code for the coordinate.
  final String digiPin;

  /// URL to a QR code image encoding the phrase.
  final String qrCode;

  /// Unmodified API response. Use this to read fields that may be added
  /// to the API before the SDK exposes them as typed getters.
  final Map<String, dynamic> rawData;

  /// Creates a [GeophraseAddress]. Prefer [GeophraseAddress.fromJson] when
  /// constructing from an API response.
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

  /// Builds a [GeophraseAddress] from the JSON response of the Geophrase
  /// `/business/resolve/` endpoint.
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
  /// Opaque single-use token. Send to your backend to exchange for the
  /// resolved address via the Geophrase `/business/resolve/` endpoint.
  final String token;

  /// Wraps an opaque resolution [token].
  GeophraseToken({required this.token});
}

/// Error reported via the `onError` callback.
class GeophraseError {
  /// Either `'API_ERROR'` or `'NETWORK_ERROR'`.
  final String type;

  /// Human-readable error message, suitable for logging.
  final String message;

  /// HTTP status code, set only when [type] is `'API_ERROR'`.
  final int? status;

  /// Creates a [GeophraseError].
  GeophraseError({required this.type, required this.message, this.status});
}

/// Undocumented override for staging/QA environments.
class GeophraseEndpoints {
  /// Origin of the Geophrase widget to load (e.g. `https://connect.geophrase.com`).
  final String? widgetOrigin;

  /// Base URL of the Geophrase REST API (e.g. `https://api.geophrase.com`).
  final String? apiBase;

  /// Creates a [GeophraseEndpoints] override.
  const GeophraseEndpoints({this.widgetOrigin, this.apiBase});
}
