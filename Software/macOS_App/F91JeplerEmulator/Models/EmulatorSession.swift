import Foundation
import Combine
import SwiftUI
import CoreGraphics

public enum ViewMode: String, CaseIterable, Identifiable {
    case watch = "Watch View"
    case pcb = "KiCad PCB"
    case gdb = "GDB CPU"
    case split = "Workbench"
    
    public var id: String { rawValue }
}

@MainActor
public final class EmulatorSession: ObservableObject {
    @Published public var isRunning: Bool = false
    @Published public var statusMessage: String = "Starting Renode..."
    @Published public var errorMessage: String? = nil
    
    @Published public var selectedViewMode: ViewMode = .split
    @Published public var watchPanelHeight: CGFloat = 210
    @Published public var terminalPanelHeight: CGFloat = 280
    @Published public var uartLogs: String = ""
    @Published public var processOutputBuffer: String = ""
    @Published public var oledImage: CGImage? = nil
    
    @Published public var pressedKeys: Set<String> = [] // "1", "2", "3"
    @Published public var pcbBoard: KiCadBoard = KiCadBoard()
    @Published public var comparisonPCBURL: URL? = nil
    @Published public var pcbDiffResult: PCBBoardDiffResult? = nil
    
    @Published public var pcbInspectorTab: Int = 0
    @Published public var pcbNetFilterText: String = ""
    @Published public var selectedFootprintID: String = ""
    
    @Published public var customPCBURL: URL? = nil
    @Published public var customAppBinURL: URL? = nil
    @Published public var customBootloaderURL: URL? = nil
    
    @Published public var showSetupSheet: Bool = false
    @Published public var isTargetedForDrop: Bool = false
    @Published public var terminalSearchText: String = ""
    @Published public var terminalAutoScroll: Bool = true
    
    @Published public var cpuInspector = CPUInspectorModel()
    
    private let processManager = RenodeProcessManager()
    private let socketClient = RenodeSocketClient()
    private let uartSocketClient = RenodeUartSocketClient()
    private var frameTimer: Timer?
    private var framePpmURL: URL?
    
    public init() {
        loadEmbeddedDefaults()
    }
    
    public func loadComparisonPCB(fileURL: URL) {
        self.comparisonPCBURL = fileURL
        if let draft = try? KiCadParser.parse(fileURL: fileURL) {
            self.pcbDiffResult = PCBDiffEngine.compare(base: self.pcbBoard, draft: draft)
            self.pcbInspectorTab = 3 // Jump to Diff tab
        }
    }
    
    public func toggleCpuPause() {
        cpuInspector.isPaused.toggle()
        if cpuInspector.isPaused {
            socketClient.send(command: "pause")
            socketClient.send(command: "sysbus.cpu PC")
            socketClient.send(command: "sysbus.cpu SP")
        } else {
            socketClient.send(command: "start")
        }
    }
    
    public func stepInstruction() {
        guard cpuInspector.isPaused else { return }
        socketClient.send(command: "sysbus.cpu Step")
        socketClient.send(command: "sysbus.cpu PC")
        socketClient.send(command: "sysbus.cpu SP")
    }
    
    public func refreshMemoryDump() {
        let hexAddr = cpuInspector.targetMemoryAddressHex
        socketClient.send(command: "sysbus ReadDoubleWord 0x\(hexAddr)")
    }
    
    public func loadEmbeddedDefaults() {
        if let embeddedPCB = customPCBURL ?? ResourceLoader.url(forResource: "f91_jepler", withExtension: "kicad_pcb") {
            if let board = try? KiCadParser.parse(fileURL: embeddedPCB) {
                self.pcbBoard = board
            }
        }
    }
    
