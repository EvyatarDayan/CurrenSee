import SwiftUI

private enum SettingsStyle {
    static let horizontalPadding: CGFloat = 20
    static let rowSpacing: CGFloat = 10

    static func cardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemBackground)
    }
}

private extension View {
    func settingsCompactCardStyle(background: Color) -> some View {
        padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: CurrencyConverterViewModel

    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showingHistory = false

    private var cardBackground: Color {
        SettingsStyle.cardBackground(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            pageHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: SettingsStyle.rowSpacing) {
                        settingsSectionHeader("Preferences")
                        settingsCompactCard(darkModeRow)
                    }

                    VStack(alignment: .leading, spacing: SettingsStyle.rowSpacing) {
                        settingsSectionHeader("Data")
                        settingsCompactCard(historyRow)
                    }

                    VStack(alignment: .leading, spacing: SettingsStyle.rowSpacing) {
                        settingsSectionHeader("Support")
                        VStack(spacing: 0) {
                            settingsNavigationRow(
                                destination: HelpSupportView(),
                                icon: "questionmark.circle.fill",
                                iconColor: .blue,
                                title: "Help and support",
                                subtitle: "Get help and contact support"
                            )

                            settingsDivider

                            settingsNavigationRow(
                                destination: TermsPrivacyView(),
                                icon: "lock.fill",
                                iconColor: .green,
                                title: "Terms and privacy",
                                subtitle: "View terms and privacy policy"
                            )

                            settingsDivider

                            settingsNavigationRow(
                                destination: AboutCurrenSeeView(),
                                icon: "info.circle.fill",
                                iconColor: .orange,
                                title: "About",
                                subtitle: "App version and information"
                            )
                        }
                        .background(cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    }
                }
                .padding(.horizontal, SettingsStyle.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(.blue)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showingHistory) {
            HistoryView(converterViewModel: viewModel)
        }
    }

    private var pageHeader: some View {
        Text("Settings")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 6)
    }

    private func settingsSectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }

    private func settingsCompactCard<Content: View>(_ content: Content) -> some View {
        content.settingsCompactCardStyle(background: cardBackground)
    }

    private var settingsDivider: some View {
        Divider()
            .background(Color(.separator))
            .padding(.leading, 60)
    }

    private var darkModeRow: some View {
        settingsRow(
            icon: isDarkMode ? "moon.fill" : "sun.max.fill",
            iconColor: isDarkMode ? .purple : .orange,
            title: "Dark Mode",
            subtitle: "Switch light/dark mode",
            compact: true
        ) {
            Toggle("", isOn: $isDarkMode)
                .labelsHidden()
                .scaleEffect(0.72, anchor: .trailing)
        }
    }

    private var historyRow: some View {
        Button {
            showingHistory = true
        } label: {
            settingsRow(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .green,
                title: "Exchange Rate History",
                subtitle: "View historical rates",
                compact: true
            ) {
                settingsChevron
            }
        }
        .buttonStyle(.plain)
    }

    private var settingsChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
    }

    private func settingsNavigationRow<Destination: View>(
        destination: Destination,
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            settingsRow(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle) {
                settingsChevron
            }
        }
        .buttonStyle(.plain)
    }

    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        compact: Bool = false,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon: icon, color: iconColor, compact: compact)

            VStack(alignment: .leading, spacing: compact ? 1 : 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(.horizontal, compact ? 12 : 16)
        .padding(.vertical, compact ? 6 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func settingsIcon(icon: String, color: Color, compact: Bool = false) -> some View {
        let size: CGFloat = compact ? 28 : 32
        let iconSize: CGFloat = compact ? 14 : 16
        return ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: CurrencyConverterViewModel())
    }
}
