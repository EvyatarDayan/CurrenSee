import SwiftUI
import AVFoundation
import Vision

struct CameraScanView: View {
    @ObservedObject var viewModel: CurrencyConverterViewModel
    @ObservedObject var scanner: CameraTextScanner
    @State private var showClearButton = false
    @State private var pendingCameraConversion = false
    @State private var autoClearTask: Task<Void, Never>?

    private let autoClearDelay: TimeInterval = 20

    private var canConvert: Bool {
        scanner.detectedAmount != nil && !viewModel.cameraIsLoading && !showClearButton
    }

    var body: some View {
        GeometryReader { geometry in
            let helperHeight: CGFloat = 36
            let cameraTopExpansion: CGFloat = 24
            let cameraBottomExpansion: CGFloat = 40
            let minButtonHeight: CGFloat = 44
            let topInset: CGFloat = max(0, 24 - cameraTopExpansion)
            let sectionSpacing: CGFloat = 10
            let availableHeight = geometry.size.height - 24 - helperHeight - sectionSpacing
            let totalStackHeight = availableHeight * ConverterBoxLayout.stackScale
            let sectionHeight = max(0, (totalStackHeight - sectionSpacing) / 3)
            let buttonHeight = max(minButtonHeight, sectionHeight - cameraBottomExpansion)
            let bottomExpansionApplied = sectionHeight - buttonHeight
            let cameraHeight = max(
                0,
                sectionHeight * 2 + sectionSpacing + cameraTopExpansion + bottomExpansionApplied
            )

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: topInset)

                Spacer(minLength: 0)

                VStack(spacing: sectionSpacing) {
                    cameraSection
                        .frame(maxWidth: .infinity)
                        .frame(height: cameraHeight)

                    Button {
                        if showClearButton {
                            clearCameraResults()
                        } else {
                            convertDetectedAmount()
                        }
                    } label: {
                        HStack {
                            if viewModel.cameraIsLoading && !showClearButton {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(showClearButton ? "Clear" : "Convert")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .disabled(showClearButton ? false : !canConvert)
                    .background(actionButtonColor)
                    .cornerRadius(12)
                    .converterBoxShadow()
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                }
                .padding(.horizontal, ConverterBoxLayout.horizontalPadding)

                Spacer(minLength: 0)

                RatesLastUpdatedLabel(lastUpdateTime: viewModel.lastUpdateTime)
                    .padding(.top, 8)
                    .frame(height: helperHeight)
                    .padding(.horizontal, 32)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: viewModel.cameraConversionTick) { _, _ in
                guard pendingCameraConversion else { return }
                pendingCameraConversion = false
                showClearButton = true
                startAutoClearTimer()
            }
            .onChange(of: viewModel.cameraErrorMessage) { _, error in
                guard error != nil, pendingCameraConversion else { return }
                pendingCameraConversion = false
            }
            .onDisappear {
                autoClearTask?.cancel()
                autoClearTask = nil
            }
        }
    }

    private var actionButtonColor: Color {
        if showClearButton {
            return .orange
        }
        return canConvert ? .green : .gray
    }

    private func convertDetectedAmount() {
        guard let amount = scanner.detectedAmount else { return }
        pendingCameraConversion = true
        viewModel.convertCamera(amount: formatScannedAmount(amount))
    }

    private func clearCameraResults() {
        autoClearTask?.cancel()
        autoClearTask = nil
        showClearButton = false
        pendingCameraConversion = false
        viewModel.clearCameraResults()
    }

    private func startAutoClearTimer() {
        autoClearTask?.cancel()
        autoClearTask = Task {
            try? await Task.sleep(for: .seconds(autoClearDelay))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                clearCameraResults()
            }
        }
    }

    private var displaySourceAmount: Double {
        scanner.detectedAmount ?? 0
    }

    private var displayConvertedAmount: Double {
        viewModel.cameraLastConversion?.convertedAmount ?? 0
    }

    private var cameraSection: some View {
        GeometryReader { cameraGeometry in
            let overlayHorizontalPadding: CGFloat = 12
            let contentWidth = max(0, cameraGeometry.size.width - overlayHorizontalPadding * 2)

            ZStack {
                if scanner.permissionDenied {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Camera access is required to scan prices.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                } else {
                    CameraPreviewView(scanner: scanner)
                }

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appRed, lineWidth: 3)

                VStack {
                    Spacer()
                    CameraConversionBannerView(
                        sourceAmount: displaySourceAmount,
                        convertedAmount: displayConvertedAmount,
                        fromCurrency: viewModel.fromCurrency,
                        toCurrency: viewModel.toCurrency,
                        contentWidth: contentWidth
                    )
                        .padding(.horizontal, overlayHorizontalPadding)
                        .padding(.bottom, 16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .converterBoxShadow()
        }
    }

    private func formatScannedAmount(_ value: Double) -> String {
        AmountInputLimit.cameraDetectedAmountString(from: value) ?? "0"
    }
}

private struct MaxAmountWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CameraConversionBannerView: View {
    let sourceAmount: Double
    let convertedAmount: Double
    let fromCurrency: Currency
    let toCurrency: Currency
    let contentWidth: CGFloat

    @State private var amountColumnWidth: CGFloat = 0

    private let bannerAmountFontSize: CGFloat = 40
    private let bannerCodeFont: Font = .title3.weight(.semibold)

    private var innerWidth: CGFloat {
        max(0, contentWidth - 32)
    }

    var body: some View {
        VStack(spacing: 6) {
            bannerRow(
                amount: AmountDisplayFormat.format(sourceAmount),
                currency: fromCurrency,
                amountFontSize: bannerAmountFontSize,
                codeFont: bannerCodeFont,
                color: .white
            )

            HStack(spacing: 4) {
                HStack {
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.down")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                    Spacer(minLength: 0)
                }
                .frame(width: max(amountColumnWidth, 1))

                cameraCurrencyMeta(fromCurrency, codeFont: bannerCodeFont)
                    .opacity(0)
                    .accessibilityHidden(true)
            }

            bannerRow(
                amount: AmountDisplayFormat.format(convertedAmount),
                currency: toCurrency,
                amountFontSize: bannerAmountFontSize,
                codeFont: bannerCodeFont,
                color: .green
            )
        }
        .frame(maxWidth: contentWidth)
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onPreferenceChange(MaxAmountWidthKey.self) { amountColumnWidth = $0 }
    }

    private func bannerRow(
        amount: String,
        currency: Currency,
        amountFontSize: CGFloat,
        codeFont: Font,
        color: Color
    ) -> some View {
        HStack(spacing: 4) {
            CameraFittingAmountText(
                text: amount,
                fontSize: amountFontSize,
                weight: .bold,
                color: color
            )
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: MaxAmountWidthKey.self,
                        value: geometry.size.width
                    )
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            cameraCurrencyMeta(currency, codeFont: codeFont)
        }
        .frame(maxWidth: innerWidth, alignment: .center)
    }

    private func cameraCurrencyMeta(_ currency: Currency, codeFont: Font) -> some View {
        HStack(spacing: 4) {
            Text(currency.flag)
                .fixedSize()
            Text(currency.code)
                .font(codeFont)
                .foregroundStyle(.blue)
                .fixedSize()
        }
    }
}

private struct CameraFittingAmountText: View {
    let text: String
    let fontSize: CGFloat
    let weight: Font.Weight
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: weight))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .allowsTightening(true)
    }
}

