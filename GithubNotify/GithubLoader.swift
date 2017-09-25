import Foundation
import OAuth2
import SwiftyJSON

class GithubLoader: OAuth2DataLoader {
    let baseURL = URL(string: "https://api.github.com/")!

    public init(clientId: String, clientSecret: String) {
        let oauth = OAuth2CodeGrant(settings: [
            "client_id": clientId,
            "client_secret": clientSecret,
            "authorize_uri": "https://github.com/login/oauth/authorize",
            "token_uri": "https://github.com/login/oauth/access_token",
            "scope": "notifications",
            "redirect_uris": ["github-notify://oauth"],
            "secret_in_body": true,
            "verbose": true,
        ])

        super.init(oauth2: oauth)
    }

    public func refreshNotifications(callback: @escaping (([JSON]?, Error?) -> Void)) {
        oauth2.logger = OAuth2DebugLogger(.trace)

        let url = baseURL.appendingPathComponent("notifications")

        var request = oauth2.request(forURL: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        perform(request: request) { response in
            do {
                let responseString = String(data: try response.responseData(), encoding: .utf8)!
                let notifications = JSON.parse(responseString).array!

                DispatchQueue.main.async {
                    callback(notifications, nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    callback(nil, error)
                }
            }
        }
    }
}
