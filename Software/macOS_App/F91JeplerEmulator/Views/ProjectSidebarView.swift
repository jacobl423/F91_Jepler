//
//  ProjectSidebarView.swift
//  F91JeplerEmulator
//
//  Collapsible left sidebar providing dedicated drag-and-drop cards,
//  live metadata inspection badges, and non-modal quick actions for
//  KiCad PCB, Firmware binaries, MCUboot bootloader, and Renode scripts.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - ProjectSidebarView

/// Collapsible left sidebar view managing emulator project assets and files.
public struct ProjectSidebarView: View {
    @ObservedObject public var session: EmulatorSession

    public init(session: EmulatorSession) {
        self.session = session
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Sidebar Header with collapse control & defaults reset
            SidebarHeaderView(session: session)

            Divider()

            // 2. Scrollable Asset Dropzone Cards
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    ForEach(SessionAssetKind.allCases) { kind in
                        SessionAssetCardView(kind: kind, session: session)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }
            .background(Color.clear)

            Divider()

            // 3. Sidebar Status Footer
            SidebarFooterView(session: session)
        }
        .frame(minWidth: 230, idealWidth: session.sidebarWidth, maxWidth: 380)
        .background(.ultraThinMaterial)
    }
}

// MARK: - SidebarHeaderView

private struct SidebarHeaderView: View {
    @ObservedObject var session: EmulatorSession

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "shippingbox.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 13, weight: .semibold))

            Text("Workbench Assets")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            // Revert all to defaults button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    session.loadEmbeddedDefaults()
                }
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Revert all 4 assets to embedded defaults")

            // Collapse sidebar button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    session.isSidebarVisible = false
                }
            }) {
                Image(systemName: "sidebar.leading")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Collapse Project Sidebar (⌘0 or ⌥⌘S)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - SessionAssetCardView

private struct SessionAssetCardView: View {
    let kind: SessionAssetKind
    @ObservedObject var session: EmulatorSession

    @State private var isTargeted: Bool = false
    @State private var dropError: String? = nil
    @State private var isHoveringCard: Bool = false

    private var asset: SessionAsset {
        session.assets[kind] ?? SessionAsset(kind: kind)
    }

    private var accentColor: Color {
        switch kind {
        case .pcb: return Color.green
        case .appFirmware: return Color.blue
        case .bootloader: return Color.orange
        case .rescScript: return Color.purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1. Card Header Row: Icon, Title, Status Pill
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 22, height: 22)

                    Image(systemName: kind.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(kind.title)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(.primary)
                    Text(kind.subtitle)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Spacer()

                AssetStatusPill(state: asset.state, isCustom: asset.isCustom)
            }

            // 2. Dedicated Dropzone Area
            DropzoneBox(
                asset: asset,
                kind: kind,
                accentColor: accentColor,
                isTargeted: isTargeted
            )
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }

            // 3. Inline Drop Error Warning (if any)
            if let error = dropError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 9))
                    Text(error)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(2)
                    Spacer()
                    Button(action: { dropError = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.red.opacity(0.12))
                .cornerRadius(4)
            }

            // 4. Non-Modal Quick Action Controls
            HStack(spacing: 5) {
                // Browse / Replace
                CardActionButton(
                    title: "Browse",
                    icon: "folder",
                    tooltip: "Choose replacement file for \(kind.title)",
                    action: { browseFile() }
                )

                // In-Memory Reload
                CardActionButton(
                    title: "Reload",
                    icon: "arrow.clockwise",
                    tooltip: "Reload file from disk in-memory",
                    action: { session.reloadAsset(kind: kind) }
                )
                .disabled(asset.fileURL == nil)

                // Revert to Default
                CardActionButton(
                    title: "Default",
                    icon: "arrow.uturn.backward",
                    tooltip: "Revert to embedded default resource",
                    action: { session.revertAssetToDefault(kind: kind) }
                )
                .disabled(!asset.isCustom)

                Spacer(minLength: 0)

                // Reveal in Finder
                CardActionButton(
                    title: nil,
                    icon: "magnifyingglass",
                    tooltip: "Reveal file in Finder",
                    action: { session.revealAssetInFinder(kind: kind) }
                )
                .disabled(asset.fileURL == nil)
            }
        }
        .padding(10)
        .workbenchGlass(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isTargeted ? accentColor : (isHoveringCard ? Color(NSColor.separatorColor) : Color(NSColor.separatorColor).opacity(0.35)),
                    lineWidth: isTargeted ? 2 : 1
                )
        )
        .shadow(
            color: isTargeted ? accentColor.opacity(0.3) : Color.black.opacity(0.04),
            radius: isTargeted ? 4 : 1,
            x: 0,
            y: 1
        )
        .onHover { inside in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHoveringCard = inside
            }
        }
        .contextMenu {
            Button("Browse / Replace...") { browseFile() }
            Button("Reload from Disk") { session.reloadAsset(kind: kind) }
                .disabled(asset.fileURL == nil)
            Button("Revert to Default") { session.revertAssetToDefault(kind: kind) }
                .disabled(!asset.isCustom)
            Divider()
            Button("Reveal in Finder") { session.revealAssetInFinder(kind: kind) }
                .disabled(asset.fileURL == nil)
            Button("Copy File Path") {
                if let path = asset.filePath {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                }
            }
            .disabled(asset.filePath == nil)
        }
    }

    // MARK: - Drop Handling

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        _ = provider.loadObject(ofClass: URL.self) { object, _ in
            guard let url = object else {
                Task { @MainActor in
                    self.dropError = "Unable to read dropped file URL"
                }
                return
            }

            Task { @MainActor in
                let ext = url.pathExtension.lowercased()
                let allowed = self.kind.allowedExtensions.map { $0.lowercased() }

                if allowed.contains(ext) {
                    self.dropError = nil
                    self.session.updateAsset(kind: self.kind, url: url)
                } else {
                    let allowedFormatted = allowed.map { ".\($0)" }.joined(separator: ", ")
                    let errStr = "Rejected .\(ext) (expected \(allowedFormatted))"
                    self.dropError = errStr
                    self.session.errorMessage = "Cannot assign .\(ext) to \(self.kind.title). Expected: \(allowedFormatted)"

                    // Auto dismiss local inline alert after 4s
                    Task {
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        if self.dropError == errStr {
                            self.dropError = nil
                        }
                    }
                }
            }
        }
        return true
    }

    // MARK: - NSOpenPanel File Picker

    private func browseFile() {
        let panel = NSOpenPanel()
        panel.title = "Select \(kind.title)"
        panel.message = "Choose a file for \(kind.subtitle)"
        panel.prompt = "Select"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        let types = kind.allowedExtensions.compactMap { UTType(filenameExtension: $0) }
        if !types.isEmpty {
            panel.allowedContentTypes = types
        }
        panel.allowsOtherFileTypes = false

        if let currentPath = asset.filePath, FileManager.default.fileExists(atPath: currentPath) {
            panel.directoryURL = URL(fileURLWithPath: currentPath).deletingLastPathComponent()
        }

        if panel.runModal() == .OK, let selectedURL = panel.url {
            session.updateAsset(kind: kind, url: selectedURL)
        }
    }
}

