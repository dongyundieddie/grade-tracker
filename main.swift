import Cocoa
import WebKit
import UniformTypeIdentifiers

/// Thin native shell: shows index.html in a window and stores the JSON data
/// in ~/Library/Application Support/GradeTracker/data.json.
final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandlerWithReply, WKUIDelegate {
    var window: NSWindow!
    var web: WKWebView!

    let dataDir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GradeTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()
    var dataFile: URL { dataDir.appendingPathComponent("data.json") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMenu()

        let conf = WKWebViewConfiguration()
        conf.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: "store")
        web = WKWebView(frame: .zero, configuration: conf)
        web.uiDelegate = self

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Grade Tracker · 成绩追踪"
        window.contentView = web
        window.minSize = NSSize(width: 820, height: 560)
        let restored = window.setFrameUsingName("MainWindow")
        // If there is no saved frame, or it is not fully on a screen, centre on the main screen.
        let fullyVisible = NSScreen.screens.contains { $0.visibleFrame.contains(window.frame) }
        if !restored || !fullyVisible {
            if let vf = NSScreen.main?.visibleFrame {
                var f = window.frame
                f.size.width = min(f.width, vf.width); f.size.height = min(f.height, vf.height)
                f.origin = NSPoint(x: vf.midX - f.width / 2, y: vf.midY - f.height / 2)
                window.setFrame(f, display: false)
            }
        }
        window.setFrameAutosaveName("MainWindow")
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: JS bridge
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        guard let body = message.body as? [String: Any], let op = body["op"] as? String else {
            replyHandler(nil, "bad message"); return
        }
        switch op {
        case "load":
            if let s = try? String(contentsOf: dataFile, encoding: .utf8) { replyHandler(s, nil) }
            else { replyHandler(NSNull(), nil) }

        case "save":
            guard let s = body["data"] as? String else { replyHandler(nil, "no data"); return }
            do {
                snapshotOncePerDay()
                try s.write(to: dataFile, atomically: true, encoding: .utf8)
                replyHandler(true, nil)
            } catch { replyHandler(nil, error.localizedDescription) }

        case "export":
            guard let s = body["data"] as? String else { replyHandler(nil, "no data"); return }
            let panel = NSSavePanel()
            panel.nameFieldStringValue = (body["name"] as? String) ?? "GradeTracker-backup.json"
            panel.allowedContentTypes = [.json]
            if panel.runModal() == .OK, let url = panel.url {
                do { try s.write(to: url, atomically: true, encoding: .utf8); replyHandler(true, nil) }
                catch { replyHandler(nil, error.localizedDescription) }
            } else { replyHandler(false, nil) }

        case "import":
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.json]
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.url, let s = try? String(contentsOf: url, encoding: .utf8) {
                replyHandler(s, nil)
            } else { replyHandler(NSNull(), nil) }

        default:
            replyHandler(nil, "unknown op")
        }
    }

    /// Keep the pre-change file the first time we save each day (backups/data-YYYY-MM-DD.json).
    func snapshotOncePerDay() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: dataFile.path) else { return }
        let dir = dataDir.appendingPathComponent("backups", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let dest = dir.appendingPathComponent("data-\(f.string(from: Date())).json")
        if !fm.fileExists(atPath: dest.path) { try? fm.copyItem(at: dataFile, to: dest) }
    }

    // MARK: JS alert / confirm
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = NSAlert(); a.messageText = message; a.runModal(); completionHandler()
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert(); a.messageText = message
        a.addButton(withTitle: "确定"); a.addButton(withTitle: "取消")
        completionHandler(a.runModal() == .alertFirstButtonReturn)
    }

    // MARK: menu (needed so ⌘C/⌘V/⌘Z work in text fields)
    func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem(); main.addItem(appItem)
        let app = NSMenu(); appItem.submenu = app
        app.addItem(withTitle: "关于 Grade Tracker", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: "隐藏 Grade Tracker", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(.separator())
        app.addItem(withTitle: "退出 Grade Tracker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "编辑"); editItem.submenu = edit
        edit.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "拷贝", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let view = NSMenu(title: "显示"); viewItem.submenu = view
        view.addItem(withTitle: "重新载入", action: #selector(reload), keyEquivalent: "r")

        let winItem = NSMenuItem(); main.addItem(winItem)
        let win = NSMenu(title: "窗口"); winItem.submenu = win
        win.addItem(withTitle: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "关闭", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        NSApp.mainMenu = main
    }
    @objc func reload() { web.reload() }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
