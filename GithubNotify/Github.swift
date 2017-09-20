import Cocoa
import Foundation

import OctoKit

var OCTO_CLIENT: OCTClient? = nil

func InitGithub() {
    let infoPlist = Bundle.main.infoDictionary!

    let clientId = infoPlist["GITHUB_OAUTH_CLIENT_ID"] as! String,
        clientSecret = infoPlist["GITHUB_OAUTH_CLIENT_SECRET"] as! String

    OCTClient.setClientID(clientId, clientSecret: clientSecret)

    if let (login, token) = findExistingLogin() {

        let user = OCTUser(rawLogin: login, server: OCTServer.dotCom())
        let client = OCTClient.authenticatedClient(with: user, token: token)

        OCTO_CLIENT = client
        getNotifications()
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
        .subscribeNext { (client: Any!) -> () in
            print("sup, client")
            print(client)

            if let client = client as? OCTClient {
                OCTO_CLIENT = client

                print("CLIENT" , OCTO_CLIENT)

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
    print("completed signin:", url)
}

func getNotifications () {
    let notifications = OCTO_CLIENT?.fetchNotificationsNot(matchingEtag: nil, includeReadNotifications: false, updatedSince: nil)
        .map { raw in
            if let resp = raw as? OCTResponse { return resp.parsedResult as? OCTNotification }
            return nil
        }
        .filter { n in n != nil }
        .toArray() as! [OCTNotification]

    print("Unread notifications:", notifications)
}
