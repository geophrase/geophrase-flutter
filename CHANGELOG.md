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
