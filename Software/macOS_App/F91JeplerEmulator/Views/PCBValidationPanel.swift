import SwiftUI
import AppKit

public struct PCBValidationPanel: View {
    @ObservedObject var session: EmulatorSession
    @State private var filterSeverity: FilterSeverity = .all
    @State private var autoFixFeedback: String? = nil
    
    public var onSelectComponent: ((String) -> Void)? = nil
    
    public init(session: EmulatorSession, onSelectComponent: ((String) -> Void)? = nil) {
        self.session = session
        self.onSelectComponent = onSelectComponent
    }
    
    public enum FilterSeverity: String, CaseIterable, Identifiable {
        case all = "All"
        case errors = "Errors"
        case warnings = "Warnings"
        case passed = "Passed"
        case autoFix = "Auto-Fixable"
        
        public var id: String { rawValue }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header: Overall Design Score & Metrics
            if let result = session.pcbValidationResult {
                scoreHeaderCard(result: result)
            } else {
                HStack {
                    Text("No validation results available")
                    Spacer()
                    Button("Run Validation") { session.validateActiveBoard() }
                }
                .padding()
            }
            
            Divider()
            
            // Filter Bar & Export Actions
            HStack {
                Picker("Filter", selection: $filterSeverity) {
                    ForEach(FilterSeverity.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 340)
                
                Spacer()
                
                // Export Menu
                Menu {
                    Button("Export JSON Report...") { exportJSON() }
                    Button("Export CSV Report...") { exportCSV() }
                    Button("Export Email-Ready Markdown...") { exportMarkdown() }
                } label: {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                        .font(.system(size: 11))
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Auto-Fix Feedback Toast Banner
            if let toast = autoFixFeedback {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Button("Dismiss") { autoFixFeedback = nil }
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.18))
            }
            
            // Checks List
            List {
                ForEach(filteredChecks) { check in
                    ValidationCheckRow(
                        check: check,
                        onSelectComponent: { ref in
                            session.selectedFootprintID = ref
                            onSelectComponent?(ref)
                        },
                        onApplyAutoFix: {
                            applyAutoFix(for: check)
                        }
                    )
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)
        }
    }
    
    // MARK: - Header Score Card
    
