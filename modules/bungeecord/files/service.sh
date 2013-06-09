#!/bin/bash
# /etc/init.d/bungeecord

### BEGIN INIT INFO
# Provides:          bungeecord
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      $network
# Should-Stop:       $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: BungeeCord Server
# Description:       Init script for BungeeCord http://www.spigotmc.org/threads/bungeecord-guide-installation-faq.700/
### END INIT INFO

# Created by Nullreff
# Inspiration taken from Ahtenus init script

# Name of BungeeCord jar
SERVICE="BungeeCord.jar"
# Name to use for the screen instance
SCREEN="bungee"
# User that should run the server
BUNGEE_USER="bungee"
# The user running this script
CURRENT_USER=`whoami`
# BungeeCord home direcory
BUNGEE_PATH="/home/$BUNGEE_USER"
# Number of CPUs/cores to usei
CPU_COUNT=`nproc`
# Memory to use
MEM="256M"
# What to run
INVOCATION="java -Xmx$MEM -XX:ParallelGCThreads=$CPU_COUNT -XX:+AggressiveOpts -jar $SERVICE"

run_as() {
    if [ $CURRENT_USER == $BUNGEE_USER ]; then
        bash -c "$1"
    elif type 'sudo' > /dev/null; then
        sudo su - $BUNGEE_USER -c "$1"
    else
        su - $BUNGEE_USER -c "$1"
    fi
}

bungee_running() {
    ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
}

bungee_start() {
    if bungee_running; then
        echo 'BungeeCord is already running'
    else
        echo -n 'Starting BungeeCord... '
        cd $HOME_DIR
        run_as "cd $BUNGEE_PATH && screen -dmS $SCREEN $INVOCATION"
        sleep 7
        if bungee_running; then
            echo 'Done'
        else
            echo 'Error'
            echo 'There was an issue starting BungeeCord'
        fi
    fi
}

bungee_stop() {
    if bungee_running; then
        echo -n 'Stopping BungeeCord... '
        run_as "screen -p 0 -S $SCREEN -X eval 'stuff \"end\"\015'"
        sleep 7
        if bungee_running; then
            echo 'Error'
            echo 'There was an issue stopping BungeeCord'
        else
            echo 'Done'
        fi
    else
        echo "BungeeCord is not running"
    fi
}

bungee_status() {
    if bungee_running;  then
        echo "BungeeCord is running"
        exit 0
    else
        echo "BungeeCord is not running"
        exit 1
    fi
}

case "$1" in
    start)
        bungee_start
        ;;
    stop)
        bungee_stop
        ;;
    status)
        bungee_status
        ;;
    *)
        echo "Usage: /etc/init.d/bungeecord {start|stop|status}"
        exit 1
        ;;
esac

exit 0
