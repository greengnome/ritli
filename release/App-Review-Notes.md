# Ritli App Review notes — draft

Paste the text below into App Store Connect's Review Notes after verifying it against the signed release candidate. Enter the review contact's name, email, and phone in App Store Connect's separate contact fields.

---

Ritli is an iPhone focus timer with local task planning, configurable focus/break routines, and session statistics. No login, account, subscription, or external hardware is needed to access its features.

On first launch, complete the three onboarding pages. The Home tab provides a focus timer. Tap Start focus, then Pause or Resume to exercise the main controls. Settings provides timer durations; the focus duration can be shortened to 5 minutes for review. Short breaks can be set to 1 minute.

Notification permission is optional. Ritli schedules local notifications for the end of a timer; denying permission does not prevent use of the timer or tasks. Notification sound also depends on the user's iOS settings. Timer state is stored locally and reconciled when the app returns to the foreground; the app does not require continuous background execution.

To review the Live Activity, start a timer and leave the app or lock the iPhone. On a compatible device with Live Activities allowed, iOS displays timer information on the Lock Screen and Dynamic Island. Task names are hidden by default. To test the optional display of a task name, create and select a task, then enable Settings → Privacy → Show task names on Lock Screen. Turning this setting off hides the task name again.

The Tasks tab supports task creation, completion, custom timer routines, and archiving. Archived Tasks allows restoration or deletion. The Stats tab shows period-based statistics and session history. Statistics are initially empty on a fresh install. Settings → Data → Clear focus history removes recorded sessions while keeping tasks, preferences, and any active timer.

English and Ukrainian are included. The language control in Settings opens iOS app settings.

---

## Before submitting

- Install and verify the signed release candidate through TestFlight, including real-device notification, haptic, and Live Activity behavior.
- Publish the privacy policy and verify its link in Settings → About. Do not claim the policy is accessible until this is complete.
- Supply a monitored review contact in App Store Connect. No demo credentials are required for the current app.
