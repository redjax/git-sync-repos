# Git Mirror

Mirror git repositories from one remote to another (i.e. a Github repository to Codeberg). On Windows hosts, run [`git_mirror_sync.ps1`](./git_mirror_sync.ps1), and on Linux run [`git_mirror_sync.sh`](./git_mirror_sync.sh).

Includes a [Docker container](./containers/Dockerfile) and [Docker Compose file](./compose.yml) for running the sync operation in a container.

## Setup

Before running this script, make sure your repositories are public, or that you've added a public SSH key to both the source and target repository. Instructions for adding your SSH key [to Github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), [to Codeberg](https://docs.codeberg.org/security/ssh-key/), and [to Gitlab](https://docs.gitlab.com/ee/user/ssh.html).

**Note**: The [Docker container](./containers/Dockerfile) expects your SSH key to be named ``. You can generate an SSH key with:

```shell
ssh-keygen -t rsa -b 4096 -f ~/.ssh/git_mirror_id_rsa -N ""
```

This will create an SSH key in your home directory, under the `.ssh/` directory, named `git_mirror_id_rsa`. You will also see a `git_mirror_id_rsa.pub`; copy the contents of your `.pub` public key into your git repositories (Github, Gitlab, Codeberg, etc).

You also need to create a copy of [`mirrors.example`](./mirrors.example) named `mirrors` (this file should not have a file extension). Edit `mirrors`, deleting the examples and adding your own mirror pairs.

### Automated synching with cron

You can optionally add a `crontab` schedule to run the mirror sync script on a regular interval.

Edit your crontab with `crontab -e`. At the bottom, paste a line like this:

```bash
*/30 * * * * /path/to/git-sync-repos/git_mirror_sync.sh
```

This will run the [`git_mirror_sync.sh`](./git_mirror_sync.sh) script every 30 minutes. Other crontab schedules you could use:

```bash
## Once a day at 2am
0 2 * * *  /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

## Once a week on Sunday at 3am
0 3 * * 0 /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

### Once a month on the 1st day of the month at 4am
0 4 1 * * /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

## Once an hour
0 * * * * /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

## Twice a day
0 9,17 * * * /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

## Four times a day
0 6,12,18,0 * * * /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

## Once per hour
@hourly * * * * /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

## Once daily
@daily * * * * /bin/bash /path/to/git-sync-repos/git_mirror_sync.sh

```

### Add logging

You can log the output of the git sync script by adding a log file path to the end of the crontab schedule:

```bash
*/30 * * * * /path/to/git-sync-repos/git_mirror_sync.sh >> /path/to/git_mirror_sync.log 2>&1
```

## Running with Docker

The included [Docker Compose file](./compose.yml) can build the [Dockerfile in the ./containers/ directory](./containers/Dockerfile) to run the git mirroring within a container environment. The container installs GNU parallel to allow the script to run git operations concurrently, which significantly speeds up the synchronization. You still need to copy the [example mirrors file](./mirrors.example) to a file named `mirrors` (no file extension) and add some git repository mirrors before running the container.

To run the container, build it with `docker compose build`, then run `docker compose up`. You can check the logs with `docker compose logs -f git-sync`.

If you want to change any of the defaults, such as the SSH directory mounted in the container, the path to data files on the host, or anything else, you can copy the [example `.env` file](./.env.example) to `.env` and edit the variables before running.

The script calls a [crontab schedule](./containers/crontab) to run the script on a schedule you choose.
