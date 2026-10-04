import Foundation
import Network

public final class RenodeUartSocketClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.jepler.renode.uart.socket", qos: .userInteractive)
    
    public var onTextReceived: ((String) -> Void)?
    public private(set) var isConnected: Bool = false
    private var isConnecting = false
    
    private var targetPort: UInt16 = 0
    
    public init() {}
    
    public func connect(port: UInt16) {
        disconnect()
        self.targetPort = port
        self.isConnecting = false
        tryConnect()
    }
    
    private func tryConnect() {
        guard !isConnected, !isConnecting, targetPort > 0 else { return }
        isConnecting = true
        
        let endpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: NWEndpoint.Port(integerLiteral: targetPort))
        let nwConnection = NWConnection(to: endpoint, using: .tcp)
        
        nwConnection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isConnected = true
                self.isConnecting = false
                self.receiveNext()
            case .failed, .waiting:
                self.isConnected = false
                self.isConnecting = false
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
        guard !isConnected else { return }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) { [weak self] in
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
                self.scheduleRetry()
            }
        }
    }
    
    public func disconnect() {
        isConnected = false
        isConnecting = false
        connection?.cancel()
        connection = nil
    }
}
