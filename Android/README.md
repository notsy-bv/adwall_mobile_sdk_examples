# Membrana AdWall SDK for Android

Membrana AdWall is an Android SDK that exchanges access to protected publisher content for a
rewarded ad impression. A publisher-supplied view defines where protection starts; the wall spans
the Activity's content area and extends from that edge through its bottom. Localized text and an
optional logo come from the Membrana settings API, and a gate is never shown unless its rewarded
inventory is already loaded.

The SDK supports Android Views from Kotlin and Java, and Jetpack Compose through the optional
`adwall-compose` module.

## Requirements

- `minSdk` 24 or later, and `compileSdk` 36 or later
- Java 17 or later bytecode target
- A Membrana App ID, supplied by the Membrana team for your application
- A Google Mobile Ads application ID, also supplied by the Membrana team, which you declare in your
  app's `AndroidManifest.xml`

The SDK works with either of Google's Android ad SDKs, which cannot share an app. Pick the
Membrana artifact that matches the one your app uses:

| Artifact | Google SDK |
| --- | --- |
| `media.membrana:adwall-sdk` | Google Mobile Ads (`com.google.android.gms:play-services-ads` 25.5.0) |
| `media.membrana:adwall-sdk-nextgen` | GMA Next-Gen (`com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk` 1.5.0) |

The Google SDK is a transitive dependency, **not** embedded inside a Membrana AAR, so Gradle
resolves a single copy for your app and you can update it independently. No Google Mobile Ads type
appears in the Membrana public API, so your AdWall code is the same with either artifact.

## Install with Gradle

The SDK is published to Maven Central. Google Mobile Ads and AndroidX come from Google's Maven
repository, so keep both repositories in `settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}
```

Then add the SDK to your app module, with exactly one of the two artifacts:

```kotlin
dependencies {
    // With the Google Mobile Ads SDK (play-services-ads):
    implementation("media.membrana:adwall-sdk:1.0.1")
    // Or, with GMA Next-Gen:
    // implementation("media.membrana:adwall-sdk-nextgen:1.0.1")

    // Add only for Jetpack Compose integration.
    implementation("media.membrana:adwall-compose:1.0.1")
}
```

