// swift-tools-version:5.9
import PackageDescription

import Foundation

var swiftSettings: [SwiftSetting] = []
let xcodePluginDir = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"
if FileManager.default.fileExists(atPath: xcodePluginDir) {
    swiftSettings.append(.unsafeFlags(["-plugin-path", xcodePluginDir]))
}

let package = Package(
    name: "F91JeplerEmulator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "F91JeplerEmulator", targets: ["F91JeplerEmulator"])
    ],
    targets: [
        .executableTarget(
            name: "F91JeplerEmulator",
            path: "F91JeplerEmulator",
            exclude: [
                "F91JeplerEmulator.entitlements",
                "Resources/Info.plist",
                "Resources/AppIcon.icns"
            ],
            resources: [
                .copy("Resources/Embedded")
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageVersions: [.v5]
)
