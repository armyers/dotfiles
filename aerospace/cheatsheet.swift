import Cocoa

// ─── Transparent background view ─────────────────────────────────────────────
class BackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        NSColor(white: 0.08, alpha: 0.78).setFill()
        path.fill()
        NSColor(white: 0.3, alpha: 0.6).setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}

// ─── Borderless key window ───────────────────────────────────────────────────
class PopupWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// ─── App delegate ────────────────────────────────────────────────────────────
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: PopupWindow!

    // Section headers to highlight (green + bold)
    let sectionHeaders = ["WORKSPACES", "FOCUS / MOVE / JOIN", "LAYOUT", "MONITORS", "OTHER",
                          "SERVICE MODE", "DISMISS", "main monitor:", "built-in monitor:", "unassigned:"]
    // Title keyword to highlight (blue + bold)
    let titleKeyword = "AeroSpace Keybindings"

    func loadCheatsheet() -> String {
        let dir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
        let path = (dir as NSString).appendingPathComponent("cheatsheet.txt")
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            return content
        }
        return "  Could not load cheatsheet.txt\n  Place it next to the cheatsheet binary."
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let cheatsheet = loadCheatsheet()
        let lines = cheatsheet.components(separatedBy: "\n")
        let lineCount = CGFloat(lines.count)
        let lineHeight: CGFloat = 18
        let padding: CGFloat = 24
        let width: CGFloat = 750
        let height: CGFloat = lineCount * lineHeight + padding * 2

        guard let screen = NSScreen.main else { return }
        let x = (screen.frame.width - width) / 2
        let y = (screen.frame.height - height) / 2

        window = PopupWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true

        let bg = BackgroundView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = bg

        let scroll = NSScrollView(frame: NSRect(x: padding, y: padding,
                                                 width: width - padding * 2,
                                                 height: height - padding * 2))
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.hasHorizontalScroller = false

        let textView = NSTextView(frame: scroll.bounds)
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Menlo", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor(white: 0.70, alpha: 1.0),
            .paragraphStyle: style
        ]

        let full = NSMutableAttributedString(string: cheatsheet, attributes: attrs)

        // Highlight title
        if let headerRange = cheatsheet.range(of: titleKeyword) {
            let nsRange = NSRange(headerRange, in: cheatsheet)
            full.addAttribute(.foregroundColor, value: NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0), range: nsRange)
            full.addAttribute(.font,
                              value: NSFont(name: "Menlo-Bold", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .bold),
                              range: nsRange)
        }

        // Highlight section headers
        for section in sectionHeaders {
            var searchRange = cheatsheet.startIndex..<cheatsheet.endIndex
            while let range = cheatsheet.range(of: section, range: searchRange) {
                let nsRange = NSRange(range, in: cheatsheet)
                full.addAttribute(.foregroundColor, value: NSColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 1.0), range: nsRange)
                full.addAttribute(.font,
                                  value: NSFont(name: "Menlo-Bold", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
                                  range: nsRange)
                searchRange = range.upperBound..<cheatsheet.endIndex
            }
        }

        textView.textStorage?.setAttributedString(full)
        scroll.documentView = textView
        bg.addSubview(scroll)

        window.makeKeyAndOrderFront(nil)

        // Dismiss on Esc or Q
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 || event.charactersIgnoringModifiers == "q" {
                NSApplication.shared.terminate(nil)
            }
            return event
        }
    }

    // Dismiss on focus loss
    func applicationDidResignActive(_ notification: Notification) {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.activate(ignoringOtherApps: true)
app.run()
