import Foundation
import Network

public final class RenodeSocketClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.jepler.renode.socket", qos: .userInteractive)
    
    public var onConnected: (() -> Void)?
    public var onError: ((String) -> Void)?
    public var onOutputReceived: ((String) -> Void)?
    public private(set) var isConnected: Bool = false
    
    private var retryTimer: Timer?
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
                self.onConnected?()
                self.receiveNext()
            case .failed(let error):
                self.isConnected = false
                self.connection = nil
                self.scheduleRetry(error: error.localizedDescription)
            case .waiting(let error):
                // Server port not open yet (e.g. ECONNREFUSED)
                self.connection = nil
                nwConnection.cancel()
                self.scheduleRetry(error: error.localizedDescription)
            default:
                break
            }
        }
        
        self.connection = nwConnection
        nwConnection.start(queue: queue)
    }
    
    private func scheduleRetry(error: String) {
        guard !isConnected else { return }
        if attempts < 30 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.tryConnect()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onError?("Failed to connect to Renode socket on port \(self?.targetPort ?? 0): \(error)")
            }
        }
    }
    
    public func send(command: String, completion: ((Result<String, Error>) -> Void)? = nil) {
        guard let connection = connection, isConnected else {
            completion?(.failure(NSError(domain: "RenodeSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket not connected"])))
            return
        }
        
        let formatted = command.trimmingCharacters(in: .whitespacesAndNewlines) + "\r\n"
        guard let data = formatted.data(using: .utf8) else { return }
        
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success("Sent"))
            }
        }))
    }
    
    private func receiveNext() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                let cleaned = self.cleanTelnetData(data)
                if !cleaned.isEmpty {
                    DispatchQueue.main.async {
                        self.onOutputReceived?(cleaned)
                    }
                }
            }
            
            if isComplete || error != nil {
                self.isConnected = false
                return
            }
            self.receiveNext()
        }
    }
    
    /// Strips RFC 854 Telnet command sequences (IAC 0xFF ...) and cleanly decodes UTF-8 text
    private func cleanTelnetData(_ data: Data) -> String {
        var cleanBytes = [UInt8]()
        cleanBytes.reserveCapacity(data.count)
        
        var i = 0
        let bytes = [UInt8](data)
        let count = bytes.count
        
        while i < count {
            let b = bytes[i]
            if b == 0xFF { // IAC
                if i + 1 < count {
                    let cmd = bytes[i + 1]
                    switch cmd {
                    case 0xFB, 0xFC, 0xFD, 0xFE: // WILL, WONT, DO, DONT (3 bytes)
                        i += 3
                    case 0xFA: // SB (subnegotiation) - skip until SE (0xFF 0xF0)
                        i += 2
                        while i + 1 < count && !(bytes[i] == 0xFF && bytes[i + 1] == 0xF0) {
                            i += 1
                        }
                        i += 2
                    case 0xFF: // Escaped 0xFF literal
                        cleanBytes.append(0xFF)
                        i += 2
                    default:
                        i += 2
                    }
                } else {
                    i += 1
                }
            } else {
                cleanBytes.append(b)
                i += 1
            }
        }
        
        return String(decoding: cleanBytes, as: UTF8.self)
    }
    
    public func disconnect() {
        retryTimer?.invalidate()
        retryTimer = nil
        isConnected = false
        connection?.cancel()
        connection = nil
    }
}
