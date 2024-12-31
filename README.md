# Git Mirror

Mirror git repositories from one remote to another (i.e. a Github repository to Codeberg). On Windows hosts, run [`git_mirror_sync.ps1`](./git_mirror_sync.ps1), and on Linux run [`git_mirror_sync.sh`](./git_mirror_sync.sh).

Includes a [Docker container](./containers/Dockerfile) and [Docker Compose file](./compose.yml) for running the sync operation in a container.

## Setup

Before running this script, make sure your repositories are public, or that you've added a public SSH key to both the source and target repository. Instructions for adding your SSH key [to Github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), [to Codeberg](https://docs.codeberg.org/security/ssh-key/), and [to Gitlab](https://docs.gitlab.com/ee/user/ssh.html).

- Copy [`mirrors.example`](./mirrors.example) to `mirrors` (this file should not have a file extension).
  - Edit `mirrors`, deleting the examples and adding your own mirror pairs.
- Run the [`git_mirror_sync.sh`](./git_mirror_sync.sh) or [`git_mirror_sync.ps1`](./git_mirror_sync.ps1) script.
  - The script will read the `mirrors` file, create a `./repositories/` path, and clone each repository source, then mirror to the target.

### Automated synching with cron

You can optionally add a `crontab` schedule to run the mirror sync script on a regular interval.

Edit your crontab with `crontab -e`. At the bottom, paste a line like this:

```bash
*/30 * * * * /path/to/git-sync-repos/git_mirror_sync.sh
```

This will run the [`git_mirror_sync.sh`](./git_mirror_sync.sh) script every 30 minutes. Other crontab schedules you could use:

```bash
## Once a day at 2am
0 2 * * *  /path/to/git-sync-repos/git_mirror_sync.sh

## Once a week on Sunday at 3am
0 3 * * 0 /path/to/git-sync-repos/git_mirror_sync.sh

### Once a month on the 1st day of the month at 4am
0 4 1 * * /path/to/git-sync-repos/git_mirror_sync.sh

## Once an hour
0 * * * * /path/to/git-sync-repos/git_mirror_sync.sh

## Twice a day
0 9,17 * * * /path/to/git-sync-repos/git_mirror_sync.sh

## Four times a day
0 6,12,18,0 * * * /path/to/git-sync-repos/git_mirror_sync.sh

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

The script sleeps for 1 hour between executions. To change this, modify the `sleep 3600` line in the `compose.yml` file.