    public func startSession() {
        guard let renodePath = RenodeProcessManager.findRenodeExecutable() else {
            self.errorMessage = "Renode executable not found. Please install Renode at /Applications/Renode.app"
            self.statusMessage = "Renode missing"
            return
        }
        
        guard let appBinURL = customAppBinURL ?? ResourceLoader.url(forResource: "app.signed", withExtension: "bin") else {
            self.errorMessage = "Missing embedded firmware app.signed.bin"
            self.statusMessage = "Missing Firmware"
            return
        }
        
        let bootloaderURL = customBootloaderURL ?? ResourceLoader.url(forResource: "mcuboot", withExtension: "elf")
        let ssd1306CsURL = ResourceLoader.url(forResource: "F91SSD1306", withExtension: "cs")
        let pcbURL = customPCBURL ?? ResourceLoader.url(forResource: "f91_jepler", withExtension: "kicad_pcb")
        
        if let pcb = pcbURL, let board = try? KiCadParser.parse(fileURL: pcb) {
            self.pcbBoard = board
        }
        
        do {
            let (port, uartPort) = try processManager.start(
                appBinURL: appBinURL,
                bootloaderURL: bootloaderURL,
                ssd1306CsURL: ssd1306CsURL,
                renodePath: renodePath
            )
            
            processManager.onOutputReceived = { [weak self] str in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.processOutputBuffer += str
                }
            }
            
            if let workDir = processManager.workDir {
                self.framePpmURL = workDir.appendingPathComponent("screen.ppm")
            }
            
            self.statusMessage = "Connecting socket (Port \(port)..."
            
            socketClient.onConnected = { [weak self] in
                Task { @MainActor in
                    self?.isRunning = true
                    self?.statusMessage = "Renode Connected & Running"
                    self?.setupInitialCommands()
                }
            }
            
            socketClient.onError = { [weak self] err in
                Task { @MainActor in
                    self?.errorMessage = err
                    self?.statusMessage = "Socket Error"
                }
            }
            
            uartSocketClient.onTextReceived = { [weak self] text in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.uartLogs += text
                    if self.uartLogs.count > 32000 {
                        self.uartLogs = String(self.uartLogs.suffix(16000))
                    }
                }
            }
            
            // Connect sockets with auto-retry
            self.socketClient.connect(port: port)
            self.uartSocketClient.connect(port: uartPort)
            
            startFramePolling()
            
        } catch {
            self.errorMessage = "Failed to launch Renode: \(error.localizedDescription)"
            self.statusMessage = "Launch Error"
        }
    }
    
    private func setupInitialCommands() {
        socketClient.send(command: "mach")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 11 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 12 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 24 true")
        socketClient.send(command: "start")
    }
    
    public func handleKeyDown(key: String) {
        guard !pressedKeys.contains(key) else { return }
        pressedKeys.insert(key)
        sendButtonGPIO(key: key, pressed: true)
    }
    
    public func handleKeyUp(key: String) {
        guard pressedKeys.contains(key) else { return }
        pressedKeys.remove(key)
        sendButtonGPIO(key: key, pressed: false)
    }
    
    private func sendButtonGPIO(key: String, pressed: Bool) {
        let pinStr: String
        switch key {
        case "1": pinStr = pcbBoard.buttonAPin
        case "2": pinStr = pcbBoard.buttonBPin
        case "3": pinStr = pcbBoard.buttonCPin
        default: return
        }
        
        let pinNum = pinStr.replacingOccurrences(of: "P0.", with: "")
        guard let pin = Int(pinNum) else { return }
        
        // Active low: pressed -> false (GND), released -> true (VCC)
        let activeHigh = !pressed
        socketClient.send(command: "sysbus.gpioPortA OnGPIO \(pin) \(activeHigh ? "true" : "false")")
    }
    
    public func rebootMachine() {
        socketClient.send(command: "machine Reset")
        setupInitialCommands()
        self.uartLogs += "\n--- MACHINE COLD REBOOT ---\n"
    }
    
    private func startFramePolling() {
        frameTimer?.invalidate()
        guard let ppmURL = self.framePpmURL else { return }
        let timer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                self.socketClient.send(command: "sysbus.twi0.display SaveFrame \"\(ppmURL.path)\"")
                if let data = try? Data(contentsOf: ppmURL), let cgImg = self.cgImageFromPPM(data: data) {
                    DispatchQueue.main.async {
                        self.oledImage = cgImg
                    }
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.frameTimer = timer
    }
    
    private nonisolated func cgImageFromPPM(data: Data) -> CGImage? {
        guard let strHeader = String(data: data.prefix(100), encoding: .ascii) else { return nil }
        let components = strHeader.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard components.count >= 4, components[0] == "P6" else { return nil }
        guard let width = Int(components[1]), let height = Int(components[2]), components[3] == "255" else { return nil }
        
        let expectedPixelBytes = width * height * 3
        guard data.count >= expectedPixelBytes else { return nil }
        let pixelData = data.suffix(expectedPixelBytes)
        
        let provider = CGDataProvider(data: pixelData as CFData)
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 24,
            bytesPerRow: width * 3,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
    
    public func stopSession() {
        uartSocketClient.disconnect()
        frameTimer?.invalidate()
        frameTimer = nil
        socketClient.disconnect()
        processManager.stop()
        isRunning = false
        statusMessage = "Stopped"
    }
    
    deinit {
        uartSocketClient.disconnect()
        frameTimer?.invalidate()
        socketClient.disconnect()
        processManager.stop()
    }
}
