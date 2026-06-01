## 1.6.0

* Added required `apiKeyId` (your public Key ID), now passed to the widget on every capture.

## 1.5.0

* more fields in address object now

## 1.4.1

* minor metadata update

## 1.4.0

* Bumped dependencies to latest stable: `geolocator ^14.0.0`, `package_info_plus ^10.0.0`, `web ^1.1.0`, `webview_flutter ^4.13.0`.
* Migrated `Geolocator.getCurrentPosition` call to the `LocationSettings`-based API required by geolocator 12+.
* Expanded dartdoc coverage on the public API (`GeophraseAddress`, `GeophraseToken`, `GeophraseError`, `GeophraseEndpoints`).

## 1.3.3

* Minor bug fix

## 1.3.2

* Minor bug fix

## 1.3.1

* Auto publish from Github action

## 1.3.0

* Example Application Added

## 1.2.2

* Minor fix

## 1.2.1

* Android Status Bar color fix

## 1.2.0

* Aligned behavior with the React Native SDK for consistency across platforms.
* `GeophraseAddress` now exposes all API fields as typed getters (`addressLineOne`, `city`, `postalCode`, `latitude`, `digiPin`, `qrCode`, etc.). `rawData` is retained as an escape hatch.
* Mobile: progressive location strategy — a fast low-accuracy fix is sent first, then refined with a high-accuracy stream. `LOCATION_DENIED` is only signalled when no fix is produced.
* Mobile and Web: soft validation (`debugPrint`) instead of throwing, so a misconfigured prop can no longer crash the host app.
* Theme is now resolved against the OS brightness for the native background, preventing a white flash in dark mode when `theme: 'system'`.
* Web: fixed malformed widget URL when `orderId`, `phone`, or `theme` were passed.
* Added internal `endpoints` override for staging/QA.
* Merchant callbacks are wrapped so a thrown exception in merchant code is logged instead of crashing the SDK.

## 1.1.1

* Location bug fix on mobile.

## 1.1.0

* Added official Web support using an HTML iframe implementation.
* Removed custom origin headers on web to optimize CORS preflight requests.
* Refactored architecture to strictly separate `dart:io` and `dart:html` compilation.

## 1.0.0

* Initial release of the Geophrase Connect Flutter SDK.
