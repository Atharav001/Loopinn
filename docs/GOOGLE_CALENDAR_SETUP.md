# Google Calendar connection

Loopinn uses a Google OAuth **Desktop app** client ID, PKCE, the system browser, and a temporary callback on `127.0.0.1`. No client secret belongs in the public repository. Users enter their Desktop client ID in Settings → Google Calendar, then select Connect. Access and refresh tokens are stored in this Mac's Keychain. Disconnect removes the local token.

1. In [Google Cloud Console](https://console.cloud.google.com/), create or select a project for Loopinn.
2. [Enable the Google Calendar API](https://developers.google.com/workspace/guides/enable-apis) in that project.
3. In **Google Auth Platform → Branding**, enter the app name, support email and contact email. In **Audience**, select **External** and keep the app in **Testing** while developing; add the Google account you will use under **Test users**.
4. In **Data Access**, add the Calendar event and read-only calendar scopes requested by Loopinn: `https://www.googleapis.com/auth/calendar.events` and `https://www.googleapis.com/auth/calendar.readonly`.
5. In **Clients**, choose **Create client → Desktop app**, name it Loopinn, and copy the **client ID** into Loopinn Settings → Google Calendar. Do not put the client secret in the repository.

The redirect uses a random local port and does not require a fixed redirect URI for Google's Desktop client type. The first connection opens the system browser and asks the test account to approve the requested scopes. Google may display an unverified-app notice during testing; public distribution needs Google's applicable OAuth verification.

The app requests calendar event and calendar list scopes. Reading calendars does not change remote data. Each block publish has a separate preview and confirmation. A stable event ID is used to reduce duplicate publishes after a local failure. Network requests have deadlines; transient 429/5xx responses retry at most twice. Live OAuth and API acceptance require a configured Google project and account.

See [Google's desktop OAuth guide](https://developers.google.com/identity/protocols/oauth2/native-app) and [Calendar API events reference](https://developers.google.com/workspace/calendar/api/v3/reference/events).
