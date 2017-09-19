import OctoKit

var CLIENT: OCTClient? = nil

func InitGithub() {
    OCTClient.setClientID("id", clientSecret:     "secret")

    OCTClient.signInToServer(usingWebBrowser: OCTServer.dotCom(), scopes: OCTClientAuthorizationScopes.notifications)

        .logAll()

        .subscribeNext { (client: Any) -> () in
            print("sup, client")
            print(client)

            CLIENT = client as? OCTClient
    }



    print("i tried")
}

func HandleGithubOAuthURL(url: URL) {
    OCTClient.completeSignIn(withCallbackURL: url)
    print("completed signin:", url)
}
