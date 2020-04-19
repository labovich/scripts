#!/bin/bash

BACKUP_FOLDER='/mnt/yandex/backup_postgres'
TMP_FOLDER='/tmp'
DT=$(date +%Y-%m-%d)
LIST_DB=$(su -c "psql -c \"SELECT datname FROM pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1')\" -t" postgres)

cd $BACKUP_FOLDER

# Create subfolder
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

# Delete exist folder
if [ -e "$BFD/$DT" ]; then
    rm -Rf $BFD/$DT
fi

mkdir $BFD/$DT
cd $BFD/$DT

# Backups global data
GLOB_FILE_NAME="globals_$(date +'%F').sql.gz"
su -c "pg_dumpall -g | gzip -c9 > $TMP_FOLDER/$GLOB_FILE_NAME" postgres
mv $TMP_FOLDER/$GLOB_FILE_NAME .

# Backups database
for DATABASE in $LIST_DB; do
    echo 'Backup database ' $DATABASE
    FILE_NAME=$DATABASE"_$(date +'%F').sql.gz"
    su -c "pg_dump $DATABASE | gzip -c9 > $TMP_FOLDER/$FILE_NAME" postgres
    mv $TMP_FOLDER/$FILE_NAME .
done

# Rotate backups
if [ $(date +%u) = "1" ]; then
    cp -Rfp $BFD/$DT $BFW
fi
if [ $(date +%d) = "01" ]; then
    cp -Rfp $BFD/$DT $BFM
fi

# Delete old backups
find $BFD -ctime +7 -exec rm -rf {} \; >/dev/null 2>&1
find $BFW -ctime +35 -exec rm -rf {} \; >/dev/null 2>&1
find $BFM -ctime +365 -exec rm -rf {} \; >/dev/null 2>&1
