import AppKit
import CryptoKit
import Foundation
import LoopinnCore
import Network
import Security

enum GoogleCalendarError: LocalizedError {
    case missingClientID, invalidCallback, accessDenied, timedOut, invalidResponse, notConnected, api(Int)
    var errorDescription: String? {
        switch self {
        case .missingClientID: "Add a Google OAuth Desktop client ID in Settings first."
        case .invalidCallback: "Google sign-in returned an invalid response."
        case .accessDenied: "Google Calendar access was not granted."
        case .timedOut: "Google sign-in timed out. Try connecting again."
        case .invalidResponse: "Google Calendar returned an invalid response."
        case .notConnected: "Connect Google Calendar first."
        case .api(let status): "Google Calendar returned HTTP \(status)."
        }
    }
}

private struct GoogleToken: Codable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
}

private struct TokenResponse: Decodable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int
}

@MainActor
final class GoogleCalendarService {
    private var token: GoogleToken?
    private let keychainService = "com.atharav.loopinn.google-calendar"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
        token = try? loadToken()
    }

    var isConnected: Bool { token != nil }

    func connect(clientID: String) async throws {
        guard !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw GoogleCalendarError.missingClientID }
        let receiver = try LoopbackReceiver()
        let port = try await receiver.start()
        let redirect = "http://127.0.0.1:\(port)"
        let verifier = randomString()
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncodedString()
        let state = randomString()
        var parts = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        parts.queryItems = [
            URLQueryItem(name: "client_id", value: clientID), URLQueryItem(name: "redirect_uri", value: redirect),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.readonly"),
            URLQueryItem(name: "access_type", value: "offline"), URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "code_challenge", value: challenge), URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]
        guard let authURL = parts.url, NSWorkspace.shared.open(authURL) else { throw GoogleCalendarError.invalidCallback }
        let callback = try await receiver.waitForCallback()
        let values = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard values.first(where: { $0.name == "state" })?.value == state else { throw GoogleCalendarError.invalidCallback }
        guard let code = values.first(where: { $0.name == "code" })?.value else { throw GoogleCalendarError.accessDenied }
        let response = try await tokenRequest([
            "client_id": clientID, "code": code, "code_verifier": verifier,
            "redirect_uri": redirect, "grant_type": "authorization_code"
        ])
        token = GoogleToken(accessToken: response.access_token, refreshToken: response.refresh_token ?? token?.refreshToken ?? "",
                            expiresAt: .now.addingTimeInterval(Double(response.expires_in)))
        try saveToken()
    }

    func disconnect() throws {
        token = nil
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: keychainService]
        let result = SecItemDelete(query as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else { throw GoogleCalendarError.invalidResponse }
    }

    func calendars(clientID: String) async throws -> [CalendarChoice] {
        var result: [CalendarChoice] = []
        var page: String?
        for _ in 0..<50 {
            var parts = URLComponents(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!
            if let page { parts.queryItems = [URLQueryItem(name: "pageToken", value: page)] }
            let data = try await request(parts.url!, clientID: clientID)
            let payload = try JSONDecoder().decode(GoogleCalendarList.self, from: data)
            result += payload.items.map { CalendarChoice(id: $0.id, title: $0.summary) }
            page = payload.nextPageToken
            if page == nil { return result }
        }
        throw GoogleCalendarError.invalidResponse
    }

    func events(calendarID: String, calendarTitle: String, from start: Date, to end: Date, clientID: String) async throws -> [ExternalCalendarEvent] {
        var result: [ExternalCalendarEvent] = []
        var page: String?
        for _ in 0..<50 {
            var parts = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(encodedCalendarID(calendarID))/events")!
            parts.queryItems = [URLQueryItem(name: "timeMin", value: ISO8601DateFormatter().string(from: start)),
                                URLQueryItem(name: "timeMax", value: ISO8601DateFormatter().string(from: end)),
                                URLQueryItem(name: "singleEvents", value: "true"), URLQueryItem(name: "maxResults", value: "250")]
            if let page { parts.queryItems?.append(URLQueryItem(name: "pageToken", value: page)) }
            let data = try await request(parts.url!, clientID: clientID)
            let payload = try JSONDecoder().decode(GoogleEventList.self, from: data)
            result += payload.items.compactMap { event in
                guard event.status != "cancelled", let start = event.start?.value, let end = event.end?.value else { return nil }
                return ExternalCalendarEvent(id: "google:\(calendarID):\(event.id)", title: event.summary ?? "Untitled event", startAt: start,
                                             endAt: end, source: "Google Calendar", isAllDay: event.start?.date != nil,
                                             calendarID: "google:\(calendarID)", isHoliday: calendarTitle.localizedCaseInsensitiveContains("holiday") || calendarID.localizedCaseInsensitiveContains("holiday"))
            }
            page = payload.nextPageToken
            if page == nil { return result }
        }
        throw GoogleCalendarError.invalidResponse
    }

    func publish(block: CalendarBlock, title: String, calendarID: String, clientID: String) async throws -> ExternalCalendarLink {
        let eventID = block.externalLinks?.first(where: { $0.provider == "google" && $0.calendarID == calendarID })?.eventID
            ?? "loopinn" + block.id.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let calendarPath = encodedCalendarID(calendarID)
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarPath)/events\(block.externalLinks?.contains(where: { $0.provider == "google" && $0.calendarID == calendarID }) == true ? "/\(eventID)" : "")")!
        let body: [String: Any] = ["id": eventID, "summary": title,
                                   "start": ["dateTime": ISO8601DateFormatter().string(from: block.startAt)],
                                   "end": ["dateTime": ISO8601DateFormatter().string(from: block.endAt)]]
        let data = try JSONSerialization.data(withJSONObject: body)
        do {
            _ = try await request(url, clientID: clientID, method: block.externalLinks?.contains(where: { $0.provider == "google" && $0.calendarID == calendarID }) == true ? "PUT" : "POST", body: data)
        } catch GoogleCalendarError.api(409) {
            // A previous publish may have succeeded before its local mapping was committed.
        }
        return ExternalCalendarLink(provider: "google", calendarID: calendarID, eventID: eventID)
    }

    func remove(_ link: ExternalCalendarLink, clientID: String) async throws {
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(encodedCalendarID(link.calendarID))/events/\(link.eventID)")!
        do { _ = try await request(url, clientID: clientID, method: "DELETE") }
        catch GoogleCalendarError.api(404) { return }
    }

    private func request(_ url: URL, clientID: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        let access = try await accessToken(clientID: clientID)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        for attempt in 0..<3 {
            let (data, response) = try await session.data(for: request)
            guard let status = (response as? HTTPURLResponse)?.statusCode else { throw GoogleCalendarError.invalidResponse }
            if (200..<300).contains(status) { return data }
            if (status == 429 || (500..<600).contains(status)) && attempt < 2 {
                try await Task.sleep(for: .milliseconds(300 * (1 << attempt) + Int.random(in: 0...200)))
                continue
            }
            throw GoogleCalendarError.api(status)
        }
        throw GoogleCalendarError.invalidResponse
    }

    private func accessToken(clientID: String) async throws -> String {
        guard var token else { throw GoogleCalendarError.notConnected }
        if token.expiresAt > .now.addingTimeInterval(60) { return token.accessToken }
        guard !token.refreshToken.isEmpty else { throw GoogleCalendarError.notConnected }
        let response = try await tokenRequest(["client_id": clientID, "refresh_token": token.refreshToken, "grant_type": "refresh_token"])
        token.accessToken = response.access_token
        token.expiresAt = .now.addingTimeInterval(Double(response.expires_in))
        self.token = token
        try saveToken()
        return token.accessToken
    }

    private func tokenRequest(_ fields: [String: String]) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let formCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        request.httpBody = fields.map { key, value in
            "\(key.addingPercentEncoding(withAllowedCharacters: formCharacters) ?? key)=\(value.addingPercentEncoding(withAllowedCharacters: formCharacters) ?? value)"
        }.joined(separator: "&").data(using: .utf8)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw GoogleCalendarError.accessDenied }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func saveToken() throws {
        guard let token else { return }
        let data = try JSONEncoder().encode(token)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: keychainService]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { throw GoogleCalendarError.invalidResponse }
    }

    private func loadToken() throws -> GoogleToken? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: keychainService,
                                    kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw GoogleCalendarError.invalidResponse }
        return try JSONDecoder().decode(GoogleToken.self, from: data)
    }

    private func randomString() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private func encodedCalendarID(_ id: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return id.addingPercentEncoding(withAllowedCharacters: allowed) ?? id
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}

