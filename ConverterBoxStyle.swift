import SwiftUI

enum ConverterBoxLayout {
    static let stackScale: CGFloat = 0.85
    static let horizontalPadding: CGFloat = 12
}

enum AmountInputLimit {
    static let maxDigits = 10
    static let maxCameraDigits = 8
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

    static func clamp(_ text: String, digitLimit: Int = maxDigits) -> String {
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
            if digits >= digitLimit { continue }
            digits += 1
            result.append(character)
        }

        return result
    }

    static func cameraDetectedAmountString(from value: Double) -> String? {
        let clamped = clamp(rawAmountString(from: value), digitLimit: maxCameraDigits)
        guard digitCount(in: clamped) <= maxCameraDigits else { return nil }
        return clamped
    }

    static func cameraDetectedAmount(from value: Double) -> Double? {
        guard let string = cameraDetectedAmountString(from: value) else { return nil }
        return Double(string)
    }

    static func detectedAmountString(from value: Double) -> String? {
        let clamped = clamp(rawAmountString(from: value))
        guard digitCount(in: clamped) <= maxDigits else { return nil }
        return clamped
    }

    static func detectedAmount(from value: Double) -> Double? {
        guard let string = detectedAmountString(from: value) else { return nil }
        return Double(string)
    }

    private static func rawAmountString(from value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
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

    func circularIconBadgeStyle() -> some View {
        background(Color(.systemBackground))
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

private struct ConversionDirectionArrow: View {
    var body: some View {
        Image(systemName: "arrow.down")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.appRed)
            .frame(width: 36, height: 36)
            .circularIconBadgeStyle()
    }
}

struct ConversionAmountText: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 44, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .allowsTightening(true)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52, alignment: .leading)
            .animation(nil, value: text)
    }
}

struct CurrencyConversionResultsView: View {
    enum DividerStyle {
        case underEachRow
        case centerOnly
    }

    let sourceAmount: String
    let convertedAmount: String
    let fromCurrency: Currency
    let toCurrency: Currency
    var dividerStyle: DividerStyle = .underEachRow

    @AppStorage("isDarkMode") private var isDarkMode = true

    private var dividerColor: Color {
        isDarkMode ? Color.white.opacity(0.35) : Color.primary.opacity(0.25)
    }

    var body: some View {
        Group {
            if dividerStyle == .centerOnly {
                centerOnlyResults
            } else {
                underEachRowResults
            }
        }
        .animation(nil, value: sourceAmount)
        .animation(nil, value: convertedAmount)
    }

    private var underEachRowResults: some View {
        VStack(spacing: 0) {
            currencyAmountRow(
                currency: fromCurrency,
                amount: sourceAmount,
                isSource: true,
                showsDivider: true
            )

            ConversionDirectionArrow()
                .padding(.top, 10)
                .padding(.bottom, 6)

            currencyAmountRow(
                currency: toCurrency,
                amount: convertedAmount,
                isSource: false,
                showsDivider: true
            )
            .padding(.top, 6)
        }
    }

    private var centerOnlyResults: some View {
        VStack(spacing: 0) {
            currencyAmountRow(
                currency: fromCurrency,
                amount: sourceAmount,
                isSource: true,
                showsDivider: false
            )

            ZStack {
                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)

                ConversionDirectionArrow()
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)

            currencyAmountRow(
                currency: toCurrency,
                amount: convertedAmount,
                isSource: false,
                showsDivider: false
            )
        }
    }

    private func currencyAmountRow(
        currency: Currency,
        amount: String,
        isSource: Bool,
        showsDivider: Bool
    ) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                ConversionAmountText(
                    text: amount,
                    color: isSource
                        ? (isDarkMode ? .white : .primary)
                        : .appRed
                )

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text(currency.flag)
                    Text(currency.code)
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(isDarkMode ? .white : .primary)
                .frame(width: 96, alignment: .trailing)
            }
            .frame(height: 52)

            if showsDivider {
                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)
            }
        }
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
