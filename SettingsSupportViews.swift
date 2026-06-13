import SwiftUI
import MessageUI

struct HelpSupportView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showForm = false
    @State private var showError = false
    @State private var showMailSheet = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var mailDidFinish = false
    @State private var showMailError = false
    @State private var showThankYou = false

    private var allFieldsFilled: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if showForm {
                    Form {
                        Section(header: Text("Your full name")) {
                            TextField("Full name", text: $fullName)
                        }

                        Section(header: Text("Your email")) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }

                        Section(header: Text("Subject")) {
                            TextField("", text: $subject)
                                .onChange(of: subject) { _, newValue in
                                    if newValue.count > 100 {
                                        subject = String(newValue.prefix(100))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(subject.count)/100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Section(header: Text("Description")) {
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .onChange(of: description) { _, newValue in
                                    if newValue.count > 400 {
                                        description = String(newValue.prefix(400))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(description.count)/400")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if showError && !allFieldsFilled {
                            Section {
                                Text("All fields are required.")
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }
                        }

                        Section {
                            Button(action: sendMessage) {
                                Text("Send")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(allFieldsFilled ? Color.green : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!allFieldsFilled)
                        }
                        .listRowBackground(Color.clear)
                    }
                } else {
                    VStack {
                        Spacer(minLength: 0)
                        VStack(alignment: .center, spacing: 32) {
                            VStack(alignment: .center, spacing: 16) {
                                Text("We'd love to hear from you!")
                                    .font(.title3)
                                    .fontWeight(.bold)

                                Text("Whether you have questions,")
                                    .font(.body)

                                Text("feedback, or need help with CurrenSee,")
                                    .font(.body)

                                Text("feel free to reach out.")
                                    .font(.body)

                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                                    .padding(.bottom, 32)

                                Text("Email: abashelariprod@gmail.com")
                                    .font(.subheadline)

                                Text("Website: https://abashelari.com")
                                    .font(.subheadline)

                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)

                            Text("OR")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)

                            Button(action: {
                                showForm = true
                            }) {
                                Text("Contact form")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 32)
                            }

                            Text("We aim to respond within 24 hours.")
                                .font(.body)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.vertical, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(showForm ? "Contact us" : "Help and support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Thank you!", isPresented: $showThankYou) {
            Button("OK", role: .cancel) {
                showForm = false
                clearForm()
            }
        } message: {
            Text("Your message has been sent. One of our team members will be in touch with you shortly.")
        }
        .alert("Mail Not Configured", isPresented: $showMailError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please set up a mail account on your device to send emails.")
        }
        .sheet(isPresented: $showMailSheet) {
            MailView(
                recipients: ["abashelariprod@gmail.com"],
                subject: subject.isEmpty ? "CurrenSee Support Request" : subject,
                body: mailBody(),
                result: $mailResult,
                didFinish: $mailDidFinish
            )
        }
        .onChange(of: mailDidFinish) { _, finished in
            if finished {
                showThankYou = true
                mailDidFinish = false
            }
        }
    }

    private func sendMessage() {
        if allFieldsFilled {
            if MFMailComposeViewController.canSendMail() {
                showError = false
                showMailSheet = true
            } else {
                showMailError = true
            }
        } else {
            showError = true
        }
    }

    private func mailBody() -> String {
        """
        Full Name: \(fullName)
        Email: \(email)

        Message:
        \(description)
        """
    }

    private func clearForm() {
        fullName = ""
        email = ""
        subject = ""
        description = ""
    }
}

struct TermsPrivacyView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Terms").tag(0)
                Text("Privacy").tag(1)
                Text("Disclaimer").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(contentText)
                        .font(.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Terms & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentText: String {
        switch selectedTab {
        case 0:
            return termsContent
        case 1:
            return privacyContent
        default:
            return disclaimerContent
        }
    }

    private let termsContent = """
    TERMS OF USE

    Last Updated: June 11, 2026

    Welcome to CurrenSee. These Terms of Use ("Terms") govern your access to and use of the CurrenSee mobile application ("App"). By using the App, you agree to be bound by these Terms.

    1. ACCEPTANCE OF TERMS
    By downloading, installing, or using CurrenSee, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy.

    2. DESCRIPTION OF SERVICE
    CurrenSee is a currency converter app designed to help users convert amounts between currencies. The App allows users to:
    - Convert amounts manually between supported currencies
    - Scan prices with the camera to detect amounts
    - View exchange rate history for selected currency pairs
    - Customize interface settings such as dark mode

    3. USER ACCOUNTS
    You may use the App without creating an account.

    4. ACCEPTABLE USE
    You agree to use the App only for lawful purposes and in accordance with these Terms. You agree not to:
    - Use the App for any illegal or unauthorized purpose
    - Attempt to gain unauthorized access to any part of the App
    - Interfere with or disrupt the App's functionality
    - Use automated systems to abuse or overload the App

    5. INTELLECTUAL PROPERTY
    The App and its content, including but not limited to text, graphics, logos, and software, are the property of CurrenSee and are protected by copyright and other intellectual property laws.

    6. LIMITATION OF LIABILITY
    CurrenSee is provided "as is" without warranties of any kind. We do not guarantee that the App will be error-free or uninterrupted. In no event shall CurrenSee be liable for any indirect, incidental, or consequential damages.

    7. MODIFICATIONS TO TERMS
    We reserve the right to modify these Terms at any time. Your continued use of the App after any changes constitutes acceptance of the modified Terms.

    8. CONTACT INFORMATION
    If you have questions about these Terms, please contact us through the App's Help and support section.
    """

    private let privacyContent = """
    PRIVACY POLICY

    Last Updated: June 11, 2026

    At CurrenSee, we are committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our mobile application.

    1. LOCAL APP USAGE
    CurrenSee stores preferences such as dark mode, selected currencies, and your last conversion locally on your device.

    2. CAMERA FEATURES
    CurrenSee can request camera access to scan prices and detect amounts using on-device processing. Camera images are used only for this feature and are not stored by the App.

    3. NETWORK REQUESTS
    CurrenSee fetches exchange rates and historical rate data from third-party APIs when you convert currencies or view rate history. These requests include currency codes required to retrieve rates.

    4. DATA STORAGE
    App preferences and your last conversion are stored locally on your device. CurrenSee does not require a user account.

    5. DATA SHARING
    CurrenSee does not sell your personal data. Exchange rate requests may be processed by third-party providers and are subject to those providers' terms and privacy policies.

    6. DATA SECURITY
    Your data is protected by your device's built-in security features. We use iOS-provided storage and permission systems.

    7. CHILDREN'S PRIVACY
    CurrenSee is a utility app suitable for broad audiences. Since CurrenSee does not require account creation, personal data collection is limited.

    8. CHANGES TO THIS POLICY
    We may update this Privacy Policy from time to time. Changes will be reflected in this section.

    9. CONTACT US
    If you have any questions about this Privacy Policy, please contact us through the App's Help and support section.
    """

    private let disclaimerContent = """
    DISCLAIMER

    Last Updated: June 11, 2026

    EXCHANGE RATE NOTICE
    The exchange rates displayed in CurrenSee are based on publicly available sources and are intended for general information only. They may not reflect real-time or market-accurate rates. We do not guarantee the accuracy, completeness, or timeliness of the information. Use at your own discretion.

    1. NO WARRANTY
    CurrenSee is provided "as is" and "as available" without warranties, express or implied. We do not guarantee that the App will be error-free, uninterrupted, or free from defects.

    2. ACCURACY OF RATES
    While we strive to provide useful conversion results, we cannot guarantee absolute accuracy of exchange rates, historical data, or scanned amounts in every situation.

    3. LIMITATION OF LIABILITY
    To the fullest extent permitted by law, CurrenSee shall not be liable for indirect, incidental, special, consequential, or punitive damages, including financial loss arising from use of the App.

    4. USER RESPONSIBILITY
    Users are responsible for:
    - Verifying exchange rates when accuracy is critical
    - Using the app as a supplementary reference tool
    - Maintaining security and access control of their own device

    5. THIRD-PARTY SERVICES
    CurrenSee uses third-party services to provide exchange rates and historical data. These services are governed by their own terms and privacy policies.

    6. CHANGES TO THE APP
    We reserve the right to modify, suspend, or discontinue CurrenSee features at any time without prior notice.

    7. NO PROFESSIONAL ADVICE
    CurrenSee is intended for informational purposes only and does not constitute financial, investment, tax, or legal advice.

    8. ACCEPTANCE
    By using CurrenSee, you acknowledge that you have read, understood, and agree to this Disclaimer.
    """
}

struct AboutCurrenSeeView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About CurrenSee")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("CurrenSee is a currency converter app that helps you convert amounts quickly between currencies. Enter amounts manually or scan prices with your camera, view results instantly, and explore exchange rate history for your selected currency pair.")
                            .font(.body)
                            .multilineTextAlignment(.leading)

                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("About ABASHELARI")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("At ABASHELARI, we believe in creating software that makes everyday life simpler, smarter, and more enjoyable. Our mission is to develop innovative digital solutions that blend creativity with technology, offering users tools that are intuitive, reliable, and engaging.")
                            .font(.body)
                            .multilineTextAlignment(.leading)

                        Text("Whether it's educational apps, lifestyle tools, or entertainment experiences, ABASHELARI is dedicated to delivering high-quality products that inspire learning, spark curiosity, and bring value to people around the world.")
                            .font(.body)
                            .multilineTextAlignment(.leading)

                        Text("Driven by passion and guided by innovation, ABASHELARI is committed to continuous improvement and to building software that connects people with what matters most.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MailView: UIViewControllerRepresentable {
    var recipients: [String]
    var subject: String
    var body: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Binding var didFinish: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(result: $result, didFinish: $didFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        controller.mailComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var result: Result<MFMailComposeResult, Error>?
        @Binding var didFinish: Bool

        init(result: Binding<Result<MFMailComposeResult, Error>?>, didFinish: Binding<Bool>) {
            _result = result
            _didFinish = didFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            defer { controller.dismiss(animated: true) }
            if let error {
                self.result = .failure(error)
            } else {
                self.result = .success(result)
            }
            self.didFinish = true
        }
    }
}
