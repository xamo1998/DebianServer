#!/usr/bin/perl
use strict;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use warnings;
use Quota;
use Linux::usermod;
use File::Path qw(make_path remove_tree);
use MIME::Base64 ();
use DBI;
my $root = "admin";
my $pass = "admin1234";
my $host = "localhost";
my $db = "users";

my $dbh = DBI->connect("DBI:MariaDB:database=$db;host=$host", $root, $pass,{RaiseError => 1, PrintError => 0});
my $sth =  $dbh->prepare("SELECT * FROM users_to_change");
$sth->execute();

while(my($username)=$sth->fetchrow_array()){

  my $sth1 = $dbh->prepare("SELECT * FROM final_users WHERE username='$username'");
  $sth1->execute();
  my ($id, $username1, $name, $last_name, $password, $email) = $sth1->fetchrow_array;
  Linux::usermod->del($username);
   my $folder='/mnt/home/'.$username.'/';
   my $mail_folder='/var/mail/'.$username.'/';
  remove_tree($folder);
  remove_tree($mail_folder);
  my $pass = MIME::Base64::decode($password);
  Linux::usermod->add($username,$pass,'','1001',$name,"/mnt/home/".$username, "/bin/bash"); 
  my $user = Linux::usermod->new($username);
  my $www_user = Linux::usermod->new('www-data');
  chown $user->get('uid'), $user->get('gid'), "/mnt/home/".$username."/";
  dircopy('/etc/skel','/mnt/home/'.$username.'/');
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
  $folder ="/mnt/home/".$username."/.htpasswd";
  my $code = "htpasswd -c /mnt/home/".$username."/.htpasswd ".$username." contraseñaa";
  system("htpasswd -bc $folder $username contraseñaa");
  chown $user->get('uid'),$www_user->get('gid'),"/mnt/home/".$username."/public_html/.htaccess";
  Quota::setqlim("/dev/loop16",$user->get('uid'),3072,5120,0,0);

  my $consult4 = $dbh->prepare("DELETE FROM users_to_change WHERE username='$username'");
  $consult4->execute();
}
$dbh -> disconnect();
