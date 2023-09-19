#!/bin/false
#
# Meant to be included in the source script, e.g.:
#  . ./scripts/progress-bar.sh
#

# Disabled for now since lockfile is included from scripts that are not compliant
#set -o errexit
#set -o pipefail     # WARNING: finish "|head" and "|tail" with ";true" to ignore SIGPIPE exits
#set -o nounset
## set -o xtrace     # script debugging

[[ -z "${BASH_SOURCE-}" ]] && echo "ERROR (lockfile.sh): Caller (${0}?) is not using bash shell! lockfile.sh depends on bash shell for correct operation!" >&2 && exit 1

BAR="="
SPNR='/-\|'
SPNR_POS=0
PROGRESS_BAR_STATE=

reset_progress_bar_state() {
    PROGRESS_BAR_STATE=($1 $(date +%s) $2)
}

draw_progress_bar() {
    COUNT="$1"
    MAX="$2"        # e.g. "100" or "12345+++". Can have nay number of +s as suffix -- means that COUNT could get larger than MAX by this many orders of magnitude
    FORMAT="$3"     # Format string. Known patterns will be replaced; everything else left alone. Known patterns are:
                    #   COUNT:   COUNT
                    #   MAX:     MAX
                    #   BAR:     progress bar. Can have any number of -s _s or letters between A and R to denote how large the bar should be
                    #   BYTES:   convert COUNT from bytes to KB/MB/GB as necessary
                    #   MBS:     convert MAX from bytes to KB/MB/GB as necessary
                    #   PERCENT: COUNT as percentage of MAX
                    #   SPINNER: dumb spinner (updated on each call to progress_bar)
                    #   SEC:     seconds since this progress bar started tracking (resets each time MAX changes)
                    #   SECFB:   **TODO** seconds since first byte
                    #   XFER1:   transfer rate over last few seconds (assumes that count is bytes)
                    #   XFER2:   transfer rate since this progress bar started (assumes that count is bytes)
                    # some examples:
                    #   "COUNT / MAX BAAAAAAAAAAAAAAAAAAAAAR [BYTES / MBS] (PERCENT%) SPINNER"
                    #   "COUNT of MAX BA__________R [BYTES / MBS] (PERCENT...%) SPINNER"
                    #   "COUNT+++ / MAX (PERCENT..%) SPINNER"
    
    # Extract "+++" from MAX to reserve extra whitespaces for the count -- and clean up MAX to an int
    max_spc=$(echo $MAX | grep -oE '\+*?$')   # check for extra spaces
    [[ ! -z "$max_spc" ]] && MAX=$(echo $MAX | grep -oE '^[0-9]+')

    # Process "MAX" and "COUNT"
    FORMAT=${FORMAT//MAX/$MAX}
    [[ "$FORMAT" =~ "COUNT" ]] && n=$(( ${#MAX}+${#max_spc} )) && repl=$(printf "%${n}d" $COUNT) && FORMAT=${FORMAT//COUNT/$repl}
    
    # Process "BYTES" and "MBS"
    if [[ "$FORMAT" =~ "MBS" ]] || [[ "$FORMAT" =~ "BYTES" ]]; then
        repl=$(pb_byte ${MAX})
        FORMAT=${FORMAT//MBS/$repl}
        mbs_len=${#repl}
        [[ $mbs_len -lt 8 ]] && mbs_len=8   
        [[ "$FORMAT" =~ "BYTES" ]] && repl=$( pb_byte ${COUNT} | awk "{printf \"%${mbs_len}s\", \$1}" )     && FORMAT=${FORMAT//BYTES/$repl}
    fi
    
    # Process time
    if [[ "$FORMAT" =~ "SEC" ]]; then
        if [[ "$MAX" != "${PROGRESS_BAR_STATE[0]}" ]]; then
            reset_progress_bar_state $MAX $COUNT
        fi
        repl=$(( $(date +%s) - ${PROGRESS_BAR_STATE[1]} ))
        repl=$(echo $repl | awk '{printf "%4s", $1}')
        FORMAT=${FORMAT//SEC/$repl}
    fi
    
    # Process spinner
    [[ "$FORMAT" =~ "SPINNER" ]] && repl=${SPNR:$SPNR_POS:1} && SPNR_POS=$(( ($SPNR_POS+1)%4 ))  && FORMAT=${FORMAT//SPINNER/$repl}
    
    # Process "PERCENT"
    while [[ "$FORMAT" =~ "PERCENT" ]]; do
        pct_fmt=$(echo "$FORMAT" | grep -oE '\<PERCENT\>\.*')
        nnn=$(echo "$pct_fmt" | head -n1) && pct_fmt=$nnn       # Note: this is not a noop! head -n1 fails when there's just one entry, so no reassignment happens
        nnn=$(echo "$pct_fmt" | grep -oE '\.*$'); dcm=${#nnn}
        repl=$(echo "scale=${dcm}; 100 * $COUNT / $MAX" | bc)
        maxlen=$(( $dcm + 4 ))
        repl=$(echo $repl | awk "{printf \"%${maxlen}s\", \$1}")
        FORMAT=${FORMAT//$pct_fmt/$repl}
    done
    
    # Process progress bar
    bar_fmt=$(echo "$FORMAT" | grep -oE '\<BA[-_A-Z]*RS?\>')
    if [[ ! -z "$bar_fmt" ]]; then
        bar_len=$(( ${#bar_fmt} - 2 ))
        progress_cnt=$(( $bar_len * $COUNT / $MAX ))
        bar_str=$(for _i in $(seq 1 ${progress_cnt}); do echo -n '='; done)
        [[ $COUNT -gt 0 ]] && [[ $COUNT -lt $MAX ]] && bar_str="${bar_str}-"
        repl=$(echo $bar_str | awk "{printf \"[%-${bar_len}s]\", \$1}")
        FORMAT=${FORMAT//$bar_fmt/$repl}
    fi
    
    # Process transfer rate
    if [[ "$FORMAT" =~ "XFER1" ]]; then
        if [[ "$MAX" != "${PROGRESS_BAR_STATE[0]}" ]]; then
            reset_progress_bar_state $MAX $COUNT
            repl="N/A"
        else
            dt=
            dc=
            for i in {21..5..2}; do
                PROGRESS_BAR_STATE[ $(($i+1)) ]=${PROGRESS_BAR_STATE[ $(($i-1)) ]-}
                PROGRESS_BAR_STATE[    $i     ]=${PROGRESS_BAR_STATE[ $(($i-2)) ]-}
                [[ -z $dt ]] && [[ ! -z ${PROGRESS_BAR_STATE[$i]} ]] && dt=$(( $(date +%s) - ${PROGRESS_BAR_STATE[$i]} )) && dc=$(( $COUNT - ${PROGRESS_BAR_STATE[$i+1]} ))
            done
            PROGRESS_BAR_STATE[3]=$(date +%s)
            PROGRESS_BAR_STATE[4]=$COUNT
            if [[ ! -z $dt ]] && [[ $dt -gt 0 ]]; then
                res=$(( $dc / $dt ))
                repl="$(pb_byte $res)/sec"
            else
                repl="N/A"
            fi
        fi
        repl=$(echo $repl | awk '{printf "%13s", $1}')
        FORMAT=${FORMAT//XFER1/$repl}
    fi
    if [[ "$FORMAT" =~ "XFER2" ]]; then
        if [[ "$MAX" != "${PROGRESS_BAR_STATE[0]}" ]]; then
            reset_progress_bar_state $MAX $COUNT
            repl="N/A"
        else
            dt=$(( $(date +%s) - ${PROGRESS_BAR_STATE[1]} ))
            dc=$(( $COUNT      - ${PROGRESS_BAR_STATE[2]} ))
            if [[ ! -z $dt ]] && [[ $dt -gt 0 ]]; then
                res=$(( $dc / $dt ))
                repl="$(pb_byte $res)/sec"
            else
                repl="N/A"
            fi
        fi
        repl=$(echo $repl | awk '{printf "%13s", $1}')
        FORMAT=${FORMAT//XFER2/$repl}
    fi
    
    echo -ne "\r${FORMAT}"
    
}
## Note: print an extra space for the spinner, otherwise it will appear in the rightmost column
##  e.g. echo -n "Waiting:  "; while $waiting; do draw_spinner; done
draw_spinner() {
    echo -ne "\b${SPNR:$SPNR_POS:1}"
    SPNR_POS=$(( ($SPNR_POS+1)%4 ))
}

pb_byte() {
    echo $1 | awk '{
        if ($1 < 1000) { printf("%dB", $1); }
        else if ($1 < 1024000) { printf("%.2fKB", $1 / 1024); }
        else if ($1 < 1048576000) { printf("%.2fMB", $1 / 1024 / 1024); }
        else { printf("%.2fGB", $1 / 1024 / 1024 / 1024); }
    }'
}

