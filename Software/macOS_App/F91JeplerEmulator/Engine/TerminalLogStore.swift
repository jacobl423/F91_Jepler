import Foundation
import AppKit
import UniformTypeIdentifiers
import SwiftUI
import Combine

public struct TerminalLogLine: Identifiable, Equatable {
    public let id: Int
    public let raw: String
    public let category: LogCategory
    public let attributed: NSAttributedString
    
    public init(id: Int, raw: String) {
        self.id = id
        self.raw = raw
        
        // Categorize line
        var detected: LogCategory = .all
        for cat in LogCategory.allCases where cat != .all {
            if cat.matches(line: raw) {
                detected = cat
                break
            }
        }
        self.category = detected
        self.attributed = AnsiParser.parseToNSAttributedString(text: raw)
    }
    
    public static func == (lhs: TerminalLogLine, rhs: TerminalLogLine) -> Bool {
        lhs.id == rhs.id && lhs.raw == rhs.raw
    }
}

@MainActor
public final class TerminalLogStore: ObservableObject {
    public static let shared = TerminalLogStore()
    
    private var nextLineId: Int = 0
    public var onUartLine: ((String) -> Void)?
    
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
    public var filteredText: String { filteredLines.map(\.raw).joined(separator: "\n") }
    public let maximumLines: Int
    @Published public private(set) var discardedLineCount = 0
    @Published public private(set) var groupedRadioWarnings = 0
    private var seenRadioWarnings = Set<String>()
    private var radioWarningCounts: [String: Int] = [:]
    private var lastWarningSummary = Date()
    private var uartPartial = ""
    private var renodePartial = ""
    @Published public private(set) var logRevision: Int = 0
    
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
    
    public init(maximumLines: Int = 2000) {
        self.maximumLines = max(1, maximumLines)
    }
    
    deinit {
        batchFlushTimer?.invalidate()
        uartPollingTimer?.cancel()
    }
    
    public func copyVisibleLogs() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(filteredLines.map(\.raw).joined(separator: "\n"), forType: .string)
    }

    public func exportVisibleLogs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "f91_jepler_\(selectedTab == 0 ? "uart" : "renode")_log.txt"
        let text = AnsiParser.stripAnsi(from: filteredLines.map(\.raw).joined(separator: "\n"))
        if panel.runModal() == .OK, let url = panel.url {
            do { try text.write(to: url, atomically: true, encoding: .utf8) }
            catch { NSAlert(error: error).runModal() }
        }
    }

    // MARK: - Ingestion
    
    public func appendUart(text: String) {
        pendingUartBuffer += text
        scheduleFlush()
    }
    
    public func appendRenodeConsole(text: String) {
        // Filtering must happen after complete lines have been assembled.
        pendingRenodeBuffer += text
        scheduleFlush()
    }
    
    public func clear(tab: Int) {
        if tab == 0 {
            uartLines.removeAll()
            uartPartial = ""
            pendingUartBuffer = ""
        } else {
            renodeLines.removeAll()
            seenRadioWarnings.removeAll()
            radioWarningCounts.removeAll()
            groupedRadioWarnings = 0
            renodePartial = ""
            pendingRenodeBuffer = ""
        }
        updateFilteredLines()
    }
    
    private func scheduleFlush() {
        guard batchFlushTimer == nil else { return }
        let timer = Timer(timeInterval: 0.15, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.flushPendingBuffers() }
        }
        RunLoop.main.add(timer, forMode: .common)
        batchFlushTimer = timer
    }

    func flushPendingBuffers() {
        batchFlushTimer?.invalidate()
        batchFlushTimer = nil
        let uartChanged = consume(&pendingUartBuffer, partial: &uartPartial, into: &uartLines, onLine: onUartLine)
        let renodeChanged = consume(&pendingRenodeBuffer, partial: &renodePartial, into: &renodeLines, groupRadioWarnings: true)
        if selectedTab == 0 ? uartChanged : renodeChanged { updateFilteredLines() }
    }

    private func consume(_ pending: inout String, partial: inout String,
                         into lines: inout [TerminalLogLine], onLine: ((String) -> Void)? = nil, groupRadioWarnings: Bool = false) -> Bool {
        guard !pending.isEmpty else { return false }
        let text = partial + pending
        pending = ""
        // A transport chunk is not a line. Retain the unfinished record.
        let parts = text.components(separatedBy: "\n")
        partial = String((parts.last ?? "").suffix(8192))
        var changed = false
        var grouped = 0
        for raw in parts.dropLast() {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.contains("SaveFrame"),
                  line != "(monitor)", line != "(machine-0)" else { continue }
            onLine?(line)
            if groupRadioWarnings,
               let marker = line.range(of: "[WARNING] radio: Unhandled ") {
                let signature = String(line[marker.lowerBound...])
                if !seenRadioWarnings.insert(signature).inserted {
                    radioWarningCounts[signature, default: 0] += 1
                    grouped += 1
                    continue
                }
                // Bound the grouping index as well as the visible history.
                if seenRadioWarnings.count > 256 { seenRadioWarnings.removeAll() }
            }
            nextLineId += 1
            lines.append(TerminalLogLine(id: nextLineId, raw: String(line.prefix(8192))))
            changed = true
        }
        if grouped > 0 { groupedRadioWarnings += grouped }
        if groupRadioWarnings, Date().timeIntervalSince(lastWarningSummary) >= 5, !radioWarningCounts.isEmpty {
            for (warning, count) in radioWarningCounts.sorted(by: { $0.key < $1.key }) {
                nextLineId += 1
                lines.append(TerminalLogLine(id: nextLineId, raw: "\(warning) [repeated \(count) more times]"))
            }
            radioWarningCounts.removeAll()
            lastWarningSummary = Date()
            changed = true
        }
        if lines.count > maximumLines {
            let excess = lines.count - maximumLines
            lines.removeFirst(excess)
            discardedLineCount += excess
        }
        return changed
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
        self.logRevision &+= 1
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
