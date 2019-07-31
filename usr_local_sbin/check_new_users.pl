#!/usr/bin/perl

#use strict;
use warnings;
use DBI;
use MIME::Base64 ();
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use Quota;
use Linux::usermod;

my $root = "admin";
my $pass = "admin1234";
my $host = "localhost";
my $db = "users";

my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});
my $consult1 = $dbh->prepare("SELECT * FROM verified_users");
$consult1->execute();

my $consult2;
while(my ($id, $username, $name, $last_name, $password, $email) = $consult1->fetchrow_array()){
  $consult2 = $dbh->prepare("INSERT INTO final_users(id,username,name,last_name,password,email)
	 												VALUES (NULL, \'$username\', \'$name\',\'$last_name\',\'$password\',\'$email\')");
  $consult2->execute();
  $consult2 = $dbh->prepare("DELETE FROM verified_users WHERE username='$username'");
  $consult2->execute();
  #Lo insertamos en linux
  my $directory = "/mnt/home/".$username;
      unless(mkdir $directory) {
          die "Unable to create $directory\n";
      }
  my $recovered = MIME::Base64::decode($password);
  Linux::usermod->add($username,$recovered,'','1001',$name,"/mnt/home/".$username, "/bin/bash");
  my $user=Linux::usermod->new($username);
  my $www_user=Linux::usermod->new('www-data');
  chown $user->get('uid'), $user->get('gid'), "/mnt/home/".$username."/";
  dircopy('/etc/skel','/mnt/home/'.$username);
  #Creamos el .htaccess
  my $filename = '/mnt/home/'.$username.'/public_html/.htaccess';
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh "<Files \"index.html\">\n";
  print $fh "AuthName \"Introduce tus credenciales\"\n";
  print $fh "AuthType Basic\n";
  print $fh "AuthUserFile /mnt/home/".$username."/.htpasswd\n";
  print $fh "require valid-user\n";
  print $fh "</Files>\n";
  chown $user->get('uid'),$www_user->get('gid'),"/mnt/home/".$username."/public_html/";
  chown $user->get('uid'),$www_user->get('gid'),"/mnt/home/".$username."/public_html/index.html";
  my $folder ="/mnt/home/".$username."/.htpasswd";
  #my $code = "htpasswd -c /mnt/home/".$username."/.htpasswd ".$username." ".$recovered;
  system ("htpasswd -bc $folder $username $recovered");
  chown $user->get('uid'),$www_user->get('gid'),"/mnt/home/".$username."/public_html/.htaccess";
  my $perm=0750; 
  chmod ($perm, "/mnt/home/".$username."/public_html/index.html");
  chown $user->get('uid'),$www_user->get('gid'),"/mnt/home/".$username.".htpasswd";
  Quota::setqlim("/dev/loop16",$user->get('uid'),3072,5120,0,0);
}

