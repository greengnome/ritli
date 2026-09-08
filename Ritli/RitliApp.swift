//
//  RitliApp.swift
//  Ritli
//
//  Created by Kirill Gladkov on 14/08/2026.
//

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
            #else
            let dependencies = try AppDependencies.live()
            #endif
            self.dependencies = dependencies
            _onboardingStore = State(initialValue: OnboardingStore())
        } catch {
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
                    .transition(.opacity)
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
        withAnimation(.easeOut(duration: 0.22)) {
            isShowingSplash = false
        }
    }
}
