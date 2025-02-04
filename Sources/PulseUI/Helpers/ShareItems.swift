// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse
import CoreData

enum ShareStoreOutput: String, RawRepresentable {
    case store, text, html

    var fileExtension: String {
        switch self {
        case .store: return ".pulse"
        case .text: return ".txt"
        case .html: return ".html"
        }
    }
}

struct ShareItems: Identifiable {
    let id = UUID()
    let items: [Any]
    let cleanup: () -> Void

    init(_ items: [Any], cleanup: @escaping () -> Void = { }) {
        self.items = items
        self.cleanup = cleanup
    }
}

enum ShareService {
    static func share(_ message: LoggerMessageEntity, as output: ShareOutput) -> ShareItems {
        share(TextRenderer.share([message]), as: output)
    }

    static func share(_ task: NetworkTaskEntity, as output: ShareOutput) -> ShareItems {
        share(TextRenderer.share([task]), as: output)
    }

    static func share(_ string: NSAttributedString, as output: ShareOutput) -> ShareItems {
        let string = sanitized(string)
        switch output {
        case .plainText:
            return ShareItems([string.string])
        case .html:
            let html = (try? TextUtilities.html(from: string)) ?? Data()
            let directory = TemporaryDirectory()
            let fileURL = directory.write(data: html, extension: "html")
            return ShareItems([fileURL], cleanup: directory.remove)
        case .pdf:
#if os(iOS)
            let pdf = (try? TextUtilities.pdf(from: string)) ?? Data()
            let directory = TemporaryDirectory()
            let fileURL = directory.write(data: pdf, extension: "pdf")
            return ShareItems([fileURL], cleanup: directory.remove)
#else
            return ShareItems(["Sharing as PDF is not supported on this platform"])
#endif
        }
    }

    static func sanitized(_ string: NSAttributedString) -> NSAttributedString {
        var ranges: [NSRange] = []
        string.enumerateAttribute(.isTechnicalKey, in: NSRange(location: 0, length: string.length)) { value, range, _ in
            if (value as? Bool) == true {
                ranges.append(range)
            }
        }
        let output = NSMutableAttributedString(attributedString: string)
        for range in ranges.reversed() {
            output.deleteCharacters(in: range)
        }
        return output
    }
}

enum ShareOutput {
    case plainText
    case html
    case pdf
}

struct TemporaryDirectory {
    let url: URL

    init() {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("com.github.kean.logger", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

extension TemporaryDirectory {
    func write(text: String, extension fileExtension: String) -> URL {
        write(data: text.data(using: .utf8) ?? Data(), extension: fileExtension)
    }

    func write(data: Data, extension fileExtension: String) -> URL {
        let date = makeCurrentDate()
        let fileURL = url.appendingPathComponent("logs-\(date).\(fileExtension)", isDirectory: false)
        try? data.write(to: fileURL)
        return fileURL
    }
}

func makeCurrentDate() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "yyyy-MM-dd-HH-mm"
    return formatter.string(from: Date())
}

private extension LoggerStore.Level {
    var title: String {
        switch self {
        case .trace: return "trace"
        case .debug: return "debug"
        case .info: return "info"
        case .notice: return "notice"
        case .warning: return "warning"
        case .error: return "error"
        case .critical: return "critical"
        }
    }
}
