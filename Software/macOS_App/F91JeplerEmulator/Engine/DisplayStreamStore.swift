import Foundation
import SwiftUI
import CoreGraphics

@MainActor
public final class DisplayStreamStore: ObservableObject {
    public static let shared = DisplayStreamStore()
    
    @Published public var oledImage: CGImage? = nil
    @Published public var displayMetrics = DisplayMetrics()
    @Published public var oledTheme: OLEDTheme = .cyan
    @Published public var showPixelGridMesh: Bool = true
    
    private var lastFrameTimes: [Double] = []
    private var frameTimer: Timer?
    private let decodeQueue = DispatchQueue(label: "org.jepler.framedecode", qos: .userInteractive)
    private var isDecodingFrame = false
    
    public init() {}
    
    deinit {
        frameTimer?.invalidate()
    }
    
    public func startPolling(socketSender: @escaping (String) -> Void, ppmURL: URL) {
        stopPolling()
        
        let timer = Timer(timeInterval: 0.125, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                socketSender("sysbus.twi0.display SaveFrame \"\(ppmURL.path)\"")
                self.scheduleFrameIngestion(ppmURL: ppmURL)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.frameTimer = timer
    }
    
    public func stopPolling() {
        frameTimer?.invalidate()
        frameTimer = nil
    }
    
    private func scheduleFrameIngestion(ppmURL: URL) {
        guard !isDecodingFrame else { return }
        isDecodingFrame = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        decodeQueue.async { [weak self] in
            guard let self = self else { return }
            guard let data = try? Data(contentsOf: ppmURL) else {
                DispatchQueue.main.async { self.isDecodingFrame = false }
                return
            }
            
            let result = Self.decodePPMFast(data: data)
            let latencyMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            
            DispatchQueue.main.async {
                self.isDecodingFrame = false
                guard let (cgImg, litCount) = result else { return }
                
                self.oledImage = cgImg
                self.displayMetrics.frameCount += 1
                self.displayMetrics.drawCallCount += 1
                self.displayMetrics.litPixelCount = litCount
                self.displayMetrics.lastFrameLatencyMs = latencyMs
                
                let now = CFAbsoluteTimeGetCurrent()
                self.lastFrameTimes.append(now)
                self.lastFrameTimes.removeAll { now - $0 > 1.0 }
                self.displayMetrics.fps = Double(self.lastFrameTimes.count)
            }
        }
    }
    
    /// High-performance zero-copy binary parser for P6 PPM images
    private nonisolated static func decodePPMFast(data: Data) -> (CGImage, Int)? {
        guard data.count > 16 else { return nil }
        
        return data.withUnsafeBytes { rawBuffer -> (CGImage, Int)? in
            guard let ptr = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            let totalBytes = data.count
            
            // Check Magic "P6"
            if ptr[0] != 0x50 || ptr[1] != 0x36 { return nil } // 'P', '6'
            
            var cursor = 2
            func skipWhitespaceAndComments() {
                while cursor < totalBytes {
                    let b = ptr[cursor]
                    if b == 0x23 { // '#' comment
                        while cursor < totalBytes && ptr[cursor] != 0x0A {
                            cursor += 1
                        }
                    } else if b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09 {
                        cursor += 1
                    } else {
                        break
                    }
                }
            }
            
            func readInt() -> Int? {
                skipWhitespaceAndComments()
                var value = 0
                var hasDigits = false
                while cursor < totalBytes {
                    let b = ptr[cursor]
                    if b >= 0x30 && b <= 0x39 { // '0'...'9'
                        value = value * 10 + Int(b - 0x30)
                        hasDigits = true
                        cursor += 1
                    } else {
                        break
                    }
                }
                return hasDigits ? value : nil
            }
            
            guard let width = readInt(), let height = readInt(), let maxVal = readInt(), maxVal == 255 else {
                return nil
            }
            
            // Single whitespace character follows maxVal before pixel data
            if cursor < totalBytes && (ptr[cursor] == 0x0A || ptr[cursor] == 0x20 || ptr[cursor] == 0x0D) {
                cursor += 1
            }
            
            let expectedPixelBytes = width * height * 3
            let headerOffset = cursor
            guard totalBytes >= headerOffset + expectedPixelBytes else { return nil }
            
            // Count lit pixels with fast SIMD/stride pointer
            var litCount = 0
            let pixelPtr = ptr + headerOffset
            for i in stride(from: 0, to: expectedPixelBytes, by: 3) {
                if pixelPtr[i] > 10 {
                    litCount += 1
                }
            }
            
            let subData = data.subdata(in: headerOffset..<(headerOffset + expectedPixelBytes))
            guard let provider = CGDataProvider(data: subData as CFData) else { return nil }
            
            guard let cgImg = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 24,
                bytesPerRow: width * 3,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            ) else {
                return nil
            }
            
            return (cgImg, litCount)
        }
    }
}
