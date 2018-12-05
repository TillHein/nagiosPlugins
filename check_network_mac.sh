#!/usr/bin/env bash

#Set script name
SCRIPT=`basename ${BASH_SOURCE[0]}`

#Set default values
optMW=95
optMC=98
netwSpeed=1000
adapter=en0
# help function
function printHelp {
  echo -e \\n"Help for $SCRIPT"\\n
  echo -e "Basic usage: $SCRIPT -w {warning} -c {critical} -n {speed} -a {adapter}"\\n
  echo "Command switches are optional, default values for warning is 95% and critical is 98%"
  echo "-w - Sets warning value for Memory Usage. Default is 95%"
  echo "-c - Sets critical value for Memory Usage. Default is 98%"
  echo "-n - Sets the default network connection speed in b/s if adapter shows autoselect. Default is 1000"
  echo "-a - Sets network adapter Name. Default is en0"
  echo -e "-h  - Displays this help message"\\n
  echo -e "Example: $SCRIPT -w 80 -c 90 -n 100 -a en1"\\n
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
    n)
      if ! [[ $OPTARG =~ $re ]] ; then
        echo "error: Not a number" >&2; exit 1
      else
        netwSpeed=$OPTARG
      fi
      ;;
    a)
        adapter=$OPTARG
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

array1=($(netstat -i -I en1 -b | awk '{print $7, $10}'| tail -n 1 | awk '{printf("%i %i", $1, $2)}'))
array2=($(netstat -i -I en1 -b | awk '{print $7, $10}'| tail -n 1 | awk '{printf("%i %i", $1, $2)}'))
sleep 1

ibytesdelta=$((${array2[0]}-${array1[0]}))
obytesdelta=$((${array2[1]}-${array1[1]}))
intotal=${array1[0]}
outtotal=${array1[1]}
media=$(ifconfig "$adapter" | grep media)
if [[ $string == *"10BaseT"* ]]; then
 netwSpeed=10
elif [[ $media == *"100BaseT"* ]]; then
 netwSpeed=100
elif [[ $media == *"1000BaseT"* ]]; then
 netwSpeed=1000
fi
netwUsedPrc=$((100/$netwSpeed*($ibytesdelta*8+$obytesdelta*8)))

message="[NETWORK] Media: $media - In_Total: $intotal B - Out_Total: $outtotal B - $netwUsedPrc% | InBytesPerSec=$ibytesdelta;;;; OutBytesPerSec=$obytesdelta;;;; "

if [ $netwUsedPrc -ge $optMC ]; then
  echo -e $message
  $(exit 2)
elif [ $netwUsedPrc -ge $optMW ]; then
  echo -e $message
  $(exit 1)
else
  echo -e $message
  $(exit 0)
fi
