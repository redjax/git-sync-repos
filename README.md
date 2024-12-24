# Git Mirror

Mirror git repositories from one remote to another (i.e. a Github repository to Codeberg). This is a Bash script, so only Linux hosts are supported currently.

## Setup

- Copy [`mirrors.example`](./mirrors.example) to `mirrors` (this file should not have a file extension).
  - Edit `mirrors`, deleting the examples and adding your own mirror pairs.
- Run the [`git_mirror_sync.sh`](./git_mirror_sync.sh) script.
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
