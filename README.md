# ![icon][icon] GithubNotify 

[icon]: https://raw.githubusercontent.com/erik/github-notify/master/GithubNotify/Assets.xcassets/MenuIconDefault.imageset/MenuIconDefault.png

It sits in your menubar and changes color when you have unread github notifications.

## Quick install

Grab the latest [release](https://github.com/erik/github-notify/releases/latest), 
unzip, and run GithubNotify.

## Building from source

Requires [Carthage](https://github.com/Carthage/Carthage).

Register a new [GitHub OAuth application](https://github.com/settings/developers)
with permissions to read notifications. Fields can be filled out however you'd like,
but make sure the callback URL is set to `github-notify://oauth`

``` bash
git clone git@github.com:erik/github-notify.git && cd github-notify/

carthage update

# Remember to fill these in from the OAuth application you set up before.
echo "GITHUB_OAUTH_ID=[your_github_oauth_client_id]" > .secrets
echo "GITHUB_OAUTH_SECRET=[your_github_oauth_secret]" >> .secrets

# If you want to build from the command line:
xcodebuild
open build/Release/GithubNotify.app

# Or if you want to open xcode and build there:
open GithubNotify.xcodeproj
```
