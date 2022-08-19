jstatutil=/usr/bin/jstat  # установить на сервер jstat и указать до него путь

#добавить в список маски процессов у которых определять хип
servers=( instance.id=SASServer1_1 instance.id=SASServer2_1 instance.id=SASServer6_1 instance.id=SASServer11_1 instance.id=SASServer12_1  )

 

for servername in "${servers[@]}";

do

                if [ $(ps -eo pid,command |grep -i "$servername" |grep -v 'grep\|heap_mon' |wc -l) -ne 1 ]; then

                continue

                fi

 

                PID=$(ps -eo pid,command |grep -i "$servername" |grep -v 'grep\|heap_mon' |awk '{print $1}')

                currentheap=$($jstatutil -gc $PID |awk '{printf "%d\n",($3+$4+$6+$8)*1000}' |tail -n1)

                currentheap_mb=$(($currentheap/1024/1024))

                maxheap=$(ps -eo pid,command |grep -i "$servername" | grep -o 'Xmx[0-9]*' | grep -o '[0-9]*')

 
		#убираем лишнее из маски, чтобы получить название
                echo ${servername/instance.id\=/} $currentheap_mb $maxheap

done
