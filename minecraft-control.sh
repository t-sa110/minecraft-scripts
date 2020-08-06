#!/bin/bash
# Path settings
MC_PATH_HOME="/var/games/minecraft_forge-1.15.2"               # Minecraft server dir
MC_PATH_BACKUP="${MC_PATH_HOME}/schedule_backup"               # World data backup file save dir
MC_PATH_BACKUP_WORLD="${MC_PATH_HOME}/schedule_backup/world"
MC_PATH_WORLD="${MC_PATH_HOME}/world"                          # World data dir
RAM_DISK_PATH_HOME="/mnt/ram"                                  # Base dir for ram disk
RAM_DISK_PATH_WORLD="/mnt/ram/world"                           # World dir for ram disk

# Machine settings
USE_MEM_SIZE="6G"     # JVM allocation memory size
USE_NEW_SIZE="3G"     # JVM allocation new area size
USE_META_SIZE="1G"    # JVM allocation metaspace size

# Minecraft settings
MC_SERVICE="forge-1.15.2-31.1.0.jar"    # Server program file name
MC_SERVICE_NAME="Forge Server-1.15.2"   # Distinguished name for server
MC_OPTION="nogui"                       # Options for server program
MC_STOP_INTERVAL=60                     # Wait time for server stopped
MC_SCREENNAME="minecraft-server"        # screen name

# Command to run Minecraft server
MC_INVOCATION="java -Xms${USE_MEM_SIZE} -Xmx${USE_MEM_SIZE} -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -XX:+CMSIncrementalPacing -XX:+AggressiveOpts -XX:-UseAdaptiveSizePolicy -XX:NewSize=${USE_NEW_SIZE} -XX:MaxNewSize=${USE_NEW_SIZE} -XX:MetaspaceSize=${USE_META_SIZE} -XX:MaxMetaspaceSize=${USE_META_SIZE} -jar ./${MC_SERVICE} ${MC_OPTION}"

# Send command
MC_SEND="screen -p 0 -S ${MC_SCREENNAME} -X eval"

# Show settings
RESET=$'\e[0m'
BOLD=$'\e[1m'
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'

# Echo message ###################################################################################
as_message() {
    echo "minecraft: ${MC_SERVICE_NAME}: [${2}${1}${RESET}]"
}

# Server start process ###########################################################################
mc_start() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
    then
        as_message "Already started server" "${GREEN}"
    else
        as_message "Starting..." "${BOLD}"
        cd ${MC_PATH_HOME}
        screen -AmdS ${MC_SCREENNAME} ${MC_INVOCATION}
        sleep 7
        if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
        then
            as_message "Successfully" "${GREEN}"
        else
            as_message "Fatled" "${RED}"
        fi
    fi
}

# Server stop process #############################################################################
mc_stop() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
    then
        as_message "Stopping..." "${BOLD}"
        ${MC_SEND} 'stuff "say SERVER SHUTTING DOWN IN '${MC_STOP_INTERVAL}' SECONDS.\015"'
        i=${MC_STOP_INTERVAL}
        while [ ${i} -ne 0 ]
        do
            if test `expr $i % 30` -eq 0 -o ${i} -le 10
            then
                ${MC_SEND} 'stuff "say SERVER WILL STOP IN '${i}' SECONDS.\015"'
                
            fi
            i=`expr ${i} - 1`
            sleep 1
        done
        ${MC_SEND} 'stuff "say saving map...\015"'
        ${MC_SEND} 'stuff "save-all\015"'
        ${MC_SEND} 'stuff "stop\015"'
        sleep 7
        if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
        then
            as_message "Failed" "${RED}"
        else
            as_message "Successfully" "${GREEN}"
        fi
    else
        as_message "Already stopped" "${RED}"
    fi
}

