import SwiftUI

private enum SettingsStyle {
    static let horizontalPadding: CGFloat = 20
    static let rowSpacing: CGFloat = 10

    static func cardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemBackground)
    }
}

private extension View {
    func settingsCardStyle(background: Color) -> some View {
        padding(16)
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
    var onDefaultsDismissed: () -> Void = {}

    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showingDefaultSettings = false
    @State private var showingHistory = false
    @State private var showingDisclaimer = false
    @State private var showingContactUs = false

    private var cardBackground: Color {
        SettingsStyle.cardBackground(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pageHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: SettingsStyle.rowSpacing) {
                            settingsSectionHeader("Preferences")
                            settingsCard(darkModeRow)
                            settingsCard(defaultCurrenciesRow)
                        }

                        VStack(alignment: .leading, spacing: SettingsStyle.rowSpacing) {
                            settingsSectionHeader("Data")
                            settingsCard(historyRow)
                        }

                        VStack(alignment: .leading, spacing: SettingsStyle.rowSpacing) {
                            settingsSectionHeader("Support")
                            settingsCard(infoRow)
                            settingsCard(contactUsRow)
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
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showingDefaultSettings) {
            DefaultSettingsView()
                .onDisappear { onDefaultsDismissed() }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(
                viewModel: HistoryViewModel(),
                base: viewModel.fromCurrency.code,
                target: viewModel.toCurrency.code
            )
        }
        .sheet(isPresented: $showingDisclaimer) {
            DisclaimerView()
        }
        .sheet(isPresented: $showingContactUs) {
            ContactUsView(isPresented: $showingContactUs)
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

    private func settingsCard<Content: View>(_ content: Content) -> some View {
        content.settingsCardStyle(background: cardBackground)
    }

    private var darkModeRow: some View {
        settingsRow(
            icon: isDarkMode ? "moon.fill" : "sun.max.fill",
            iconColor: isDarkMode ? .purple : .orange,
            title: "Dark Mode",
            subtitle: "Switch between light and dark appearance"
        ) {
            Toggle("", isOn: $isDarkMode)
                .labelsHidden()
                .scaleEffect(0.72, anchor: .trailing)
        }
    }

    private var defaultCurrenciesRow: some View {
        Button {
            showingDefaultSettings = true
        } label: {
            settingsRow(
                icon: "gear",
                iconColor: .blue,
                title: "Default Currencies",
                subtitle: "Set your default from and to currencies"
            ) {
                settingsChevron
            }
        }
        .buttonStyle(.plain)
    }

    private var historyRow: some View {
        Button {
            showingHistory = true
        } label: {
            settingsRow(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .green,
                title: "Exchange Rate History",
                subtitle: "View historical rates for your currency pair"
            ) {
                settingsChevron
            }
        }
        .buttonStyle(.plain)
    }

    private var infoRow: some View {
        Button {
            showingDisclaimer = true
        } label: {
            settingsRow(
                icon: "exclamationmark.circle",
                iconColor: .orange,
                title: "Disclaimer",
                subtitle: "Important information about exchange rates"
            ) {
                settingsChevron
            }
        }
        .buttonStyle(.plain)
    }

    private var contactUsRow: some View {
        Button {
            showingContactUs = true
        } label: {
            settingsRow(
                icon: "envelope",
                iconColor: .teal,
                title: "Contact Us",
                subtitle: "Send us a message or get support"
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

    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
    }
}

#Preview {
    SettingsView(viewModel: CurrencyConverterViewModel())
}
