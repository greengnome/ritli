# Ritli privacy release audit

Reviewed September 7, 2026, against local commit `ac56de3` plus the uncommitted Release debug-hook fix. This is source and archive evidence, not an App Store Connect declaration or a network-capture test.

## Result

The current app uses local storage and Apple system frameworks. The inspected source and project contain no app-server requests, third-party packages, advertising SDK, analytics SDK, tracking permission request, or CloudKit entitlement. The privacy manifest declares no tracking or collected data and declares the app's UserDefaults access.

The public-policy requirement is **incomplete**: `RITLI_PRIVACY_POLICY_URL` is empty, so Settings does not display a Privacy Policy link. A draft is available in [Privacy-Policy-Draft.md](Privacy-Policy-Draft.md). It is not ready to publish until the owner/contact/support fields are completed and the hosting practices are checked.

## Evidence

| Area | Current behavior | Source |
| --- | --- | --- |
| Local database | SwiftData stores categories, tasks, routines, settings, session records, and timer cycle state. No app-owned synchronization is configured. | `Ritli/Persistence/AppModelContainer.swift`; `Ritli/Domain/Models/` |
| Onboarding | Reads/writes the app's own completion preference. Test overrides are Debug-only. | `Ritli/Features/Onboarding/OnboardingStore.swift` |
| Notifications | Local requests contain generic focus/break text and a session UUID. No task name or notes are put in notification content. | `Ritli/Services/Notifications/LocalTimerNotificationScheduler.swift` |
| Live Activities | Supplies timer state and, only when enabled, the task title to ActivityKit. Task-name visibility defaults to false. No push token is requested. | `Ritli/Services/LiveActivities/`; `Ritli/Domain/Models/PomodoroSettings.swift` |
| Task deletion | Archiving retains the task; deleting an archived task nullifies its session relationship. History is retained. | `Ritli/Features/Tasks/ArchivedTasksView.swift`; `Ritli/Domain/Models/FocusTask.swift` |
| History deletion | Deletes terminal sessions and preserves tasks, preferences, and running/paused sessions. | `Ritli/Features/Settings/FocusHistoryCleaner.swift` |
| External links | HTTPS-only links loaded from ReleaseLinks.plist. A missing/invalid URL hides the corresponding Settings link. | `Ritli/Features/Settings/AppExternalLinks.swift`; `SettingsView.swift` |
| Support | Configured GitHub issues page returned HTTP 200 without authentication on September 7. Posting an issue requires a GitHub account; a private contact is not configured. | `Ritli/ReleaseLinks.plist`; `https://github.com/greengnome/ritli/issues` |
| Manifest | Confirmed present in the unsigned Release archive. No tracking domains or collected data types; UserDefaults reason CA92.1. | `Ritli/PrivacyInfo.xcprivacy` |

## App Store Connect preparation

The source audit supports a provisional **Data Not Collected** answer for the app's local task/timer features. Apple excludes data processed only on the device from its collection definition. The owner must also account for actual support handling, diagnostics received from Apple, and any services added before submission. A source search alone cannot establish those operational practices. [Apple's App Privacy guidance](https://developer.apple.com/app-store/app-privacy-details/)

No ATT prompt is implemented or needed for the current nontracking behavior. Revisit this if tracking is introduced. [Apple's user privacy and data use guidance](https://developer.apple.com/app-store/user-privacy-and-data-use/)

Apple requires an accessible privacy-policy link both in the app and in App Store Connect, with data use and retention/deletion explained. Keep the publication and URL checklist items open until both locations work. [App Review Guideline 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy)

The draft distinguishes local app storage from device backup: iCloud Backup can include downloaded apps' data. Do not publish an absolute claim that data can never leave the device. [Apple's backup explanation](https://support.apple.com/en-ie/108770)

The draft also distinguishes deleting the app from offloading it: offloading preserves its documents and data. [Apple's storage guidance](https://support.apple.com/en-us/108429)

## Remaining steps

1. Supply the legal owner, a monitored private contact, and actual support-message retention/deletion practices. Confirm whether the developer receives or uses Apple-provided diagnostics or analytics and update the policy if needed.
2. Choose the public policy URL and check its hosting, logs, and analytics before publishing. The draft currently covers the app, not an unspecified website's data practices.
3. Publish the completed policy, set `RITLI_PRIVACY_POLICY_URL` in `Ritli/ReleaseLinks.plist`, and enter the same URL in App Store Connect.
4. Build the release candidate and verify Settings → About → Privacy Policy opens the public page without authentication. Verify Support as well.
5. Review the final privacy answers, generate the archive's privacy report in Xcode, and validate the signed archive. The existing unsigned archive does not prove App Store Connect acceptance.
