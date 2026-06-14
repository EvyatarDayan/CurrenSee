import SwiftUI

enum WelcomeStorage {
    static let skipWelcomeKey = "skipWelcomeScreen"
}

struct RootView: View {
    @AppStorage(WelcomeStorage.skipWelcomeKey) private var skipWelcomeScreen = false
    @State private var hasStartedSession = false

    private var shouldShowMainApp: Bool {
        skipWelcomeScreen || hasStartedSession
    }

    var body: some View {
        if shouldShowMainApp {
            ContentView()
        } else {
            WelcomeView {
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasStartedSession = true
                }
            }
        }
    }
}
