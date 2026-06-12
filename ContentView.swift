//
//  ContentView.swift
//  CurrenSee
//
//  Created by EVYATAR DAYAN on 03/06/2025.
//

import SwiftUI
import MessageUI

enum ConverterTab: String, CaseIterable {
    case manual = "Manual"
    case camera = "Camera"
}

struct ContentView: View {
    @StateObject private var viewModel = CurrencyConverterViewModel()
    @StateObject private var cameraScanner = CameraTextScanner()
    @State private var selectedTab: ConverterTab = .manual
    @State private var showSettings = false
    @State private var showingCurrencySelection = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showMailError = false
    @State private var mailDidFinish = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var manualLayoutHeight: CGFloat = 0
    @State private var requestAmountFieldFocus = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    ZStack {
                        manualConverterContent
                            .opacity(selectedTab == .manual ? 1 : 0)
                            .allowsHitTesting(selectedTab == .manual)
                            .zIndex(selectedTab == .manual ? 1 : 0)

                        CameraScanView(viewModel: viewModel, scanner: cameraScanner)
                            .opacity(selectedTab == .camera ? 1 : 0)
                            .allowsHitTesting(selectedTab == .camera)
                            .zIndex(selectedTab == .camera ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top, 4)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.circle")
                                .foregroundColor(.green)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        ConverterTabPicker(selection: Binding(
                            get: { selectedTab },
                            set: { newTab in
                                if newTab != .manual {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = newTab
                                }
                                if newTab == .camera {
                                    cameraScanner.activate()
                                } else {
                                    cameraScanner.deactivate()
                                }
                            }
                        ))
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingCurrencySelection = true
                        }) {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(viewModel: viewModel) {
                        viewModel.updateDefaultsIfNeeded()
                    }
                }
                .sheet(isPresented: $showingCurrencySelection) {
                    CurrencySelectionView(viewModel: viewModel)
                }
                .onAppear {
                    viewModel.updateDefaultsIfNeeded()
                    cameraScanner.prepare()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }

    private var manualConverterContent: some View {
        GeometryReader { geometry in
            let viewHeight = manualLayoutHeight > 0 ? manualLayoutHeight : geometry.size.height
            let helperHeight: CGFloat = 36
            let topInset: CGFloat = 24
            let sectionSpacing: CGFloat = 10
            let availableHeight = viewHeight - topInset - helperHeight - sectionSpacing * 2
            let totalStackHeight = availableHeight * ConverterBoxLayout.stackScale
            let sectionHeight = max(0, (totalStackHeight - sectionSpacing * 2) / 3)
            let canConvert = !viewModel.isLoading && !viewModel.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: topInset)

                Spacer(minLength: 0)

                VStack(spacing: sectionSpacing) {
                    manualAmountSection
                        .frame(maxWidth: .infinity)
                        .frame(height: sectionHeight)

                    ConversionResultSection(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .frame(height: sectionHeight)

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
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .disabled(!canConvert)
                    .background(canConvert ? Color.blue : Color.gray)
                    .cornerRadius(12)
                    .converterBoxShadow()
                    .frame(maxWidth: .infinity)
                    .frame(height: sectionHeight)
                }
                .padding(.horizontal, ConverterBoxLayout.horizontalPadding)

                Spacer(minLength: 0)

                RatesLastUpdatedLabel(lastUpdateTime: viewModel.lastUpdateTime)
                    .padding(.top, 8)
                    .frame(height: helperHeight)
                    .padding(.horizontal, 32)
            }
            .frame(width: geometry.size.width, height: viewHeight)
            .onChange(of: geometry.size.height) { _, height in
                if manualLayoutHeight == 0 && height > 0 {
                    manualLayoutHeight = height
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var manualAmountSection: some View {
        ZStack {
            Color(.systemGray6)

            DecimalPadAmountField(
                text: $viewModel.amount,
                requestFocus: $requestAmountFieldFocus,
                placeholder: "0",
                fixedWidth: amountFieldFixedWidth
            )
            .frame(width: amountFieldFixedWidth)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.55))
            .cornerRadius(12)

        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                viewModel.amount = ""
                viewModel.convertedAmount = 0
                requestAmountFieldFocus = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .opacity(viewModel.amount.isEmpty ? 0 : 1)
            .disabled(viewModel.amount.isEmpty)
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .converterBoxShadow()
    }

    private var amountFieldFixedWidth: CGFloat {
        let font = UIFont.systemFont(ofSize: 48, weight: .bold)
        return ceil(("000000" as NSString).size(withAttributes: [.font: font]).width)
    }

}

private struct DecimalPadAmountField: UIViewRepresentable {
    @Binding var text: String
    @Binding var requestFocus: Bool
    var placeholder: String
    var fixedWidth: CGFloat

    private static let maxFontSize: CGFloat = 48
    private static let minFontSize: CGFloat = 20
    private static let fieldHeight: CGFloat = 58

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .center
        field.font = .systemFont(ofSize: Self.maxFontSize, weight: .bold)
        field.textColor = .systemGreen
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = Self.minFontSize
        field.setContentHuggingPriority(.required, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.systemGreen.withAlphaComponent(0.45),
                .font: UIFont.systemFont(ofSize: Self.maxFontSize, weight: .bold)
            ]
        )

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        toolbar.items = [flex, done]
        field.inputAccessoryView = toolbar
        context.coordinator.textField = field

        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        context.coordinator.textField = uiView
        let sanitized = text.replacingOccurrences(of: ",", with: "")
        if uiView.text != sanitized {
            uiView.text = sanitized
        }
        uiView.adjustsFontSizeToFitWidth = true
        uiView.minimumFontSize = Self.minFontSize
        if requestFocus {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                requestFocus = false
            }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        CGSize(width: fixedWidth, height: Self.fieldHeight)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DecimalPadAmountField
        weak var textField: UITextField?

        init(parent: DecimalPadAmountField) {
            self.parent = parent
        }

        @objc func textChanged(_ field: UITextField) {
            let sanitized = AmountInputLimit.clamp((field.text ?? "").replacingOccurrences(of: ",", with: ""))
            if field.text != sanitized {
                field.text = sanitized
            }
            if parent.text != sanitized {
                parent.text = sanitized
            }
        }

        @objc func doneTapped() {
            textField?.resignFirstResponder()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty { return true }

            let allowed = CharacterSet(charactersIn: "0123456789.")
            guard string.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }

            let current = textField.text ?? ""
            guard let textRange = Range(range, in: current) else { return false }
            let updated = current.replacingCharacters(in: textRange, with: string)
            return AmountInputLimit.isValid(updated)
        }
    }
}

struct ConverterTabPicker: View {
    @Binding var selection: ConverterTab
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ConverterTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selection == tab ? .semibold : .regular)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .background {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(isDarkMode ? Color(.systemGray4) : Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
        .frame(width: 220)
        .padding(.top, 35)
        .contentShape(Rectangle())
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
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search Currency", text: $searchText)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)

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
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
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
