import XCTest
@testable import F91JeplerEmulator

final class AssetProvenanceTests: XCTestCase {
    func testManifestResolvesBuildArtifactsBesideImageAndStillChecksHashes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("build artifacts-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("zephyr"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let image = dir.appendingPathComponent("app.signed.bin")
        let elf = dir.appendingPathComponent("zephyr/zephyr.elf")
        let config = dir.appendingPathComponent("zephyr/.config")
        try Data("ELF fixture".utf8).write(to: elf)
        try Data("CONFIG_TEST=y".utf8).write(to: config)
        for absolute in [false, true] {
            let manifest = FirmwareBuildManifest(
                schemaVersion: 1, imageSHA256: "unused", mcubootSHA256: nil,
                sourceRevision: "test", sourceDirty: false, board: "test",
                elfPath: absolute ? elf.path : "zephyr/zephyr.elf",
                elfSHA256: try FirmwareBuildManifest.digest(elf),
                configPath: absolute ? config.path : nil,
                configSHA256: try FirmwareBuildManifest.digest(config), buttons: [],
                i2cSDA: nil, i2cSCL: nil, framebufferHeight: 40, visibleHeight: 39)
            XCTAssertEqual(try manifest.verifiedELF(relativeTo: image), elf.standardizedFileURL)
            XCTAssertNoThrow(try manifest.verifyConfig(relativeTo: image))
            let original = try Data(contentsOf: config)
            try Data("changed".utf8).write(to: config)
            XCTAssertThrowsError(try manifest.verifyConfig(relativeTo: image))
            try original.write(to: config)
        }
    }

    func testAssetInspectorHashesEntireFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("asset-\(UUID().uuidString).bin")
        defer { try? FileManager.default.removeItem(at: url) }
        var bytes = Data(repeating: 0x41, count: 16_384)
        try bytes.write(to: url)
        let first = try AssetInspector.inspectSynchronous(url: url, kind: .appFirmware, isCustom: true)
        bytes[bytes.count - 1] ^= 0xff
        try bytes.write(to: url)
        let second = try AssetInspector.inspectSynchronous(url: url, kind: .appFirmware, isCustom: true)
        XCTAssertNotNil(first.sha256)
        XCTAssertEqual(first.sha256?.count, 64)
        XCTAssertTrue(first.isSHA256Complete)
        XCTAssertTrue(second.isSHA256Complete)
        XCTAssertNotEqual(first.sha256, second.sha256)
    }

    func testRescStagingPreservesExactApprovedBytesAndRejectsChanges() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("resc-review-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = dir.appendingPathComponent("custom.resc")
        let staged = dir.appendingPathComponent("session.resc")
        let script = "using sysbus\n# reviewed script\ninclude @\"child.resc\"\n"
        try Data(script.utf8).write(to: source)
        let approvedDigest = try FirmwareBuildManifest.digest(source)
        XCTAssertEqual(try RenodeProcessManager.stageReviewedScript(at: source, to: staged, approvedSHA256: approvedDigest), approvedDigest)
        XCTAssertEqual(try Data(contentsOf: staged), Data(script.utf8))
        XCTAssertEqual(RenodeProcessManager.resourceReferences(in: script), ["child.resc"])
        let child = dir.appendingPathComponent("child.resc")
        try Data("# child\n".utf8).write(to: child)
        let before = try RenodeProcessManager.referenceEvidence(in: script, relativeTo: dir)
        try Data("# changed child\n".utf8).write(to: child)
        let after = try RenodeProcessManager.referenceEvidence(in: script, relativeTo: dir)
        XCTAssertNotEqual(before, after)
        try Data("changed".utf8).write(to: source)
        XCTAssertThrowsError(try RenodeProcessManager.stageReviewedScript(at: source, to: dir.appendingPathComponent("rejected.resc"), approvedSHA256: approvedDigest))
    }

    func testFirmwareManifestRejectsModifiedImage() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("manifest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let image = dir.appendingPathComponent("image.bin")
        try Data([1, 2, 3, 4]).write(to: image)
        let manifest = """
        {"schemaVersion":1,"imageSHA256":"wrong","mcubootSHA256":"wrong","sourceRevision":"test","sourceDirty":false,"board":"nrf52840dk/nrf52840","elfPath":"zephyr.elf","elfSHA256":"wrong","configSHA256":"wrong","buttons":[{"key":"1","label":"A","port":"gpio0","pin":1,"active_low":true},{"key":"2","label":"B","port":"gpio0","pin":2,"active_low":true},{"key":"3","label":"C","port":"gpio0","pin":3,"active_low":true}],"i2cSDA":null,"i2cSCL":null,"framebufferHeight":40,"visibleHeight":39}
        """
        try Data(manifest.utf8).write(to: dir.appendingPathComponent("firmware-manifest.json"))
        XCTAssertThrowsError(try FirmwareBuildManifest.load(for: image))
    }
}
