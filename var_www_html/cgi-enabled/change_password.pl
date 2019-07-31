#!/usr/bin/perl
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use CGI::Session;
use Mail::Sender;
use MIME::Base64 ();
use Linux::usermod;
use Email::Send::SMTP::Gmail;
my $cgi = new CGI;

#Creamos un objeto session
my $session = new CGI::Session;

#Cargamos los datos de la sesion
$session -> load();
my $usuario=$session->param("username");
#Recogemos los datos del formulario
my $old_password = $cgi->param('old_password', $cgi->param('old_password'));
my $new_password= $cgi->param('new_password', $cgi->param('new_password'));

my $root = "admin";
my $pass = "admin1234";
my $host = "localhost";
my $db = "users";

my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});

my $sth = $dbh->prepare("SELECT password FROM final_users WHERE username='$usuario'");
$sth->execute();

my $hash=$sth->fetchrow_array;
my $pass_from_server = MIME::Base64::decode($hash);
if ($old_password eq $pass_from_server) { #Si la contraseña es correcta

  #Obtenemos al $usuario
  $sth=$dbh->prepare("SELECT * FROM final_users WHERE username='$usuario'");
  $sth->execute();
  my @user=$sth->fetchrow_array;
  #Borramos ese usuario...
  my $consult2 = $dbh->prepare("DELETE FROM final_users WHERE username='$usuario'");
  $consult2->execute();
  my $consult3 = $dbh->prepare("INSERT INTO users_to_change(username) VALUES (\'$usuario\')");  
  $consult3->execute();
#Insertamos el usuario con la nueva contraseña
    #Creamos el hash de la nueva constraseña
    my $new_hash= MIME::Base64::encode($new_password);

  $sth = $dbh->prepare("INSERT INTO final_users(id,username,name,last_name,password,email)
                          VALUES (NULL, \'$user[1]\', \'$user[2]\',\'$user[3]\',\'$new_hash\',\'$user[5]\')");
  $sth->execute();
	
  #Modificamos el fichero shadow...
  #$sth =  $dbh->prepare("INSERT INTO users_to_change_password (username, password) VALUES (\'$user[1]\',)");
  #$sth->execute();
  #my $userToModify = Linux::usermod->new($user[1]);
  #$userToModify->set(password=>$new_password);

  print $session->header(-location => "private.pl");
  $dbh -> disconnect();
}else{
  print $cgi->header("text/html");
  print "<meta http-equiv ='refresh' content='3; ../index.html'>";
  print "<h3 style= 'color: red;'>La contraseña introducida no es la del usuario $usuario </h3>";
  $dbh -> disconnect();
}
