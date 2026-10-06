# EmulatorSession Integration Specification for Milestone 1

## 1. New Published State & Persistence Keys

Add to `EmulatorSession`:
```swift
// MARK: - Asset Management & Sidebar State (Milestone 1 & 2)

@Published public var assets: [SessionAssetKind: SessionAsset] = [:]
@Published public var isSidebarVisible: Bool = UserDefaults.standard.object(forKey: "f91_sidebar_visible") as? Bool ?? true {
    didSet { UserDefaults.standard.set(isSidebarVisible, forKey: "f91_sidebar_visible") }
}
@Published public var sidebarWidth: CGFloat = {
    let saved = UserDefaults.standard.double(forKey: "f91_sidebar_width")
    return saved > 0 ? CGFloat(saved) : 280
}() {
    didSet { UserDefaults.standard.set(Double(sidebarWidth), forKey: "f91_sidebar_width") }
}
```

## 2. Asset Initialization in `loadEmbeddedDefaults()`

Replace or enhance `loadEmbeddedDefaults()` in `EmulatorSession`:
```swift
public func loadEmbeddedDefaults() {
    for kind in SessionAssetKind.allCases {
        initializeAsset(kind: kind)
    }
}

private func initializeAsset(kind: SessionAssetKind) {
    let persistedPath = UserDefaults.standard.string(forKey: kind.userDefaultsKey)
    let url: URL?
    let isCustom: Bool

    if let path = persistedPath, FileManager.default.fileExists(atPath: path) {
        url = URL(fileURLWithPath: path)
        isCustom = true
    } else {
        url = ResourceLoader.url(forResource: kind.defaultResourceName.name, withExtension: kind.defaultResourceName.ext)
        isCustom = false
    }

    var asset = SessionAsset(kind: kind, url: url, state: .inspecting, isCustom: isCustom)
    self.assets[kind] = asset

    guard let targetURL = url else {
        asset.state = .notLoaded
        self.assets[kind] = asset
        return
    }

    Task { [weak self] in
        do {
            let metadata = try await AssetInspector.inspect(url: targetURL, kind: kind, isCustom: isCustom)
            await MainActor.run {
                guard let self = self else { return }
                var updated = self.assets[kind] ?? SessionAsset(kind: kind)
                updated.url = targetURL
                updated.state = .loaded(metadata)
                updated.isCustom = isCustom
                self.assets[kind] = updated

                // Hook into legacy state variables for backward compatibility
                self.syncLegacyVariables(kind: kind, url: targetURL, isCustom: isCustom)
            }
        } catch {
            await MainActor.run {
                guard let self = self else { return }
                var updated = self.assets[kind] ?? SessionAsset(kind: kind)
                updated.state = .failed(error: error.localizedDescription)
                self.assets[kind] = updated
            }
        }
    }
}

private func syncLegacyVariables(kind: SessionAssetKind, url: URL, isCustom: Bool) {
    switch kind {
    case .pcb:
        self.activePCBURL = url
        if isCustom { self.customPCBURL = url }
        Task { [weak self] in
            if let board = try? await KiCadParser.parseAsync(fileURL: url) {
                await MainActor.run {
                    self?.pcbBoard = board
                    self?.validateActiveBoard()
                    self?.startWatchingActivePCB()
                }
            }
        }
    case .appFirmware:
        if isCustom { self.customAppBinURL = url }
    case .bootloader:
        if isCustom { self.customBootloaderURL = url }
    case .rescScript:
        if isCustom { self.customRescURL = url }
    }
}
```

## 3. Public Mutation API

```swift
// MARK: - Asset Management Actions

public func updateAsset(kind: SessionAssetKind, url: URL) {
    UserDefaults.standard.set(url.path, forKey: kind.userDefaultsKey)

    var asset = assets[kind] ?? SessionAsset(kind: kind)
    asset.url = url
    asset.isCustom = true
    asset.state = .inspecting
    assets[kind] = asset

    Task { [weak self] in
        do {
            let metadata = try await AssetInspector.inspect(url: url, kind: kind, isCustom: true)
            await MainActor.run {
                guard let self = self else { return }
                var updated = self.assets[kind] ?? SessionAsset(kind: kind)
                updated.url = url
                updated.isCustom = true
                updated.state = .loaded(metadata)
                self.assets[kind] = updated

                switch kind {
                case .pcb:
                    // Hot in-memory reload without restarting Renode
                    self.activePCBURL = url
                    self.customPCBURL = url
                    self.reloadPCB(fileURL: url)
                    self.startWatchingActivePCB()
                case .appFirmware:
                    self.customAppBinURL = url
                    if self.isRunning { self.startSession() }
                case .bootloader:
                    self.customBootloaderURL = url
                    if self.isRunning { self.startSession() }
                case .rescScript:
                    self.customRescURL = url
                    if self.isRunning { self.startSession() }
                }
            }
        } catch {
            await MainActor.run {
                guard let self = self else { return }
                var updated = self.assets[kind] ?? SessionAsset(kind: kind)
                updated.state = .failed(error: error.localizedDescription)
                self.assets[kind] = updated
            }
        }
    }
}

public func revertAssetToDefault(kind: SessionAssetKind) {
    UserDefaults.standard.removeObject(forKey: kind.userDefaultsKey)

    switch kind {
    case .pcb: self.customPCBURL = nil
    case .appFirmware: self.customAppBinURL = nil
    case .bootloader: self.customBootloaderURL = nil
    case .rescScript: self.customRescURL = nil
    }

    initializeAsset(kind: kind)

    if kind != .pcb && isRunning {
        startSession()
    }
}

public func reloadAsset(kind: SessionAssetKind) {
    guard let url = assets[kind]?.url else { return }
    updateAsset(kind: kind, url: url)
}

public func revealAssetInFinder(kind: SessionAssetKind) {
    guard let url = assets[kind]?.url else { return }
    NSWorkspace.shared.activateFileViewerSelecting([url])
}
```
