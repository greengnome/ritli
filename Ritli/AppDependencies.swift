import SwiftData

@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let timerEngine: TimerEngine
    let notificationPermissionService: NotificationPermissionService

    static func live(
        inMemory: Bool = false,
        notificationsEnabled: Bool = true
    ) throws -> AppDependencies {
        let container = try AppModelContainer.make(inMemory: inMemory)
        let context = container.mainContext
        let settings = try fetchOrInsert(PomodoroSettings.self, in: context) {
            PomodoroSettings(notificationsEnabled: notificationsEnabled)
        }
        let cycleState = try fetchOrInsert(PomodoroCycleState.self, in: context) {
            PomodoroCycleState()
        }
        try DefaultFocusCategories.seedIfNeeded(in: context)
        let notificationCenter = SystemUserNotificationCenterClient()
        let permissionService = NotificationPermissionService(
            center: notificationCenter
        )
        let engine = TimerEngine(
            store: SwiftDataTimerSessionStore(context: context),
            settings: settings,
            cycleState: cycleState,
            dateProvider: SystemDateProvider(),
            notifications: LocalTimerNotificationScheduler(
                center: notificationCenter
            ),
            liveActivities: ActivityKitTimerLiveActivityCoordinator(),
            feedback: SystemTimerFeedbackPlayer()
        )
        try engine.restore()

        return AppDependencies(
            modelContainer: container,
            timerEngine: engine,
            notificationPermissionService: permissionService
        )
    }

    private static func fetchOrInsert<Model: PersistentModel>(
        _ type: Model.Type,
        in context: ModelContext,
        create: () -> Model
    ) throws -> Model {
        var descriptor = FetchDescriptor<Model>()
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let model = create()
        context.insert(model)
        try context.save()
        return model
    }
}
