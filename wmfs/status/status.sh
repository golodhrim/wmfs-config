#!/bin/bash

_mpd() {
    ############
    # mpd info
    #
    # <mpc> is required for "now playing" informations
    #
    if [ "`mpc 2>&1 | wc -l`" -gt "1" ]; then
        if [ "`mpc | grep "^\[paused\]"`" != "" ]; then
            mpd_current="`mpc current` [paused]"
        else
            mpd_current=`mpc current`
        fi
    else
        mpd_current="stopped/offline"
    fi
    mpd="\\#1791d1\\$mpd_current"
    #
    ############
}

_network() {
    ############
    # network
    #
    # network usage stats
    #
    # Variables
    ethiface=eth0
    wlaniface=wlan0
    tmpdir=/tmp 
    #
    # Functions
    function rx_bytes {
        rxethernet=`cat /sys/class/net/${ethiface}/statistics/rx_bytes`
        rxwireless=`cat /sys/class/net/${wlaniface}/statistics/rx_bytes`
        echo $((${rxethernet}+${rxwireless}))
    }
    function tx_bytes {
        txethernet=`cat /sys/class/net/${ethiface}/statistics/tx_bytes`
        txwireless=`cat /sys/class/net/${wlaniface}/statistics/tx_bytes`
        echo $((${txethernet}+${txwireless}))
    }
    #
    # Download
    lastrxbytes=`cat ${tmpdir}/last_rxbytes`
    # Upload
    lasttxbytes=`cat ${tmpdir}/last_txbytes`
    #
    # Download
    rxbytes=`rx_bytes`
    rxresult=$(((${rxbytes}-lastrxbytes)/1000))
    echo ${rxbytes} > ${tmpdir}/last_rxbytes
    #
    # Upload
    txbytes=`tx_bytes`
    txresult=$(((${txbytes}-lasttxbytes)/1000))
    echo ${txbytes} > ${tmpdir}/last_txbytes
    #
    # Output
    network="\\#1791d1\\↓ $rxresult Ko/s | $txresult Ko/s ↑"
    #
    ############
}

_battery() {
    ############
    # battery state
    #
    bat_percent=$((`cat /sys/class/power_supply/BAT*/current_now`/`cat /sys/class/power_supply/BAT*/charge_full_design | sed 's/00$//'`))
    bat_acpi=`cat /sys/class/power_supply/BAT*/status`
    #
    # use an arrow to show if batter is charging, discharging or full/AC
    #
    if [ "${bat_acpi}" = "Discharging" ]; then
        bat_state="↓"
    elif [ "${bat_acpi}" = "Charging" ]; then
        bat_state="↑"
    fi
    ############
    # battery time
    #
    # <acpi> is required
    #
    bat_remtime="`acpi | cut -d' ' -f5 | cut -d':' -f 1,2`"
    #
    ############
    if [ "${bat_acpi}" = "Full" ]; then
        battery="\\#1791d1\\Bat. ${bat_acpi}"
    else
        battery="\\#1791d1\\Bat. ${bat_percent}% ${bat_state} (${bat_remtime})"
    fi
}

_uptime() {
    ############
    # uptime
    #
    uptime=`cut -d'.' -f1 /proc/uptime`
    secs=$((${uptime}%60))
    mins=$((${uptime}/60%60))
    hours=$((${uptime}/3600%24))
    days=$((${uptime}/86400))
    uptime="${mins}:${secs}"
    #
    if [ "${hours}" -ne "0" ]; then
        uptime="${hours}:${uptime}"
    fi
    #
    if [ "${days}" -ne "0" ]; then
        uptime="${days}d ${uptime}"
    fi
    #
    ############
    uptime="\\#1791d1\\Up ${uptime}"
}

_memory() {
    ############
    # memory usage
    #
    memory_used="`free -m | sed -n 's|^-.*:[ \t]*\([0-9]*\) .*|\l|gp'`"
    memory_total="`free -m | sed -n 's|^M.*:[ \t]*\([0-9]*\) .*|\l|gp'`"
    memory="${memory_used}/${memory_total} Mo"
    #
    ############
}

_volume() {
    ############
    # volume
    #
    # <amixer> is required
    #
    if [ "`amixer get Master | grep '\[off\]$'`" = "" ]; then
        volume="\\#1791d1\\Vol: `amixer get Master | sed -n 's|.*\[\([0-9]*\)\%.*|\1%|pg'`"
    else
        volume="\\#1791d1\\Vol: [off]"
    fi
    #
    ############
}

_date() {
    ############
    # date
    #
    sys_date=`date '+%a %m/%d/%Y'`
    date="\\#1791d1\\${sys_date}"
    #
    ############
}

_hour() {
    ############
    # hour
    #
    sys_hour=`date '+%I:%M %P'`
    hour="\\#1791d1\\${sys_hour}"
    #
    ############
}

_datehour() {
    ############
    # datehour
    #
    sys_datehour=`date '+%a %m/%d/%Y %I:%M %P'`
    datehour="\\#1791d1\\${sys_datehour}"
    #
    ############
}

_ompload() {
    ############
    # ompload
    #
    # <ompload> is required
    #
    [ -e /tmp/omploadurl ] && ompload_url=`cat /tmp/omploadurl`
    ompload="$ompload_url"
    #
    ############
}

_separateurstart() {
    separateurstart="\\#ff6b6b\\--{"
}

_separateur() {
    separateur="\\#ff6b6b\\}--{"
}

_separateurstop() {
    separateurstop="\\#ff6b6b\\}--"
}

statustext() {
    ############
    # concatenate arguments
    #
    args=""
    for arg in $@; do
        _${arg}
        args="${args} `eval echo '$'${arg}`"
    done
    #
    ############
    # wmfs magic
    #
    wmfs -s "${args}"
    #
    ############
}

############
# status text
#
# add <variables> from the from the following list
# mpd network battery uptime volume date hour datehour ompload
#
while true; do statustext separateurstart mpd separateur volume separateur network separateur datehour separateurstop; sleep 10; done
#
############
