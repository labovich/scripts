#!/bin/bash

BACKUP_FOLDER='/mnt/yandex/backup_mysql'
DT=$(date +%Y-%m-%d)
LIST_DB=$(mysql --defaults-file=/root/mysql_pass -e "show databases\g" | awk '{print $1}' | tail -n +2)

cd $BACKUP_FOLDER

for I in daily weekly monthly; do
    if test -d $I; then
        echo "Folder $I exist"
    else
        mkdir $I
    fi
done

BFD=$BACKUP_FOLDER"/daily"
BFW=$BACKUP_FOLDER"/weekly"
BFM=$BACKUP_FOLDER"/monthly"

if [ -e "$BFD/$DT" ]; then
    rm -Rf $BFD/$DT
fi

mkdir $BFD/$DT
cd $BFD/$DT

for DATABASE in $LIST_DB; do
    if [ "$DATABASE" = 'information_schema' ] || [ "$DATABASE" = 'mysql' ] || [ "$DATABASE" = 'performance_schema' ] || [ "$DATABASE" = 'phpmyadmin' ]; then
        echo 'Skip database ' $DATABASE
    else
        echo 'Backup database ' $DATABASE
        FILE_NAME=$DATABASE"_$(date +'%F').sql.gz"
        mysqldump --defaults-file=/root/mysql_pass --routines --databases $DATABASE | gzip -c9 >$FILE_NAME
    fi
done

if [ $(date +%u) = "1" ]; then
    cp -Rfp $BFD/$DT $BFW
fi
if [ $(date +%d) = "01" ]; then
    cp -Rfp $BFD/$DT $BFM
fi

find $BFD -ctime +7 -exec rm -rf {} \; >/dev/null 2>&1
find $BFW -ctime +35 -exec rm -rf {} \; >/dev/null 2>&1
find $BFM -ctime +365 -exec rm -rf {} \; >/dev/null 2>&1
