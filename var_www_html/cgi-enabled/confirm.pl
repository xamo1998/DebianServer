#!/usr/bin/perl

use strict;
use warnings;
use CGI ':cgi'; # Only the CGI functions
use DBI;

my $code = param('CODE');
my $username = param('USR');
my $cgi = new CGI;

my $root = "admin";
my $pass = "admin1234";
my $host = "localhost";
my $db = "users";

my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});
my $sth = $dbh->prepare("SELECT * FROM unverified_users WHERE username='$username' AND ver_code='$code' ");
$sth->execute();
my $found = 0;

print $cgi->header("text/html");


my @user=$sth->fetchrow_array;
if(scalar @user ne 0){ # Si el usuario existe..
  #lo metemos en la otra DB
  my $consult1 = $dbh->prepare("INSERT INTO verified_users (id,username,name,last_name,password,email) SELECT id,username,name,last_name,password,email FROM unverified_users WHERE username='$username' AND ver_code='$code' ");
  $consult1->execute();
  my $consult2 = $dbh->prepare("DELETE FROM unverified_users WHERE username='$username' AND ver_code='$code' ");
  $consult2->execute();
  print "<meta http-equiv ='refresh' content='0; /../succes_register.html'>";

}else{
  print 'Incorrecto';

#  print $cgi->header("text/html");
#  print "<meta http-equiv ='refresh' content='3; ../index.html'>";
#  print "<h3 style= 'color: red;'>Los datos introducidos son incorrectos </h3>";
}
$dbh -> disconnect();
