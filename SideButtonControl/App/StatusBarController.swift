import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let viewModel: DetectionViewModel
    private var statusItem: NSStatusItem?
    private var diagnosticsWindow: NSWindow?
    private var settingsWindow: NSWindow?
    // The icon is static; draw it once and reuse it instead of re-rendering on every refresh.
    private lazy var menuBarIcon: NSImage = Self.makeMenuBarIcon()

    init(viewModel: DetectionViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    func installMenuBarIcon() {
        guard statusItem == nil else {
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        refreshStatusItem()
    }

    func hideMenuBarIconUntilRelaunch() {
        guard let statusItem else {
            return
        }

        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    func showSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(viewModel: viewModel) { [weak self] in
            self?.showDiagnostics()
        }
        let hostingView = NSHostingView(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SideButtonControl"
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showDiagnostics() {
        if let diagnosticsWindow {
            diagnosticsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1_120, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SideButtonControl Tanılama"
        window.center()
        window.contentView = NSHostingView(rootView: ContentView(viewModel: viewModel))
        window.isReleasedWhenClosed = false
        window.delegate = self

        diagnosticsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        statusItem.image = menuBarIcon
        menu.addItem(statusItem)

        menu.addItem(.separator())
        let toggleItem = NSMenuItem(
            title: viewModel.isRunning ? "Eşlemeyi Durdur" : "Eşlemeyi Başlat",
            action: #selector(toggleRemapping),
            keyEquivalent: ""
        )
        toggleItem.image = NSImage(
            systemSymbolName: viewModel.isRunning ? "power.circle" : "bolt.circle",
            accessibilityDescription: nil
        )
        menu.addItem(toggleItem)
        let settingsItem = NSMenuItem(
            title: "Ayarlar...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil)
        menu.addItem(settingsItem)
        menu.addItem(
            NSMenuItem(
                title: "Tanılamayı Aç...",
                action: #selector(openDiagnostics),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Menü Çubuğu İkonunu Yeniden Açana Kadar Gizle",
                action: #selector(hideIcon),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "SideButtonControl'den Çık",
                action: #selector(quit),
                keyEquivalent: "q"
            )
        )

        for item in menu.items {
            item.target = self
        }

        return menu
    }

    private func refreshMenu() {
        refreshStatusItem()
    }

    func refreshStatusItem() {
        guard let button = statusItem?.button else {
            return
        }

        button.title = ""
        button.image = menuBarIcon
        button.imagePosition = .imageOnly
        button.toolTip = "\(statusTitle)\nTıkla: menüyü aç"
    }

    private var statusTitle: String {
        if viewModel.isRunning {
            return "SideButtonControl: Çalışıyor"
        }

        if viewModel.permissionSnapshot.canRemap {
            return "SideButtonControl: Durdu"
        }

        return "SideButtonControl: İzin Gerekli"
    }

    @objc
    private func statusItemClicked() {
        openMenu()
    }

    private func openMenu() {
        guard let button = statusItem?.button else {
            return
        }

        let menu = makeMenu()
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc
    private func toggleRemapping() {
        if viewModel.isRunning {
            viewModel.stopDetection()
        } else {
            viewModel.startDetection()
        }
        refreshMenu()
    }

    @objc
    private func openSettings() {
        showSettings()
    }

    @objc
    private func openDiagnostics() {
        showDiagnostics()
    }

    @objc
    private func hideIcon() {
        hideMenuBarIconUntilRelaunch()
    }

    @objc
    private func quit() {
        viewModel.stopDetection()
        NSApp.terminate(nil)
    }

    private static func makeMenuBarIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 20))
        image.lockFocus()

        NSColor.black.setStroke()

        let path = NSBezierPath()
        path.lineWidth = 1.8
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        path.move(to: NSPoint(x: 4.5, y: 10))
        path.line(to: NSPoint(x: 15.5, y: 10))

        path.move(to: NSPoint(x: 4.5, y: 10))
        path.line(to: NSPoint(x: 8, y: 6.5))
        path.move(to: NSPoint(x: 4.5, y: 10))
        path.line(to: NSPoint(x: 8, y: 13.5))

        path.move(to: NSPoint(x: 15.5, y: 10))
        path.line(to: NSPoint(x: 12, y: 6.5))
        path.move(to: NSPoint(x: 15.5, y: 10))
        path.line(to: NSPoint(x: 12, y: 13.5))

        path.stroke()
        image.unlockFocus()

        image.isTemplate = true
        return image
    }
}

extension StatusBarController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        let window = notification.object as? NSWindow
        if window === diagnosticsWindow {
            diagnosticsWindow = nil
        }
        if window === settingsWindow {
            settingsWindow = nil
        }
    }
}
