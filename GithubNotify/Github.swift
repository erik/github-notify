import Cocoa
import Foundation

import OctoKit
import SwiftyJSON

let NOTIFICATION_ENDPOINT = "https://api.github.com/notifications"
var OCTO_CLIENT: OCTClient? = nil
var OCTO_TOKEN: String = ""
var NOTIFICATIONS: [JSON] = []
var ETAG: String = ""


func InitGithub() {
    guard let infoPlist = Bundle.main.infoDictionary,
        let clientId = infoPlist["GITHUB_OAUTH_CLIENT_ID"] as? String,
        let clientSecret = infoPlist["GITHUB_OAUTH_CLIENT_SECRET"] as? String else {
            print("Missing GitHub credentials in Info.plist!") 
            return
    }

    OCTClient.setClientID(clientId, clientSecret: clientSecret)

    if let (login, token) = findExistingLogin() {
        let user = OCTUser(rawLogin: login, server: OCTServer.dotCom())

        OCTO_TOKEN = token
        OCTO_CLIENT = OCTClient.authenticatedClient(with: user, token: token)
        updateNotifications()
    } else {
        initOAuthFlow()
    }
}

func findExistingLogin() -> (String, String)? {
    if let creds = UserDefaults.standard.dictionary(forKey: "GithubCredentials") as? [String: String] {
        if let login = creds["login"], let token = creds["token"] {
            return (login, token)
        }
    }

    return nil
}


func initOAuthFlow() {
    OCTClient.signInToServer(usingWebBrowser: OCTServer.dotCom(), scopes: OCTClientAuthorizationScopes.notifications)
        .logAll()
        .subscribeNext { (client: Any) -> () in
            if let client = client as? OCTClient {
                OCTO_CLIENT = client
                OCTO_TOKEN = client.token

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
    var request = URLRequest(url: URL(string: "https://api.github.com/notifications?per_page=100&page=\(page)")!)
    request.httpMethod = "GET"
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    request.addValue("token \(OCTO_TOKEN)", forHTTPHeaderField: "Authorization")

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
