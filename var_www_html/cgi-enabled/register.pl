#!/usr/bin/perl

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Mail::Sender;
use MIME::Base64 ();
use Email::Send::SMTP::Gmail;
use Net::Address::IP::Local;
my $cgi = new CGI;


#Recogemos los datos del formulario
my $usuario = $cgi->param('username', $cgi->param('username'));
my $email= $cgi->param('email', $cgi->param('email'));
my $name= $cgi->param('name', $cgi->param('name'));
my $last_name= $cgi->param('last_name', $cgi->param('last_name'));

#TODO Vemos si el email o el nombre de usuario estan cogidos..

#Genereamos el codigo de verificación
my $ver_code = int(rand(80000)+20000);
#Generamos una constraseña aleatoria
my @chars = ("a".."z", 1 .. 9);
my $password;
$password.=$chars[rand @chars] for 1..10;
#Encriptamos la contraseña con SHA-512
my $hash = MIME::Base64::encode($password);





	my $root = "admin";
	my $pass = "admin1234";
	my $host = "localhost";
	my $db = "users";

	my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});

	#Primero vemos si hay algun usuario con ese nombre...
	my $consulta1 = $dbh->prepare("SELECT * FROM unverified_users WHERE username='$usuario'");
	my $consulta2 = $dbh->prepare("SELECT * FROM verified_users WHERE username='$usuario'");
	my $consulta3 = $dbh->prepare("SELECT * FROM final_users WHERE username='$usuario'");

	$consulta1->execute();
	$consulta2->execute();
	$consulta3->execute();



	my @user1=$consulta1->fetchrow_array;
	my @user2=$consulta2->fetchrow_array;
	my @user3=$consulta3->fetchrow_array;
	if(scalar @user1 ne 0 || scalar @user2 ne 0 || scalar @user3 ne 0){ #Si existe alguno de los tres...
		print $cgi->header("text/html");
		print "Ya hay un usuario con el nombre de usuario: $usuario";
		print "<meta http-equiv ='refresh' content='3; /../register_and_login.html'>";
		$dbh->disconnect();
	}else{
		#Miramos si hay algun email...
		$consulta1 = $dbh->prepare("SELECT * FROM unverified_users WHERE email='$email'");
		$consulta2 = $dbh->prepare("SELECT * FROM verified_users WHERE email='$email'");
		$consulta3 = $dbh->prepare("SELECT * FROM final_users WHERE email='$email'");

		$consulta1->execute();
		$consulta2->execute();
		$consulta3->execute();



		my @user1=$consulta1->fetchrow_array;
		my @user2=$consulta2->fetchrow_array;
		my @user3=$consulta3->fetchrow_array;
		if(scalar @user1 ne 0 || scalar @user2 ne 0 || scalar @user3 ne 0){ #Si existe alguno de los tres...
			print $cgi->header("text/html");
			print "Ya hay un usuario con el siguiente email: $email";
			print "<meta http-equiv ='refresh' content='3; /../register_and_login.html'>";
			$dbh->disconnect();
		}else{ #Insertamos el usuario...
			my $sth = $dbh->prepare("INSERT INTO unverified_users(id,username,name,last_name,password,email,ver_code)
															VALUES (NULL, \'$usuario\', \'$name\',\'$last_name\',\'$hash\',\'$email\',$ver_code)");
			$sth->execute();

			my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
																											 -login=>'xamo1998@gmail.com',
																											 -pass=>'XXXXXXXXXXXXXXXXXXXX',
																											 -layer=>'ssl');

			print "session error: $error" unless ($email!=-1);

			my $ip_addr=Net::Address::IP::Local->public_ipv4;;
			my $body="Pulsa en el siguiente enlace para confirmar el registro: http://$ip_addr/cgi-enabled/confirm.pl/?CODE=$ver_code&USR=$usuario \n\n Su contraseña es la siguiente: $password";

			$mail->send(-to=>$email, -subject=>'Confirmación registro', -body=>$body,
									-attachments=>'full_path_to_file');

			$mail->bye;

			print $cgi->header("text/html");
			print "<meta http-equiv ='refresh' content='3; ../succes_register.html'>";
			$dbh->disconnect();
		}
	}

