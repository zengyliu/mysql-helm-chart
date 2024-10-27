#!/bin/bash
set -ex
cd /var/lib/mysql
echo "1"
if [[ -f xtrabackup_slave_info ]]; then
  mv xtraback_slave_info change_master_to.sql.in
  rm -f xtrabackup_binlog_info
elif [[ -f xtrabackup_binlog_info ]]; then
    echo "2"
    [[ `cat xtrabackup_binlog_info` =~ ^(.*?)[[:space:]]+(.*?)$ ]] || exit 1
    rm xtrabackup_binlog_info
    echo "CHANGE MASTER TO MASTER_LOG_FILE='${BASH_REMATCH[1]}',\
          MASTER_LOG_POS=${BASH_REMATCH[2]}" > change_master_to.sql.in
 fi
 echo "3"
 if [[ -f change_master_to.sql.in ]]; then
    echo "Waiting for mysqld to be ready (accepting connections)"
    until mysql -h 127.0.0.1 -e "SELECT 1"; do sleep 1; done
    echo "Initializing replication from clone position"
    mv change_master_to.sql.in change_master_to.sql.orig

    mysql -h 127.0.0.1 <<EOF
 $(<change_master_to.sql.orig)
    MASTER_HOST='mysql-0.mysql',
    MASTER_USER='root',
    MASTER_PASSWORD='',
    MASTER_CONNECT_RETRY=10;
    START SLAVE;
EOF
  fi
  exec ncat --listen --keep-open --send-only --max-conns=1 3307 -c \
       "xtrabackup --backup --slave-info --stream=xbstream --host=127.0.0.1 --user=root"
