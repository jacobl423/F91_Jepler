import Foundation
import SwiftUI
import Combine

public struct TerminalLogLine: Identifiable, Equatable {
    public let id: Int
    public let raw: String
    public let attributedText: AttributedString
    public let category: LogCategory
    
    public init(id: Int, raw: String) {
        self.id = id
        self.raw = raw
        self.attributedText = AnsiParser.parseToAttributedString(text: raw)
        
        // Categorize line
        var detected: LogCategory = .all
        for cat in LogCategory.allCases where cat != .all {
            if cat.matches(line: raw) {
                detected = cat
                break
            }
        }
        self.category = detected
    }
}

@MainActor
public final class TerminalLogStore: ObservableObject {
    public static let shared = TerminalLogStore()
    
    // Line capacity limit for constant memory footprint
    private let maxLineCapacity: Int = 1000
    private var nextLineId: Int = 0
    
    // Tab 0: UART lines, Tab 1: Renode Monitor lines
    private var uartLines: [TerminalLogLine] = []
    private var renodeLines: [TerminalLogLine] = []
    
    @Published public var selectedTab: Int = 0 { // 0 = UART, 1 = Renode
        didSet { updateFilteredLines() }
    }
    @Published public var selectedCategory: LogCategory = .all {
        didSet { updateFilteredLines() }
    }
    @Published public var searchText: String = "" {
        didSet { updateFilteredLines() }
    }
    @Published public var autoScroll: Bool = true
    
    // Published filtered view for UI rendering with stable IDs
    @Published public private(set) var filteredLines: [TerminalLogLine] = []
    @Published public private(set) var filteredText: String = ""
    
    // Raw string caches for backwards compatibility, copy, export
    public var rawUartString: String {
        uartLines.map(\.raw).joined(separator: "\n")
    }
    public var rawRenodeString: String {
        renodeLines.map(\.raw).joined(separator: "\n")
    }
    
    // Queued pending chunks for batched ingestion
    private var pendingUartBuffer: String = ""
    private var pendingRenodeBuffer: String = ""
    private var batchFlushTimer: Timer?
    
    // Background UART File Tailer
    private var uartTailQueue = DispatchQueue(label: "org.jepler.uarttailer", qos: .utility)
    private var uartFileOffset: UInt64 = 0
    private var uartPollingTimer: DispatchSourceTimer?
    
    public init() {
        startBatchFlushTimer()
    }
    
    deinit {
        batchFlushTimer?.invalidate()
        uartPollingTimer?.cancel()
    }
    
    // MARK: - Ingestion
    
    public func appendUart(text: String) {
        pendingUartBuffer += text
        if pendingUartBuffer.count > 64_000 {
            pendingUartBuffer = String(pendingUartBuffer.suffix(32_000))
        }
    }
    
    public func appendRenodeConsole(text: String) {
        pendingRenodeBuffer += text
        if pendingRenodeBuffer.count > 64_000 {
            pendingRenodeBuffer = String(pendingRenodeBuffer.suffix(32_000))
        }
    }
    
    public func clear(tab: Int) {
        if tab == 0 {
            uartLines.removeAll()
            pendingUartBuffer = ""
        } else {
            renodeLines.removeAll()
            pendingRenodeBuffer = ""
        }
        updateFilteredLines()
    }
    
    private func startBatchFlushTimer() {
        batchFlushTimer?.invalidate()
        let timer = Timer(timeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.flushPendingBuffers()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.batchFlushTimer = timer
    }
    
    private func flushPendingBuffers() {
        var hasChanges = false
        
        if !pendingUartBuffer.isEmpty {
            let chunk = pendingUartBuffer
            pendingUartBuffer = ""
            processIncomingChunk(chunk, into: &uartLines)
            hasChanges = true
        }
        
        if !pendingRenodeBuffer.isEmpty {
            let chunk = pendingRenodeBuffer
            pendingRenodeBuffer = ""
            processIncomingChunk(chunk, into: &renodeLines)
            hasChanges = true
        }
        
        if hasChanges {
            updateFilteredLines()
        }
    }
    
    private func processIncomingChunk(_ chunk: String, into lineArray: inout [TerminalLogLine]) {
        let rawSplits = chunk.components(separatedBy: .newlines)
        for rawLine in rawSplits where !rawLine.isEmpty {
            nextLineId += 1
            let safeLine = rawLine.count > 1000 ? (String(rawLine.prefix(1000)) + " ... [truncated]") : rawLine
            let entry = TerminalLogLine(id: nextLineId, raw: safeLine)
            lineArray.append(entry)
        }
        
        if lineArray.count > maxLineCapacity {
            lineArray.removeFirst(lineArray.count - maxLineCapacity)
        }
    }
    
    public func updateFilteredLines() {
        let sourceLines = (selectedTab == 0) ? uartLines : renodeLines
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let matching: [TerminalLogLine]
        if selectedCategory == .all && query.isEmpty {
            matching = sourceLines
        } else {
            matching = sourceLines.filter { line in
                let catMatch = (selectedCategory == .all) || (line.category == selectedCategory) || selectedCategory.matches(line: line.raw)
                guard catMatch else { return false }
                
                if query.isEmpty { return true }
                return line.raw.localizedCaseInsensitiveContains(query)
            }
        }
        
        self.filteredLines = matching
        self.filteredText = matching.map(\.raw).joined(separator: "\n")
    }
    
    // MARK: - Background UART File Polling
    
    public func startBackgroundUartTail(fileURL: URL) {
        stopBackgroundUartTail()
        uartFileOffset = 0
        
        let timer = DispatchSource.makeTimerSource(queue: uartTailQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(75))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return }
            defer { try? fileHandle.close() }
            
            let currentSize = fileHandle.seekToEndOfFile()
            if currentSize > self.uartFileOffset {
                fileHandle.seek(toFileOffset: self.uartFileOffset)
                let newData = fileHandle.readDataToEndOfFile()
                self.uartFileOffset = currentSize
                
                if let str = String(data: newData, encoding: .utf8) ?? String(data: newData, encoding: .ascii), !str.isEmpty {
                    DispatchQueue.main.async { [weak self] in
                        self?.appendUart(text: str)
                    }
                }
            }
        }
        timer.resume()
        self.uartPollingTimer = timer
    }
    
    public func stopBackgroundUartTail() {
        uartPollingTimer?.cancel()
        uartPollingTimer = nil
        uartFileOffset = 0
    }
}
