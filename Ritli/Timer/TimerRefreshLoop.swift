import Foundation

/// Polls the engine once per interval while the app is in the foreground.
///
/// The first pass after (re)activation catches up silently: a session that
/// ended while the app was away already alerted through its notification.
/// That pass also re-applies the Live Activity, in case a request failed
/// while the app was in the background. A failing refresh is reported once
/// per failure streak rather than every second.
@MainActor
struct TimerRefreshLoop {
    var interval: Duration = .seconds(1)
    var sleep: @MainActor (Duration) async throws -> Void = { duration in
        try await Task.sleep(for: duration)
    }

    func run(
        engine: TimerEngine,
        onError: @MainActor (Error) -> Void
    ) async {
        var isFirstPass = true
        var hasReportedFailure = false

        while !Task.isCancelled {
            do {
                try engine.refresh(catchingUp: isFirstPass)
                hasReportedFailure = false
            } catch {
                if !hasReportedFailure {
                    hasReportedFailure = true
                    onError(error)
                }
            }

            if isFirstPass {
                isFirstPass = false
                engine.resynchronizeLiveActivity()
            }

            do {
                try await sleep(interval)
            } catch {
                return
            }
        }
    }
}
