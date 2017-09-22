import Cocoa
import Foundation

import OctoKit

var OCTO_CLIENT: OCTClient? = nil
var NOTIFICATIONS: [OCTNotification] = []
var ETAG: String = ""

func InitGithub() {
    let infoPlist = Bundle.main.infoDictionary!

    let clientId = infoPlist["GITHUB_OAUTH_CLIENT_ID"] as! String,
        clientSecret = infoPlist["GITHUB_OAUTH_CLIENT_SECRET"] as! String

    OCTClient.setClientID(clientId, clientSecret: clientSecret)

    if let (login, token) = findExistingLogin() {
        let user = OCTUser(rawLogin: login, server: OCTServer.dotCom())

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

func updateNotifications () {
     NOTIFICATIONS = OCTO_CLIENT?.fetchNotificationsNot(matchingEtag: ETAG, includeReadNotifications: false, updatedSince: nil)
        .logAll()
        .map { raw in
            if let resp = raw as? OCTResponse {
                print("etag = ", resp.etag, "status=", resp.statusCode)
                // ETAG = resp.etag
                return resp.parsedResult as? OCTNotification
            }
            return nil
        }
        .filter { n in n != nil }
        .toArray() as! [OCTNotification]

    print("Unread notifications:", NOTIFICATIONS)
}
