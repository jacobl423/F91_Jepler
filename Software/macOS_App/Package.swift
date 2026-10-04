// swift-tools-version:5.9
import PackageDescription

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
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
