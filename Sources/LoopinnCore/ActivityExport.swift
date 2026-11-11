import Foundation

public enum ActivityExport {
    public static func json(_ entries: [ActivityEntry]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(entries)
    }

    public static func csv(_ entries: [ActivityEntry]) -> Data {
        func field(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
        let formatter = ISO8601DateFormatter()
        let rows = entries.map { entry in
            [entry.id.uuidString, entry.title, formatter.string(from: entry.startAt), formatter.string(from: entry.endAt), entry.category]
                .map(field).joined(separator: ",")
        }
        return Data((["id,title,start,end,category"] + rows).joined(separator: "\n").appending("\n").utf8)
    }
}
