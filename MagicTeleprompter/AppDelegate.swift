import SwiftUI
import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    private var statusItem: NSStatusItem!
    private var mainWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    let scriptStore = ScriptStore()
    let playbackEngine = PlaybackEngine()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        showWindow()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "text.viewfinder",
                accessibilityDescription: "Magic Teleprompter"
            )
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }

    @objc private func statusItemClicked() {
        if let window = mainWindow, window.isVisible {
            window.orderOut(nil)
        } else {
            showWindow()
        }
    }

    // MARK: - Window

    private func showWindow() {
        if mainWindow == nil {
            createWindow()
        }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow() {
        guard let screen = NSScreen.main else { return }

        let width: CGFloat = 500
        let height: CGFloat = 260
        let x = (screen.frame.width - width) / 2
        let y = screen.visibleFrame.maxY - height

        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.minSize = NSSize(width: 340, height: 180)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self

        let content = TeleprompterView()
            .environmentObject(scriptStore)
            .environmentObject(playbackEngine)

        window.contentView = NSHostingView(rootView: content)
        window.sharingType = playbackEngine.hideFromRecording ? .none : .readOnly
        mainWindow = window

        playbackEngine.$hideFromRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hidden in
                self?.applySharingType(hidden: hidden)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let window = notification.object as? NSWindow,
                      self.playbackEngine.hideFromRecording,
                      window.parent == self.mainWindow || window == self.mainWindow else {
                    return
                }
                window.sharingType = .none
            }
            .store(in: &cancellables)
    }

    private func applySharingType(hidden: Bool) {
        let type: NSWindow.SharingType = hidden ? .none : .readOnly
        mainWindow?.sharingType = type
        for child in mainWindow?.childWindows ?? [] {
            child.sharingType = type
        }
    }

    // MARK: - Window Delegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
