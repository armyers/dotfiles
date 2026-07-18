import Cocoa

// ─── Combined AeroSpace + Kanata cheatsheet with fuzzy search ────────────────
//
// Reads the generated cheatsheet.txt from the sibling aerospace/ and kanata/
// config dirs (both live under ~/.config, next to this binary's dir), merges
// them into one scrollable popup, and filters live as you type. Matching is a
// case-insensitive subsequence ("fuzzy") test; spaces in the query are ignored.

// ─── Colors ──────────────────────────────────────────────────────────────────
let colorBody = NSColor(white: 0.70, alpha: 1.0)
let colorTitle = NSColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 1.0)
let colorSection = NSColor(red: 0.60, green: 0.90, blue: 0.60, alpha: 1.0)
let colorMatch = NSColor(red: 1.0, green: 0.75, blue: 0.30, alpha: 1.0)
let colorHint = NSColor(white: 0.45, alpha: 1.0)

let fontBody = NSFont(name: "Menlo", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
let fontTitle = NSFont(name: "Menlo-Bold", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
let fontSection = NSFont(name: "Menlo-Bold", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .bold)

// ─── Cheatsheet model ────────────────────────────────────────────────────────
struct Section {
    let header: String
    let entries: [String]
}

struct FileBlock {
    let title: String
    let sections: [Section]
}

/// Parse one cheatsheet.txt into a title + sections. Leading-space depth marks
/// structure: 1 space = title/section header, 3+ spaces = entry, 0 = blank.
func parseFile(_ text: String) -> FileBlock {
    var title = ""
    var sections: [Section] = []
    var curHeader: String? = nil
    var curEntries: [String] = []

    func flush() {
        // Drop each file's "DISMISS" section — that's popup chrome, and the
        // combined window's search field already shows how to close it.
        if let h = curHeader, !h.hasPrefix("DISMISS") {
            sections.append(Section(header: h, entries: curEntries))
        }
        curHeader = nil
        curEntries = []
    }

    for line in text.components(separatedBy: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { continue }
        let leading = line.prefix { $0 == " " }.count
        if title.isEmpty && leading <= 1 {
            title = trimmed
            continue
        }
        if leading <= 1 {
            flush()
            curHeader = trimmed
        } else {
            curEntries.append(line)
        }
    }
    flush()
    return FileBlock(title: title, sections: sections)
}

/// Fuzzy subsequence match. Returns the matched character indices in `text`
/// (for highlighting) or nil if the query doesn't match. Spaces in the query
/// are ignored so "ctrl shift" matches "ctrl+shift".
func fuzzyMatch(_ query: String, _ text: String) -> [Int]? {
    let q = Array(query.lowercased().filter { $0 != " " })
    if q.isEmpty { return [] }
    let t = Array(text.lowercased())
    var qi = 0
    var indices: [Int] = []
    for (i, c) in t.enumerated() {
        if qi < q.count && c == q[qi] {
            indices.append(i)
            qi += 1
        }
    }
    return qi == q.count ? indices : nil
}

// ─── Transparent background view ─────────────────────────────────────────────
class BackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        NSColor(white: 0.08, alpha: 0.85).setFill()
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
class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
    var window: PopupWindow!
    var searchField: NSTextField!
    var textViews: [NSTextView] = []   // one column per cheatsheet file
    var files: [FileBlock] = []

    func configDir() -> String {
        // Binary lives at <root>/cheatsheet/cheatsheet; its grandparent dir
        // holds the sibling aerospace/ and kanata/ dirs. Resolve argv[0] to an
        // absolute, symlink-followed path so this works whether launched by
        // full path (via ~/.config symlink) or as ./cheatsheet from the repo.
        var p = CommandLine.arguments[0]
        if !p.hasPrefix("/") {
            p = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(p)
        }
        let resolved = (p as NSString).resolvingSymlinksInPath
        let binDir = (resolved as NSString).deletingLastPathComponent
        return (binDir as NSString).deletingLastPathComponent
    }

    func loadFile(_ name: String) -> String? {
        // Prefer the argv-derived root; fall back to ~/.config for safety.
        let home = NSHomeDirectory()
        let candidates = [
            (configDir() as NSString).appendingPathComponent("\(name)/cheatsheet.txt"),
            "\(home)/.config/\(name)/cheatsheet.txt",
        ]
        for path in candidates {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                return content
            }
        }
        return nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        for name in ["aerospace", "kanata", "skhd", "hammerspoon"] {
            if let text = loadFile(name) {
                files.append(parseFile(text))
            }
        }
        if files.isEmpty {
            files = [FileBlock(title: "Could not load cheatsheets",
                               sections: [Section(header: "Expected cheatsheet.txt next to aerospace/ and kanata/",
                                                  entries: [])])]
        }

        let searchH: CGFloat = 34
        let padding: CGFloat = 20
        let gap: CGFloat = 24
        guard let screen = NSScreen.main else { return }

        // Each file becomes a column sized to its own content (monospace, so
        // width scales with the longest line). Narrow sources get narrow
        // columns; the window grows to fit them all, capped to 95% of screen.
        let charW = ("M" as NSString).size(withAttributes: [.font: fontBody]).width
        let colInset: CGFloat = 22   // text inset + a little slack for the scroller
        func fileCols(_ f: FileBlock) -> Int {
            var m = (" " + f.title).count
            for s in f.sections {
                m = max(m, (" " + s.header).count)
                for e in s.entries { m = max(m, e.count) }
            }
            return m
        }
        var colWidths = files.map { CGFloat(fileCols($0)) * charW + colInset }
        let n = CGFloat(files.count)
        let fixedW = padding * 2 + gap * (n - 1)
        var width = fixedW + colWidths.reduce(0, +)
        let maxW = screen.frame.width * 0.95
        if width > maxW {
            let scale = (maxW - fixedW) / colWidths.reduce(0, +)
            colWidths = colWidths.map { $0 * scale }
            width = maxW
        }

        // Height fits the tallest column, capped to most of the screen
        // (taller columns then scroll).
        let lineHeight: CGFloat = 20
        func fileLines(_ f: FileBlock) -> Int {
            2 + f.sections.reduce(0) { $0 + 2 + $1.entries.count }
        }
        let maxLines = files.map(fileLines).max() ?? 0
        let contentH = min(CGFloat(maxLines) * lineHeight + padding, screen.frame.height * 0.85)
        let height = contentH + searchH + padding

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

        // Search field pinned to the top.
        searchField = NSTextField(frame: NSRect(x: padding, y: height - searchH - padding / 2,
                                                width: width - padding * 2, height: searchH))
        searchField.font = fontBody
        searchField.textColor = .white
        searchField.backgroundColor = NSColor(white: 1.0, alpha: 0.08)
        searchField.drawsBackground = true
        searchField.isBordered = false
        searchField.focusRingType = .none
        searchField.placeholderString = "  fuzzy search…  (esc to close)"
        searchField.delegate = self
        searchField.cell?.usesSingleLineMode = true
        if let cell = searchField.cell as? NSTextFieldCell {
            cell.wraps = false
            cell.isScrollable = true
        }
        bg.addSubview(searchField)

        // One scrollable column per file, laid out side by side below the
        // search field, each as wide as its own content needs.
        let colY = padding / 2
        let colH = height - searchH - padding * 1.5
        var colX = padding
        for i in files.indices {
            let colWidth = colWidths[i]
            let scroll = NSScrollView(frame: NSRect(x: colX, y: colY, width: colWidth, height: colH))
            scroll.drawsBackground = false
            scroll.hasVerticalScroller = true
            scroll.autohidesScrollers = true

            let tv = NSTextView(frame: scroll.bounds)
            tv.isEditable = false
            tv.isSelectable = false
            tv.drawsBackground = false
            tv.textContainerInset = NSSize(width: 4, height: 4)
            // Grow vertically with content so the scroll view can scroll.
            tv.minSize = NSSize(width: 0, height: 0)
            tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                height: CGFloat.greatestFiniteMagnitude)
            tv.isVerticallyResizable = true
            tv.isHorizontallyResizable = false
            tv.autoresizingMask = [.width]
            tv.textContainer?.containerSize = NSSize(width: scroll.contentSize.width,
                                                     height: CGFloat.greatestFiniteMagnitude)
            tv.textContainer?.widthTracksTextView = true
            scroll.documentView = tv
            bg.addSubview(scroll)
            textViews.append(tv)
            colX += colWidth + gap
        }

        rebuild(query: "")

        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(searchField)

        // Esc dismisses (q must stay typable in the search field).
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                NSApplication.shared.terminate(nil)
            }
            return event
        }
    }

    // Re-filter on every keystroke.
    func controlTextDidChange(_ obj: Notification) {
        rebuild(query: searchField.stringValue)
    }

    /// Rebuild every column for the given query.
    func rebuild(query: String) {
        for (i, file) in files.enumerated() where i < textViews.count {
            let tv = textViews[i]
            tv.textStorage?.setAttributedString(attributed(for: file, query: query))
            tv.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
    }

    /// Build the styled, fuzzy-filtered content for a single cheatsheet file.
    func attributed(for file: FileBlock, query: String) -> NSAttributedString {
        let out = NSMutableAttributedString()
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3

        func append(_ s: String, color: NSColor, font: NSFont, matches: [Int] = []) {
            let start = out.length
            out.append(NSAttributedString(string: s + "\n", attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style,
            ]))
            for idx in matches where idx < s.count {
                out.addAttribute(.foregroundColor, value: colorMatch,
                                 range: NSRange(location: start + idx, length: 1))
            }
        }

        let hasQuery = !query.trimmingCharacters(in: .whitespaces).isEmpty

        // Collect the sections (and their entries) that survive the filter.
        var kept: [(String, [(String, [Int])])] = []
        for section in file.sections {
            let headerMatched = hasQuery ? fuzzyMatch(query, section.header) != nil : false
            var ents: [(String, [Int])] = []
            for entry in section.entries {
                if !hasQuery {
                    ents.append((entry, []))
                } else if let idx = fuzzyMatch(query, entry) {
                    ents.append((entry, idx))
                } else if headerMatched {
                    ents.append((entry, []))
                }
            }
            if !hasQuery || headerMatched || !ents.isEmpty {
                kept.append((section.header, ents))
            }
        }

        append(" " + file.title, color: colorTitle, font: fontTitle)
        append("", color: colorBody, font: fontBody)

        if kept.isEmpty {
            append("   no matches", color: colorHint, font: fontBody)
            return out
        }

        for (header, ents) in kept {
            append(" " + header, color: colorSection, font: fontSection)
            for (entry, idx) in ents {
                // Entries keep their original leading indent, so match
                // indices line up with the string we append verbatim.
                append(entry, color: colorBody, font: fontBody, matches: idx)
            }
            append("", color: colorBody, font: fontBody)
        }
        return out
    }

    // Dismiss on focus loss (click away).
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
