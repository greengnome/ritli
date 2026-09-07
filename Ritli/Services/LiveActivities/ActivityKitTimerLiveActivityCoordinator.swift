import ActivityKit
import Foundation

@MainActor
final class ActivityKitTimerLiveActivityCoordinator: TimerLiveActivityCoordinating {
    private typealias TimerActivity = Activity<TimerLiveActivityAttributes>

    private var currentActivity: TimerActivity?
    private var pendingOperation: Task<Void, Never>?
    private var expirationTask: Task<Void, Never>?

    func synchronize(with descriptor: TimerLiveActivityDescriptor?) {
        guard let descriptor else {
            endAllActivities()
            return
        }

        let activities = knownActivities
        if let matchingActivity = activities.first(where: {
            $0.attributes.sessionID == descriptor.attributes.sessionID
        }) {
            currentActivity = matchingActivity
            end(activities.filter { $0.id != matchingActivity.id })
            update(matchingActivity, with: descriptor.contentState)
            scheduleExpiration(
                of: matchingActivity,
                for: descriptor.contentState
            )
            return
        }

        currentActivity = nil
        end(activities)

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            currentActivity = try TimerActivity.request(
                attributes: descriptor.attributes,
                content: content(for: descriptor.contentState)
            )
            if let currentActivity {
                scheduleExpiration(
                    of: currentActivity,
                    for: descriptor.contentState
                )
            }
        } catch {
            currentActivity = nil
        }
    }

    private var knownActivities: [TimerActivity] {
        var activitiesByID = Dictionary(
            uniqueKeysWithValues: TimerActivity.activities.map { ($0.id, $0) }
        )

        if let currentActivity {
            activitiesByID[currentActivity.id] = currentActivity
        }

        return Array(activitiesByID.values)
    }

    private func update(
        _ activity: TimerActivity,
        with state: TimerLiveActivityAttributes.ContentState
    ) {
        let activityContent = content(for: state)
        enqueue {
            await activity.update(activityContent)
        }
    }

    private func endAllActivities() {
        expirationTask?.cancel()
        expirationTask = nil
        let activities = knownActivities
        currentActivity = nil
        end(activities)
    }

    private func end(_ activities: [TimerActivity]) {
        guard !activities.isEmpty else { return }

        enqueue {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func enqueue(
        _ operation: @escaping @MainActor () async -> Void
    ) {
        let previousOperation = pendingOperation
        pendingOperation = Task { @MainActor in
            await previousOperation?.value
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    private func content(
        for state: TimerLiveActivityAttributes.ContentState
    ) -> ActivityContent<TimerLiveActivityAttributes.ContentState> {
        ActivityContent(
            state: state,
            staleDate: TimerLiveActivityPresentation.expirationDate(for: state)
        )
    }

    private func scheduleExpiration(
        of activity: TimerActivity,
        for state: TimerLiveActivityAttributes.ContentState
    ) {
        expirationTask?.cancel()
        expirationTask = nil

        guard let endDate = TimerLiveActivityPresentation.expirationDate(
            for: state
        ) else {
            return
        }

        expirationTask = Task { @MainActor [weak self] in
            let delay = max(0, endDate.timeIntervalSinceNow)
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }

            guard
                !Task.isCancelled,
                self?.currentActivity?.id == activity.id
            else {
                return
            }

            await activity.end(
                self?.content(for: state),
                dismissalPolicy: .immediate
            )
            self?.currentActivity = nil
            self?.expirationTask = nil
        }
    }
}