// MARK: - Camera Preview

private struct CameraPreviewView: UIViewRepresentable {
    let scanner: CameraTextScanner

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = scanner.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.frame = uiView.bounds
    }
}

private final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Scanner

final class CameraTextScanner: NSObject, ObservableObject {
    @Published var detectedPreview: String?
    @Published var detectedAmount: Double?
    @Published var permissionDenied = false

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "currensee.camera.scan", qos: .userInitiated)
    private var isConfigured = false
    private let frameLock = NSLock()
    private var isProcessingFrame = false
    private var scanPausedUntil: Date?
    private let rescanDelay: TimeInterval = 2

    private var isScanPaused: Bool {
        guard let until = scanPausedUntil else { return false }
        return Date() < until
    }

    private var isActive = false

    /// Configures the capture session ahead of time so tab switches stay fast.
    func prepare() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.permissionDenied = false }
            processingQueue.async {
                self.configureIfNeeded()
            }
        case .notDetermined, .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func activate() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.permissionDenied = false }
            processingQueue.async {
                self.isActive = true
                self.configureIfNeeded()
                self.resumeSession()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.permissionDenied = !granted
                }
                if granted {
                    self.processingQueue.async {
                        self.isActive = true
                        self.configureIfNeeded()
                        self.resumeSession()
                    }
                }
            }
        default:
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }

    func deactivate() {
        processingQueue.async { [weak self] in
            guard let self else { return }
            self.isActive = false
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func resumeSession() {
        guard isConfigured, !session.isRunning else { return }
        session.startRunning()
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .medium

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(videoOutput)

        session.commitConfiguration()
        isConfigured = true
    }

    private func handleRecognizedText(_ strings: [String]) {
        if isScanPaused { return }

        let candidates = strings
            .compactMap { Self.extractPrice(from: $0) }
            .compactMap { AmountInputLimit.cameraDetectedAmount(from: $0) }
        guard let best = candidates.max() else {
            detectedPreview = nil
            detectedAmount = nil
            return
        }

        detectedPreview = AmountDisplayFormat.format(best)
        detectedAmount = best
        scanPausedUntil = Date().addingTimeInterval(rescanDelay)
    }

    nonisolated private static func extractPrice(from text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let pattern = #"(?<!\d)(?:\d{1,3}(?:[,\s]\d{3})+|\d+)(?:[.,]\d{1,2})?(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(cleaned.startIndex..., in: cleaned)
        let matches = regex.matches(in: cleaned, range: range)
        let values = matches.compactMap { match -> Double? in
            guard let swiftRange = Range(match.range, in: cleaned) else { return nil }
            return parseNumericString(String(cleaned[swiftRange]))
        }

        return values.max()
    }

    nonisolated private static func parseNumericString(_ raw: String) -> Double? {
        var normalized = raw.replacingOccurrences(of: " ", with: "")

        let commaCount = normalized.filter { $0 == "," }.count
        let dotCount = normalized.filter { $0 == "." }.count

        if commaCount == 1 && dotCount == 0 {
            normalized = normalized.replacingOccurrences(of: ",", with: ".")
        } else if commaCount >= 1 && dotCount == 1 {
            normalized = normalized.replacingOccurrences(of: ",", with: "")
        } else if commaCount >= 1 && dotCount == 0 {
            normalized = normalized.replacingOccurrences(of: ",", with: "")
        }

        return Double(normalized)
    }
}

extension CameraTextScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isActive else { return }

        frameLock.lock()
        if isProcessingFrame {
            frameLock.unlock()
            return
        }
        isProcessingFrame = true
        frameLock.unlock()

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            frameLock.lock()
            isProcessingFrame = false
            frameLock.unlock()
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, _ in
            defer {
                self?.frameLock.lock()
                self?.isProcessingFrame = false
                self?.frameLock.unlock()
            }
            guard let self else { return }

            let strings = (request.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string } ?? []

            DispatchQueue.main.async {
                self.handleRecognizedText(strings)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }
}
