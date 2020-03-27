# fsctl [![Build status](https://badge.buildkite.com/22ecc67f358163f4714383ff0fde8e847d1e3ae488fc10312f.svg)](https://buildkite.com/starfish/sf-control)

```
fsctl is a command line interface for the Starfish API.

Usage:
  fsctl [command]

Available Commands:
  account     account commands
  auth        auth commands
  time        time reporting commands
  version     show the current version

Flags:
  -h, --help        help for fsctl
```

## Installing `fsctl`

### Using a Package Manager (Preferred)

More to come.

### Git

More to come.

## Authentication

Before you can use `sfctl`, you need to authenticate with Starfish.team by providing an access token, which can be created on the profile page of your account.

```
sfctl auth init
```

You wil be promted to enter your access token that you've generated on the profile page.

```
Starfish.team access token: YOUR_TOKEN
```

After entering your token, you will receive confirmation that the credentials were accepted. In case your token is not accepted, please make sure you copy and paste it correctly.

```
Your token is valid 👍
```

As a consequece a .sfctl directory will be created in your $HOME and all data is stored for further use. You can safely copy this folder to other machines to replicate the access. Just be aware this is giving the user controlling the directory access to your starfish account.

You can log out by either removing the config directory or by executing the following command:

```
sfctl auth bye
```

## Account Details

You can access your account details directly from the command line.

### Account Info

```
sfctl account info
```

This will read your profile data and give you an overview of your account.

```
Hi [FULL NAME]

we have stored this information for you.

UUID                Username            Email             Status
----------------------------------------------------------------------------
[UUID]              [USERNAME]          [EMAIL]           [STATUS]
```

### Assignments

```
sfctl account assignments
```

This command will list all of your assignments that are currently active. If you want to read all assignments you have to provide the flag `-a`.

```
Assignment [NAME]
-------------------------
  Service: [SERVICE NAME]
  Start:   [START DATE]
  End:     [END DATE]
  Budget:  [AMOUNT] [UNIT]

[MORE ASSIGNMENTS]
```
