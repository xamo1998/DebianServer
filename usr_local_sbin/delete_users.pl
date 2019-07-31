#!/usr/bin/perl
use strict;
use warnings;
use Linux::usermod;
use File::Path qw(make_path remove_tree);
use DBI;
my $root = "admin";
my $pass = "admin1234";
my $host = "localhost";
my $db = "users";

my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});
my $sth =  $dbh->prepare("SELECT * FROM users_to_delete");
$sth->execute();

while(my($username)=$sth->fetchrow_array()){
  my $folder='/mnt/home/'.$username.'/';
  my $mail_folder='/var/mail/'.$username.'/';  
  remove_tree($folder);
  remove_tree($mail_folder);
  Linux::usermod->del($username);
  my $consult2 = $dbh->prepare("DELETE FROM users_to_delete WHERE username='$username'");
  $consult2->execute();
}
$dbh -> disconnect();

