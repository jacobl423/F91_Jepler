import Foundation

public enum TestStatus: String {
    case pending = "Pending"
    case running = "Running..."
    case passed = "PASSED"
    case failed = "FAILED"
}

public struct BootCheckStep: Identifiable {
    public let id = UUID()
    public let name: String
    public let expectedString: String
    public var status: TestStatus = .pending
    public var detail: String = ""
    public var durationMs: Int = 0
    
    public init(name: String, expectedString: String) {
        self.name = name
        self.expectedString = expectedString
    }
}

public enum ButtonKey: String, CaseIterable, Identifiable {
    case a = "1"
    case b = "2"
    case c = "3"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .a: return "Light (A)"
        case .b: return "Mode (B)"
        case .c: return "Alarm/Toggle (C)"
        }
    }
}

public struct ButtonSequenceStep: Identifiable {
    public let id = UUID()
    public let button: ButtonKey
    public let holdDurationMs: Int
    public let pauseAfterMs: Int
    
    public init(button: ButtonKey, holdDurationMs: Int = 150, pauseAfterMs: Int = 150) {
        self.button = button
        self.holdDurationMs = holdDurationMs
        self.pauseAfterMs = pauseAfterMs
    }
}

public struct SequencePreset: Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let steps: [ButtonSequenceStep]
    
    public init(name: String, description: String, steps: [ButtonSequenceStep]) {
        self.name = name
        self.description = description
        self.steps = steps
    }
    
    public static var defaultPresets: [SequencePreset] {
        return [
            SequencePreset(
                name: "Repeated Button B Hold Test",
                description: "Verifies button B held and released GPIO states; does not validate watch modes.",
                steps: [
                    ButtonSequenceStep(button: .b, holdDurationMs: 150, pauseAfterMs: 300),
                    ButtonSequenceStep(button: .b, holdDurationMs: 150, pauseAfterMs: 300),
                    ButtonSequenceStep(button: .b, holdDurationMs: 150, pauseAfterMs: 300)
                ]
            ),
            SequencePreset(
                name: "Button C / B / C Hold Test",
                description: "Verifies button C, B, and C held/released GPIO states; does not assert clock-format behavior.",
                steps: [
                    ButtonSequenceStep(button: .c, holdDurationMs: 150, pauseAfterMs: 300),
                    ButtonSequenceStep(button: .b, holdDurationMs: 150, pauseAfterMs: 300),
                    ButtonSequenceStep(button: .c, holdDurationMs: 150, pauseAfterMs: 300)
                ]
            ),
            SequencePreset(
                name: "Long-Press Hold Verification",
                description: "Tests extended button hold states (Button A 1000ms, Button B 1500ms)",
                steps: [
                    ButtonSequenceStep(button: .a, holdDurationMs: 1000, pauseAfterMs: 400),
                    ButtonSequenceStep(button: .b, holdDurationMs: 1500, pauseAfterMs: 400)
                ]
            ),
            SequencePreset(
                name: "Rapid Button Fuzzing Stress Test",
                description: "Fuzzes 12 rapid clicks across all 3 buttons to verify state machine doesn't deadlock",
                steps: [
                    ButtonSequenceStep(button: .a, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .b, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .c, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .b, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .a, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .c, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .b, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .c, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .a, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .b, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .c, holdDurationMs: 80, pauseAfterMs: 100),
                    ButtonSequenceStep(button: .b, holdDurationMs: 80, pauseAfterMs: 100)
                ]
            )
        ]
    }
}
