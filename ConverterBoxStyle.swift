import SwiftUI

enum ConverterBoxLayout {
    static let stackScale: CGFloat = 0.85
    static let horizontalPadding: CGFloat = 12
}

enum AmountInputLimit {
    static let maxDigits = 10
    static let maxDecimalPlaces = 2

    static func digitCount(in text: String) -> Int {
        text.filter(\.isNumber).count
    }

    static func isValid(_ text: String) -> Bool {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return false }
        if parts.count == 2 && parts[1].count > maxDecimalPlaces { return false }
        return digitCount(in: text) <= maxDigits
    }

    static func clamp(_ text: String) -> String {
        var digits = 0
        var result = ""
        var hasDecimal = false
        var decimalPlaces = 0

        for character in text {
            if character == "." {
                if hasDecimal { continue }
                hasDecimal = true
                result.append(character)
                continue
            }
            guard character.isWholeNumber else { continue }
            if hasDecimal {
                if decimalPlaces >= maxDecimalPlaces { continue }
                decimalPlaces += 1
            }
            if digits >= maxDigits { continue }
            digits += 1
            result.append(character)
        }

        return result
    }
}

enum AmountDisplayFormat {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static var decimalSeparator: String { "." }

    static func format(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    static func formatInput(_ rawAmount: String) -> String {
        let trimmed = rawAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "." else {
            return format(0)
        }
        return format(Double(trimmed) ?? 0)
    }
}

extension View {
    func converterBoxShadow() -> some View {
        shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

private struct FittingResultAmountText: View {
    enum Style {
        case source
        case converted

        var font: Font {
            switch self {
            case .source:
                return .title2.bold()
            case .converted:
                return .system(size: 48, weight: .bold)
            }
        }

        var minimumScale: CGFloat {
            switch self {
            case .source:
                return 0.5
            case .converted:
                return 0.35
            }
        }
    }

    let text: String
    let style: Style
    let color: Color

    var body: some View {
        Text(text)
            .font(style.font)
            .monospacedDigit()
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(style.minimumScale)
            .allowsTightening(true)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(-1)
    }
}

struct ConversionResultSection: View {
    @ObservedObject var viewModel: CurrencyConverterViewModel
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var resultsScale: CGFloat = 1.0

    var body: some View {
        let display = viewModel.lastConversion ?? LastConversion(
            sourceAmount: 0,
            convertedAmount: 0,
            fromCurrencyCode: viewModel.fromCurrency.code,
            toCurrencyCode: viewModel.toCurrency.code
        )
        let fromCurrency = display.fromCurrency() ?? viewModel.fromCurrency
        let toCurrency = display.toCurrency() ?? viewModel.toCurrency

        ZStack {
            VStack(spacing: 8) {
                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        FittingResultAmountText(
                            text: formatNumber(display.sourceAmount),
                            style: .source,
                            color: isDarkMode ? .white : .black
                        )
                        Text(fromCurrency.flag)
                            .fixedSize()
                        Text(fromCurrency.code)
                            .font(.headline)
                            .foregroundColor(.blue)
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity)

                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.green)

                    HStack(spacing: 4) {
                        FittingResultAmountText(
                            text: formatNumber(display.convertedAmount),
                            style: .converted,
                            color: .green
                        )
                        Text(toCurrency.flag)
                            .fixedSize()
                        Text(toCurrency.code)
                            .font(.headline)
                            .foregroundColor(.blue)
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .scaleEffect(resultsScale, anchor: .center)

                Spacer(minLength: 0)
            }

            if let error = viewModel.errorMessage {
                VStack {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.top, 8)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .converterBoxShadow()
        .onChange(of: viewModel.conversionTick) { _, _ in
            animateResultsUpdate()
        }
    }

    private func animateResultsUpdate() {
        resultsScale = 1.0
        withAnimation(.spring(response: 0.22, dampingFraction: 0.48)) {
            resultsScale = 1.14
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
                resultsScale = 1.0
            }
        }
    }

    private func formatNumber(_ value: Double) -> String {
        AmountDisplayFormat.format(value)
    }
}

struct RatesLastUpdatedLabel: View {
    let lastUpdateTime: String?

    var body: some View {
        Text(displayText)
            .font(.caption)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
    }

    private var displayText: String {
        if let lastUpdateTime, let formatted = Self.formatLastUpdate(lastUpdateTime) {
            return "Last updated: \(formatted)"
        }
        return "Last updated: —"
    }

    private static func formatLastUpdate(_ raw: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        guard let date = inputFormatter.date(from: raw) else { return nil }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale.current
        outputFormatter.dateFormat = "dd MMM, HH:mm"
        return outputFormatter.string(from: date)
    }
}