    private func scoreHeaderCard(result: PCBValidationResult) -> some View {
        HStack(spacing: 20) {
            // Circular Score Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 54, height: 54)
                Circle()
                    .trim(from: 0, to: CGFloat(result.overallScore))
                    .stroke(
                        result.overallScore >= 0.85 ? Color.green : (result.overallScore >= 0.65 ? Color.orange : Color.red),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 54, height: 54)
                
                VStack(spacing: 0) {
                    Text("\(result.scorePercentage)%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Text("VALID")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Status and Board Dimensions
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("PCB VALIDATION ENGINE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    
                    if result.isReadyForFabrication {
                        Text("HEURISTIC CHECKS PASS")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(3)
                    } else {
                        Text("DRAFT / IN-PROGRESS")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(3)
                    }
                }
                
                Text("Board: \(session.pcbBoard.filename) (\(String(format: "%.1f", session.pcbBoard.widthMm)) × \(String(format: "%.1f", session.pcbBoard.heightMm)) mm)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Badges: Pass / Warning / Error Counts
            HStack(spacing: 12) {
                MetricCountBadge(count: result.passCount, label: "Passed", color: .green, icon: "checkmark.circle.fill")
                MetricCountBadge(count: result.warningCount, label: "Warnings", color: .orange, icon: "exclamationmark.triangle.fill")
                MetricCountBadge(count: result.errorCount, label: "Critical", color: .red, icon: "xmark.octagon.fill")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Filter Logic
    
    private var filteredChecks: [ValidationCheck] {
        guard let result = session.pcbValidationResult else { return [] }
        switch filterSeverity {
        case .all: return result.checks
        case .errors: return result.checks.filter { $0.severity == .error }
        case .warnings: return result.checks.filter { $0.severity == .warning }
        case .passed: return result.checks.filter { $0.severity == .pass }
        case .autoFix: return result.checks.filter { $0.autoFixable }
        }
    }
    
    // MARK: - Auto-Fix & Export
    
    private func applyAutoFix(for check: ValidationCheck) {
        if PCBValidator.applyAutoFix(check: check, board: &session.pcbBoard) {
            session.validateActiveBoard()
            self.autoFixFeedback = "Auto-fix applied successfully: \(check.fixActionDescription ?? check.title)"
        }
    }
    
    private func exportJSON() {
        guard let result = session.pcbValidationResult else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        struct ExportWrapper: Codable {
            let filename: String
            let generatedAt: Date
            let overallScore: Double
            let isReadyForFabrication: Bool
            let checks: [ValidationCheck]
            let componentBOM: [BOMEntry]
        }
        
        let wrapper = ExportWrapper(
            filename: session.pcbBoard.filename,
            generatedAt: result.generatedAt,
            overallScore: result.overallScore,
            isReadyForFabrication: result.isReadyForFabrication,
            checks: result.checks,
            componentBOM: result.componentBOM
        )
        
        guard let data = try? encoder.encode(wrapper), let jsonStr = String(data: data, encoding: .utf8) else { return }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "pcb_validation_\(session.pcbBoard.filename.replacingOccurrences(of: ".kicad_pcb", with: "")).json"
        if panel.runModal() == .OK, let url = panel.url {
            try? jsonStr.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func exportCSV() {
        guard let result = session.pcbValidationResult else { return }
        var csv = "Severity,Category,Title,Detail,RelatedComponent,Suggestion\n"
        for c in result.checks {
            let sev = c.severity.rawValue.uppercased()
            let cat = escapeCsv(c.category)
            let title = escapeCsv(c.title)
            let detail = escapeCsv(c.detail)
            let comp = escapeCsv(c.relatedComponentRef ?? "")
            let sug = escapeCsv(c.suggestion ?? "")
            csv += "\(sev),\(cat),\(title),\(detail),\(comp),\(sug)\n"
        }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "pcb_validation_\(session.pcbBoard.filename.replacingOccurrences(of: ".kicad_pcb", with: "")).csv"
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func exportMarkdown() {
        guard let result = session.pcbValidationResult else { return }
        var md = "# PCB Validation Report: \(session.pcbBoard.filename)\n\n"
        md += "- **Overall Design Score:** \(result.scorePercentage)%\n"
        md += "- **Heuristic Status:** \(result.isReadyForFabrication ? "Heuristic checks pass; fabrication review required" : "Draft / Unrouted ⚠️")\n"
        md += "- **Board Envelope:** \(String(format: "%.2f", session.pcbBoard.widthMm)) × \(String(format: "%.2f", session.pcbBoard.heightMm)) mm\n"
        md += "- **Date:** \(Date().formatted())\n"
        md += "- **Passed:** \(result.passCount) | **Warnings:** \(result.warningCount) | **Critical:** \(result.errorCount)\n\n"
        
        md += "## Validation Checks\n\n"
        for c in result.checks {
            let icon = c.severity == .pass ? "✅" : (c.severity == .warning ? "⚠️" : "❌")
            md += "### \(icon) [\(c.category)] \(c.title)\n"
            md += "- **Detail:** \(c.detail)\n"
            if let ref = c.relatedComponentRef { md += "- **Component:** `\(ref)`\n" }
            if let sug = c.suggestion { md += "- **Recommendation:** \(sug)\n" }
            md += "\n"
        }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "PCB_Validation_Summary_\(session.pcbBoard.filename.replacingOccurrences(of: ".kicad_pcb", with: "")).md"
        if panel.runModal() == .OK, let url = panel.url {
            try? md.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func escapeCsv(_ str: String) -> String {
        let clean = str.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(clean)\""
    }
}

// MARK: - Check Row Component

struct ValidationCheckRow: View {
    let check: ValidationCheck
    let onSelectComponent: (String) -> Void
    let onApplyAutoFix: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Severity Icon
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 14))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title & Category Badge
                HStack(spacing: 6) {
                    Text(check.title)
                        .font(.system(size: 11, weight: .bold))
                    
                    Text(check.category.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.secondary)
                        .cornerRadius(3)
                    
                    if let comp = check.relatedComponentRef {
                        Button(action: { onSelectComponent(comp) }) {
                            Text(comp)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .help("Focus \(comp) on canvas")
                    }
                    
                    Spacer()
                    
                    if check.autoFixable {
                        Button(action: onApplyAutoFix) {
                            HStack(spacing: 3) {
                                Image(systemName: "wand.and.stars")
                                Text("Auto-Fix")
                            }
                            .font(.system(size: 9, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                        .tint(.green)
                    }
                }
                
                // Detail Message
                Text(check.detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                
                // Actionable Suggestion
                if let sug = check.suggestion {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Text(sug)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
    }
    
    private var iconName: String {
        switch check.severity {
        case .pass: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    private var iconColor: Color {
        switch check.severity {
        case .pass: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

struct MetricCountBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 10))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(6)
    }
}
