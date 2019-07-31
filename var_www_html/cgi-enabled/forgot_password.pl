#!/usr/bin/perl

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Mail::Sender;
use Email::Send::SMTP::Gmail;
use MIME::Base64 ();
my $cgi = new CGI;


#Recogemos los datos del formulario
my $email= $cgi->param('email', $cgi->param('email'));

#Le enviamos una nueva contraseña a su email...
my @chars = ("a".."z", 1 .. 9);
my $password;
$password.=$chars[rand @chars] for 1..10;

my $hash = MIME::Base64::encode($password);


my $root = "admin";
my $pass = "admin1234";
my $host = "localhost";
my $db = "users";

my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});
my $sth=$dbh->prepare("SELECT * FROM final_users WHERE email='$email'");
$sth->execute();
my @user=$sth->fetchrow_array;

#Obtenemos al $usuario
  $sth=$dbh->prepare("SELECT * FROM final_users WHERE email='$email'");
  $sth->execute();
  my @user=$sth->fetchrow_array;
  #Borramos ese usuario...
  my $consult2 = $dbh->prepare("DELETE FROM final_users WHERE email='$email'");
  $consult2->execute();
  $consult2 = $dbh->prepare("INSERT INTO final_users(id,username,name,last_name,password,email)
                        VALUES (NULL, \'$user[1]\', \'$user[2]\',\'$user[3]\',\'$hash\',\'$user[5]\')");
  $consult2->execute();
  my $consult3 = $dbh->prepare("INSERT INTO users_to_change(username) VALUES (\'$user[1]\')");
  $consult3->execute();






#modificamos el usuario de Linux
#my $userToModify = Linux::usermod->new($user[1]);
#$userToModify->set(password=>$password);

my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                                 -login=>'xamo1998@gmail.com',
                                                 -pass=>'XXXXXXXXXXXXXXXXXXXXX',
                                                 -layer=>'ssl');

print "session error: $error" unless ($email!=-1);


my $body="La nueva contraseña es la siguiente: $password";

$mail->send(-to=>$email, -subject=>'Olvido de contraseña', -body=>$body,
            -attachments=>'full_path_to_file');

$mail->bye;



print $cgi->header("text/html");
print "<meta http-equiv ='refresh' content='3; ../index.html'>";
print "<h3 style= 'color: red;'>La nueva contraseña se le ha enviado</h3>";

$dbh->disconnect();
