#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use Linux::usermod;
use CGI::Session;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

#creamos un objeto CGI
my $cgi=new CGI;

#Creamos un objeto session
my $session = new CGI::Session;

#Cargamos los datos de la sesion
$session -> load();
my $usuario=$session->param("username");


my $root = "admin";
my $pass = "admin1234";
my $host = "localhost";
my $db = "users";

my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});

my $sth =  $dbh->prepare("INSERT INTO users_to_delete (username) VALUES (\'$usuario\')");
$sth->execute();
$sth = $dbh->prepare("DELETE FROM final_users WHERE username='$usuario'");
$sth->execute();
$session->delete();
$session->flush();
print $cgi->header("text/html");
print "meta http-equiv ='refresh' content'=3; ../index.html'>"; #Puesto que el usuario no ha iniciado sesion
print "<h3 style= 'color: red;'>Usuario eliminado con exito</h3>";
