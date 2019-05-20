#!/bin/bash
#
# Title:      PGBlitz (Reference Title File)
# Author(s):  Admin9705
# URL:        https://pgblitz.com - http://github.pgblitz.com
# GNU:        General Public License v3.0
################################################################################
# NOTES
# Variables come from what's being called from deploymove.sh under functions
## BWLIMIT 9 and Lower Prevents Google 750GB Google Upload Ban
################################################################################
if pidof -o %PPID -x "$0"; then
   exit 1
fi

touch /var/plexguide/logs/pgmove.log

echo "" >> /var/plexguide/logs/pgmove.log
echo "" >> /var/plexguide/logs/pgmove.log
echo "----------------------------" >> /var/plexguide/logs/pgmove.log
echo "PG Move Log - First Startup" >> /var/plexguide/logs/pgmove.log

chown -R 1000:1000 "{{hdpath}}/downloads"
chmod -R 775 "{{hdpath}}/downloads"
chown -R 1000:1000 "{{hdpath}}/move"
chmod -R 775 "{{hdpath}}/move"

sleep 10
while true
do

  cleaner="$(cat /var/plexguide/cloneclean)"
  useragent="$(cat /var/plexguide/uagent)"

dir=$(dirname $0)

rclone moveto "{{hdpath}}/downloads/" "{{hdpath}}/move/" \
--config /opt/appdata/plexguide/rclone.conf \
--log-file=/var/plexguide/logs/pgmove.log \
--log-level ERROR --stats 5s --stats-file-name-length 0 \
--min-age 5d \
--exclude="**_HIDDEN~" --exclude=".unionfs/**" \
--exclude='**partial~' --exclude=".unionfs-fuse/**" \
--exclude=".fuse_hidden**" \
--exclude="**sabnzbd**" --exclude="**nzbget**" \
--exclude="**qbittorrent**" --exclude="**rutorrent**" \
--exclude="**deluge**" --exclude="**transmission**" \
--exclude="**jdownloader**" --exclude="**makemkv**" \
--exclude="**handbrake**" --exclude="**bazarr**" \
--exclude="**ignore**"  --exclude="**inProgress**"

chown -R 1000:1000 "{{hdpath}}/move"
chmod -R 775 "{{hdpath}}/move"

find "{{hdpath}}/move/" -type f ! -iname "**_HIDDEN~" ! -ipath ".unionfs/**" \
   ! -iname '**partial~' ! -ipath ".unionfs-fuse/**" \
   ! -iname ".fuse_hidden**" \
   ! -iname "**sabnzbd**" ! -iname "**nzbget**" \
   ! -iname "**qbittorrent**" ! -iname "**rutorrent**" \
   ! -iname "**deluge**" ! -iname "**transmission**" \
   ! -iname "**jdownloader**" ! -iname "**makemkv**" \
   ! -iname "**handbrake**" ! -iname "**bazarr**" \
   ! -iname "**ignore**"  ! -iname "**inProgress**" -print0 | while read -d $'\0' file
do

   echo "" >> /var/plexguide/logs/pgmove.log
   echo "Starting premove scripts" >> /var/plexguide/logs/pgmove.log
   echo "----------------------------" >> /var/plexguide/logs/pgmove.log

   run-parts --verbose --arg="$file" --regex='^.*\.sh$' "$dir/premove/" >> /var/plexguide/logs/pgmove.log

   dest=$(dirname $(realpath --relative-to {{hdpath}}/move "$file"))
   rclone move "$file" "{{type}}:/$dest" \
   --config /opt/appdata/plexguide/rclone.conf \
   --log-file=/var/plexguide/logs/pgmove.log \
   --log-level INFO --stats 5s --stats-file-name-length 0 \
   --bwlimit {{bandwidth.stdout}}M \
   --tpslimit 6 \
   --checkers=16 \
   --max-size=300G \
   --drive-chunk-size={{vfs_dcs}} \
   --user-agent="$useragent"

   echo "" >> /var/plexguide/logs/pgmove.log
   echo "Starting postmove scripts" >> /var/plexguide/logs/pgmove.log
   echo "----------------------------" >> /var/plexguide/logs/pgmove.log

   run-parts --verbose --arg="$file" --regex='^.*\.sh$' "$dir/postmove/" >> /var/plexguide/logs/pgmove.log
done

sleep 5

# Remove empty directories
  find "{{hdpath}}/move/" -mindepth 2 -type d -mmin +2 -empty -exec rm -rf {} \;

# Removes garbage
  find "{{hdpath}}/downloads" -mindepth 2 -type d -cmin +$cleaner  $(printf "! -name %s " $(cat /opt/pgclone/functions/exclude)) -empty -exec rm -rf {} \;
  find "{{hdpath}}/downloads" -mindepth 2 -type f -cmin +$cleaner  $(printf "! -name %s " $(cat /opt/pgclone/functions/exclude)) -size +1M -exec rm -rf {} \;

done
