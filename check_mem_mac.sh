#!/usr/bin/env bash

#Set script name
SCRIPT=`basename ${BASH_SOURCE[0]}`

#Set default values
optMW=95
optMC=98

# help function
function printHelp {
  echo -e \\n"Help for $SCRIPT"\\n
  echo -e "Basic usage: $SCRIPT -w {warning} -c {critical}"\\n
  echo "Command switches are optional, default values for warning is 95% and critical is 98%"
  echo "-w - Sets warning value for Memory Usage. Default is 95%"
  echo "-c - Sets critical value for Memory Usage. Default is 98%"
  echo -e "-h  - Displays this help message"\\n
  echo -e "Example: $SCRIPT -w 80 -c 90"\\n
  echo -e \\n\\n"Author: Till Hein"
  echo -e "Git: https://github.org/TillHein/nagiosPlugins"
  exit 1
}

# regex to check is OPTARG an integer
re='^[0-9]+$'

while getopts :w:c:h FLAG; do
  case $FLAG in
    w)
      if ! [[ $OPTARG =~ $re ]] ; then
        echo "error: Not a number" >&2; exit 1
      else
        optMW=$OPTARG
      fi
      ;;
    c)
      if ! [[ $OPTARG =~ $re ]] ; then
        echo "error: Not a number" >&2; exit 1
      else
        optMC=$OPTARG
      fi
      ;;
    h)
      printHelp
      ;;
    \?)
      echo -e \\n"Option - $OPTARG not allowed."
      printHelp
      exit 2
      ;;
  esac
done

shift $((OPTIND-1))



array=($(vm_stat | egrep 'free|Pages active|inactive|speculat|throttled|File-backed' |awk '{print $3}' | tr -d '.' | tr '\n' ' ' | awk '{printf("%i %i %i %i %i %i", $1,$2,$3,$4,$5,$6)}'))
free_p=${array[0]}
free_B=$((free_p * 4096))
active_p=${array[1]}
active_B=$((active_p * 4096))
inactive_p=(${array[2]})
inactive_B=$((inactive_p * 4096))
speculative_p=(${array[3]})
speculative_B=$((speculative_p * 4096))
throttled_p=(${array[4]})
throttled_B=$((throttled_p * 4096))
memCache_p=(${array[5]})
memCache_B=$((memCache_p * 4096))
occupied_p=$(vm_stat | egrep 'occupied' | awk '{print $5}' | tr -d '.' | tr '\n' ' ' | awk '{printf("%i", $1)}')
occupied_B=$((occupied_p * 4096))
wiredDown_p=$(vm_stat | egrep 'wired' | awk '{print $4}' | tr -d '.' | tr '\n' ' ' | awk '{printf("%i", $1)}')
wiredDown_B=$((wiredDown_p * 4096))

memTotal_b=$((free_B + active_B + inactive_B + speculative_B + throttled_B + occupied_B + wiredDown_B))
memUsed_b=$((memTotal_b - free_B))
memUsedPrc=$((memUsed_b * 100 / memTotal_b))
memTotal_m=$((memTotal_b / 1024 / 1024))
memUsed_m=$((memUsed_b / 1024 / 1024))
message="[MEMORY] Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% | MTOTAL=$memTotal_b;;;; MUSED=$memUsed_b;;;; MCACHE=$memCache_b;;;; "


if [ $memUsedPrc -ge $optMC ]; then
  echo -e $message
  $(exit 2)
elif [ $memUsedPrc -ge $optMW ]; then
  echo -e $message
  $(exit 1)
else
  echo -e $message
  $(exit 0)
fi
