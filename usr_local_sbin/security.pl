#!/usr/bin/perl
use strict;
use warnings;

use Mail::Sender;
use Email::Send::SMTP::Gmail;

system('tripwire --check > datos.txt');
my $destination='xamo1998@gmail.com';
my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com', 
						 -login=>'xamo1998@gmail.com', 
						 -pass=>'XXXXXXXXXXXXXXXXXXXXXXX',
						 -layer=>'ssl');
print "Session error: $error" unless ($mail!=1);
$mail->send(-to=>$destination,-subject=>'Security report', -body=>'Here is your daily report!', -attachments=>'/usr/local/sbin/datos.txt');
$mail->bye;
unlink 'datos.txt';
