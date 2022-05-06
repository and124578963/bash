jstatutil=/usr/bin/jstat

server=$(hostname -f)

adapters=( nbo.xml nbo-log.xml nbo-http.xml nbo-esp-flat-response.xml nbo-async-sql.xml nbo-telecard-history.xml )

 

for adapter in "${adapters[@]}";

do

                if [ $(ps -eo pid,command | grep adapter | grep -i "$adapter" | grep -v 'grep\|heap_mon' | wc -l) -ne 1 ]; then

                exit 1

                fi

 

                PID=$(ps -eo pid,command | grep adapter | grep -i "$adapter" | grep -v 'grep\|heap_mon' | awk '{print $1}')

                currentheap=$($jstatutil -gc $PID | awk '{printf "%d\n",($3+$4+$6+$8)*1000}' | tail -n1)

                currentheap_mb=$(($currentheap/1024/1024))

                maxheap=$(ps -eo pid,command | grep adapter | grep -i "$adapter" | grep -o 'Xmx[0-9]*' | grep -o '[0-9]*')

 

                echo exporter.sas.javaheap.$server.${adapter/.xml/}.currentheap_mb $currentheap_mb

                echo exporter.sas.javaheap.$server.${adapter/.xml/}.maxheap $maxheap

done

 