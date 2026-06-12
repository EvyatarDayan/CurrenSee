import SwiftUI
import AVFoundation
import Vision

struct CameraScanView: View {
    @ObservedObject var viewModel: CurrencyConverterViewModel
    @ObservedObject var scanner: CameraTextScanner

    private var canConvert: Bool {
        scanner.detectedAmount != nil && !viewModel.isLoading
    }

    var body: some View {
        GeometryReader { geometry in
            let helperHeight: CGFloat = 36
            let topInset: CGFloat = 24
            let sectionSpacing: CGFloat = 10
            let availableHeight = geometry.size.height - topInset - helperHeight - sectionSpacing * 2
            let totalStackHeight = availableHeight * ConverterBoxLayout.stackScale
            let sectionHeight = max(0, (totalStackHeight - sectionSpacing * 2) / 3)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: topInset)

                Spacer(minLength: 0)

                VStack(spacing: sectionSpacing) {
                    cameraSection
                        .frame(maxWidth: .infinity)
                        .frame(height: sectionHeight)

                    ConversionResultSection(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .frame(height: sectionHeight)

                    Button {
                        guard let amount = scanner.detectedAmount else { return }
                        viewModel.amount = formatScannedAmount(amount)
                        viewModel.convert()
                    } label: {
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
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var cameraSection: some View {
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
                .stroke(Color.green, lineWidth: 3)

            VStack {
                Spacer()
                Text(scanner.detectedPreview ?? "0")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.55))
                    .cornerRadius(12)
                    .padding(.bottom, 16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .converterBoxShadow()
    }

    private func formatScannedAmount(_ value: Double) -> String {
        let formatted: String
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            formatted = String(format: "%.0f", value)
        } else {
            formatted = String(format: "%.2f", value)
        }
        return AmountInputLimit.clamp(formatted)
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

        let candidates = strings.compactMap { Self.extractPrice(from: $0) }
        guard let best = candidates.max() else {
            detectedPreview = nil
            detectedAmount = nil
            return
        }

        detectedPreview = Self.formatPreview(best)
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

    nonisolated private static func formatPreview(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
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
