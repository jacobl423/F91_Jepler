import Foundation

public enum NotificationCategory: UInt8, CaseIterable, Identifiable {
    case call = 0x01
    case sms = 0x02
    case email = 0x04
    case alert = 0x08
    
    public var id: UInt8 { rawValue }
    
    public var displayName: String {
        switch self {
        case .call: return "Incoming Call"
        case .sms: return "SMS Text Message"
        case .email: return "Email Message"
        case .alert: return "System Alert"
        }
    }
    
    public var iconName: String {
        switch self {
        case .call: return "phone.fill"
        case .sms: return "message.fill"
        case .email: return "envelope.fill"
        case .alert: return "exclamationmark.triangle.fill"
        }
    }
}

public struct NotificationPayload {
    public var category: NotificationCategory = .sms
    public var title: String = "Alice Smith"
    public var subtitle: String = "Meeting Update"
    public var message: String = "Ready to test F-91 Jepler watch firmware?"
    
    public init() {}
    
    public func serializeNotificationBar() -> [UInt8] {
        return [category.rawValue]
    }
    
    public func serializeIncomingCall() -> [UInt8] {
        let stringToSerialize = title.prefix(20)
        var bytes = Array(stringToSerialize.utf8)
        if bytes.count > 20 {
            bytes = Array(bytes.prefix(20))
        }
        return bytes
    }
    
    public func serializeIncomingText() -> [UInt8] {
        let stringToSerialize = message.prefix(20)
        var bytes = Array(stringToSerialize.utf8)
        if bytes.count > 20 {
            bytes = Array(bytes.prefix(20))
        }
        return bytes
    }
    
    public var hexSummary: String {
        let barHex = serializeNotificationBar().map { String(format: "%02X", $0) }.joined(separator: " ")
        let callHex = serializeIncomingCall().map { String(format: "%02X", $0) }.joined(separator: " ")
        let textHex = serializeIncomingText().map { String(format: "%02X", $0) }.joined(separator: " ")
        return "Bar: [\(barHex)] | Call: [\(callHex)] | Text: [\(textHex)]"
    }
}

public struct ClockSyncPayload {
    public var timestamp: UInt32
    public var timezoneOffsetMinutes: Int16
    public var is24HourMode: Bool
    public var isDST: Bool
    
    public init(date: Date = Date(), is24Hour: Bool = false) {
        self.timestamp = UInt32(date.timeIntervalSince1970)
        let tz = TimeZone.current
        self.timezoneOffsetMinutes = Int16(tz.secondsFromGMT(for: date) / 60)
        self.is24HourMode = is24Hour
        self.isDST = tz.isDaylightSavingTime(for: date)
    }
    
    public func serializeTime() -> [UInt8] {
        var val = timestamp.littleEndian
        return withUnsafeBytes(of: &val) { Array($0) }
    }
    
    public func serializeTimezone() -> [UInt8] {
        var val = UInt16(bitPattern: timezoneOffsetMinutes).littleEndian
        return withUnsafeBytes(of: &val) { Array($0) }
    }
    
    public func serializeTimeMode() -> [UInt8] {
        return [is24HourMode ? 1 : 0]
    }
    
    public func serializeDST() -> [UInt8] {
        return [isDST ? 1 : 0]
    }
    
    public var hexSummary: String {
        let timeHex = serializeTime().map { String(format: "%02X", $0) }.joined(separator: " ")
        let tzHex = serializeTimezone().map { String(format: "%02X", $0) }.joined(separator: " ")
        let modeHex = serializeTimeMode().map { String(format: "%02X", $0) }.joined(separator: " ")
        let dstHex = serializeDST().map { String(format: "%02X", $0) }.joined(separator: " ")
        return "Time: [\(timeHex)] | TZ: [\(tzHex)] | Mode: [\(modeHex)] | DST: [\(dstHex)]"
    }
}

public struct BatteryMockPayload {
    public var percentage: Int = 85 // 0 - 100
    public var voltageVolts: Double = 3.95 // 3.0V - 4.2V LiPo or 2.0V - 3.2V ML2016
    public var isCharging: Bool = false
    
    public init() {}
    
    public func serializeBASLevel() -> [UInt8] {
        return [UInt8(max(0, min(100, percentage)))]
    }
    
    public var isLowBattery: Bool {
        percentage <= 15 || voltageVolts < 3.3
    }
}

public struct GATTLogEntry: Identifiable {
    public let id = UUID()
    public let timestamp: Date = Date()
    public let service: String
    public let summary: String
    public let hexData: String
    public let status: String
    
    public init(service: String, summary: String, hexData: String, status: String = "Injected") {
        self.service = service
        self.summary = summary
        self.hexData = hexData
        self.status = status
    }
}
