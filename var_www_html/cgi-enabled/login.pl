#!/usr/bin/perl

use strict;
use CGI;
use CGI::Session;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use MIME::Base64 ();
use POSIX;
my $cgi = new CGI;
my $campo;
my $usuario = $cgi->param('username', $cgi->param('username'));
my $password= $cgi->param('password', $cgi->param('password'));


	my $root = "admin";
	my $pass = "admin1234";
	my $host = "localhost";
	my $db = "users";

	my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});
	my $sth = $dbh->prepare("SELECT password FROM final_users WHERE username='$usuario'");
	#my $sth = $dbh->prepare('SELECT * FROM login');
	#$sth->execute();
	$sth->execute();

	my $hash=$sth->fetchrow_array;

	if(length ($hash) != 0){ #En el caso de encontrar un hash asociado a ese usuario...
		my $pass_from_server = MIME::Base64::decode($hash);
			if ($pass_from_server eq $password) { #Si la contraseña es correcta
			my $session = new CGI::Session;
			#Guardamos los parametros para la sesion
			$session -> save_param($cgi);
			#Incluimos un metodo para la expiracion de la sesion
			$session->expires("+30m");
			#Inlcluimos flush para que sincronice los datos dentro del servidor
			$session->flush();
			#Incluimos un header que nos reedireccionara a nuestra pagina privada (es private)
			#Imprimimos log:
			$campo="Correct Access";			
			open(SESION,">> /var/log/adsys/server_access.log");
			print SESION strftime "%F %T",localtime time;
			print SESION ' -- User: '.$usuario.' -- ';
			print SESION $campo;
			print SESION "\n";
			close (SESION);


			print $session->header(-location => "private.pl");
			
			$dbh -> disconnect();
		}else{
			print $cgi->header("text/html");
			print "<meta http-equiv ='refresh' content='0; ../wrong_login.html'>";
			
			$campo="Wrong Password or Email";			
			open(SESION,">> /var/log/adsys/server_access.log");
			print SESION strftime "%F %T",localtime time;
			print SESION ' -- User: '.$usuario.' -- ';
			print SESION $campo;
			print SESION "\n";
			close (SESION);
			$dbh -> disconnect();
		}
	}else{
			#Buscamos en las otras bases de datos...
			$sth = $dbh->prepare("SELECT password FROM verified_users WHERE username='$usuario'");
			$sth->execute();
			$hash=$sth->fetchrow_array;
			if(length ($hash) != 0){ #Hay un usuario con ese hash en el proceso de verificación
				print $cgi->header("text/html");
				print "<meta http-equiv ='refresh' content='0; ../verifying_user.html'>";
				
				$campo="Access While Verifying User";			
				open(SESION,">> /var/log/adsys/server_access.log");
				print SESION strftime "%F %T",localtime time;
				print SESION ' -- User: '.$usuario.' -- ';
				print SESION $campo;
				print SESION "\n";
				close (SESION);
				$dbh -> disconnect();
			}else{
				#Por último buscamos en la base de datos no verificados...
				$sth = $dbh->prepare("SELECT password FROM unverified_users WHERE username='$usuario'");
				$sth->execute();
				$hash=$sth->fetchrow_array;
				if(length ($hash) != 0){ #Hay un usuario con ese hash sin verificar
					print $cgi->header("text/html");
					print "<meta http-equiv ='refresh' content='0; ../need_to_verify.html'>";
					
					$campo="Unverified Access";			
					open(SESION,">> /var/log/adsys/server_access.log");
					print SESION strftime "%F %T",localtime time;
					print SESION ' -- User: '.$usuario.' -- ';
					print SESION $campo;
					print SESION "\n";
					close (SESION);
					$dbh -> disconnect();
				}else{
					print $cgi->header("text/html");
					print "<meta http-equiv ='refresh' content='0; ../incorrect_log_in_data.html'>";
					
					$campo="Incorrect Access";			
					open(SESION,">> /var/log/adsys/server_access.log");
					print SESION strftime "%F %T",localtime time;
					print SESION ' -- User: '.$usuario.' -- ';
					print SESION $campo;
					print SESION "\n";
					close (SESION);
					$dbh -> disconnect();
				}
			}
	}

