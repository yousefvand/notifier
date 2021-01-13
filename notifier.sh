#!/usr/bin/env bash

# Title:         systemd reminder
# Description:   Add/Remove systemd based event reminder
# Author:        Remisa Yousefvand <remisa.yousefvand@gmail.com>
# Date:          2021-01-13
# Version:       1.0.0

# Exit codes
# ==========
# 0   no error
# 1   unknown option

# >>>>>>>>>>>>>>>>>>>>>>>> variables >>>>>>>>>>>>>>>>>>>>>>>>

systemdPath="$HOME/.config/systemd/user/"

# <<<<<<<<<<<<<<<<<<<<<<<< variables <<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>> functions >>>>>>>>>>>>>>>>>>>>>>>>

function banner_color() {
  local color=$1
  shift

  case $color in
    black) color=0
    ;;
    red) color=1
    ;;
    green) color=2
    ;;
    yellow) color=3
    ;;
    blue) color=4
    ;;
    magenta) color=5
    ;;
    cyan) color=6
    ;;
    white) color=7
    ;;
    *) echo "color is not set"; exit 1
    ;;
  esac

  local s=("$@") b w
  for l in "${s[@]}"; do
    ((w<${#l})) && { b="$l"; w="${#l}"; }
  done
  tput setaf $color
  echo " =${b//?/=}=
| ${b//?/ } |"
  for l in "${s[@]}"; do
    printf '| %s%*s%s |\n' "$(tput setaf $color)" "-$w" "$l" "$(tput setaf $color)"
  done

  echo "| ${b//?/ } |
 =${b//?/=}="
  tput sgr 0
}

function usage () {
  echo "
  $0 [options]

    options:
    ==================
    -h | --help
    -l | --list timers
  "
}


# <<<<<<<<<<<<<<<<<<<<<<<< functions <<<<<<<<<<<<<<<<<<<<<<<<

POSITIONAL=()
while [[ $# > 0 ]]; do
  case "$1" in
    -h|--help)
    usage
    exit 0
    ;;
    -l|--list-timers)
    systemctl --user list-timers
    exit 0
    ;;
    *)
    echo `tput setaf 1`Unknown option`tput sgr0`
    exit 1
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional params


# Entry Point

banner_color magenta "systemd reminder"
echo

mkdir -p "${systemdPath}"

echo `tput setaf 3`For any question about event, if you want all posibilities type `tput setaf 1`* [asterisk]`tput sgr0`
echo

read -ep "Year? " -i "*" year
read -ep "Month? " -i "*" month
read -ep "Day of month? " -i "*" day
read -ep "Time of day? " -i "*:*:00" timeOfDay
read -ep "Notification header? " -i "Message header" header
read -ep "Notification body? " -i "Message body" body
read -ep "Notification duration (milliseconds)? " -i "10000" notificationDuration
read -ep "Icon name (should exist on your system)? " -i flag-yellow icon

random=$((100000 + RANDOM % $((999999-100000))))
serviceFilePath="${systemdPath}sr${random}.service"

# Write service file
cat >"${serviceFilePath}" <<EOL
[Unit]
Description=Systemd reminder ${random}

[Service]
ExecStart=notify-send -u normal -t ${notificationDuration} -a "System" -i "${icon}" "${header}" "${body}"

[Install]
WantedBy=default.target
EOL

timerFilePath="${systemdPath}sr${random}.timer"
serviceUnit="sr${random}.service"

# Write timer file
cat >"${timerFilePath}" <<EOL
[Unit]
Description=Systemd reminder ${random}
Requires=${serviceUnit}

[Timer]
Unit=${serviceUnit}
OnCalendar=${year}-${month}-${day} ${timeOfDay}

[Install]
WantedBy=timers.target 
EOL

# Enable reminder
service="sr${random}.timer"
echo "$service"
$(systemctl --user enable --now ${service})

# Generate deactivator

cat >"sr${random}.sh" <<EOL
#!/usr/bin/env bash

systemctl --user disable --now ${service}
rm -f "${serviceFilePath}" "${timerFilePath}"
EOL

chmod +x "sr${random}.sh"

echo
echo `tput setaf 4`Deactivation file generated!`tput sgr0`
