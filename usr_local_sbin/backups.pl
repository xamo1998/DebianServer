#!/usr/bin/perl
use warnings;
use strict;

system('rsync -av /mnt /var/backups/backup_mnt.rsync');
system('rsync -av /etc /var/backups/backup_etc.rsync');
system('rsync -av /home /var/backups/backup_home.rsync');
system('rsync -av /usr/local/sbin /var/backups/backup_usr.rsync');
my $perm=0644;
chmod($perm, "/var/backups/backup_mnt.rsync");
chmod($perm, "/var/backups/backup_etc.rsync");
chmod($perm, "/var/backups/backup_home.rsync");
chmod($perm, "/var/backups/backup_usr.rsync");

