import Foundation

struct Currency: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    
    var flag: String {
        let base: UInt32 = 127397 // Unicode scalar for regional indicator symbol letter A
        var flag = ""
        
        // Special cases for currencies that don't map directly to country codes
        switch code {
        case "EUR": return "🇪🇺"
        case "BTC": return "₿"
        case "XAU": return "🪙"
        case "XAG": return "🥈"
        case "XPD": return "🥇"
        case "XPT": return "🥇"
        case "XDR": return "💱"
        case "ANG", "XCD", "XAF", "XOF", "XPF": return "🪙" // Regional currencies
        default:
            // Get the country code from the currency code (first two letters)
            let countryCode = String(code.prefix(2))
            for scalar in countryCode.unicodeScalars {
                if let scalarValue = UnicodeScalar(base + scalar.value) {
                    flag.append(String(scalarValue))
                }
            }
            // If the flag is empty or invalid, use coin emoji
            return flag.isEmpty ? "🪙" : flag
        }
    }
    
    static let allCurrencies: [Currency] = [
        Currency(code: "USD", name: "US Dollar"),
        Currency(code: "EUR", name: "Euro"),
        Currency(code: "GBP", name: "British Pound"),
        Currency(code: "JPY", name: "Japanese Yen"),
        Currency(code: "AUD", name: "Australian Dollar"),
        Currency(code: "CAD", name: "Canadian Dollar"),
        Currency(code: "CHF", name: "Swiss Franc"),
        Currency(code: "CNY", name: "Chinese Yuan"),
        Currency(code: "INR", name: "Indian Rupee"),
        Currency(code: "ILS", name: "Israeli Shekel"),
        Currency(code: "AED", name: "UAE Dirham"),
        Currency(code: "AFN", name: "Afghan Afghani"),
        Currency(code: "ALL", name: "Albanian Lek"),
        Currency(code: "AMD", name: "Armenian Dram"),
        Currency(code: "ANG", name: "Netherlands Antillean Guilder"),
        Currency(code: "AOA", name: "Angolan Kwanza"),
        Currency(code: "ARS", name: "Argentine Peso"),
        Currency(code: "AWG", name: "Aruban Florin"),
        Currency(code: "AZN", name: "Azerbaijani Manat"),
        Currency(code: "BAM", name: "Bosnia-Herzegovina Convertible Mark"),
        Currency(code: "BBD", name: "Barbadian Dollar"),
        Currency(code: "BDT", name: "Bangladeshi Taka"),
        Currency(code: "BGN", name: "Bulgarian Lev"),
        Currency(code: "BHD", name: "Bahraini Dinar"),
        Currency(code: "BIF", name: "Burundian Franc"),
        Currency(code: "BMD", name: "Bermudan Dollar"),
        Currency(code: "BND", name: "Brunei Dollar"),
        Currency(code: "BOB", name: "Bolivian Boliviano"),
        Currency(code: "BRL", name: "Brazilian Real"),
        Currency(code: "BSD", name: "Bahamian Dollar"),
        Currency(code: "BTC", name: "Bitcoin"),
        Currency(code: "BTN", name: "Bhutanese Ngultrum"),
        Currency(code: "BWP", name: "Botswanan Pula"),
        Currency(code: "BYN", name: "Belarusian Ruble"),
        Currency(code: "BZD", name: "Belize Dollar"),
        Currency(code: "CDF", name: "Congolese Franc"),
        Currency(code: "CLF", name: "Chilean Unit of Account"),
        Currency(code: "CLP", name: "Chilean Peso"),
        Currency(code: "COP", name: "Colombian Peso"),
        Currency(code: "CRC", name: "Costa Rican Colón"),
        Currency(code: "CUC", name: "Cuban Convertible Peso"),
        Currency(code: "CUP", name: "Cuban Peso"),
        Currency(code: "CVE", name: "Cape Verdean Escudo"),
        Currency(code: "CZK", name: "Czech Republic Koruna"),
        Currency(code: "DJF", name: "Djiboutian Franc"),
        Currency(code: "DKK", name: "Danish Krone"),
        Currency(code: "DOP", name: "Dominican Peso"),
        Currency(code: "DZD", name: "Algerian Dinar"),
        Currency(code: "EGP", name: "Egyptian Pound"),
        Currency(code: "ERN", name: "Eritrean Nakfa"),
        Currency(code: "ETB", name: "Ethiopian Birr"),
        Currency(code: "FJD", name: "Fijian Dollar"),
        Currency(code: "FKP", name: "Falkland Islands Pound"),
        Currency(code: "GEL", name: "Georgian Lari"),
        Currency(code: "GGP", name: "Guernsey Pound"),
        Currency(code: "GHS", name: "Ghanaian Cedi"),
        Currency(code: "GIP", name: "Gibraltar Pound"),
        Currency(code: "GMD", name: "Gambian Dalasi"),
        Currency(code: "GNF", name: "Guinean Franc"),
        Currency(code: "GTQ", name: "Guatemalan Quetzal"),
        Currency(code: "GYD", name: "Guyanaese Dollar"),
        Currency(code: "HKD", name: "Hong Kong Dollar"),
        Currency(code: "HNL", name: "Honduran Lempira"),
        Currency(code: "HRK", name: "Croatian Kuna"),
        Currency(code: "HTG", name: "Haitian Gourde"),
        Currency(code: "HUF", name: "Hungarian Forint"),
        Currency(code: "IDR", name: "Indonesian Rupiah"),
        Currency(code: "IMP", name: "Manx pound"),
        Currency(code: "IQD", name: "Iraqi Dinar"),
        Currency(code: "IRR", name: "Iranian Rial"),
        Currency(code: "ISK", name: "Icelandic Króna"),
        Currency(code: "JEP", name: "Jersey Pound"),
        Currency(code: "JMD", name: "Jamaican Dollar"),
        Currency(code: "JOD", name: "Jordanian Dinar"),
        Currency(code: "KES", name: "Kenyan Shilling"),
        Currency(code: "KGS", name: "Kyrgystani Som"),
        Currency(code: "KHR", name: "Cambodian Riel"),
        Currency(code: "KMF", name: "Comorian Franc"),
        Currency(code: "KPW", name: "North Korean Won"),
        Currency(code: "KRW", name: "South Korean Won"),
        Currency(code: "KWD", name: "Kuwaiti Dinar"),
        Currency(code: "KYD", name: "Cayman Islands Dollar"),
        Currency(code: "KZT", name: "Kazakhstani Tenge"),
        Currency(code: "LAK", name: "Laotian Kip"),
        Currency(code: "LBP", name: "Lebanese Pound"),
        Currency(code: "LKR", name: "Sri Lankan Rupee"),
        Currency(code: "LRD", name: "Liberian Dollar"),
        Currency(code: "LSL", name: "Lesotho Loti"),
        Currency(code: "LYD", name: "Libyan Dinar"),
        Currency(code: "MAD", name: "Moroccan Dirham"),
        Currency(code: "MDL", name: "Moldovan Leu"),
        Currency(code: "MGA", name: "Malagasy Ariary"),
        Currency(code: "MKD", name: "Macedonian Denar"),
        Currency(code: "MMK", name: "Myanmar Kyat"),
        Currency(code: "MNT", name: "Mongolian Tugrik"),
        Currency(code: "MOP", name: "Macanese Pataca"),
        Currency(code: "MRU", name: "Mauritanian Ouguiya"),
        Currency(code: "MUR", name: "Mauritian Rupee"),
        Currency(code: "MVR", name: "Maldivian Rufiyaa"),
        Currency(code: "MWK", name: "Malawian Kwacha"),
        Currency(code: "MXN", name: "Mexican Peso"),
        Currency(code: "MYR", name: "Malaysian Ringgit"),
        Currency(code: "MZN", name: "Mozambican Metical"),
        Currency(code: "NAD", name: "Namibian Dollar"),
        Currency(code: "NGN", name: "Nigerian Naira"),
        Currency(code: "NIO", name: "Nicaraguan Córdoba"),
        Currency(code: "NOK", name: "Norwegian Krone"),
        Currency(code: "NPR", name: "Nepalese Rupee"),
        Currency(code: "NZD", name: "New Zealand Dollar"),
        Currency(code: "OMR", name: "Omani Rial"),
        Currency(code: "PAB", name: "Panamanian Balboa"),
        Currency(code: "PEN", name: "Peruvian Nuevo Sol"),
        Currency(code: "PGK", name: "Papua New Guinean Kina"),
        Currency(code: "PHP", name: "Philippine Peso"),
        Currency(code: "PKR", name: "Pakistani Rupee"),
        Currency(code: "PLN", name: "Polish Złoty"),
        Currency(code: "PYG", name: "Paraguayan Guarani"),
        Currency(code: "QAR", name: "Qatari Rial"),
        Currency(code: "RON", name: "Romanian Leu"),
        Currency(code: "RSD", name: "Serbian Dinar"),
        Currency(code: "RUB", name: "Russian Ruble"),
        Currency(code: "RWF", name: "Rwandan Franc"),
        Currency(code: "SAR", name: "Saudi Riyal"),
        Currency(code: "SBD", name: "Solomon Islands Dollar"),
        Currency(code: "SCR", name: "Seychellois Rupee"),
        Currency(code: "SDG", name: "Sudanese Pound"),
        Currency(code: "SEK", name: "Swedish Krona"),
        Currency(code: "SGD", name: "Singapore Dollar"),
        Currency(code: "SHP", name: "Saint Helena Pound"),
        Currency(code: "SLL", name: "Sierra Leonean Leone"),
        Currency(code: "SOS", name: "Somali Shilling"),
        Currency(code: "SRD", name: "Surinamese Dollar"),
        Currency(code: "SSP", name: "South Sudanese Pound"),
        Currency(code: "STN", name: "São Tomé and Príncipe Dobra"),
        Currency(code: "SVC", name: "Salvadoran Colón"),
        Currency(code: "SYP", name: "Syrian Pound"),
        Currency(code: "SZL", name: "Swazi Lilangeni"),
        Currency(code: "THB", name: "Thai Baht"),
        Currency(code: "TJS", name: "Tajikistani Somoni"),
        Currency(code: "TMT", name: "Turkmenistani Manat"),
        Currency(code: "TND", name: "Tunisian Dinar"),
        Currency(code: "TOP", name: "Tongan Paʻanga"),
        Currency(code: "TRY", name: "Turkish Lira"),
        Currency(code: "TTD", name: "Trinidad and Tobago Dollar"),
        Currency(code: "TWD", name: "New Taiwan Dollar"),
        Currency(code: "TZS", name: "Tanzanian Shilling"),
        Currency(code: "UAH", name: "Ukrainian Hryvnia"),
        Currency(code: "UGX", name: "Ugandan Shilling"),
        Currency(code: "UYU", name: "Uruguayan Peso"),
        Currency(code: "UZS", name: "Uzbekistani Som"),
        Currency(code: "VES", name: "Venezuelan Bolívar"),
        Currency(code: "VND", name: "Vietnamese Dong"),
        Currency(code: "VUV", name: "Vanuatu Vatu"),
        Currency(code: "WST", name: "Samoan Tala"),
        Currency(code: "XAF", name: "Central African CFA Franc"),
        Currency(code: "XAG", name: "Silver Ounce"),
        Currency(code: "XAU", name: "Gold Ounce"),
        Currency(code: "XCD", name: "East Caribbean Dollar"),
        Currency(code: "XDR", name: "Special Drawing Rights"),
        Currency(code: "XOF", name: "West African CFA Franc"),
        Currency(code: "XPD", name: "Palladium Ounce"),
        Currency(code: "XPF", name: "CFP Franc"),
        Currency(code: "XPT", name: "Platinum Ounce"),
        Currency(code: "YER", name: "Yemeni Rial"),
        Currency(code: "ZAR", name: "South African Rand"),
        Currency(code: "ZMW", name: "Zambian Kwacha"),
        Currency(code: "ZWL", name: "Zimbabwean Dollar")
    ]
}

