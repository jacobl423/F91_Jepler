# Start your Jepler watch

1. Unzip Jepler_Dev_Universal.zip and move Jepler Dev.app to Applications.
2. Open Jepler Dev. Easy Setup appears on each launch; you can reopen it from the main screen.
3. Choose an external KiCad PCB layout, application firmware, and matching MCUboot bootloader, then click Start Renode. Jepler Dev remembers these selections on this Mac using macOS file-access bookmarks; the files remain external and are never copied into or packaged with the app. Renode and its .NET runtime are built in.
4. Use keys 1, 2, and 3 for the watch buttons, then try Test notification.

Jepler Dev requires macOS 13 or newer and includes native runtimes for Intel and Apple Silicon.

Advanced settings lets developers select custom firmware, a project folder, or a different Renode executable. If startup fails, read the error on the main screen and the Terminal panel. If a remembered file has moved or macOS access has been revoked, select it again. A custom Renode script is optional and requires review before execution.

## Packaging a release

Run `bash Software/macOS_App/scripts/archive_app.sh` from the repository root. The app packages only emulator support and UI assets; PCB layouts, application firmware, bootloaders, and project scripts stay external. Building the app does not require a firmware build.

The packager downloads and checksum-verifies pinned official portable Renode builds for both architectures, retaining all upstream licenses under Contents/Resources/Renode/<architecture>/licenses. Downloads are cached in build/renode-cache. The pinned build is 1.16.1+20260828git00139efee, which provides both macOS architectures. Updating it requires updating both download hashes in scripts/bundle_renode.sh and testing firmware startup on both runtimes. Packaging needs network access on the first run and permission to mount the downloaded DMGs. Recipients do not need network access for setup.

## Testing external components

Run `swift test --package-path Software/macOS_App` for unit tests. After rebuilding the app, set `JEPLER_INTEGRATION_ROOT` to the absolute repository path when running the same command to enable the Renode integration test. It explicitly selects the external PCB and existing `build/renode-app` firmware pair, waits for the watch and UART test bridge, checks notification acknowledgment, and checks that clearing the bootloader stops emulation. It uses the packaged runtime for the current Mac architecture; the external firmware must include the test bridge.
