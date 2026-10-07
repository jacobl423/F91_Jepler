import Foundation
import CryptoKit

public struct FirmwareButtonBinding: Codable, Equatable {
    public let key: String
    public let label: String
    public let port: String
    public let pin: Int
    public let activeLow: Bool
    enum CodingKeys: String, CodingKey {
        case key, label, port, pin
        case activeLow = "active_low"
    }
    public var pinName: String { "P\(port == "gpio1" ? 1 : 0).\(String(format: "%02d", pin))" }
    public var renodePort: String { port == "gpio1" ? "gpioPortB" : "gpioPortA" }
}

/// Build provenance and bindings exported from the *compiled* devicetree.
/// Never use a manifest unless its image digest matches the selected firmware.
public struct FirmwareBuildManifest: Codable {
    public let schemaVersion: Int
    public let imageSHA256: String
    public let mcubootSHA256: String?
    public let sourceRevision: String
    public let sourceDirty: Bool
    public let board: String
    public let elfPath: String
    public let elfSHA256: String
    public let configPath: String?
    public let configSHA256: String
    public let buttons: [FirmwareButtonBinding]
    public let i2cSDA: String?
    public let i2cSCL: String?
    public let framebufferHeight: Int
    public let visibleHeight: Int

    public var expectedPins: [String: String] {
        var pins: [String: String] = [:]
        for button in buttons {
            let name = ["1": "buttonA", "2": "buttonB", "3": "buttonC"][button.key]
            if let name { pins[name] = button.pinName }
        }
        pins["sda"] = i2cSDA
        pins["scl"] = i2cSCL
        return pins
    }

    public static func digest(_ url: URL) throws -> String {
        digest(data: try Data(contentsOf: url))
    }

    public static func digest(data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func load(for imageURL: URL) throws -> Self {
        let url = imageURL.deletingLastPathComponent().appendingPathComponent("firmware-manifest.json")
        let manifest = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard manifest.schemaVersion == 1, try digest(imageURL) == manifest.imageSHA256 else {
            throw ManifestError.invalid("Firmware manifest does not match the selected image. Rebuild firmware.")
        }
        guard manifest.mcubootSHA256 != nil else {
            throw ManifestError.invalid("Firmware manifest does not bind a matching MCUboot build. Rebuild firmware.")
        }
        guard Set(manifest.buttons.map(\.key)) == Set(["1", "2", "3"]), manifest.buttons.count == 3,
              manifest.buttons.allSatisfy({ ["gpio0", "gpio1"].contains($0.port) && (0...31).contains($0.pin) }),
              Set(manifest.buttons.map(\.pinName)).count == 3 else {
            throw ManifestError.invalid("Firmware manifest has invalid or duplicate GPIO bindings.")
        }
        return manifest
    }

    public func verifiedELF(relativeTo imageURL: URL) throws -> URL {
        let url = Self.resolve(elfPath, relativeTo: imageURL)
        guard try Self.digest(url) == elfSHA256 else {
            throw ManifestError.invalid("Debug ELF does not match the build manifest.")
        }
        return url
    }

    public func verifyMCUboot(_ url: URL) throws {
        guard let expected = mcubootSHA256, try Self.digest(url) == expected else {
            throw ManifestError.invalid("Selected MCUboot ELF does not match the firmware build manifest.")
        }
    }

    public func verifyConfig(relativeTo imageURL: URL) throws {
        let path = configPath ?? "zephyr/.config"
        let url = Self.resolve(path, relativeTo: imageURL)
        guard try Self.digest(url) == configSHA256 else {
            throw ManifestError.invalid("Firmware config no longer matches the build manifest.")
        }
    }

    private static func resolve(_ path: String, relativeTo imageURL: URL) -> URL {
        // Check the manifest string before URL initialization makes it absolute
        // against the process working directory.
        if path.hasPrefix("/") { return URL(fileURLWithPath: path).standardizedFileURL }
        return imageURL.deletingLastPathComponent().appendingPathComponent(path).standardizedFileURL
    }

    public enum ManifestError: LocalizedError {
        case invalid(String)
        public var errorDescription: String? { if case let .invalid(message) = self { return message }; return nil }
    }
}
