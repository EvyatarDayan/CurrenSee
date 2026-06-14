import SwiftUI

struct ManualConverterView: View {
    @ObservedObject var viewModel: CurrencyConverterViewModel

    private var displayAmount: String {
        AmountDisplayFormat.formatInput(viewModel.amount)
    }

    private var displayConverted: String {
        AmountDisplayFormat.format(viewModel.convertedAmount)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                displaySection
                    .frame(height: geometry.size.height * 0.48)

                IntegratedNumericKeypad(amount: $viewModel.amount)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    private var displaySection: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VStack(spacing: 0) {
                CurrencyConversionResultsView(
                    sourceAmount: displayAmount,
                    convertedAmount: displayConverted,
                    fromCurrency: viewModel.fromCurrency,
                    toCurrency: viewModel.toCurrency
                )

                RatesLastUpdatedLabel(lastUpdateTime: viewModel.lastUpdateTime)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) {
            if let error = viewModel.manualErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }
}

private struct IntegratedNumericKeypad: View {
    @Binding var amount: String
    @AppStorage("isDarkMode") private var isDarkMode = true

    private let rows: [[KeypadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.clear, .digit("0"), .backspace]
    ]

    private enum KeypadKey: Hashable {
        case digit(String)
        case clear
        case backspace
    }

    private var dividerColor: Color {
        isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private let dividerInset: CGFloat = 10
    private let dividerThickness: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            let rowHeight = geometry.size.height / CGFloat(rows.count)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, key in
                            VStack(spacing: 0) {
                                KeypadKeyButton(key: key, isDarkMode: isDarkMode) {
                                    handleKey(key)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                                if rowIndex < rows.count - 1 {
                                    Rectangle()
                                        .fill(dividerColor)
                                        .frame(height: dividerThickness)
                                        .padding(.horizontal, dividerInset)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if columnIndex < row.count - 1 {
                                Rectangle()
                                    .fill(dividerColor)
                                    .frame(width: dividerThickness)
                                    .padding(.vertical, dividerInset)
                            }
                        }
                    }
                    .frame(height: rowHeight)
                }
            }
        }
        .background(isDarkMode ? Color(.systemBackground) : Color(.systemBackground))
    }

    private func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let digit):
            appendDigit(digit)
        case .clear:
            amount = ""
        case .backspace:
            deleteLastDigit()
        }
    }

    private func deleteLastDigit() {
        guard !amount.isEmpty else { return }
        amount.removeLast()
    }

    private func appendDigit(_ digit: String) {
        var updated = amount.split(separator: ".").first.map(String.init) ?? amount

        if updated == "0" && digit == "0" {
            return
        }

        if updated == "0" && digit != "0" {
            updated = ""
        }

        updated.append(digit)
        guard AmountInputLimit.digitCount(in: updated) <= AmountInputLimit.maxDigits else { return }
        amount = updated
    }

    private struct KeypadKeyButton: View {
        let key: KeypadKey
        let isDarkMode: Bool
        let action: () -> Void

        @State private var isHighlighted = false

        private var highlightColor: Color {
            isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
        }

        var body: some View {
            Button {
                playTapAnimation()
                action()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(highlightColor.opacity(isHighlighted ? 1 : 0), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(highlightColor.opacity(isHighlighted ? 1 : 0))
                        )
                        .padding(6)

                    keyLabel
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(isHighlighted ? 0.94 : 1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder
        private var keyLabel: some View {
            switch key {
            case .digit(let digit):
                Text(digit)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(isDarkMode ? .white : .primary)
            case .clear:
                Text("C")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.red)
            case .backspace:
                Image(systemName: "delete.left")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.red)
            }
        }

        private func playTapAnimation() {
            withAnimation(.easeOut(duration: 0.08)) {
                isHighlighted = true
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(.easeOut(duration: 0.14)) {
                    isHighlighted = false
                }
            }
        }
    }
}

#Preview {
    ManualConverterView(viewModel: CurrencyConverterViewModel())
        .preferredColorScheme(.dark)
}
