import Foundation
import UserNotifications

final class ActivityNotificationService: @unchecked Sendable {
    static let shared = ActivityNotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge]) { _, _ in }
    }

    func sendPrompt(for interval: DateInterval) {
        center.getNotificationSettings { [self] settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let content = UNMutableNotificationContent()
            content.title = "What did you do in the last hour?"
            let start = interval.start.formatted(date: .omitted, time: .shortened)
            let end = interval.end.formatted(date: .omitted, time: .shortened)
            content.body = "What did you do from \(start) to \(end)? Open Loopinn to log it."
            let request = UNNotificationRequest(identifier: "loopinn-hour-\(Int(interval.start.timeIntervalSince1970))", content: content, trigger: nil)
            center.add(request) { _ in }
        }
    }
}
