#!/bin/bash
# /etc/init.d/minecraft

### BEGIN INIT INFO
# Provides:   minecraft
# Required-Start: $local_fs $remote_fs
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description:    Minecraft server
# Description:    Init script for minecraft/bukkit server, with rolling logs and use of ramdisk for less lag. 
### END INIT INFO

# Created by Ahtenus

# Based on http://www.minecraftwiki.net/wiki/Server_startup_script
# Support for multiworld by Benni-chan
# Support for world resets by Nullreff

#############################
######### SETTINGS ##########
#############################
# Server name
SERVER_NAME=`uname -n`
# Name of server.jar file
SERVICE="craftbukkit.jar"
# Name to use for the screen instance
SCREEN="minecraft"
# User that should run the server
USERNAME="minecraft"
# Minecraft home direcory
MCHOME="/home/minecraft"
# Path to minecraft directory 
MCPATH="${MCHOME}/server"
# Number of CPUs/cores to usei
CPU_COUNT=`nproc`
# Initial memory usage
INITMEM="512M"
# Maximum amount of memory to use
MAXMEM="800M"
# Remember: give the ramdisk enough space, subtract from the total amount
# of RAM available the size of your map and the RAM-consumption of your base system.
INVOCATION="java -Xmx$MAXMEM -Xms$INITMEM -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPU_COUNT -XX:+AggressiveOpts -jar $SERVICE nogui"
# Where the world backups should go
BACKUPPATH="${MCHOME}/backups/worlds"
# Where the logs are copied with log-roll 
LOGPATH="${MCHOME}/logs"
# Where the whole minecraft directory is copied when whole-backup is executed
WHOLEBACKUP="${MCHOME}/backups/server"
# Where the worlds are located on the disk. Can not be the same as MCPATH.
WORLDSTORAGE="${MCPATH}/worlds"
# Path to the the mounted ramdisk default in Ubuntu: /dev/shm
RAMDISK="/dev/shm"
# use tar or zip files for world backup
BACKUPFORMAT="zip"

ME=`whoami`
as_user() {
    if [ $ME == $USERNAME ] ; then
        bash -c "$1"
    else
        sudo su - $USERNAME -c "$1"
    fi
}
datepath() {
    # datepath path filending-to-check returned-filending
    if [ -e $1`date +%F`$2 ]
    then
        echo $1`date +%FT%T`$3
    else
        echo $1`date +%F`$3
    fi
}
mc_start() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
        echo "Tried to start but $SERVICE was already running!"
    else
        echo "$SERVICE was not running... starting."
        cd $MCPATH
        as_user "cd $MCPATH && screen -dmS $SCREEN $INVOCATION"
        sleep 7
        if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
        then
            echo "$SERVICE is now running."
        else
            echo "Could not start $SERVICE."
        fi
    fi
}

mc_saveoff() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
        echo "$SERVICE is running... suspending saves"
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"save-off\"\015'"
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"save-all\"\015'"
        sync
        sleep 10
    else
        echo "$SERVICE was not running. Not suspending saves."
    fi
}

mc_saveon() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
        echo "$SERVICE is running... re-enabling saves"
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"save-on\"\015'"
    else
        echo "$SERVICE was not running. Not resuming saves."
    fi
}

