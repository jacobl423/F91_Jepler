import Foundation

public enum HarnessError: LocalizedError, Equatable {
    case failure(String)

    public var errorDescription: String? {
        if case let .failure(message) = self { return message }
        return nil
    }
}

/// Parses only explicit emulator test-bridge records; ordinary or stale UART text is not an acknowledgement.
public enum FirmwareHarnessProtocol {
    private static let ackPrefix = "[TEST] ACK "
    private static let statePrefix = "[TEST] STATE "

    /// Returns `OK` or the firmware's error detail for a matching request/field ACK.
    public static func acknowledgment(in output: String, id: UInt32, field: String) -> String? {
        for line in output.split(whereSeparator: { $0.isNewline }) {
            let text = String(line)
            guard text.hasPrefix(ackPrefix) else { continue }
            let parts = text.dropFirst(ackPrefix.count).split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            guard parts.count >= 3,
                  parts[0] == Substring(String(id)),
                  parts[1] == Substring(field),
                  parts[2] == "OK" || parts[2] == "ERR" else { continue }
            if parts[2] == "OK" { return "OK" }
            return parts.count == 4 ? "ERR \(parts[3])" : "ERR"
        }
        return nil
    }

    /// Returns the button bitmask from a state record for the exact requested ID.
    public static func buttonMask(in output: String, id: UInt32) -> Int? {
        for line in output.split(whereSeparator: { $0.isNewline }) {
            let text = String(line)
            guard text.hasPrefix(statePrefix) else { continue }
            let parts = text.dropFirst(statePrefix.count).split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 2, parts[0] == Substring(String(id)),
                  parts[1].hasPrefix("buttons="),
                  let mask = Int(parts[1].dropFirst("buttons=".count)), (0...7).contains(mask) else { continue }
            return mask
        }
        return nil
    }
}
