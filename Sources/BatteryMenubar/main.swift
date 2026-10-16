import AppKit
import ServiceManagement

// `BatteryMenubar.app/Contents/MacOS/BatteryMenubar --unregister-login-item`
// lets uninstall.sh remove the login item without a GUI.
if CommandLine.arguments.contains("--unregister-login-item") {
    do {
        try SMAppService.mainApp.unregister()
        print("login item unregistered")
        exit(0)
    } catch {
        FileHandle.standardError.write("unregister failed: \(error.localizedDescription)\n".data(using: .utf8)!)
        exit(1)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