mc_stop() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
        echo "$SERVICE is running... stopping."
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"save-all\"\015'"
        sleep 10
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"stop\"\015'"
        sleep 7
    else
        echo "$SERVICE was not running."
    fi
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
        echo "$SERVICE could not be shut down... still running."
    else
        echo "$SERVICE is shut down."
    fi
}
log_roll() {
    as_user "mkdir -p $LOGPATH"
    path=`datepath $LOGPATH/${SERVER_NAME}_ .log.gz .log`
    as_user "mv $MCPATH/server.log $path && gzip $path"
}
get_worlds() {
    a=1
    for NAME in $(ls $WORLDSTORAGE)
    do
        if [ -d $WORLDSTORAGE/$NAME ]
        then
            WORLDNAME[$a]=$NAME
            if [ -e $WORLDSTORAGE/$NAME/ramdisk ]
            then
                WORLDRAM[$a]=true
            else
                WORLDRAM[$a]=false
            fi
            a=$a+1
        fi
    done
}
mc_whole_backup() {
    as_user "mkdir -p $WHOLEBACKUP"
    path=`datepath $WHOLEBACKUP/mine_`
    as_user "cp -rP $MCPATH $path"
}
mc_world_backup() {
    get_worlds
    for INDEX in ${!WORLDNAME[@]}
    do
        echo "Backing up minecraft ${WORLDNAME[$INDEX]}"
        as_user "mkdir -p $BACKUPPATH/${WORLDNAME[$INDEX]}"

        case "$BACKUPFORMAT" in
            tar)
                path=`datepath $BACKUPPATH/${WORLDNAME[$INDEX]}/ .tar.bz2 .tar.bz2`
                as_user "tar -hcjf $path $MCPATH/${WORLDNAME[$INDEX]}"
                ;;
            zip)
                path=`datepath $BACKUPPATH/${WORLDNAME[$INDEX]}/ .zip .zip`
                as_user "(cd $MCPATH/${WORLDNAME[$INDEX]}; zip -rq $path *)"
                ;;
            *)
                echo "$BACKUPFORMAT is no supported backup format"
                ;;
        esac
    done
}
check_links() {
    get_worlds
    for INDEX in ${!WORLDNAME[@]}
    do
        if [[ -L $MCPATH/${WORLDNAME[$INDEX]} || ! -a $MCPATH/${WORLDNAME[$INDEX]} ]]
        then
            link=`ls -l $MCPATH/${WORLDNAME[$INDEX]} | awk '{print $11}'`
            if ${WORLDRAM[$INDEX]}
            then
                if [ "$link" != "$RAMDISK/${WORLDNAME[$INDEX]}" ]
                then
                    as_user "rm -f $MCPATH/${WORLDNAME[$INDEX]}"
                    as_user "ln -s $RAMDISK/${WORLDNAME[$INDEX]} $MCPATH/${WORLDNAME[$INDEX]}"
                    echo "created link for ${WORLDNAME[$INDEX]}"
                fi
            else
                if [ "$link" != "${WORLDSTORAGE}/${WORLDNAME[$INDEX]}" ]
                then
                    as_user "rm -f $MCPATH/${WORLDNAME[$INDEX]}"
                    as_user "ln -s ${WORLDSTORAGE}/${WORLDNAME[$INDEX]} $MCPATH/${WORLDNAME[$INDEX]}"
                    echo "created link for ${WORLDNAME[$INDEX]}"
                fi
            fi
        else
            echo "could not process ${WORLDNAME[$INDEX]}. please move all worlds to ${WORLDSTORAGE}."
            exit 1
        fi
    done
    echo "links checked"
}
to_ram() {
    get_worlds
    for INDEX in ${!WORLDNAME[@]}
    do
        if ${WORLDRAM[$INDEX]}
        then
            if [ -L $MCPATH/${WORLDNAME[$INDEX]} ]
            then
                as_user "rsync -rt --exclude 'ramdisk' ${WORLDSTORAGE}/${WORLDNAME[$INDEX]}/ $RAMDISK/${WORLDNAME[$INDEX]}"
                echo "${WORLDNAME[$INDEX]} copied to ram"
            fi
        fi
    done
}
to_disk() {
    get_worlds
    for INDEX in ${!WORLDNAME[@]}
    do
        as_user "rsync -rt --exclude 'ramdisk' $MCPATH/${WORLDNAME[$INDEX]}/ ${WORLDSTORAGE}/${WORLDNAME[$INDEX]}"
        echo "${WORLDNAME[$INDEX]} copied to disk"
    done
}
map_update() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
        echo "$SERVICE is running! Will not start update."
    else
        echo "Beginning map update.  This will take a while...."
        as_user "overviewer.py --textures-path=/srv/minecraft/textures /srv/minecraft/worlds/world /srv/www/barroncraft.com/public_html/worlds/world"
        as_user "overviewer.py --textures-path=/srv/minecraft/textures /srv/minecraft/worlds/chaos /srv/www/barroncraft.com/public_html/worlds/chaos"
        echo "Map has been updated!"
    fi
}
mc_update() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
        echo "$SERVICE is running! Will not start update."
    else
        ### update minecraft_server.jar
        echo "Updating minecraft_server.jar...."
        MC_SERVER_URL=http://minecraft.net/`wget -q -O - http://www.minecraft.net/download.jsp | grep minecraft_server.jar\</a\> | cut -d \" -f 2`
        as_user "cd $MCPATH && wget -q -O $MCPATH/minecraft_server.jar.update $MC_SERVER_URL"
        if [ -f $MCPATH/minecraft_server.jar.update ]
        then
            if `diff $MCPATH/minecraft_server.jar $MCPATH/minecraft_server.jar.update >/dev/null`
            then
                echo "You are already running the latest version of the Minecraft server."
                as_user "rm $MCPATH/minecraft_server.jar.update"
            else
                as_user "mv $MCPATH/minecraft_server.jar.update $MCPATH/minecraft_server.jar"
                echo "Minecraft successfully updated."
            fi
        else
            echo "Minecraft update could not be downloaded."
        fi

        ### update craftbukkit

        echo "Updating craftbukkit...."
        as_user "cd $MCPATH && wget -q -O $MCPATH/craftbukkit.jar.update http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-0.0.1-SNAPSHOT.jar"
        if [ -f $MCPATH/craftbukkit.jar.update ]
        then
            if `diff $MCPATH/craftbukkit-0.0.1-SNAPSHOT.jar $MCPATH/craftbukkit.jar.update > /dev/null`
            then
                echo "You are already running the latest version of CraftBukkit."
                as_user "rm $MCPATH/craftbukkit.jar.update"
            else
                as_user "mv $MCPATH/craftbukkit.jar.update $MCPATH/craftbukkit-0.0.1-SNAPSHOT.jar"
                echo "CraftBukkit successfully updated."
            fi
        else
            echo "CraftBukkit update could not be downloaded."
        fi
    fi
}
change_ramdisk_state() {
    if [ ! -e $WORLDSTORAGE/$1 ]
    then
        echo "World \"$1\" not found."
        exit 1
    fi

    if [ -e $WORLDSTORAGE/$1/ramdisk ]
    then
        rm $WORLDSTORAGE/$1/ramdisk
        echo "removed ramdisk flag from \"$1\""
    else
        touch $WORLDSTORAGE/$1/ramdisk
        echo "added ramdisk flag to \"$1\""
    fi
    echo "changes will only take effect after server is restarted."	
}

