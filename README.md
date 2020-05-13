# sfctl [![Build status](https://badge.buildkite.com/22ecc67f358163f4714383ff0fde8e847d1e3ae488fc10312f.svg)](https://buildkite.com/starfish/sf-control)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Falphatier-works%2Fsfctl.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Falphatier-works%2Fsfctl?ref=badge_shield)

```
sfctl is a command line interface for the Starfish API.

Usage:
  sfctl [command]

Available Commands:
  account     account commands
  auth        auth commands
  time        time reporting commands
  version     show the current version

Flags:
  -a, --all         don't filter data
  -d, --dry-run     just execute the command - no writes to starfish.team
  -h, --help        help for fsctl
  -t, --touchy      no data will be overwritten in starfish.team
```

## Installing `sfctl`

### Using Ruby Gems (Preferred)

```
gem install sfctl
```

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

As a consequece a `.sfctl` directory will be created in your `$HOME` and all data is stored for further use. You can safely copy this folder to other machines to replicate the access. Just be aware this is giving the user controlling the directory access to your starfish account.

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

Username            Email
---------------------------
[USERNAME]          [EMAIL]
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

## Time Reports

Time reports and consolidation are an essential part of Starfish.team. You are able to configure on a project level which assignments you want to charge with time report data you have. The time report data will come from standard time tracking tools and will be loaded to starfish using commands in this section.

The key consideration for the approach to support this with a command line interface is to prevent you from storing your personal secrets (like the accesstoken to your lovely time-reporting tool) on our system.

We will provide a couple of integrations but also open up for plugins later on to extend to what's out there.

As of today we support:

- Toggl

Another advantage of this approach is, that you think of any automation ⚒ you like to support your processes.

### Initialize a Project

In your project's root directory you can use the following command to create a `.sflink` file that will store your project configuration. Although sensitive data is stored in the main `.sfctl` directory we'd like to recommend to not add the `.sflink` file to your version control system.

```
sfctl time init
```

### Get Current Providers

```
sfctl time providers get
```

This command will read which providers are configured on your system. These configurations include sensitve information (e.g. access-tokens etc.) and will be read from the `.sfct` main directory.

```
Provider: [harvest|toggl|clockify]
  ACCESS_TOKEN: [TOKEN]
  ACCOUNT_ID: [ACCOUNT_ID]
  ...

[More Providers]
```

The information stored is specific for each provider and contains the basic data that is required to authenticate on the API level.

### Set A Provider

```
sfctl time providers set [harvest|toggl|clockify]
```

With this command you set the configuration required for the provider to authenticate a call to their API.
As stated already, the required information depends on the API of the provider.

The system will prompt you for the data.

```
Setting up [harvest|toggl|clockify]
Your access token at [harvest|toggl|clockify]: ACCESS_TOKEN
...
Is that information correct? (Y/n)
```

In case there is already a configuration for the provider, you will if you want to overwrite that information.

```
Setting up [harvest|toggl|clockify]
You already have a configuration for this provider.

Do you want to replace it? (Y/n)
...
```

### Unset A Provider

```
sfctl time providers unset [harvest|toggl|clockify]
```

With this command you can unset the configuration of a provider.

```
Unsetting [harvest|toggl|clockify]

Do you want to remove the delete the configuration? (Y/n)
...
```

### Get Current Connections

Connections are the project specific link of a time-reporting tool and respective reporting setup there with an assignment at Starfish.team.

```
sfctl time connections get
```

This will list all known connections in that project. The data is read from the `.sflink` file.

```
Connection: [ASSIGNMENT NAME]
  provider: toggl
  workspace_id: 54321
  project_ids: 123, 324,23, 333
  task_ids:
  billable: both
  rounding: off

[MORE CONNECTIONS]
```

### Add a Connection

```
sfctl time connections add [harvest|toggl|clockify]
```

This command will add a connection between a provider and an assignment. In each project configuration you can have only one connection per assignment.

The system will therefore prompt you to select one of the not yet connected assignments.

```
Select on assignment first:

1. [ASSIGNMENT NAME] / [SERVICE]
2. [ASSIGNMENT NAME] / [SERVICE]
...
```

After selecting the assignment the command will prompt you to enter the provider specific data.
See an example for toggl below:

```
Workspace ID                  (required): [WORKSPACE_ID]
Project IDs (required / comma separated): [LIST OF PROJECT IDS]
Task IDs    (optional / comma separated): [LIST OF TASK IDS]
Billable?                     (required): [BILLED|UNBILLED|BOTH]
Rounding?                     (required): [ON|OFF]
```

### Synchronize Data

This command is the essential part of the whole CLI. It will gets for each assignment the next reporting segment from starfish.team and loads the corresponding time reports from the provider.

This command supports the `--dry-run` and the `--touchy` flag, such that you could check the data first respectively prevent data from being overwritten.

```
sfctl time sync
```

It will ask you if you want to sync all assignments or only a single one.

```
Which assignment do you want to sync?
1. [ASSIGNMENT NAME] / [SERVICE]
2. [ASSIGNMENT NAME] / [SERVICE]
N. [ALL]
```

In case there is no next reporting segment on starfish that accepts time report data, the synchronization will be skipped. All others are synchronized in sequence.

If the `--touchy` flag was used, the synchronizsation will be skipped if there is preexisting data.

```
Synchronizing:                              [ASSIGNMENT NAME] / [SERVICE]
Next Report:                                [2020-03]
Loaded data from [harvest|toggl|clockify]:  [IN PROGRESS|DONE]

Date          Comment                 Time
-------------------------------------------
2020.03.01    Work Work               7.75h
...

Total:                              150.00h

Uploading to starfish.team:                 [IN PROGRESS|DONE]

[NEXT CONNECTION]
```


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Falphatier-works%2Fsfctl.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Falphatier-works%2Fsfctl?ref=badge_large)