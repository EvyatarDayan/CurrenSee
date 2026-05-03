import SwiftUI

struct DefaultSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingFromPicker = false
    @State private var showingToPicker = false
    @AppStorage("defaultFromCurrency") private var defaultFromCurrencyCode: String = "USD"
    @AppStorage("defaultToCurrency") private var defaultToCurrencyCode: String = "EUR"
    
    // Temporary state for selection
    @State private var tempFromCurrencyCode: String = "USD"
    @State private var tempToCurrencyCode: String = "EUR"
    
    private var tempFromCurrency: Currency {
        Currency.allCurrencies.first { $0.code == tempFromCurrencyCode } ?? Currency.allCurrencies[0]
    }
    
    private var tempToCurrency: Currency {
        Currency.allCurrencies.first { $0.code == tempToCurrencyCode } ?? Currency.allCurrencies[1]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // From Currency Section
                VStack(alignment: .leading) {
                    Text("From Currency")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Button(action: { showingFromPicker = true }) {
                        HStack {
                            Text(tempFromCurrency.flag)
                                .font(.title2)
                            Text(tempFromCurrency.code)
                                .font(.title2)
                                .bold()
                            Text(tempFromCurrency.name)
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // To Currency Section
                VStack(alignment: .leading) {
                    Text("To Currency")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Button(action: { showingToPicker = true }) {
                        HStack {
                            Text(tempToCurrency.flag)
                                .font(.title2)
                            Text(tempToCurrency.code)
                                .font(.title2)
                                .bold()
                            Text(tempToCurrency.name)
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                Text("The currency codes selected below will be used as your default \"From\" and \"To\" currencies in the converter.\nThese defaults ensure a quick and consistent experience every time you open the app.\n\nYou can still manually change the currency pair at any time within the main converter view.\nHowever, the next time the app is launched, it will automatically return to the default currencies selected here.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 24)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Default Currencies")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Set as default") {
                    defaultFromCurrencyCode = tempFromCurrencyCode
                    defaultToCurrencyCode = tempToCurrencyCode
                    dismiss()
                }
            )
            .onAppear {
                tempFromCurrencyCode = defaultFromCurrencyCode
                tempToCurrencyCode = defaultToCurrencyCode
            }
            .sheet(isPresented: $showingFromPicker) {
                DefaultCurrencyPickerView(selectedCurrency: Binding(
                    get: { tempFromCurrency },
                    set: { tempFromCurrencyCode = $0.code }
                ))
            }
            .sheet(isPresented: $showingToPicker) {
                DefaultCurrencyPickerView(selectedCurrency: Binding(
                    get: { tempToCurrency },
                    set: { tempToCurrencyCode = $0.code }
                ))
            }
        }
    }
}

struct DefaultCurrencyPickerView: View {
    @Binding var selectedCurrency: Currency
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.allCurrencies
        } else {
            return Currency.allCurrencies.filter { currency in
                currency.code.localizedCaseInsensitiveContains(searchText) ||
                currency.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredCurrencies) { currency in
                Button(action: {
                    selectedCurrency = currency
                    dismiss()
                }) {
                    HStack {
                        Text(currency.flag)
                            .font(.title2)
                        Text(currency.code)
                            .font(.headline)
                        Text(currency.name)
                            .foregroundColor(.gray)
                        Spacer()
                        if currency.code == selectedCurrency.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Currency")
            .focused($isSearchFocused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
} 
