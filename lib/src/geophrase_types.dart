/// Nested address block within a fully-resolved [GeophraseAddress].
/// Field names mirror the Geophrase REST API response shape.
class GeophraseAddressDetails {
  /// The city where the address is located.
  final String city;

  /// State or union territory name.
  final String state;

  /// India Post DIGIPIN code for the coordinate.
  final String digiPin;

  /// A nearby landmark to help locate the address. May be an empty string,
  /// never `null`.
  final String landmark;

  /// Latitude of the address coordinate.
  final double latitude;

  /// Longitude of the address coordinate.
  final double longitude;

  /// 6-digit Indian postal code.
  final int postalCode;

  /// The type of address. Possible values are HOUSE, OFFICE, OTHER.
  final String addressType;

  /// The first line of the address, typically house number and street.
  final String addressLineOne;

  /// The second line of the address, for additional details. May be an empty
  /// string, never `null`.
  final String addressLineTwo;

  /// The full name of the contact person at the address.
  final String contactFullName;

  /// The verified mobile number for the address.
  final String verifiedMobileNum;

  /// Creates a [GeophraseAddressDetails]. Prefer
  /// [GeophraseAddressDetails.fromJson] when constructing from an API response.
  GeophraseAddressDetails({
    required this.city,
    required this.state,
    required this.digiPin,
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.postalCode,
    required this.addressType,
    required this.addressLineOne,
    required this.addressLineTwo,
    required this.contactFullName,
    required this.verifiedMobileNum,
  });

  /// Builds a [GeophraseAddressDetails] from the nested `address` object of
  /// the Geophrase `/business/resolve/` response.
  factory GeophraseAddressDetails.fromJson(Map<String, dynamic> json) {
    return GeophraseAddressDetails(
      city: json['city'] as String,
      state: json['state'] as String,
      digiPin: json['digi_pin'] as String,
      landmark: json['landmark'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      postalCode: (json['postal_code'] as num).toInt(),
      addressType: json['address_type'] as String,
      addressLineOne: json['address_line_one'] as String,
      addressLineTwo: json['address_line_two'] as String,
      contactFullName: json['contact_full_name'] as String,
      verifiedMobileNum: json['verified_mobile_num'] as String,
    );
  }
}

/// Fully-resolved address returned in client mode.
/// Field names mirror the Geophrase REST API response shape.
///
/// All fields are always present. [orderId] is an empty string when no
/// `orderId` was passed to [GeophraseConnect]. Inside [address], `landmark`
/// and `addressLineTwo` may be empty strings. No field is ever `null`.
class GeophraseAddress {
  /// Short alphanumeric code identifying the captured address.
  final String shortCode;

  /// Short URL pointing to the captured address.
  final String shortLink;

  /// URL to a QR code image encoding the short link.
  final String qrCode;

  /// Capture timestamp as milliseconds since the Unix epoch.
  final int capturedAt;

  /// Merchant-supplied reference ID echoed back from the request. Empty
  /// string when no `orderId` was passed.
  final String orderId;

  /// Structured address fields (city, state, coordinates, etc.).
  final GeophraseAddressDetails address;

  /// Unmodified API response. Use this to read fields that may be added
  /// to the API before the SDK exposes them as typed getters.
  final Map<String, dynamic> rawData;

  /// Creates a [GeophraseAddress]. Prefer [GeophraseAddress.fromJson] when
  /// constructing from an API response.
  GeophraseAddress({
    required this.shortCode,
    required this.shortLink,
    required this.qrCode,
    required this.capturedAt,
    required this.orderId,
    required this.address,
    required this.rawData,
  });

  /// Builds a [GeophraseAddress] from the JSON response of the Geophrase
  /// `/business/resolve/` endpoint.
  factory GeophraseAddress.fromJson(Map<String, dynamic> json) {
    return GeophraseAddress(
      shortCode: json['short_code'] as String,
      shortLink: json['short_link'] as String,
      qrCode: json['qr_code'] as String,
      capturedAt: (json['captured_at'] as num).toInt(),
      orderId: json['order_id'] as String,
      address: GeophraseAddressDetails.fromJson(
        json['address'] as Map<String, dynamic>,
      ),
      rawData: json,
    );
  }
}

/// Short-lived UUID4 returned in server mode.
/// Forward to your backend to exchange for a [GeophraseAddress].
class GeophraseRequestId {
  /// Single-use request ID. Send to your backend to exchange for the
  /// resolved address via the Geophrase `/business/resolve/` endpoint.
  final String requestId;

  /// Wraps a resolution [requestId].
  GeophraseRequestId({required this.requestId});
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
