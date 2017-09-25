import Cocoa
import Foundation

import OctoKit
import SwiftyJSON

var TOKEN: String? = nil
var NOTIFICATIONS: [JSON] = []

func InitGithub() {
    guard let infoPlist = Bundle.main.infoDictionary,
        let clientId = infoPlist["GITHUB_OAUTH_CLIENT_ID"] as? String,
        let clientSecret = infoPlist["GITHUB_OAUTH_CLIENT_SECRET"] as? String else {
            print("Missing GitHub credentials in Info.plist!") 
            return
    }

    OCTClient.setClientID(clientId, clientSecret: clientSecret)

    if let token = findExistingToken() {
        TOKEN = token
        updateNotifications()
    } else {
        initOAuthFlow()
    }
}

func findExistingToken() -> String? {
    guard let creds = UserDefaults.standard.dictionary(forKey: "GithubCredentials") as? [String: String],
        let token = creds["token"]
        else {
            return nil
    }

    return token
}

func initOAuthFlow() {
    OCTClient.signInToServer(usingWebBrowser: OCTServer.dotCom(), scopes: OCTClientAuthorizationScopes.notifications)
        .logAll()
        .subscribeNext { (client: Any) -> () in
            if let client = client as? OCTClient {
                TOKEN = client.token

                let credentials = [
                   "login": client.user.rawLogin,
                   "token": client.token
                ]

                UserDefaults.standard.set(credentials, forKey: "GithubCredentials")
            }
        }
}

func HandleGithubOAuthURL(url: URL) {
    OCTClient.completeSignIn(withCallbackURL: url)
    updateNotifications()
}


func updateNotifications (page: Int = 1) {
    guard let token = TOKEN else {
        print("Not authed!")
        return
    }

    var request = URLRequest(url: URL(string: "https://api.github.com/notifications?per_page=100&page=\(page)")!)
    request.httpMethod = "GET"
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    request.addValue("token \(token)", forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("error=\(String(describing: error))")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("response = \(String(describing: response))")
            return
        }

        guard let responseString = String(data: data, encoding: .utf8),
            let json = JSON.parse(responseString).array else {
                print("malformed JSON from github?", data)
                return
        }

        if page == 1 {
            NOTIFICATIONS = []
        }

        NOTIFICATIONS.append(contentsOf: json)

        // Iterate through pages.
        if let link = (httpResponse.allHeaderFields["Link"] as? String) {
            if link.contains("rel=\"next\"") {
                updateNotifications(page: page+1)
            }
        }

        print("NOTIFICATIONS =>", NOTIFICATIONS)
    }

    task.resume()
}
