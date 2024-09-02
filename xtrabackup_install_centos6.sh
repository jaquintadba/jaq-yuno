#!/bin/bash
# Title: Percona xtrabackup install centos6  - Automatic Percona xtraBackup setup on CentOs 6.X
# Version 1.0 - Dec 20th, 2021
# Created by: Julio Alvarez
# Execution: /opt/xtrabackup_install_centos6.sh

# Dependencies: CentOS 6.X, xtrabackup version 2.4.24 based on MySQL server 5.7.35 Linux (x86_64) (revision id: b4ee263)
# Requirements: sudo access
# Run as user: root

ver="1.0"
SUFFIX=`date +%Y%m%d-%H%M`

# Log
log="/tmp/xtrabackup_install_centos6_${SUFFIX}.log"

#get hostname 
echo "hostname = '$HOSTNAME'"

#define log and backup location directories
log_location=/var/db_backups/$hostname/xtrabackup/log
backup_location=/var/db_backups/$hostname/xtrabackup 

#create directories
mkdir log_location
mkdir backup_location

#cd $backup_location
#folder=$(ls -td -- */ | head -n 1 | tr -d “/“)

#Download xtrabackup
wget https://downloads.percona.com/downloads/Percona-XtraBackup-2.4/Percona-XtraBackup-2.4.21/binary/tarball/percona-xtrabackup-2.4.21-Linux-x86_64.glibc2.12.tar.gz

#uncompress downloaded packaged
tar xvf percona-xtrabackup-2.4.21-Linux-x86_64.glibc2.12.tar.gz

#Install percona xtrabackup
yum install percona-xtrabackup-24
sleep 10
echo "yes"

#check the xtrabackup version installed
xtrabackup --version

exit