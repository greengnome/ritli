# Release validation — September 7, 2026

Scope: commit `ac56de3` plus the local Release debug-hook gates, Home Dynamic Type layout changes, and regression tests. The changes were uncommitted during this September 7 validation; consult Git history for the subsequent preparation commit. Draft policy and store metadata are not published or submitted.

## Supported-device target

The owner’s target support starts with **iPhone 14 and newer**. The existing **iOS 17.0 minimum** is unchanged. Required release coverage includes the base iPhone 14 (without Dynamic Island), a Pro model with Dynamic Island, and a large Plus/Pro Max layout. Verify the minimum supported OS and a current OS across this matrix. Six targeted Debug UI checks passed on iPhone 14 / iOS 18.1 Simulator. Physical iPhone 14 and iOS 17 validation remain pending.

Previous iPhone SE runs are supplementary small-screen stress tests, outside the target device matrix. They do not make SE the minimum supported model.

This is a product support and testing target, not an enforced installation cutoff. Apple filters hardware compatibility through [required device capabilities](https://developer.apple.com/support/required-device-capabilities/), rather than an arbitrary minimum iPhone model setting. The current iOS 17 deployment target can also allow installation on older iPhones. No artificial hardware requirement or runtime model block was added.

## Verified locally

| Check | Result |
| --- | --- |
| Unsigned iOS Release archive | Passed for Ritli and its Live Activity extension. |
| Release debug behavior | UI-test storage/notification, onboarding, tab, and splash overrides are gated by DEBUG. No UI-test argument strings remain in either archived executable. |
| Release compiler and bundle | Optimized whole-module compilation, no DEBUG/testability, no test bundles, debug dylibs, or linked sanitizer/test libraries in the inspected archive. |
| Debug unit suite | 148 tests in 48 suites passed. |
| Debug startup UI regression | 3 tests passed; these also passed as part of the subsequent full suite. |
| Release startup regression | 4 tests in 2 suites passed. These test onboarding persistence and ignored onboarding/splash override arguments. Testability was enabled only for this separate simulator test build, not the archive. |
| Full Debug UI suite | 28 tests passed on iPhone 17 Pro / iOS 26.5 Simulator: 24 flow tests plus 4 launch configurations. Includes tasks/routines, history clearing, timer pause/resume, settings, English/Ukrainian flows, and Live Activity expansion in SpringBoard. |
| iPhone 14 baseline | 6 targeted Debug UI tests passed together on iOS 18.1: onboarding persistence, task creation/completion, normal and largest-text timer controls, Ukrainian Settings, and Ukrainian tasks with the keyboard open. This is targeted simulator coverage, not the full suite or physical-device validation. |
| App icon | Source PNG is 1024 × 1024 with no alpha channel. |
| Archived identifiers | `com.kirill.Ritli` and `com.kirill.Ritli.LiveActivity`; both version 1.0, build 1, iPhone only, minimum iOS 17.0. |
| Privacy manifest | Present in the app archive; no tracking or collected data, UserDefaults reason CA92.1. See Privacy-Audit.md for scope and remaining work. |
| Public support page | Configured GitHub issues URL returned HTTP 200 without authentication. |
| Development-signed Release archive | Archive succeeded; app and extension use Apple Development signing with `get-task-allow = true`. Deep/strict signature verification passed. This does not validate App Store distribution signing or export. |
| App Store distribution export | Failed (exit 70). Xcode could not authenticate an App Store Connect provider and found no distribution profiles for either bundle ID. The attempt used `destination = export`, with no upload or provisioning-update option. |
| Signing identities | System-keychain check found 2 Apple Development identities and no local Apple Distribution identity. The earlier sandbox-limited zero-identity result was incomplete. |
| Draft store text | English and Ukrainian names/subtitles, promotional text, descriptions, and UTF-8 keyword byte lengths are within the checked limits. Name availability and owner choices are unverified. |

The first full UI invocation failed before any test ran because Simulator refused the runner launch as busy. After confirming that process had ended and the simulator was shut down, the simulator was explicitly booted; the same full suite then passed. No failing product assertion was bypassed or test skipped in the successful full run.

## Local evidence

- iPhone 14 passing test log: `/tmp/ritli-iphone14-baseline-fixed.log`
- iPhone 14 passing result bundle: `/tmp/ritli-iphone14-baseline-fixed.xcresult`
- iPhone 14 initial failure log: `/tmp/ritli-iphone14-baseline.log`
- Latest unsigned archive, including the Home accessibility fix: `/tmp/ritli-release-accessibility.xcarchive`
- Latest archive log: `/tmp/ritli-release-accessibility-archive.log`
- Development-signed archive: `/tmp/ritli-release-signed-check.xcarchive`
- App Store export attempt log: `/tmp/ritli-app-store-export-check.log`
- App Store export options: `/tmp/ritli-app-store-export-options.plist`
- Development-signed archive log: `/tmp/ritli-release-signed-check.log`
- Earlier debug-hook archive: `/tmp/ritli-release-gated.xcarchive`
- Archive log: `/tmp/ritli-release-gated-archive.log`
- Unit/startup test log: `/tmp/ritli-startup-debug-tests.log`
- Release startup test log: `/tmp/ritli-startup-release-tests.log`
- Full UI test log: `/tmp/ritli-release-full-ui-retry.log`
- Supplementary iPhone SE full run: `/tmp/ritli-se-final-ui-tests.log`
- Final iOS 26 largest-text and Settings checks: `/tmp/ritli-accessibility-ios26-final.log`
- Final supplementary iPhone SE Settings rerun: `/tmp/ritli-se-version-final.log`
- Full UI result bundle: `/tmp/ritli-startup-tests/Logs/Test/Test-Ritli-2026.09.07_15-09-49-+0300.xcresult`

These temporary paths can be cleaned by the system. Preserve final signed candidate artifacts and CI results separately when freezing the release.

## Home accessibility follow-up

A largest-Dynamic-Type check reproduced a truncated task prompt, clipped category icon, and timer-mode text wrapping inside the horizontal header. Home now stacks its task content, timer header/controls, and summary at accessibility sizes. The primary control grows to fit its label; the timer readout uses the full card width. Decorative icons fit their fixed badges. Normal text sizes keep the horizontal layout.

Visual evidence: [iPhone 14 timer controls](evidence/iphone14-largest-text-controls.png), [before](evidence/home-largest-text-before.png), [after](evidence/home-largest-text-after.png), and [iPhone SE timer controls](evidence/iphone-se-largest-text-controls.png).

The added largest-text UI test passed on both iPhone SE / iOS 18.1 and iPhone 17 Pro / iOS 26.5, exercising start, pause, resume, and cancel. The final Ukrainian Settings visibility test also passed on both runtimes. An updated unsigned archive passed and again contained no UI-test argument strings. The full SE run passed 27 of 28 cases; the remaining Settings Version check passed in a final targeted rerun after its visibility assertion was corrected. All 28 covered cases therefore pass across those runs, rather than one final all-green invocation. The Dynamic Island test was excluded on SE because that device lacks Dynamic Island; it passed in the earlier iPhone 17 Pro run. These checks do not constitute a full VoiceOver, contrast, or Dynamic Type audit of every screen.

The initial small-screen run found two test limitations: whole-screen swipes could hit the keyboard, and the Settings Version check did not scroll far enough for the title. On iOS 18 the read-only title is covered by a combined title/value accessibility element, so the corrected check verifies the exact Ukrainian title and its unobscured screen bounds instead of requiring it to be tappable. The scroll helper now targets the largest visible scroll container, avoids the keyboard, and can scroll in either direction. Localized content and interaction assertions remain in place.

The initial iPhone 14 largest-text run exposed another test-helper limitation: XCTest reported Pause as hittable while its center lay behind the navigation bar. The helper now excludes navigation and tab bars from the visible scroll area and requires the tap point to be inside it. The six targeted iPhone 14 checks then passed in one invocation. Product timer code was unchanged for this correction.

CI now includes the two Release startup test suites, with testability enabled only for the separate simulator test build. Its YAML parses and its command passes a local shell syntax check; the updated workflow has not yet run remotely.

## Screenshot preparation

Six screenshot drafts (three English and three Ukrainian) are available in [the local gallery](screenshots/index.html). They show the running task-linked timer, three fictional sample tasks, and timer settings. Captured from the current Debug app on iPhone 17 Pro Max / iOS 26.5, with explicit English/Ukrainian language arguments and a normalized status bar. The fictional task titles were localized through the app’s editor. All six were visually inspected and verified as 1320 × 2868 JPEGs without alpha, an accepted size in [Apple’s screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/). No app UI was composited or altered. Notifications were declined in this simulator. These files are not uploaded; selection review and comparison with the final signed candidate remain pending.

## Still required for release readiness

- Review the committed code changes and run CI on the exact release candidate. Historical CI for `9bc04a8` does not validate the current changes.
- Verify the iPhone 14-and-newer target matrix on physical devices, including iOS 17, base iPhone 14, Dynamic Island and large Plus/Pro Max layouts, Dynamic Type, VoiceOver, sound/haptics, notification permissions/delivery, lock/unlock, app termination, and Live Activity cleanup. The iOS 26.5 simulator results do not cover that matrix.
- Validate a fresh installation and an upgrade of the signed candidate through TestFlight, including persistent data and background timer restoration.
- Configure the correct owner-provided release team and its App Store Connect access, configure distribution signing/profiles for both bundle IDs, then repeat App Store export and validate the final signed package. The local export attempt failed on provider authentication and missing profiles; a local Apple Distribution identity is also absent. The owner confirmed that `YY9396KB75` is not the intended release team and will provide the correct team ID. The project has not been changed to an unverified replacement; rebuild the archive after configuring the correct team.
- Finalize and publish the privacy policy, configure its public URL in the app and App Store Connect, and verify the in-app link. Complete owner/contact/support details and review App Privacy answers.
- Complete metadata choices, required screenshots, business/account declarations, App Review contact, and release-candidate selection in App Store Connect. Draft files are preparation, not submitted metadata.

Continue tracking the full release in [App-Store-Release-Checklist.html](../App-Store-Release-Checklist.html).
