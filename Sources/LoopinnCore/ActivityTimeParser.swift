import Foundation

public struct ActivityTimeDraft: Equatable, Sendable {
    public let title: String
    public let startAt: Date
    public let endAt: Date
}

public enum ActivityTimeParser {
    // Explicit AM/PM, noon or midnight is required. Ambiguous ranges use the manual form.
    public static func parse(_ input: String, on day: Date, calendar: Calendar = .current) -> ActivityTimeDraft? {
        let token = "(?:[0-9]{1,2}(?::[0-9]{2})?\\s*(?:am|pm)|noon|midnight)"
        guard let regex = try? NSRegularExpression(pattern: "^\\s*(\(token))\\s*(?:-|to)\\s*(\(token))\\s+(.+?)\\s*$", options: [.caseInsensitive]),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              match.numberOfRanges == 4,
              let startRange = Range(match.range(at: 1), in: input),
              let endRange = Range(match.range(at: 2), in: input),
              let titleRange = Range(match.range(at: 3), in: input),
              let startMinutes = minutes(String(input[startRange])),
              let endMinutes = minutes(String(input[endRange])) else { return nil }
        let title = String(input[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, endMinutes > startMinutes,
              let start = calendar.date(byAdding: .minute, value: startMinutes, to: calendar.startOfDay(for: day)),
              let end = calendar.date(byAdding: .minute, value: endMinutes, to: calendar.startOfDay(for: day)) else { return nil }
        return ActivityTimeDraft(title: title, startAt: start, endAt: end)
    }

    private static func minutes(_ input: String) -> Int? {
        let compact = input.lowercased().replacingOccurrences(of: " ", with: "")
        if compact == "noon" { return 720 }
        if compact == "midnight" { return 0 }
        let suffix = compact.hasSuffix("am") ? "am" : "pm"
        let number = String(compact.dropLast(2)).split(separator: ":")
        guard let hour = Int(number[0]), (1...12).contains(hour),
              let minute = number.count == 2 ? Int(number[1]) : 0,
              (0...59).contains(minute) else { return nil }
        return (hour % 12 + (suffix == "pm" ? 12 : 0)) * 60 + minute
    }
}
