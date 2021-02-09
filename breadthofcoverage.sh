#!/bin/sh

help() {
	echo "Description: Calculate breadth of coverage"
	echo
	echo "Syntax: scriptTemplate [-b|c|g|h|v|V]"
	echo "options:"
	echo "b     Bed file."
	echo "c     Samtools depth output file."
	echo "h     Print this Help."
	echo "v     Verbose mode."
	echo "V     Print software version and exit."
	echo
	exit;
}

while getopts ":b:c:h:g:v:V" option; do
	case $option in
		b) # display Help
			BED="$OPTARG"
			;;
		c) # display Help
			COVERAGE="$OPTARG"
			;;
		h) # display Help
			help
			;;
		*)
			help
			;;
	esac
done


if [ $OPTIND = 1 ]
then
    echo "Error: No options specified"
    echo ""
    help
fi

if [ ! "$COVERAGE" ] || [ ! "$BED" ]
then
    echo "Error: Coverage file and bed file is required."
    echo ""
    help
fi

# if [ $# = 0 ]
# then
#     echo "No positional arguments specified"
# fi

BEDLENGTH=$(awk -F'\t' 'BEGIN{SUM=0}{ SUM+=$3-$2 }END{print SUM}' "$BED")
NF=$(awk "{ print NF }" "$COVERAGE" | sed 1q)

thresholds="1 10 20 50 100"
prefix="% of bases covered at"
postfix="✕"
header=$(echo "$thresholds" | sed "s/ /$postfix\t$prefix /g")
printf "sample\tmean coverage\t%s" "$prefix $header$postfix"

i=3
while [ $i -le "$NF" ]
do
        sample=$(sed 1q "$COVERAGE" | cut -f "$i")
        mean=$(awk -v i=$i '{ total += $i } END { print total/NR }' "$COVERAGE")
	line="$sample\t$mean"
        for threshold in $thresholds; do
                pass=$(awk -v i=$i -v threshold="$threshold" '$i>=threshold' "$COVERAGE" | wc -l | awk -v bl="$BEDLENGTH" '{print ($1/bl)*100}')
                line="$line\t$pass"
        done
        printf "%s" "$line"
        i=$(( i + 1 ))
done
