import SwiftUI
import UIKit

private enum CurrencySheetPresentation {
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var detents: Set<PresentationDetent> {
        isPad ? [.large] : [.medium]
    }

    static var backgroundInteractionDetent: PresentationDetent {
        isPad ? .large : .medium
    }
}

struct CurrencySelectionView: View {
    @ObservedObject var viewModel: CurrencyConverterViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFromPicker = false
    @State private var showingToPicker = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        VStack(spacing: 24) {
            Text("Currencies")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.top, 8)

            VStack(spacing: 28) {
                currencyRow(title: "From", currency: viewModel.fromCurrency) {
                    showingFromPicker = true
                }

                currencyRow(title: "To", currency: viewModel.toCurrency) {
                    showingToPicker = true
                }
                .padding(.top, 20)
            }
            .overlay {
                swapCurrenciesButton
                    .offset(y: 16)
            }

            Spacer(minLength: 0)

            Button(action: { dismiss() }) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appRed)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .background(SheetUndimmingBackground())
        .presentationDetents(CurrencySheetPresentation.detents)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(
            .enabled(upThrough: CurrencySheetPresentation.backgroundInteractionDetent)
        )
        .presentationBackground(Color(.systemBackground))
        .sheet(isPresented: $showingFromPicker) {
            CurrencyPickerView(selectedCurrency: $viewModel.fromCurrency)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    viewModel.persistSelectedCurrencies()
                }
        }
        .sheet(isPresented: $showingToPicker) {
            CurrencyPickerView(selectedCurrency: $viewModel.toCurrency)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    viewModel.persistSelectedCurrencies()
                }
        }
        .onDisappear {
            viewModel.persistSelectedCurrencies()
        }
    }

    private var swapCurrenciesButton: some View {
        Button(action: {
            viewModel.swapCurrencies()
        }) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.appRed)
                .frame(width: 52, height: 52)
                .circularIconBadgeStyle()
        }
        .buttonStyle(.plain)
    }

    private var currencyFieldBackground: Color {
        isDarkMode ? Color(white: 0.75) : Color(.systemGray6)
    }

    private func currencyRow(title: String, currency: Currency, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(isDarkMode ? .white : .black)

            Button(action: action) {
                HStack {
                    Text(currency.flag)
                        .font(.title2)
                    Text(currency.code)
                        .font(.title2)
                        .bold()
                        .foregroundColor(isDarkMode ? .black : .primary)
                    Text(currency.name)
                        .foregroundColor(isDarkMode ? Color(white: 0.45) : .gray)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(isDarkMode ? Color(white: 0.45) : .gray)
                }
                .padding()
                .background(currencyFieldBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct SheetUndimmingBackground: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SheetUndimmingViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class SheetUndimmingViewController: UIViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let sheet = sheetPresentationController else { return }
        presentingViewController?.view.tintAdjustmentMode = .normal

        if CurrencySheetPresentation.isPad {
            sheet.largestUndimmedDetentIdentifier = .large
        } else {
            sheet.largestUndimmedDetentIdentifier = .medium
        }
    }
}
