import Foundation
import Network

public final class RenodeUartSocketClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.jepler.renode.uart.socket", qos: .userInteractive)
    
    public var onTextReceived: ((String) -> Void)?
    public private(set) var isConnected: Bool = false
    
    private var targetPort: UInt16 = 0
    private var attempts = 0
    
    public init() {}
    
    public func connect(port: UInt16) {
        disconnect()
        self.targetPort = port
        self.attempts = 0
        tryConnect()
    }
    
    private func tryConnect() {
        guard !isConnected else { return }
        attempts += 1
        
        let endpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: NWEndpoint.Port(integerLiteral: targetPort))
        let nwConnection = NWConnection(to: endpoint, using: .tcp)
        
        nwConnection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isConnected = true
                self.attempts = 0
                self.receiveNext()
            case .failed, .waiting:
                self.isConnected = false
                self.connection = nil
                nwConnection.cancel()
                self.scheduleRetry()
            default:
                break
            }
        }
        
        self.connection = nwConnection
        nwConnection.start(queue: queue)
    }
    
    private func scheduleRetry() {
        guard !isConnected, attempts < 30 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.tryConnect()
        }
    }
    
    private func receiveNext() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let data = data, !data.isEmpty,
               let str = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                self.onTextReceived?(str)
            }
            if !isComplete && error == nil {
                self.receiveNext()
            } else {
                self.isConnected = false
            }
        }
    }
    
    public func disconnect() {
        isConnected = false
        connection?.cancel()
        connection = nil
    }
}
