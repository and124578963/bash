#!/bin/bash
#FrozenRequestsFromSTP.sh
#Скрипт определяет зависшие запросы с stp server в течение дня
#Перед использованием необходимо указать путь PATH_TO_LOGS к папке с логами stp server'a 
#
#Порядок использования:
#FrozenRequestsFromSTP.sh <маска файлов/дата в формате 2022-06-30>
#

PATH_TO_LOGS="/log/stpserver_logs/"

AMOUNT_STRING_BEFORE=15

cd $PATH_TO_LOGS
for file in * ; do

    if [[ $file == *"${1}"* ]]; then
        count=`grep -l "Session Purge for .* blocked by running" ./$file`
        check=$?

        if [ ${check} -eq 0 ]; then
            
            declare -a listRows
            grep -n "Session Purge for .* blocked by running" ./$file | cut -d : -f 1 >/tmp/temp_qwe
            while read -r row; do
               listRows+=( "$row" )
            done < /tmp/temp_qwe
            
            for row in "${listRows[@]}"; do
               
               let first=(${row} - 5)
               let last=(${row} + 5)
               
               begin=`sed -n "${first}{p;q}" ./$file | grep -o T..:..:.. | grep -o ..:..:..`
               end=`sed -n "${last}{p;q}" ./$file | grep -o T..:..:.. | grep -o ..:..:..`
                
               if [ ${#end} -eq 0 ]; then
                 let last=(${row} + 1)
                 end=`sed -n "${last}{p;q}" ./$file | grep -o T..:..:.. | grep -o ..:..:..`
               fi

               if [ ${#end} -eq 0 ]; then
                  end=`sed -n "${row}{p;q}" ./$file | grep -o T..:..:.. | grep -o ..:..:..`
               fi
              
               beginTime=`date -d"$begin" +%s`
               endTime=`date -d"$end" +%s`
               let duration=(${endTime} - ${beginTime})
               if (( $duration > 600 )); then
                   let firstString=(${row} - $AMOUNT_STRING_BEFORE) 
                   sed -n "{${firstString},${row}p;${row}q}" ./$file

            
                   #grep -B 10 "Session Purge for .* blocked by running" ./$file | grep -v "Session Purge for .* blocked by running"
                   let minute=(${duration} / 60)
                   echo "Duration: $minute min    Filename: $file" 
                   echo "----------------------------------------------------------------"
               fi
            done
          unset listRows 
        fi
        
    fi
done
