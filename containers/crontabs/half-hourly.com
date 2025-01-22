## Every half hour
*/30 * * * * /bin/bash /git-sync/git_mirror_sync.sh  >&1 | tee -a /var/log/cron.half-hour.log > /proc/1/fd/1
