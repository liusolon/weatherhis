#!/bin/bash -e

if [ -z $1 ]
then
	echo "Usage: $0 city-name"
	exit 1
else
	city=$1
fi

wurl=http://www.tianqihoubao.com/lishi
http_code=$(curl -o /dev/null -s -w %{http_code} $wurl/$city.html)

if [ $http_code -ne 200 ]
then
	echo "City $city weather data dont exist."
	exit 1
fi 

echo -e "Weather data is dumping \c"

for i in $(seq 11 17)
do
	for j in $(seq -f %02g 1 12)
	do	
		date=20$i$j
		echo -e ".\c"	
		timeout 5s w3m -dump $wurl/$city/month/$date.html >> $city.tmp
		if [ $? -eq 124 ]
		then
			echo -e "$date\c"
			timeout 5s w3m -dump $wurl/$city/month/$date.html >> $city.tmp
		fi
	done
done

echo "Finished!"

echo -e "weather-date\t${city}-max\t${city}-min" > $city.dat
grep '....年..月..日' $city.tmp | awk '{print $1"\t"$4"\t"$6}' | sed 's/℃//g' | sed 's/年/\//g' | sed 's/月/\//g' | sed 's/日//g' > $city.dat
rm -f $city.tmp

gnuplot <<EOF
reset
set terminal png size 3000,1000 enhanced font "Helvetica,20"
set output '$city.png'
set grid
set title "$city tempertature"
set xdata time
set timefmt "%Y/%m/%d"
set format x "%Y/%m/%d"
plot '$city.dat' using 1:2 title 'max-temp' with lines, '$city.dat' using 1:3 title 'min-temp' with lines 
EOF

