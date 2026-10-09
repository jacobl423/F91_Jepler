import XCTest
import UniformTypeIdentifiers
@testable import F91JeplerEmulator

final class AssetDropLoaderTests: XCTestCase {
    func testFinderURLRepresentationsPreserveSpacesAndUnicode() {
        let url = URL(fileURLWithPath: "/tmp/Watch files/café #1.bin")
        XCTAssertEqual(AssetDropLoader.decode(url as NSURL), url)
        XCTAssertEqual(AssetDropLoader.decode(url.dataRepresentation as NSData), url)
        XCTAssertEqual(AssetDropLoader.decode(url.absoluteString as NSString), url)
        XCTAssertNil(AssetDropLoader.decode("https://example.com/app.bin" as NSString))
        XCTAssertNil(AssetDropLoader.decode(nil))
    }

    func testLoadsFinderDataProvider() async {
        let url = URL(fileURLWithPath: "/tmp/External Components/app.signed.bin")
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier, visibility: .all) { completion in
            completion(url.dataRepresentation, nil)
            return nil
        }
        let loaded: URL? = await withCheckedContinuation { continuation in
            AssetDropLoader.load(provider) { continuation.resume(returning: $0) }
        }
        XCTAssertEqual(loaded, url)
    }
}
