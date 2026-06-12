import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black : Color(.systemGroupedBackground))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                logoView
                    .padding(.bottom, 32)

                Text("Welcome to CurrenSee")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)

                Text("Your go-to companion for fast currency conversions. Compare live exchange rates, scan prices with your camera, and review history — all in one place.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)

                Spacer()

                Button(action: onStart) {
                    Text("Start")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var logoView: some View {
        HStack(spacing: 0) {
            Text("Curren")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.blue)
            Text("$ee")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.green)
        }
    }
}

#Preview {
    WelcomeView(onStart: {})
}
