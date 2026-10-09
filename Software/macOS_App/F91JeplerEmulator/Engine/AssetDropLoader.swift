import Foundation
import UniformTypeIdentifiers

/// Finder supplies public.file-url as data as well as URL objects.
enum AssetDropLoader {
    static func decode(_ item: NSSecureCoding?) -> URL? {
        let url: URL?
        if let value = item as? URL {
            url = value
        } else if let data = item as? Data {
            // Foundation's file URL data can contain unescaped filename characters.
            // A file drop has no query or fragment: preserve them as path characters.
            if let text = String(data: data, encoding: .utf8) {
                var allowed = CharacterSet.urlPathAllowed
                allowed.insert(charactersIn: ":/%")
                allowed.remove(charactersIn: "#?")
                url = text.addingPercentEncoding(withAllowedCharacters: allowed).flatMap { URL(string: $0) }
            } else {
                url = nil
            }
        } else if let text = item as? String {
            url = URL(string: text)
        } else {
            url = nil
        }
        guard let url, url.isFileURL else { return nil }
        return url.standardizedFileURL
    }

    static func load(_ provider: NSItemProvider, completion: @escaping (URL?) -> Void) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            completion(decode(item))
        }
    }
}