# Server rapid stop process #########################################################################
mc_rapid_stop() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
    then
        as_message "Rapid stopping..." "${BOLD}"
        ${MC_SEND} 'stuff "save-all\015"'
        ${MC_SEND} 'stuff "stop\015"'
        sleep 7
        if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
        then
            as_message "Failed" "${RED}"
        else
            as_message "Successfully" "${GREEN}"
        fi
    else
        echo "${MC_SERVICE_NAME}: [${RED}停止中${RESET}]"
    fi
}

# Server reload process ##############################################################################
mc_reload() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
    then
        as_message "Reloading..." "${BOLD}"
        ${MC_SEND} 'stuff "reload\015"'
        sleep 7
        as_message "Successfully" "${GREEN}"
    else
        as_message "Failed" "${RED}"
    fi
}

# Check to server running status process  ############################################################
mc_status() {
    if ps ax | grep -v grep | grep -v -i SCREEN | grep ${MC_SERVICE} > /dev/null
    then
        as_message "Started" "${GREEN}"
    else
        as_message "Stopped" "${RED}"
    fi
}

# World data backup process ##########################################################################
mc_backup_world() {
    DIRNAME=`date '+%Y_%m_%d'`
    CREATEDIR=`date '+%H%M'`

    mkdir ${MC_PATH_BACKUP}/${DIRNAME}/${CREATEDIR}
    #rsync -a /mnt/ram/world /var/games/minecraft/backup/${DIRNAME}/${CREATEDIR}
	cp -r ${RAM_DISK_PATH_WORLD} ${MC_PATH_BACKUP}/${DIRNAME}/${CREATEDIR}
}

mc_create_backup_dir() {
    DIRNAME=`date --date tomorrow +%Y_%m_%d`
    mkdir ${MC_PATH_BACKUP}/${DIRNAME}
}

mc_remove_backup() {
    DIRNAME=`date --date "7 days ago" +%Y_%m_%d`
    rm -rf ${MC_PATH_BACKUP}/${DIRNAME}
}

# World data moving process  #########################################################################
mc_move_world() {
    STATUS=$1
    if [ ${STATUS} = "UP" ]
    then
        mv ${MC_PATH_WORLD} ${RAM_DISK_PATH_HOME}
        ln -s ${RAM_DISK_PATH_WORLD} ${MC_PATH_WORLD}
    else
        unlink ${MC_PATH_WORLD}
        mv ${RAM_DISK_PATH_WORLD} ${MC_PATH_HOME}
    fi
}

# Main process ########################################################################################
case "$1" in
    start)
		mc_move_world "UP"
        mc_start
        ;;
    stop)
        mc_stop
		    mc_move_world "DOWN"
        ;;
    reload)
        mc_reload
        ;;
    rapidstop)
        mc_rapid_stop
		    mc_move_world "DOWN"
        ;;
    restart)
        ${MC_SEND} 'stuff "say SERVER WILL RESTART! PLEASE LOGOUT!\015"'
        mc_stop
        mc_start
        ;;
  	recoverstart)
	  	mc_start
		    ;;
    backup)
        mc_backup_world
        ;;
    mkbkdir)
        mc_create_backup_dir
        ;;
    rmbackup)
        mc_remove_backup
        ;;
    status)
        mc_status
        ;;
    help)
        echo "*** Minecraft Contorol Script Use Manual ***"
        echo "EXAMPLE : sh ./minecraft-control.sh [start|stop|rapidstop|reload|restart|recoverstart|backup|mkbkdir|rmbakup]"
        echo "start        : Start server."
        echo "stop         : The server will be stopped after 60 seconds. It also notifies the player of the countdown."
        echo "rapidstop    : Stops the server immediately without notifying the player of the stop."
        echo "reload       : Reload server"
        echo "restart      : Reboot the server. It also notifies the player of the restart."
		    echo "recoverstart : Start the server without moving world data."
        echo "backup       : Back up the world data."
        echo "mkbkdir      : Create a backup directory for each date. (cron recommended)"
        echo "rmbakup      : Delete backups older than 7 days. (cron recommended)"
        ;;
    *)
        echo "Using: sh minecraft-control.sh help"
esac

exit 0