@MainActor
class CurrencyConverterViewModel: ObservableObject {
    @Published var fromCurrency: Currency
    @Published var toCurrency: Currency
    @Published var amount: String = "1"
    @Published var convertedAmount: Double = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: String?
    
    private var rates: [String: Double] = [:]
    
    init() {
        let defaultFrom = UserDefaults.standard.string(forKey: "defaultFromCurrency") ?? "USD"
        let defaultTo = UserDefaults.standard.string(forKey: "defaultToCurrency") ?? "EUR"
        self.fromCurrency = Currency.allCurrencies.first { $0.code == defaultFrom } ?? Currency.allCurrencies[0]
        self.toCurrency = Currency.allCurrencies.first { $0.code == defaultTo } ?? Currency.allCurrencies[1]
    }
    
    func updateDefaultsIfNeeded() {
        let defaultFrom = UserDefaults.standard.string(forKey: "defaultFromCurrency") ?? "USD"
        let defaultTo = UserDefaults.standard.string(forKey: "defaultToCurrency") ?? "EUR"
        self.fromCurrency = Currency.allCurrencies.first { $0.code == defaultFrom } ?? Currency.allCurrencies[0]
        self.toCurrency = Currency.allCurrencies.first { $0.code == defaultTo } ?? Currency.allCurrencies[1]
    }
    
    func convert() {
        Task {
            await fetchRatesAndConvert()
        }
    }
    
    private func fetchRatesAndConvert() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch latest rates
            rates = try await CurrencyService.shared.getRates()
            
            // Get the last update time
            if let response = try? await URLSession.shared.data(from: URL(string: "https://open.er-api.com/v6/latest/USD")!).0,
               let json = try? JSONSerialization.jsonObject(with: response) as? [String: Any],
               let time = json["time_last_update_utc"] as? String {
                lastUpdateTime = time
            }
            
            // Perform conversion
            guard let amount = Double(amount),
                  let fromRate = rates[fromCurrency.code],
                  let toRate = rates[toCurrency.code] else {
                errorMessage = "Invalid amount or currency rate not available"
                isLoading = false
                return
            }
            
            // Convert to USD first, then to target currency
            let amountInUSD = amount / fromRate
            convertedAmount = amountInUSD * toRate
            
        } catch {
            errorMessage = "Failed to fetch exchange rates: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
} 
