#!/usr/bin/perl

use strict;
use CGI;
use CGI::Session;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

#creamos un objeto CGI
my $cgi=new CGI;

#Creamos un objeto session
my $session = new CGI::Session;

#Cargamos los datos de la sesion
$session -> load();

#Creamos un array para guardar los datos de la sesion
my @storage= $session->param;

#Vemos si el usuario esta o no
if(@storage eq 0) #Si esta 0, no tendra permisos
{
	$session->delete();
	$session->flush();
	print $cgi->header("text/html");
	print "<meta http-equiv ='refresh' content='0; ../register_and_login.html'>"; #Puesto que el usuario no ha iniciado sesion
	
}
#Comprobamos que la sesion no haya expirado, puesto que si ha expirado vuelve a index.html
elsif($session -> is_expired)
{
	$session->delete();
	$session->flush();
	print $cgi->header("text/html");
	print "meta http-equiv ='refresh' content'=0; ../register_and_login.html'>"; #Puesto que el usuario no ha iniciado sesion
	
}
#El usuario tiene la sesion activa y los datos correctos, por lo tanto, puede permanecer en la pagina private o eso xd
else
{
	print $cgi->header("text/html");
	print "<meta http-equiv ='refresh' content='0; /../profile.html'>"; #Puesto que el usuario no ha iniciado sesion

}
