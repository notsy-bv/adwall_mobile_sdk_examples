# MembranaAdWall examples

This repository contains customer-facing iOS and Android integrations for MembranaAdWall SDK. Each
platform owns a top-level directory: `iOS/` and `Android/`.

## iOS

1. Open `iOS/MembranaAdWallDemo.xcodeproj`.
2. Select the `DemoUIKit`, `DemoSwiftUI`, or `DemoObjC` scheme. The matching folder beside the project owns that target's models and sample content.

Each example is commented as publisher integration steps 1-5, from creating the SDK instance
through granting access in the unlock callback. Follow them in order to see the whole flow.

The apps request the live `membrana-media-example` settings. A second Membrana-owned example App ID,
`membrana-media-example-rewarded-only`, is available for a wall whose only way past the gate is the
rewarded ad; each example carries it as a commented line beside the active one, so switching is a
one-line edit. Publishers replace both with the App ID supplied for their application. Settings
content, placement, and ad-unit selection remain SDK-owned.

Every example also carries a commented **test integration** block next to step 1. Uncommenting it
enables `enableIntegrationTesting`, which runs the SDK against Google's dedicated test ad units and
a capping ledger isolated from production, so no real inventory is requested and production capping
history is untouched. Remove or disable that call before shipping: it changes ad configuration and
capping behavior and suppresses analytics delivery by default.

`DemoUIKit` sets `adWall.logLevel = .debug` in Debug builds before calling `start()`. Run the app
from Xcode and filter the debug console for the `media.membrana.adwall.sdk` subsystem to inspect
settings requests, retries, capping, ad preloading, and presentation activity. The SDK defaults to
`.error`; publishers should enable broader logging only when they intentionally need diagnostics.

The host application must finish its privacy and consent flow before calling `start()`.
MembranaAdWall does not display consent UI or own consent state.

The example plists are intentionally not production templates. The demos do not request App
Tracking Transparency, so they omit `NSUserTrackingUsageDescription`; a publisher must add that
description if its own consent flow requests tracking, and keep every declaration aligned with the
app's actual GMA and mediation setup.

Each example does ship Google's `SKAdNetworkItems` list so it can be copied as a starting point.
Google maintains the canonical list and adds buyers to it over time, so re-check it against
[Prepare privacy strategies](https://developers.google.com/ad-manager/mobile-ads-sdk/ios/privacy/strategies) when you update Google Mobile Ads rather than trusting the
copy committed here.

The `iOS/` sources and committed Xcode project are synchronized from the private SDK repository. The project resolves MembranaAdWall SDK from [`notsy-bv/adwall_mobile_sdk_ios_resources`](https://github.com/notsy-bv/adwall_mobile_sdk_ios_resources). The iOS synchronization leaves Android example directories untouched.
