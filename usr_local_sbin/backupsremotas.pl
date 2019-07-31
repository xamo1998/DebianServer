#!/usr/bin/perl

use warnings;
use strict;

system('rsync -av /mnt/home backup_mnt.rysnc');
system('rsync -av /etc backup_etc.rysnc');
system('rsync -av /var backup_var.rysnc');
system('rsync -av /usr/local/sbin backup_usr.rysnc');

system('rsync -avz -P -e ssh /mnt/home/backup_mnt.rysnc root@172.20.1.58:/home/backups');
system('rsync -avz -P -e ssh /etc/backup_etc.rysnc root@172.20.1.58:/home/backups');
system('rsync -avz -P -e ssh /var/backup_var.rysnc root@172.20.1.58:/home/backups');
system('rsync -avz -P -e ssh /usr/local/sbin/backup_usr.rysnc root@172.20.1.58:/home/backups');