reset_dota_world() {
    as_user "	
    rm -rf $WORLDSTORAGE/dota;
    cp -r $BACKUPPATH/dota/original $WORLDSTORAGE/dota;
    rm -f $MCPATH/plugins/SimpleClans/SimpleClans.db;
    rm -rf $MCPATH/dota;
    rm -f $MCPATH/reset-required;
    "
}


case "$1" in
    start)
        # Starts the server
        check_links
        to_ram
        mc_start
        ;;
    stop)
        # Stops the server
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say SERVER SHUTDOWN IN 10 SECONDS!\"\015'"
        mc_stop
        to_disk
        ;;
    restart)
        # Restarts the server
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say SERVER REBOOT IN 10 SECONDS.\"\015'"
        mc_stop
        to_disk
        check_links
        to_ram
        mc_start
        ;;
    reset)
        # Resets the map (Minecraft DOTA)
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say MAP IS RESETING, BE BACK IN 10 SECONDS.\"\015'"
        mc_stop
        to_disk
        reset_dota_world
        log_roll
        check_links
        to_ram
        mc_start
        ;;
    reload)
        # Reloads the server plugins (Bukkit)
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"reload\"\015'"
        ;;
    backup)
        # Backups world
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say Backing up world.\"\015'"
        mc_saveoff
        to_disk
        mc_world_backup
        mc_saveon
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say Backup complete.\"\015'"
        ;;
    whole-backup)
        # Backup everything
        mc_whole_backup
        ;;
    update)
        #update minecraft_server.jar and craftbukkit.jar (thanks karrth)
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say SERVER UPDATE IN 10 SECONDS.\"\015'"
        mc_stop
        to_disk
        mc_whole_backup
        mc_update
        check_links
        mc_start
        ;;
    to-disk)
        # Writes from the ramdisk to disk, in case the server crashes. 
        # Using ramdisk speeds things up a lot, especially if you allow
        # teleportation on the server.
        mc_saveoff
        to_disk
        mc_saveon
        ;;
    connected)
        # Lists connected users
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff list\015'"
        sleep 3s
        tac $MCPATH/server.log | grep -m 1 "Connected"
        ;;
    console)
        # Re-attaches to the server console
        as_user "script /dev/null -qc \"screen -Dr\""
        ;;
    view-log)
        # Watches the end of the log file
        tail -Fn 50 $MCPATH/server.log
        ;;
    grep-log)
        # Searches through all past logs
        gzip -dc $MCHOME/logs/* | grep "$2"
        grep "$2" $MCPATH/server.log
        ;;
    log-roll)
        # Moves and Gzips the logfile, a big log file slows down the
        # server A LOT (what was notch thinking?)
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say ROUTINE REBOOT IN 10 SECONDS.\"\015'"
        mc_stop
        log_roll
        mc_start
        ;;
    roll-all)
        # Backs up the log files, regenerates the map on the website and backs up the world.
        as_user "screen -p 0 -S $SCREEN -X eval 'stuff \"say SERVER SHUTTING DOWN FOR NIGHTLY MAINTENANCE.  WE WILL BE BACK SHORTLY.\"\015'"
        mc_stop
        to_disk
        log_roll
        map_update
        check_links
        mc_start
        ;;
    last)
        # greps for recently logged in users
        echo Recently logged in users:
        cat $MCPATH/server.log | awk '/entity|conn/ {sub(/lost/,"disconnected");print $1,$2,$4,$5}'
        ;;
    status)
        # Shows server status
        if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
        then
            echo "$SERVICE is running."
        else
            echo "$SERVICE is not running."
        fi
        ;;
    version)
        echo Craftbukkit version `awk '/Craftbukkit/ {sub(/\)/, ""); print $12}' $MCPATH/server.log`
        ;;
    links)
        check_links
        ;;
    ramdisk)
        change_ramdisk_state $2
        ;;
    worlds)
        get_worlds
        for INDEX in ${!WORLDNAME[@]}
        do
            if ${WORLDRAM[$INDEX]}
            then
                echo "${WORLDNAME[$INDEX]} (ramdisk)"
            else
                echo ${WORLDNAME[$INDEX]}
            fi
        done
        ;;
    help)
        echo "Usage: /etc/init.d/minecraft command"
        echo 
        echo "start - Starts the server"
        echo "stop - stops the server"
        echo "restart - restarts the server"
        echo "reset - resets the map on the server (Minecraft DOTA)"
        echo "reload - reloads the server plugins"
        echo "backup - backups the worlds defined in the script"
        echo "whole-backup - backups the entire server folder"
        echo "update - fetches the latest version of minecraft.jar server and Bukkit"
        echo "console - attach to the servers console"
        echo "view-log - watch the end of the current log file"
        echo "grep-log - search through all past log files"
        echo "log-roll - Moves and gzips the logfile"
        echo "roll-all - Rolles logs and updates the world map"
        echo "to-disk - copies the worlds from the ramdisk to worldstorage"
        echo "connected - lists connected users"
        echo "status - Shows server status"
        echo "version - returs Bukkit version"
        echo "links - creates nessesary symlinks"
        echo "last - shows recently connected users"
        echo "worlds - shows a list of available worlds"
        echo "ramdisk WORLD - toggles ramdisk configuration for WORLD"
        ;;
    *)
        echo "No such command see /etc/init.d/minecraft help"
        exit 1
        ;;
esac

exit 0