private struct GoogleCalendarList: Decodable {
    struct Item: Decodable { let id: String; let summary: String }
    let items: [Item]
    let nextPageToken: String?
}
private struct GoogleEventList: Decodable {
    struct DateValue: Decodable {
        let dateTime: String?
        let date: String?
        var value: Date? {
            if let dateTime {
                let fractional = ISO8601DateFormatter()
                fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return fractional.date(from: dateTime) ?? ISO8601DateFormatter().date(from: dateTime)
            }
            if let date {
                let parts = date.split(separator: "-").compactMap { Int($0) }
                if parts.count == 3 { return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) }
            }
            return nil
        }
    }
    struct Item: Decodable { let id: String; let summary: String?; let status: String?; let start: DateValue?; let end: DateValue? }
    let items: [Item]
    let nextPageToken: String?
}

@MainActor
private final class LoopbackReceiver {
    private let listener: NWListener
    private var startContinuation: CheckedContinuation<UInt16, Error>?
    private var callbackContinuation: CheckedContinuation<URL, Error>?
    private var pendingCallback: URL?

    init() throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        listener = try NWListener(using: parameters, on: .any)
    }

    func start() async throws -> UInt16 {
        return try await withCheckedThrowingContinuation { continuation in
            startContinuation = continuation
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self else { return }
                    switch state {
                    case .ready:
                        if let port = self.listener.port?.rawValue { self.startContinuation?.resume(returning: port); self.startContinuation = nil }
                    case .failed(let error):
                        self.startContinuation?.resume(throwing: error); self.startContinuation = nil
                        self.callbackContinuation?.resume(throwing: error); self.callbackContinuation = nil
                    default: break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.receive(connection) }
            }
            listener.start(queue: .main)
        }
    }

    func waitForCallback() async throws -> URL {
        if let pendingCallback {
            self.pendingCallback = nil
            return pendingCallback
        }
        return try await withCheckedThrowingContinuation { continuation in
            callbackContinuation = continuation
            DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in
                guard let self, let continuation = self.callbackContinuation else { return }
                self.callbackContinuation = nil
                continuation.resume(throwing: GoogleCalendarError.timedOut)
                self.listener.cancel()
            }
        }
    }

    private func receive(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            Task { @MainActor in
                guard let self, let data, let line = String(data: data, encoding: .utf8)?.components(separatedBy: "\r\n").first,
                      let path = line.split(separator: " ").dropFirst().first,
                      let url = URL(string: "http://127.0.0.1\(path)") else { return }
                let reply = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\nLoopinn connected. You can close this tab."
                connection.send(content: Data(reply.utf8), completion: .contentProcessed { _ in connection.cancel() })
                if let continuation = self.callbackContinuation {
                    self.callbackContinuation = nil
                    continuation.resume(returning: url)
                } else {
                    self.pendingCallback = url
                }
                self.listener.cancel()
            }
        }
    }
}
