import Foundation
import UserNotifications

@MainActor
final class ActivityNotificationService {
    static let shared = ActivityNotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async {
        _ = try? await center.requestAuthorization(options: [.alert, .badge])
    }

    func sendPrompt(for interval: DateInterval) async {
        let allowed = await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
            }
        }
        guard allowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "What did you do in the last hour?"
        let start = interval.start.formatted(date: .omitted, time: .shortened)
        let end = interval.end.formatted(date: .omitted, time: .shortened)
        content.body = "What did you do from \(start) to \(end)? Open Loopinn to log it."
        content.userInfo = ["start": interval.start.timeIntervalSince1970, "end": interval.end.timeIntervalSince1970]
        let request = UNNotificationRequest(identifier: "loopinn-hour-\(Int(interval.start.timeIntervalSince1970))", content: content, trigger: nil)
        try? await center.add(request)
    }
}
