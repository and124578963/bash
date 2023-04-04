#!/bin/bash
#ParserLongDataStepInMACore.sh
#Скрипт выводит длительные процедуры за указанный промежуток времени
#Перед использованием необходимо указать путь PATH_TO_LOGS к файлу лога MACore 
#и количество отоброжаемых строк AMOUNT_ROWS_BEFORE перед real time, обычно 20-30
#если запрос большой, необходимо больше строк
#
#Порядок использования:
#ParserLongDataStepInMACore.sh <день месяца> <время начала ЧЧ:MM> <время конца ЧЧ:MM> <минимальная продолжительность процесса в мин.>
#Пример:
#ParserLongDataStepInMACore.sh 25 10:15 12:30 5
#
#Выгрузит из текущего лога длинные дата степы за 25 число с 10:15 до 12:30, которые длительнее 5 минут
#
#Примечание: минут указывать 1-60, запросы больше часа отображаются всегда 

PATH_TO_LOG="/log/SASServer6_1/SASCustIntelCore6.6.log"

AMOUNT_ROWS_BEFORE=25

#######################################################

TEMP_PATH="/tmp/maCoreParse"

day=${1}

beginHour=${2:0:2}
beginMinutes=${2:3:2}

endHour=${3:0:2}
endMinutes=${3:3:2}

minMinutes=${4}

touch $TEMP_PATH


#awk скрипт выгружает строки за указанное время из MACore лога, может подойти для других логов,
#где время указывается также 
exp1='BEGIN {chk=0} 
	{if(substr($2,0,2) >= bH && 
	  substr($2,0,2) >= 00 &&
	  substr($2,0,2) <= eH  &&
	  substr($2,0,2) <= 24  &&
	  substr($2,3,1) == ":" &&  
	  substr($2,6,1) == ":" &&
          substr($1,9,2) == D ){
		if ( substr($2,0,2) == bH ){if ( substr($2,4,2) >= bM &&
	  		     			substr($2,4,2) >= 00  &&
	  		     			substr($2,4,2) <= 60 ){chk=1}
						else {chk=0}}
		else if ( substr($2,0,2) == eH ){if (  substr($2,4,2) <= eM &&
                             			substr($2,4,2) >= 00  &&
                             			substr($2,4,2) <= 60 ){chk=1}
                        			else {chk=0}}


		else {chk=1}
	} else { if(substr($1,5,1) == "-" && substr($1,8,1) == "-" ){ chk=0}}}
	 {if(chk==1) print $0}' 
echo "Start getting slice of time"
awk -v bH="$beginHour" -v bM="$beginMinutes" -v eH="$endHour" -v eM="$endMinutes" -v D="$day" "$exp1"  $PATH_TO_LOG  > $TEMP_PATH



#функция печати результата
function printResult(){
    let firstRow=(${1} - $AMOUNT_ROWS_BEFORE)
    #печатает диапазон строк по их номеру	 	
    sed -n "{${firstRow},${1}p;${1}q}" $TEMP_PATH
    echo "----------------------------------------------------------------"
    echo ""
    echo ""	
}



declare -a listRows
#получаем номера строк, где есть время
grep -n "real time.*:" $TEMP_PATH | cut -d : -f 1 >/tmp/temp_number
grep "real time.*:" $TEMP_PATH >/tmp/temp_text

while read -r row; do
      listRows+=( "$row" )
done < /tmp/temp_number

echo "Start analyze slice of time"

indexRow=0
while read -r row; do
#обрабатываем строки
#for row in "${listRows[@]}"; do
	rowNumber=${listRows[$indexRow]}
	#echo $row
	textTime=`echo $row | awk '{print $3}'`
	tmp=`echo $textTime | grep -o '^.*:..:'`
	checkHour=$?
	#echo $textTime
#если есть часы, то точно печатаем, иначе проверям минимальную продолжительность 	
  if [ ${checkHour} -eq 0 ]; then
	printResult $rowNumber
	#echo 'hour true'
  else 
	minutes=`echo $textTime | grep -o ".*:"`
	#echo $minutes
	checkMin=`echo ${minutes/:/} | awk -v minM=$minMinutes '{if( $0 >= minM ){print 0} else {print 1}}'`
	if [ ${checkMin} -eq 0 ]; then
	    printResult $rowNumber
	    #echo 'minutes true'
	fi

  fi
let indexRow=(indexRow + 1)
done < /tmp/temp_text
