#!/usr/bin/perl

use strict;
use CGI;
use CGI::Session;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
my $cgi = new CGI;
#Cargamos la session antigua para luego poder destruirla
my $session =new CGI::Session;
$session->load();
$session->delete();
$session->flush();
print $cgi->header("text/html");
print "<meta http-equiv ='refresh' content='0; ../index.html'>";
