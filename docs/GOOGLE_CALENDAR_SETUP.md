# Google Calendar connection

Loopinn uses a Google OAuth **Desktop app** client ID, PKCE, the system browser, and a temporary callback on `127.0.0.1`. No client secret belongs in the public repository. Users enter their Desktop client ID in Settings → Google Calendar, then select Connect. Access and refresh tokens are stored in this Mac's Keychain. Disconnect removes the local token.

Create a Desktop application OAuth client in [Google Cloud Console](https://console.cloud.google.com/apis/credentials), enable the Google Calendar API, and configure the OAuth consent screen and test users as Google requires. Copy the client ID into Loopinn. The redirect uses a random local port and does not require a fixed redirect URI for Google's Desktop client type.

The app requests calendar event and calendar list scopes. Reading calendars does not change remote data. Each block publish has a separate preview and confirmation. A stable event ID is used to reduce duplicate publishes after a local failure. Network requests have deadlines; transient 429/5xx responses retry at most twice. Live OAuth and API acceptance require a configured Google project and account.

See [Google's desktop OAuth guide](https://developers.google.com/identity/protocols/oauth2/native-app) and [Calendar API events reference](https://developers.google.com/workspace/calendar/api/v3/reference/events).
