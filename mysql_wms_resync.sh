##
## Check and fix the replication for WMS instance every 1min 
# */1 * * * * /home/jalvarezq/mysql_wms_resync.sh 2>&1
##

#!/bin/bash
# Author:    Julio Alvarez
# Title:     Automatic mysql resync for WMS
# Updates:   22/Mar/2023 Script creation
#  
# Execution: mysql_wms_resync.sh
#           
# Script version: 1.1

# Execution Date
SUFFIX=`date +%Y%m%d`
STARTED_AT=`date "+%F %T"`
# Log
TMPFILE="/tmp/mysql_wms_resync_${SUFFIX}.log"

function my_repl_error_info(){
    msg="$1"
    echo -e "${STARTED_AT} \e[32mINFO: \e[0m $msg" 
    echo -e "${STARTED_AT} \e[32mINFO: \e[0m $msg" >> ${TMPFILE}
}

my_repl_fix(){
    mysql -ujulio.alvarez -p"password" -e "STOP SLAVE 'WMS'; SET @@default_master_connection = 'WMS'; SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE 'WMS'; "  
    my_repl_error_info "\e[32m Last_SQL_Errno: ${REP_STATUS_SQL_Errno} \e[0m"
    my_repl_error_info "\e[32m Last_SQL_Errno: ${REP_STATUS_SQL_Err} \e[0m" 
}

my_repl_check(){
    REP_STATUS=`mysql -ujulio.alvarez -p"password" -e "SHOW SLAVE 'WMS' STATUS \G;" | grep -i Slave_SQL_Running: |awk '{print $2 }' `
    REP_STATUS_SQL_Errno=`mysql -ujulio.alvarez -p"password" -e "SHOW SLAVE 'WMS' STATUS \G;" | grep -i Last_SQL_Errno |awk '{print $2 }'`
    REP_STATUS_SQL_Err=`mysql -ujulio.alvarez -p"password" -e "SHOW SLAVE 'WMS' STATUS \G;" | grep -i Last_SQL_Error `  
}

##########################
########## MAIN ##########

my_repl_check

if [ "${REP_STATUS}" != 'Yes' ]; then
    my_repl_error_info "\e[32m Error detected in WMS replication! \e[0m"
    
    if [[ "${REP_STATUS_SQL_Errno}" = '1032' ]] || [[ "${REP_STATUS_SQL_Errno}" = '1452' ]]; then 
        my_repl_fix
    else
        my_repl_error_info "\e[32m WARNING: The error number detected in WMS is different to 1032 and 1452, please review it: \e[0m" 
        my_repl_error_info "\e[32m Last_SQL_Errno: ${REP_STATUS_SQL_Errno} \e[0m"
        my_repl_error_info "\e[32m Last_SQL_Errno: ${REP_STATUS_SQL_Err} \e[0m"  
    fi
fi

echo -e "
$0
\e[32mINFO:\e[0m     
\e[32mINFO:\e[0m --------------------------------------------
\e[33mImportant\e[0m: Check the log file:
\e[1m ${TMPFILE}
\e[0m
"
exit