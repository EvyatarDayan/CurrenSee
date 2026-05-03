//
//  ContentView.swift
//  CurrenSee
//
//  Created by EVYATAR DAYAN on 03/06/2025.
//

import SwiftUI
import MessageUI

struct ContentView: View {
    @StateObject private var viewModel = CurrencyConverterViewModel()
    @State private var showingFromPicker = false
    @State private var showingToPicker = false
    @State private var showingDefaultSettings = false
    @State private var showCustomMenu = false
    @State private var showingDisclaimer = false
    @State private var showingHistory = false
    @State private var showingContactUs = false
    @FocusState private var isAmountFieldFocused: Bool
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showMailError = false
    @State private var mailDidFinish = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        Text("Curren")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.blue)
                        Text("$ee")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.green)
                    }
                   
                    // From Currency Section
                    VStack(alignment: .leading) {
                        Text("From")
                            .font(.headline)
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        Button(action: { showingFromPicker = true }) {
                            HStack {
                                Text(viewModel.fromCurrency.flag)
                                    .font(.title2)
                                Text(viewModel.fromCurrency.code)
                                    .font(.title2)
                                    .bold()
                                Text(viewModel.fromCurrency.name)
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
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.width * 0.8 : nil)
                    
                    // To Currency Section
                    VStack(alignment: .leading) {
                        Text("To")
                            .font(.headline)
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        Button(action: { showingToPicker = true }) {
                            HStack {
                                Text(viewModel.toCurrency.flag)
                                    .font(.title2)
                                Text(viewModel.toCurrency.code)
                                    .font(.title2)
                                    .bold()
                                Text(viewModel.toCurrency.name)
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
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.width * 0.8 : nil)
                        .overlay(
                            HStack {
                                Spacer()
                                Button(action: {
                                    let temp = viewModel.fromCurrency
                                    viewModel.fromCurrency = viewModel.toCurrency
                                    viewModel.toCurrency = temp
                                }) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.green)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                Spacer()
                            }
                                .offset(y: -40)
                        )
                    
                    // Amount Input
                    VStack(alignment: .leading) {
                        Text("Amount")
                            .font(.headline)
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        ZStack {
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                HStack(spacing: 2) {
                                    TextField("Enter amount", text: Binding(
                                        get: {
                                            if let value = Double(viewModel.amount) {
                                                return formatNumber(value)
                                            }
                                            return viewModel.amount
                                        },
                                        set: { newValue in
                                            // Remove commas for storage
                                            viewModel.amount = newValue.replacingOccurrences(of: ",", with: "")
                                        }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .focused($isAmountFieldFocused)
                                    Text(viewModel.fromCurrency.flag)
                                        .font(.title2)
                                    Text(viewModel.fromCurrency.code)
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                                if !viewModel.amount.isEmpty {
                                    Button(action: {
                                        viewModel.amount = ""
                                        viewModel.convertedAmount = 0
                                        isAmountFieldFocused = true
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 120)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.width * 0.8 : nil)
                    
                    // Convert Button
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.convert()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("Convert")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((viewModel.isLoading || viewModel.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || viewModel.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.width * 0.8 : nil)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    
                    // Results Section
                    HStack {
                        VStack(alignment: .center, spacing: 8) {
                            if viewModel.convertedAmount > 0 {
                                HStack(alignment: .firstTextBaseline) {
                                    Spacer()
                                    VStack(alignment: .center, spacing: 0) {
                                        Text(formatNumber(viewModel.convertedAmount))
                                            .font(.system(size: 50, weight: .bold))
                                            .foregroundColor(.green)
                                            .multilineTextAlignment(.center)
                                        HStack(spacing: 4) {
                                            Text(viewModel.toCurrency.flag)
                                                .font(.title2)
                                            Text(viewModel.toCurrency.code)
                                                .font(.title2)
                                                .bold()
                                                .foregroundColor(.blue)
                                        }
                                        .multilineTextAlignment(.center)
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                if let lastUpdate = viewModel.lastUpdateTime {
                                    if let formatted = formatLastUpdate(lastUpdate) {
                                        Text("Last updated: \(formatted)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                            } else {
                                Text("Convert to see results")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .frame(height: 150)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            Button(action: {
                                showingHistory = true
                            }) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.green)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            .padding(.trailing, 8)
                            .padding(.top, 8),
                            alignment: .topTrailing
                        )
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.width * 0.8 : nil)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // Bottom Menu
                    HStack {
                        Button(action: {
                            showingDefaultSettings = true
                        }) {
                            VStack {
                                Image(systemName: "gear")
                                    .font(.title2)
                                Text("Defaults")
                                    .font(.system(size: 10))
                            }
                        }
                        Spacer()
                        Button(action: {
                            showingHistory = true
                        }) {
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                Text("History")
                                    .font(.system(size: 10))
                            }
                        }
                        Spacer()
                        Button(action: {
                            // Navigate to Home (main convert view)
                        }) {
                            VStack {
                                Image(systemName: "house")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                Text("Home")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                            }
                        }
                        Spacer()
                        Button(action: {
                            showingDisclaimer = true
                        }) {
                            VStack {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.title2)
                                Text("Info")
                                    .font(.system(size: 10))
                            }
                        }
                        Spacer()
                        Button(action: {
                            showingContactUs = true
                        }) {
                            VStack {
                                Image(systemName: "envelope")
                                    .font(.title2)
                                Text("Contact Us")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.width * 0.8 : nil)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .navigationBarItems(
                    leading:
                        Button(action: {
                            withAnimation {
                                showCustomMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.green)
                        }
                )
                .sheet(isPresented: $showingFromPicker) {
                    CurrencyPickerView(selectedCurrency: $viewModel.fromCurrency)
                }
                .sheet(isPresented: $showingToPicker) {
                    CurrencyPickerView(selectedCurrency: $viewModel.toCurrency)
                }
                .sheet(isPresented: $showingDefaultSettings) {
                    DefaultSettingsView()
                }
                .sheet(isPresented: $showingDisclaimer) {
                    DisclaimerView()
                }
                .sheet(isPresented: $showingHistory) {
                    HistoryView(
                        viewModel: HistoryViewModel(),
                        base: viewModel.fromCurrency.code,
                        target: viewModel.toCurrency.code
                    )
                }
                .sheet(isPresented: $showingContactUs) {
                    ContactUsView(isPresented: $showingContactUs)
                }
                .onAppear {
                    viewModel.updateDefaultsIfNeeded()
                }
                .onChange(of: showingDefaultSettings) { newValue in
                    if newValue == false {
                        viewModel.updateDefaultsIfNeeded()
                    }
                }
                
                // Side Menu
                if showCustomMenu {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showCustomMenu = false
                        }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 0) {
                                Text("Curren")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("$ee")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 150)
                            .padding(.bottom, 16)
                            .padding(.leading, 16)
                            
                            VStack(spacing: 0) {
                                Button {
                                    showCustomMenu = false
                                    DispatchQueue.main.async {
                                        showingDefaultSettings = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "gear")
                                            .foregroundColor(.blue)
                                        Text("Defaults")
                                            .font(.headline)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Button {
                                    showCustomMenu = false
                                    DispatchQueue.main.async {
                                        showingHistory = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .foregroundColor(.blue)
                                        Text("History")
                                            .font(.headline)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Button {
                                    showCustomMenu = false
                                    DispatchQueue.main.async {
                                        showingDisclaimer = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "exclamationmark.circle")
                                            .foregroundColor(.blue)
                                        Text("Info")
                                            .font(.headline)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                HStack {
                                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                        .foregroundColor(isDarkMode ? .blue : .orange)
                                    Text("Mode")
                                        .font(.headline)
                                    Spacer()
                                    Toggle("", isOn: $isDarkMode)
                                        .labelsHidden()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button {
                                    showCustomMenu = false
                                    DispatchQueue.main.async {
                                        showingContactUs = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "envelope")
                                            .foregroundColor(.blue)
                                        Text("Contact Us")
                                            .font(.headline)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .frame(width: 240)
                        .background(Color.black.opacity(0.9))
                        .edgesIgnoringSafeArea(.vertical)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .leading))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.3), value: showCustomMenu)
    }
    
    private func formatLastUpdate(_ raw: String) -> String? {
        // Try to parse the date from the API string, e.g. "Wed, 03 Jun 2025 14:34:00 +0000"
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = inputFormatter.date(from: raw) {
            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale.current
            outputFormatter.dateFormat = "dd MMM, HH:mm"
            return outputFormatter.string(from: date)
        }
        return nil
    }
    
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

struct CurrencyPickerView: View {
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

struct DisclaimerView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                Text("The exchange rates displayed are based on publicly available sources and are intended for general information only. They may not reflect real-time or market-accurate rates. We do not guarantee the accuracy, completeness, or timeliness of the information. Use at your own discretion.")
                    .font(.body)
                    .padding()
            }
            .navigationTitle("Disclaimer")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct ContactUsView: View {
    @Binding var isPresented: Bool
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var fullName = ""
    @State private var subject = ""
    @State private var email = ""
    @State private var message = ""
    @State private var sent = false
    @State private var showThankYou = false
    @State private var showMailSheet = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showMailError = false
    @State private var mailDidFinish = false
    @State private var shouldShowThankYouAfterMail = false
    @State private var showValidationError = false

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        Text("Contact")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.blue)
                        Text("Us")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.green)
                    }
                    .padding(.top, 24)
                    
                    contactField(title: "Full Name", text: $fullName, isRequired: true)
                    contactField(title: "Email Address", text: $email, keyboard: .emailAddress, isRequired: true)
                    contactField(title: "Subject", text: $subject, isRequired: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Message")
                            .font(.headline)
                            .foregroundColor(message.isEmpty && showValidationError ? .red : (isDarkMode ? .gray : .black))
                        ZStack(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Enter your message")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 6)
                            }
                            TextEditor(text: $message)
                                .frame(minHeight: 120, maxHeight: 160)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(isDarkMode ? .white : .black)
                                .autocorrectionDisabled()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(message.isEmpty && showValidationError ? Color.red : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer(minLength: 0)
                    Button(action: {
                        if isFormValid {
                            if showThankYou {
                                isPresented = false
                            } else if MFMailComposeViewController.canSendMail() {
                                shouldShowThankYouAfterMail = true
                                showMailSheet = true
                                showThankYou = true
                            } else {
                                showMailError = true
                            }
                        } else {
                            showValidationError = true
                        }
                    }) {
                        Text(showThankYou ? "Home" : "Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showThankYou ? Color.green : (isFormValid ? Color.blue : Color.gray))
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid && showThankYou)
                    .padding(.bottom, 24)
                }
                .padding()
                .frame(minHeight: 600)
            }
            .background(isDarkMode ? Color.black : Color.white)
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
            .alert(isPresented: $showThankYou) {
                Alert(
                    title: Text("Thank you!"),
                    message: Text("Your message had been recieved, one of our team members will be in touch with you shortly."),
                    dismissButton: .default(Text("Home")) {
                        isPresented = false
                    }
                )
            }
            .alert(isPresented: $showMailError) {
                Alert(title: Text("Mail Not Configured"), message: Text("Please set up a mail account on your device to send emails."), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showMailSheet) {
                MailView(
                    recipients: ["abashelariprod@gmail.com"],
                    subject: subject.isEmpty ? "Contact Us Form Submission" : subject,
                    body: mailBody(),
                    result: $mailResult,
                    didFinish: $mailDidFinish
                )
            }
            .onChange(of: mailDidFinish) { finished in
                if finished && shouldShowThankYouAfterMail {
                    showThankYou = true
                    shouldShowThankYouAfterMail = false
                    mailDidFinish = false
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    @ViewBuilder
    private func contactField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default, isRequired: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(text.wrappedValue.isEmpty && showValidationError ? .red : (isDarkMode ? .gray : .black))
            TextField(title, text: text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .foregroundColor(isDarkMode ? .white : .black)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(text.wrappedValue.isEmpty && showValidationError ? Color.red : Color.clear, lineWidth: 1)
                )
        }
    }
    
    private func mailBody() -> String {
        """
        Full Name: \(fullName)
        Email: \(email)
        Message: \(message)
        """
    }
}

struct MailView: UIViewControllerRepresentable {
    var recipients: [String]
    var subject: String
    var body: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Binding var didFinish: Bool

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var result: Result<MFMailComposeResult, Error>?
        @Binding var didFinish: Bool
        init(result: Binding<Result<MFMailComposeResult, Error>?>, didFinish: Binding<Bool>) {
            _result = result
            _didFinish = didFinish
        }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer { controller.dismiss(animated: true) }
            if let error = error {
                self.result = .failure(error)
            } else {
                self.result = .success(result)
            }
            self.didFinish = true
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(result: $result, didFinish: $didFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

#Preview {
    ContentView()
}
