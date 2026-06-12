import SwiftUI

struct RootView: View {
    @State private var showMainApp = false

    var body: some View {
        if showMainApp {
            ContentView()
        } else {
            WelcomeView {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMainApp = true
                }
            }
        }
    }
}
