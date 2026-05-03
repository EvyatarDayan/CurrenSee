import Foundation

class CurrencyService {
    static let shared = CurrencyService()
    private let baseURL = "https://open.er-api.com/v6/latest/USD"
    private var rates: [String: Double] = [:]
    private var lastUpdateTime: Date?
    private let cacheDuration: TimeInterval = 3600 // Cache for 1 hour
    
    private init() {}
    
    func getRates() async throws -> [String: Double] {
        // Check if we have cached rates that are still valid
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < cacheDuration,
           !rates.isEmpty {
            return rates
        }
        
        // Fetch new rates
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        
        // Update cache
        rates = response.rates
        lastUpdateTime = Date()
        
        return rates
    }
}

// Response model for the API
struct ExchangeRateResponse: Codable {
    let rates: [String: Double]
    let base_code: String
    let time_last_update_utc: String
} 