// MARK: - DropzoneBox

private struct DropzoneBox: View {
    let asset: SessionAsset
    let kind: SessionAssetKind
    let accentColor: Color
    let isTargeted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isTargeted ?
                        accentColor.opacity(0.12) :
                        Color(NSColor.windowBackgroundColor).opacity(0.55)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isTargeted ? accentColor : Color(NSColor.separatorColor).opacity(0.45),
                            style: isTargeted ? StrokeStyle(lineWidth: 2) : StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )

            if isTargeted {
                // Drag-over visual feedback
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)
                    Text("Drop to replace \(kind.title)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentColor)
                    Text(kind.allowedExtensions.map { ".\($0)" }.joined(separator: " · "))
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if asset.url != nil {
                // Live metadata display
                VStack(alignment: .leading, spacing: 4) {
                    // Filename (middle truncated, full path tooltip)
                    HStack(spacing: 4) {
                        Image(systemName: "doc")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(asset.fileName)
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .help(asset.filePath ?? asset.fileName)

                    // Format Badge + Secondary Detail
                    HStack(spacing: 4) {
                        FormatBadge(text: asset.formatBadge, color: accentColor)

                        Text(asset.secondaryDetail)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Size, Date, SHA-256
                    HStack(spacing: 4) {
                        Text(asset.fileSizeFormatted)
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)

                        Text("·")
                            .font(.system(size: 8.5))
                            .foregroundColor(.secondary)

                        Text(asset.modificationDateFormatted)
                            .font(.system(size: 8.5))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if let sha = asset.metadata?.sha256Prefix {
                            Text("·")
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                            Text("sha:\(sha)")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Empty state prompt
                VStack(spacing: 3) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Drop \(kind.allowedExtensions.map { ".\($0)" }.joined(separator: ", ")) here")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
            }
        }
        .frame(minHeight: 64)
    }
}

// MARK: - FormatBadge & AssetStatusPill

private struct FormatBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .cornerRadius(3)
    }
}

private struct AssetStatusPill: View {
    let state: AssetLoadState
    let isCustom: Bool

    var body: some View {
        Group {
            switch state {
            case .inspecting:
                HStack(spacing: 3) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("SCAN")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(4)

            case .failed, .missing:
                HStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 7))
                    Text("ERROR")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(4)
                .help(state.errorMessage ?? "Asset load failure")

            default:
                if isCustom {
                    Text("CUSTOM")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(Color.blue.opacity(0.18))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                } else {
                    Text("EMBEDDED")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(Color(NSColor.separatorColor).opacity(0.25))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)
                }
            }
        }
    }
}

// MARK: - CardActionButton

private struct CardActionButton: View {
    let title: String?
    let icon: String
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                if let t = title {
                    Text(t)
                        .font(.system(size: 9.5, weight: .medium))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
        .help(tooltip)
    }
}

// MARK: - SidebarFooterView

private struct SidebarFooterView: View {
    @ObservedObject var session: EmulatorSession

    var body: some View {
        VStack(spacing: 6) {
            // Hot reload notification toast (if active)
            if let toast = session.pcbReloadToast {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 9))
                    Text(toast)
                        .font(.system(size: 9, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.14))
                .cornerRadius(4)
            }

            // Status metrics row
            HStack(spacing: 6) {
                // PCB Watcher status
                HStack(spacing: 3) {
                    Circle()
                        .fill(session.isPCBWatcherActive ? Color.green : Color.gray)
                        .frame(width: 5.5, height: 5.5)
                    Text(session.isPCBWatcherActive ? "PCB Sync" : "PCB Idle")
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Text("·")
                    .foregroundColor(.secondary)
                    .font(.system(size: 8.5))

                // Renode simulation status
                HStack(spacing: 3) {
                    Circle()
                        .fill(session.isRunning ? Color.green : Color.red)
                        .frame(width: 5.5, height: 5.5)
                    Text(session.isRunning ? "Renode Active" : "Renode Idle")
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Keyboard shortcut hint
                Text("⌘0")
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(3)
                    .help("Toggle sidebar with ⌘0 or ⌥⌘S")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
