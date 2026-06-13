import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var converterViewModel: CurrencyConverterViewModel
    @StateObject private var viewModel = HistoryViewModel()

    @State private var range: RangeType = .fiveYears

    private var base: String { converterViewModel.fromCurrency.code }
    private var target: String { converterViewModel.toCurrency.code }

    enum RangeType: String, CaseIterable {
        case week = "1w"
        case month = "1m"
        case year = "1y"
        case fiveYears = "5y"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            case .fiveYears: return 365 * 5
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text(converterViewModel.fromCurrency.flag)
                            .font(.title2)
                        Text(base)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.blue)
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(.appRed)
                        Text(converterViewModel.toCurrency.flag)
                            .font(.title2)
                        Text(target)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 12)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else if let error = viewModel.error {
                    Text(error).foregroundColor(.red)
                } else {
                    Chart(viewModel.points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Rate", point.rate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Rate", point.rate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.2)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: 250)
                    .padding()
                }

                Picker("Range", selection: $range) {
                    ForEach(RangeType.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                Text("The historical exchange rate data presented in this section is for informational purposes only. We do not guarantee its accuracy or completeness, and it should not be relied upon for financial, investment, tax, or legal decisions.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 24)

                Spacer()
            }
            .navigationTitle("History")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .onAppear { load() }
            .onChange(of: range) { _, _ in load() }
            .onChange(of: base) { _, _ in load() }
            .onChange(of: target) { _, _ in load() }
        }
    }

    private func load() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -range.days, to: end)!
        Task {
            await viewModel.fetchHistory(base: base, target: target, start: start, end: end)
        }
    }
}