The build fails if both artifacts are present. With GMA Next-Gen, also exclude `play-services-ads`
and `play-services-ads-lite` from any other dependency that brings them, as described in
[Google's Next-Gen migration guide](https://developers.google.com/admob/android/next-gen/migration).
Google's mediation adapters still require `play-services-ads`, so keep `adwall-sdk` if you rely on
them.

Use the published coordinates rather than copying an AAR into `libs/`: the POM and Gradle module
metadata carry the transitive dependencies that a bare AAR loses.

## Configure the host application

Add the Google Mobile Ads application ID supplied by the Membrana team to your manifest:

```xml
<application>
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="YOUR_GMA_APPLICATION_ID" />
</application>
```

Google Mobile Ads reads this ID while your app process starts, before any AdWall call, and stops the
app if it is missing. GMA Next-Gen takes the ID in code instead: `adwall-sdk-nextgen` reads it from
this same entry, which Google's UMP SDK also requires, and `start()` fails without it. See
[Google's Android setup guide](https://developers.google.com/ad-manager/mobile-ads-sdk/android/quick-start).
The Membrana App ID and ad unit IDs are not substitutes for it. The SDK merges the `INTERNET` and
`ACCESS_NETWORK_STATE` permissions into your manifest and requests no runtime permission.

The host application also owns its CMP integration, consent collection and storage, age treatment,
regional rules, advertising identifiers, and Google Mobile Ads request configuration.

Membrana AdWall does not display consent UI and does not own consent state. Finish your privacy and
consent flow before starting the SDK. If consent changes later, see
[Consent changes](#consent-changes); for the data the SDK itself sends, see [Privacy](#privacy).

## Start the SDK

Keep one `AdWall` instance as an application-level dependency and start it after advertising is
permitted:

```kotlin
import media.membrana.adwall.AdWall

class MyApplication : Application() {
    val adWall: AdWall by lazy { AdWall(this, "YOUR_MEMBRANA_APP_ID") }
}

// From an application-scoped coroutine, once your consent flow permits ad requests:
try {
    adWall.start()
} catch (error: AdWallException) {
    // Keep your normal experience; do not install gates.
}
```

`start()` loads Membrana settings, initializes advertising, and begins preparing rewarded demand. It
runs once per process: concurrent and later calls share the same startup, so a screen may call it
to learn when the SDK is ready. Keep navigation interactive while it runs. Cancelling your coroutine
ends only your wait, not the shared startup.

Presentation APIs do not wait for `start()`. A request made before successful startup reports
`NOT_INITIALIZED` once and is not replayed.

From Java, pass a callback that runs on the main thread:

```java
adWall.start(error -> {
    if (error != null) { return; }
    // Startup succeeded; gates may now be installed.
});
```

## Protect content

### Choosing what gets covered

There is no presentation-style flag. The view you pass to `gate` decides whether the wall covers
the whole page or only part of it:

```kotlin
// Whole page: protect the article's complete scrolling container.
adWall.gate(articleScrollView, activity, listener)

// Partial: keep the introduction readable, then cover from this view's top edge
// down to the bottom of the screen.
adWall.gate(protectedTail, activity, listener)
```

The supplied view's position defines where the wall *begins* vertically. The Activity's content
view (`android.R.id.content`) defines the horizontal span and the bottom edge, so coverage always
runs from that boundary through the bottom of the screen. Anything above the boundary stays visible
and interactive.

A few consequences worth knowing:

- An action bar or toolbar outside `android.R.id.content` stays outside the protected region.
- If the boundary you choose leaves too little room for the full dialog, a View gate expands upward
  within your content so the card's controls stay visible. A Compose gate keeps its top edge at the
  measured gate boundary, so allow it enough height; long copy scrolls inside the card.
- A `RecyclerView`, `ScrollView`, or `NestedScrollView` can be gated directly, or through any view
  inside it. No cell tracking, reserved wall height, or scroll listener is needed.
- While a wall is installed, the SDK locks every vertically scrolling View container between the
  protected view and the content view, and the nearest scroll container of any other kind. Outer
  horizontal pagers stay interactive. Locks restore each container's exact earlier state. Compose
  scroll containers are not locked; the wall follows the gate as they scroll.

### Views

Call `gate` once the protected view is attached and measured, for example in `doOnPreDraw`. The
protected view must be a `ViewGroup`.

```kotlin
class ArticleActivity : AppCompatActivity(), AdWallListener {
    private val adWall get() = (application as MyApplication).adWall

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.article)
        val protectedContent = findViewById<ViewGroup>(R.id.protected_content)
        protectedContent.doOnPreDraw {
            adWall.gate(protectedContent, this, this)
        }
    }

    override fun onContentUnlocked(adWall: AdWall) {
        // Reveal the protected content.
    }
}
```

Call `gate` on the main thread: only a main-thread call installs protection before it returns.

### Jetpack Compose

Add `media.membrana:adwall-compose` and wrap the protected content in `AdWallGate`. Like `gate`, it
does not wait for startup, so compose it only once `start()` has succeeded and show your own
protection until then. A gate composed earlier reports `NOT_INITIALIZED` and leaves its content
visible.

```kotlin
@Composable
fun PremiumArticle(adWall: AdWall, article: Article) {
    var started by remember { mutableStateOf(false) }
    LaunchedEffect(adWall) {
        try {
            adWall.start() // Joins the shared startup and returns once the SDK is ready.
            started = true
        } catch (error: AdWallException) {
            // Keep your normal experience; do not compose AdWallGate.
        }
    }

    val listener = remember {
        object : AdWallListener {
            override fun onContentUnlocked(adWall: AdWall) {
                // Access granted. Record it if your app keeps access beyond this screen.
            }

            override fun onContentUnavailable(adWall: AdWall, reason: AdWallUnavailableReason) {
                // No wall: show your fallback or leave the article readable.
            }
        }
    }

    if (started) {
        AdWallGate(adWall = adWall, listener = listener) {
            PremiumArticleContent(article)
        }
    } else {
        ArticlePreview(article) // Your own protection while startup runs.
    }
}
```

`AdWallGate` gates its content once Android has measured it, and hides that content from TalkBack
while the wall is active. It presents once per composition: recomposing it does not present again,
and callbacks go to the latest `listener` you pass. Keep navigation and other public controls
outside `AdWallGate` when they must stay visible and interactive. Apply it to a screen-level
container for whole-page coverage, or to an inline region to keep the content above it visible.

### Java

Every View API has a Java form: `start` and `setDemandEnabled` take main-thread callbacks instead
of suspending, and properties are getters and setters such as `setAppearance` and `setLogLevel`.

```java
public final class ArticleActivity extends AppCompatActivity {
    private final AdWallListener listener = new AdWallListener() {
        @Override
        public void onContentUnlocked(AdWall adWall) {
            // Reveal the protected content.
        }

        @Override
        public void onContentUnavailable(AdWall adWall, AdWallUnavailableReason reason) {
            // No wall: show your fallback or leave the article readable.
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.article);
        AdWall adWall = ((MyApplication) getApplication()).getAdWall();
        ViewGroup protectedContent = findViewById(R.id.protected_content);
        OneShotPreDrawListener.add(protectedContent,
                () -> adWall.gate(protectedContent, this, listener));
    }
}
```

`AdWallListener` methods have default implementations, so Java and Kotlin listeners override only
the callbacks they need. `OneShotPreDrawListener` (AndroidX Core) is the Java counterpart of
`doOnPreDraw`.

### Screen recreation and navigation

- A gate survives ordinary Fragment or view detachment, such as an off-screen pager page or tab.
- When a configuration change recreates your Activity and the rebuilt Activity gates again within
  ten seconds, the same flow continues without another modal-cap use.
- A rewarded ad runs in Google's own Activity and survives recreation of yours, for example when a
  creative rotates the device. Gate again from `onCreate` as usual: the rebuilt wall stays locked
  until the ad finishes, then receives its single outcome.
- Other Activity destruction ends the wall. Outside a configuration change, a Compose gate's wall
  also ends when the gate leaves the composition, as when navigation disposes its screen.

## Appearance

Remote settings own the wall's *content*: title, description, CTA copy, close-button eligibility,
and your brand logo. `AdWallAppearance` only restyles how that content is drawn, so the card can
match your app's design language.

There are three levels, each overriding the one before it:

1. The SDK's own look, which follows your app's light or dark theme and the system font scale.
2. `adWall.appearance`: an instance-level style applied to every wall that instance presents from
   then on.
3. The `appearance` argument of `gate` or `AdWallGate`: styles one presentation only.

```kotlin
val brandAppearance = AdWallAppearance(
    buttonBackgroundColor = Color.rgb(216, 27, 96),
    buttonForegroundColor = Color.WHITE,
    titleTypeface = Typeface.create("sans-serif", Typeface.BOLD),
)

// Every wall this instance presents from now on.
adWall.appearance = brandAppearance

// This presentation only; other calls keep the instance-level appearance.
val promoAppearance = AdWallAppearance(buttonBackgroundColor = Color.rgb(0, 121, 107))
adWall.gate(protectedContent, this, this, promoAppearance)
```

Every property is optional. A color left `null` follows the host's light or dark theme, so
customizing only the CTA keeps the rest of the wall correct in dark mode. The full property set is
`backdropColor`, `cardBackgroundColor`, `titleColor`, `descriptionColor`, `buttonBackgroundColor`,
`buttonForegroundColor`, `closeButtonColor`, `titleTypeface`, `descriptionTypeface`, and
`buttonTypeface`.

Typefaces replace only the face; sizes stay SDK-owned. Text uses a 22sp title, a 17sp description,
and a 17sp semibold CTA, grows with the system font scale, and shrinks together on short screens, to
no less than 65% of its resolved size, so the complete CTA stays reachable. Remote copy is never
ellipsized. The card always spans the content width.

To localize the SDK's own accessibility strings, override `membrana_adwall_close`,
`membrana_adwall_publisher_logo`, and `membrana_adwall_continue_accessibility_label` in your app's
resources.

### Jetpack Compose

```kotlin
AdWallGate(adWall = adWall, appearance = promoAppearance, listener = listener) {
    PremiumArticleContent(article)
}
```

### Java

Java callers use the same constructor, whose parameters follow the property order above. Pass
`null` for a property you leave to the SDK; trailing properties may be omitted.

```java
AdWallAppearance brandAppearance = new AdWallAppearance(
        null,                   // backdropColor
        null,                   // cardBackgroundColor
        null,                   // titleColor
        null,                   // descriptionColor
        Color.rgb(216, 27, 96), // buttonBackgroundColor
        Color.WHITE);           // buttonForegroundColor

// Every wall this instance presents from now on.
adWall.setAppearance(brandAppearance);

// Or this presentation only.
adWall.gate(protectedContent, this, listener, brandAppearance);
```

## Listener callbacks

All callbacks are delivered on the main thread, and every presentation produces exactly one terminal
outcome.

| Callback | Meaning |
| --- | --- |
| `onPresented` | The wall was installed; content is still protected. |
| `onContentUnlocked` | Access to the protected content was granted, including when the rewarded ad was skipped or could not be shown. Terminal. |
| `onContentUnavailable` | No wall can be offered, or an active wall is being removed because advertising was paused. See [Unavailable reasons](#unavailable-reasons). Terminal. |
| `onFailure` | A technical failure not represented by an unavailable reason. Terminal. An ad that cannot be shown unlocks instead, so no presentation path reports this today. |

Apart from the configuration-change continuation above, the SDK does not remember unlocks. Your app
decides whether access granted by `onContentUnlocked` survives navigation, a later visit, or an app
restart.

### Skipped rewarded ads unlock

> **Behavior change in 1.0.1, source-breaking.** Closing the rewarded ad before the reward now
> unlocks the content: the wall is removed and your listener receives `onContentUnlocked`, exactly
> as after a full watch. In 1.0.0 the wall stayed with its button and cross disabled and reported
> `onContentRejected`; that callback has been removed. Delete any override of it and treat
> `onContentUnlocked` as the only access grant.

The skipped ad still counts as one rewarded impression for capping.

### Ad errors unlock

An advertising error never keeps the reader from the content. If the rewarded ad is no longer
available when the user taps the button, or Google Mobile Ads fails to show it, the wall is removed
and your listener receives `onContentUnlocked` once, exactly as for a skipped ad. No error or
fallback screen replaces your content. An impression Google Mobile Ads confirmed before the error
still counts against the rewarded cap. This changed in 1.0.1; 1.0.0 kept the wall and reported
`onFailure` or `onContentUnavailable(REWARDED_AD_NOT_READY)` instead.

### Unavailable reasons

`onContentUnavailable` reports an expected condition, not an error. Leave the content as it is or
show your own fallback experience.

| Reason | Meaning |
| --- | --- |
| `NOT_INITIALIZED` | `start()` has not completed successfully. The request is not replayed after startup. |
| `NOT_ALLOWED` | A frequency cap currently blocks the wall. |
| `REWARDED_AD_NOT_READY` | No fresh rewarded ad is loaded, so the SDK intentionally showed no wall. |
| `AD_SERVING_PAUSED` | Advertising is turned off with `setDemandEnabled(false)`. Also reported to an active wall just before the SDK removes it; see [Consent changes](#consent-changes). |
| `ALREADY_PRESENTING` | This instance already has an active wall. |
| `INVALID_HOST` | The protected view is missing, destroyed, outside the Activity hierarchy, or has no usable bounds. |
| `PRESENTATION_FAILED` | Android could not attach or open the requested presentation. |
| `DEMAND_UNAVAILABLE` | Deprecated; the SDK reports `REWARDED_AD_NOT_READY` instead. |

For `NOT_ALLOWED` and `REWARDED_AD_NOT_READY`, remove any temporary cover and leave the article
readable: the wall is skipped for that visit, and the SDK prepares demand for a later one.

For status UI or diagnostics, `adWall.availability` returns a read-only, main-thread snapshot:
`NOT_INITIALIZED`, `AD_SERVING_PAUSED`, `NOT_ALLOWED`, `REWARDED_AD_NOT_READY`, `PRESENTING`, or
`READY`. Caps, ad freshness, and view attachment can change before the next `gate` call, so that
call's callback remains authoritative.

### Errors

`start()` throws, and `onFailure` receives, an `AdWallException`. Its `code.value` is stable across
releases and matches the iOS SDK's error codes.

| Value | `AdWallException.Code` | Meaning |
| --- | --- | --- |
| 1 | `INVALID_CONFIGURATION` | Missing App ID, or startup conflicts with an existing initialization. |
| 2 | `INITIALIZATION_FAILED` | Settings could not be loaded or advertising could not start. The message states the reason. |
| 3 | `PRESENTATION_FAILED` | An accepted ad could not be presented. |
| 4 | `INTEGRATION_TESTING_UNAVAILABLE` | Integration testing was enabled in a non-debuggable app. |
| 5 | `INVALID_INTEGRATION_TEST_OPTIONS` | Integration-test options are malformed. |
| 6 | `INTEGRATION_TESTING_EXECUTION_MODE_CONFLICT` | Production and integration-test instances in one process. |
| 8 | `INTEGRATION_TESTING_ALREADY_INITIALIZED` | Integration testing was enabled after startup began. |
| 9 | `MAIN_THREAD_REQUIRED` | A synchronous integration-test command ran off the main thread. |

`error.message` carries a human-readable explanation suitable for logs. For an expected outcome,
branch on the [unavailable reason](#unavailable-reasons) instead; most integrations only log
`onFailure`.

## Consent changes

Membrana AdWall does not read consent state. When your CMP or privacy flow decides that advertising
must stop, tell the SDK:

```kotlin
adWall.setDemandEnabled(false)
```

The SDK reports `AD_SERVING_PAUSED` to the active wall's listener, then removes its overlay,
discards loaded ads, cancels its preloads, and starts no further ad requests or presentations; later
`gate` calls report `AD_SERVING_PAUSED`. The setting applies to every `AdWall` instance in the
process, not only the one you call.

> **Cover protected content yourself in the `AD_SERVING_PAUSED` callback.** The SDK removes its own
> coverage right after reporting it, so install your fallback synchronously in that callback.

When advertising may resume, first update your CMP and Google Mobile Ads request configuration,
then re-enable demand through any instance:

```kotlin
adWall.setDemandEnabled(true)
```

The SDK then preloads one fresh ad per configured format, shared by every started instance. If
Google Mobile Ads cannot start again, the call throws `AdWallException` and advertising stays
paused, so a later call can retry.

- `start()` throws while advertising is turned off. If you turn it off while `start()` is still
  running, that startup fails; re-enabling does not resume it, so call `start()` again.
- `setDemandEnabled` only tells the SDK whether it may use advertising. It is not a consent signal
  and is not forwarded to Google Mobile Ads; pass consent to Google Mobile Ads through your CMP as
  usual.

From Java, the completion runs on the main thread. It has no error argument, so check
`availability` after enabling:

```java
adWall.setDemandEnabled(false, () -> {
    // Loaded ads are discarded and SDK ad activity has stopped.
});
```

## Privacy

The SDK makes two kinds of request to Membrana, both over HTTPS:

- **Settings**, from `mobile-app-sdk.membrana.media` at startup: your Membrana App ID, an
  SDK-generated installation identifier and a bucket number derived from it, the SDK and app
  versions, and the platform.
- **Analytics events**, to `track-events.membrana.media`, describing eligible page views, ad
  requests and responses, wall displays, and taps on the wall's buttons: the same app, installation,
  and version fields, plus a session identifier, the ad unit, the experiment and configuration
  identifiers and country from the settings response, ad response timing, and a first-show flag.
  They contain no article text, content identifiers, email addresses, raw advertising IDs, or
  consent status.

The installation identifier is a random UUID that the SDK creates and stores in app-private
`SharedPreferences`. It is not the advertising ID or `ANDROID_ID`. The SDK also keeps capping
history in `SharedPreferences` and caches your brand image in the app's cache directory.

Reflect this data in your app's Google Play Data safety form, together with what Google Mobile Ads,
any mediation adapters, your CMP, and your own code collect. Before release, exercise consent
withdrawal and confirm that `setDemandEnabled(false)` leaves your own locked content in place.

## Integration testing

Integration testing runs the real presentation path with Google test demand, a capping history
isolated from production, and analytics HTTP delivery suppressed by default. On Android it works only
in a debuggable app; in any other build `enableIntegrationTesting` throws `AdWallException` with
code 4.

> **Remove or disable `enableIntegrationTesting()` before shipping to production.** It changes ad
> configuration and capping behavior and suppresses analytics delivery.

Enable it on the main thread, on the same application-scoped instance, **before** `start()`.
Integration and production execution cannot coexist in one process, and the call throws if the
instance has already begun startup.

### Shortest smoke test

Google's official test ad units, capping disabled so the wall can present repeatedly:

```kotlin
val adWall = AdWall(context, "YOUR_MEMBRANA_APP_ID")

if (BuildConfig.DEBUG) {
    adWall.enableIntegrationTesting()
}

adWall.start()
```

### Test demand and capping options

```kotlin
val options = IntegrationTestOptions(
    ads = TestAds.custom("YOUR_TEST_REWARDED_UNIT", "YOUR_TEST_INTERSTITIAL_UNIT"),
    capping = TestCapping.accelerated(0.01),
    testDeviceIds = listOf("GMA_LOGCAT_DEVICE_ID"),
)

adWall.enableIntegrationTesting(options)
adWall.start()
```

- `ads`: `TestAds.googleTestAds()` (default) or `TestAds.custom(rewarded, interstitial)` for your
  own Google Ad Manager test inventory. The rewarded unit is required; pass `null` for no
  interstitial.
- `capping`: `TestCapping.disabled()` (default), `TestCapping.useRemote()` to keep configured
  durations in isolated test storage, or `TestCapping.accelerated(scale)` to multiply them by a value
  greater than 0 and at most 1.
- `testDeviceIds`: emulators are test devices automatically. For a physical device, make one ad
  request and copy the identifier Google Mobile Ads prints to Logcat. Mediated networks may each need
  their own test mode as well.
- `resetStoredCapping`: `true` by default. Pass `false` when a QA run must keep its isolated capping
  history across launches.
- `settingsJson`: an app-owned copy of the settings response, accepted only in integration-testing
  mode, validated before startup, and never persisted. Production apps should not ship a fallback
  payload.
- `sendsAnalyticsRequests`: `false` by default. Setting it to `true` posts test-session events to
  Membrana's real analytics endpoint; enable it only when real delivery is the behavior under test.

### Inspect capping state during QA

After startup, an integration-test session can read the exact local capping state behind the next
decision:

```kotlin
adWall.integrationTestCappingSnapshot()?.let { snapshot ->
    Log.d("AdWallQA", "${snapshot.isWallAllowed} ${snapshot.nextWallPresentationAtMillis}")
    Log.d("AdWallQA", "${snapshot.modal?.remainingCount} ${snapshot.rewarded?.remainingCount}")
}
```

The snapshot reports the `modal`, `rewarded`, and `closeButton` caps separately, each with its used,
remaining, and limit counts, its rolling-window duration, and when it next allows a presentation. A
`null` value means that cap is disabled, and `closeButton` also does not apply when
`isCloseButtonApplicable` is `false`. Accelerated mode reports the scaled durations.

`integrationTestCappingSnapshot()` returns `null` for production sessions and before
integration-test startup completes. `resetIntegrationTestCappingHistory()` clears only the isolated
test history and returns `false` outside integration-testing mode. Production capping history is
never exposed or cleared by these diagnostics.

### Java

`enableIntegrationTesting()` with no argument is the shortest smoke test, as in Kotlin. For explicit
options, the `IntegrationTestOptions` constructor takes them in the order listed above, and
trailing ones may be omitted:

```java
if (BuildConfig.DEBUG) {
    adWall.enableIntegrationTesting(new IntegrationTestOptions(
            TestAds.custom("YOUR_TEST_REWARDED_UNIT", "YOUR_TEST_INTERSTITIAL_UNIT"),
            TestCapping.accelerated(0.01),
            Collections.singletonList("GMA_LOGCAT_DEVICE_ID")));
}

adWall.start(error -> {
    if (error != null) { return; }
    IntegrationTestCappingSnapshot snapshot = adWall.integrationTestCappingSnapshot();
    if (snapshot != null && snapshot.getRewarded() != null) {
        Log.d("AdWallQA", "Rewarded remaining: " + snapshot.getRewarded().getRemainingCount());
    }
});
```

## Logging

Console output defaults to errors only. Change the level when integration diagnostics are needed:

```kotlin
adWall.logLevel = AdWallLogLevel.INFO   // lifecycle, presentation, reward, warnings, errors
adWall.logLevel = AdWallLogLevel.DEBUG  // all SDK logs, including capping and preload details
adWall.logLevel = AdWallLogLevel.NONE   // no SDK console output
```

A failed `start()` logs its reason at `ERROR`, and the thrown `AdWallException` carries the same
message. Logs identify SDK requests without naming Membrana hosts or endpoints.

## Examples

Complete Views (Kotlin, with a Java callback bridge) and Jetpack Compose integrations live in the
[`Android/`](https://github.com/notsy-bv/adwall_mobile_sdk_examples/tree/main/Android) folder of
`notsy-bv/adwall_mobile_sdk_examples`. Open that folder in Android Studio and run `demo-views` or
`demo-compose`. Each example offers a whole-page, a partial-page, and a branded wall, and is
commented as publisher integration steps 1–5 in `DemoApplication.kt` and the article screen.

The examples request the live `membrana-media-demo` settings with Google's sample Google Mobile Ads
application ID. A second Membrana-owned example App ID, `membrana-media-demo-rewarded-only`, shows a
wall whose only way past the gate is the rewarded ad; switching is a one-line edit in
`DemoApplication.kt`, which also carries a commented integration-testing call. Replace both IDs with
the ones supplied for your application.

The examples use `adwall-sdk`, with the Google Mobile Ads SDK. To run them on GMA Next-Gen, replace
`adwall-sdk` with the commented `adwall-sdk-nextgen` line in the module's `build.gradle.kts`; the code
stays the same.

## Support

Contact the Membrana team with the SDK version, Android version, device model, and your Membrana
App ID.

## License

Proprietary. All rights reserved. Use is governed by your agreement with Membrana Media.
