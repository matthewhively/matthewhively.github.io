#!/bin/bash

    # find-out-what-is-using-your-swap.sh
    # -- Get current swap usage for all running processes
    # --
    # -- rev.0.3, 2012-09-03, Jan Smid          - alignment and intendation, sorting
    # -- rev.0.2, 2012-08-09, Mikko Rantalainen - pipe the output to "sort -nk3" to get sorted output
    # -- rev.0.1, 2011-05-27, Erik Ljungstrom   - initial version


SCRIPT_NAME=`basename $0`;
SORT="kb";                 # {pid|kB|name} as first parameter, [default: kb]
[ "$1" != "" ] && { SORT="$1"; }

[ ! -x `which mktemp` ] && { echo "ERROR: mktemp is not available!"; exit; }
MKTEMP=`which mktemp`;
TMP=`${MKTEMP} -d`;
[ ! -d "${TMP}" ] && { echo "ERROR: unable to create temp dir!"; exit; }

>${TMP}/${SCRIPT_NAME}.pid;

OVERALL=0

. /opt/EntetelClient/PY/Relevad/scripts/progress-bar.sh

all_proc=$(find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+")
num_proc=$(echo $all_proc|wc -w)
cur_proc=0
for DIR in $(echo $all_proc);
do
    cur_proc=$(( $cur_proc+1 ))
    draw_progress_bar $cur_proc $num_proc "COUNT / MAX SPINNER"
    PID=$(basename $DIR)
    PROGNAME=$(ps -p $PID -o comm --no-headers)
    RUNNAME=$(ps -p $PID -o command --no-headers)

    SUM=$(grep Swap $DIR/smaps 2>/dev/null| awk '{sum+=$2} END {print sum}')

    if [[ $SUM -gt 0 ]]; then
        echo -e "${PID}\t${SUM}\t${PROGNAME}\t${RUNNAME}" >> ${TMP}/${SCRIPT_NAME}.pid
        let OVERALL=$OVERALL+$SUM
    fi
done

echo " ... scan completed"
echo "Overall swap used: ${OVERALL} kB";
echo "===========================================";
case "${SORT}" in
    name )
        echo -e "name                    kB    pid  full cmd";
        echo "===========================================";
        cat ${TMP}/${SCRIPT_NAME}.pid| awk -F'\t' '{printf "%-16s%10s%7s  %s\n", $3, $2, $1, $4}'|sort -r;
        ;;

    kb )
        echo -e "        kB    pid  name            full cmd";
        echo "===========================================";
        cat ${TMP}/${SCRIPT_NAME}.pid| awk -F'\t' '{printf "%10s%7s  %-16s%s\n", $2, $1, $3, $4}'|sort -rn;
        ;;

    pid | * )
        echo -e "    pid        kB  name            full cmd";
        echo "===========================================";
        cat ${TMP}/${SCRIPT_NAME}.pid| awk -F'\t' '{printf "%7s%10s  %-16s%s\n", $1, $2, $3, $4}'|sort -rn;
        ;;
esac
rm -fR "${TMP}/";

