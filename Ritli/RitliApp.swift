//
//  RitliApp.swift
//  Ritli
//
//  Created by Kirill Gladkov on 14/08/2026.
//

import OSLog
import SwiftData
import SwiftUI

@main
@MainActor
struct RitliApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self)
    private var appDelegate
    private let dependencies: AppDependencies?
    private let splashMinimumDisplayDuration: Duration
    @State private var onboardingStore: OnboardingStore
    @State private var isShowingSplash: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        splashMinimumDisplayDuration = SplashPresentation.minimumDisplayDuration(
            arguments: arguments
        )
        _isShowingSplash = State(
            initialValue: SplashPresentation.shouldShow(arguments: arguments)
        )

        do {
            #if DEBUG
            let isUITesting = arguments.contains("--ui-testing")
            let dependencies = try AppDependencies.live(
                inMemory: isUITesting,
                notificationsEnabled: !isUITesting
            )
            if isUITesting,
               let title = ProcessInfo.processInfo.environment["RITLI_UI_TEST_TASK_TITLE"] {
                // Seed only the isolated UI-test store. Task creation itself is
                // exercised through the editor in the smoke UI tests.
                let context = dependencies.modelContainer.mainContext
                context.insert(FocusTask(title: title))
                try context.save()
            }
            #else
            let dependencies = try AppDependencies.live()
            #endif
            self.dependencies = dependencies
            _onboardingStore = State(initialValue: OnboardingStore())
        } catch {
            Logger(subsystem: "com.kirillgl.Ritli", category: "Startup")
                .fault("Could not open the data store: \(error.localizedDescription, privacy: .public)")
            dependencies = nil
            _onboardingStore = State(initialValue: OnboardingStore())
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                appContent

                if isShowingSplash {
                    SplashView(
                        minimumDisplayDuration: splashMinimumDisplayDuration,
                        onFinished: dismissSplash
                    )
                    .zIndex(1)
                }
            }
        }
    }

    @ViewBuilder
    private var appContent: some View {
        if let dependencies {
            Group {
                if onboardingStore.hasCompletedOnboarding {
                    ContentView()
                } else {
                    WelcomeView(onContinue: onboardingStore.complete)
                }
            }
            .environment(dependencies.timerEngine)
            .environment(dependencies.notificationPermissionService)
            .preferredColorScheme(
                dependencies.timerEngine.settings.appearance.preferredColorScheme
            )
            .modelContainer(dependencies.modelContainer)
        } else {
            StartupFailureView()
        }
    }

    private func dismissSplash() {
        isShowingSplash = false
    }
}
