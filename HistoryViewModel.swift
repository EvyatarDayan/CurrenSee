import Foundation

struct HistoryRatePoint: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var points: [HistoryRatePoint] = []
    @Published var isLoading = false
    @Published var error: String?

    func fetchHistory(base: String, target: String, start: Date, end: Date) async {
        isLoading = true
        error = nil
        points = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let urlString = "https://api.frankfurter.app/\(formatter.string(from: start))..\(formatter.string(from: end))?from=\(base)&to=\(target)"
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print(String(data: data, encoding: .utf8) ?? "No data")
            let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let sorted = decoded.rates.compactMap { (key, value) -> HistoryRatePoint? in
                guard let date = dateFormatter.date(from: key), let rate = value[target] else { return nil }
                return HistoryRatePoint(date: date, rate: rate)
            }.sorted { $0.date < $1.date }
            if sorted.isEmpty {
                self.error = "No data available for this period."
            } else {
                self.points = sorted
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    struct FrankfurterResponse: Decodable {
        let rates: [String: [String: Double]]
    }
}

struct HistoryAPIResponse: Decodable {
    let rates: [String: [String: Double]]
}
