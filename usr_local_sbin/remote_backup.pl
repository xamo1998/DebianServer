use WebService::Dropbox;

my $dropbox = WebService::Dropbox->new({
    key => 'XXXXXXXXXXXXXX', # App Key
    secret => 'XXXXXXXXXXXXX' # App Secret
});
# Authorization
if ($access_token) {
    $dropbox->access_token($access_token);
} else {
    my $url = $dropbox->authorize;
 
    print "Please Access URL and press Enter: $url\n";
    print "Please Input Code: ";
 
    chomp( my $code = <STDIN> );
 
    unless ($dropbox->token($code)) {
        die $dropbox->error;
    }
 
    print "Successfully authorized.\nYour AccessToken: ", $dropbox->access_token, "\n";
}
 
my $info = $dropbox->get_current_account or die $dropbox->error;
 my $to_compress="/var/backups/backup_mnt.rsync /var/backups/backup_usr.rsync /var/backups/backup_etc.rsync";
 my $compressed="/var/backups/backup_mnt.zip";
system("zip -r $compressed $to_compress");
# upload
# https://www.dropbox.com/developers/documentation/http/documentation#files-upload
my $fh_upload = IO::File->new("/var/backups/backup_mnt.zip");
$dropbox->upload('/make_test_folder/backup.zip', $fh_upload) or die $dropbox->error;
$fh_upload->close;
unlink $compressed;
