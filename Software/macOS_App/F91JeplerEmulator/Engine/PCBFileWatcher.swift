import Foundation

public final class PCBFileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var watchedURL: URL?
    private var debounceTimer: Timer?
    private let debounceInterval: TimeInterval = 0.25
    
    public var onFileChanged: ((URL) -> Void)?
    public private(set) var isWatching: Bool = false
    
    public init() {}
    
    public func startWatching(url: URL) {
        stopWatching()
        self.watchedURL = url
        
        let path = url.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            NSLog("PCBFileWatcher: Failed to open file descriptor for %@", path)
            return
        }
        
        let queue = DispatchQueue(label: "org.jepler.pcbfilewatcher", qos: .utility)
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib, .rename, .delete],
            queue: queue
        )
        
        src.setEventHandler { [weak self] in
            guard let self = self else { return }
            let flags = src.data
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.debounceTimer?.invalidate()
                self.debounceTimer = Timer.scheduledTimer(withTimeInterval: self.debounceInterval, repeats: false) { [weak self] _ in
                    guard let self = self, let targetURL = self.watchedURL else { return }
                    
                    // If file was renamed or replaced by KiCad atomic save, re-attach watcher
                    if flags.contains(.rename) || flags.contains(.delete) {
                        self.startWatching(url: targetURL)
                    }
                    
                    self.onFileChanged?(targetURL)
                }
            }
        }
        
        src.setCancelHandler { [weak self] in
            guard let self = self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }
        
        src.resume()
        self.source = src
        self.isWatching = true
        NSLog("PCBFileWatcher: Actively watching %@", path)
    }
    
    public func stopWatching() {
        debounceTimer?.invalidate()
        debounceTimer = nil
        if let src = source {
            src.cancel()
            source = nil
        }
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
        isWatching = false
    }
    
    deinit {
        stopWatching()
    }
}
