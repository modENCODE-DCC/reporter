#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Cookies;
use File::Basename;
use File::Copy;

my $validator_path;
BEGIN {
    $validator_path = "/home/zheng/validator";
    push @INC, $validator_path;
}

#replace with your own validator dir 
#use lib $validator_path;
use ModENCODE::Cache;
use ModENCODE::Config;
use ModENCODE::Parser::Chado;
use GEO::Reporter;
#use AE::Reporter;
ModENCODE::Config::set_cfg($validator_path . '/validator.ini');
ModENCODE::Cache::init();

#my $experiment_id = $ARGV[0];
#my $report_dir = $ARGV[1];
my $report_dir = $ARGV[0];
my $dbname = $ARGV[1];
my $uniquename = $ARGV[2];

my $experiment_id = '1';
#my $report_dir = '/home/zheng/data';

#is this a new submission?
my $newsubmission = 1;
#username/password for GEO submission page
my $username = 'zheng';
my $passwd = 'weigaocn';
#test but not submit to GEO
my $submitnow = 0;

#my $dbname = 'modencode_chado';
#my $host = 'heartbroken.lbl.gov';
#my $username = 'db_public';
#my $passwd = 'ir84#4nm';

#my $dbname = 'modencode2';
#my $dbname = 'NA_MES4FLAG_EEMB';
#my $dbname = 'Dro2_AS_1182-4H';
#my $dbname = 'mod-mdg4';
#my $dbname = 'Kc_timing';
my $host = 'localhost';
my $dbusername = 'zheng';
my $dbpasswd = 'weigaocn';



my $reader = new ModENCODE::Parser::Chado({
	'dbname' => $dbname,
	'host' => $host,
	'username' => $dbusername,
	'password' => $dbpasswd,
   });

if (!$experiment_id) {
    #print out all experiment id
} else {
    #check whether experiment id is valid
}

$reader->load_experiment($experiment_id);
my $experiment = $reader->get_experiment();
print "experiment loaded\n";

my $reporter = new GEO::Reporter();

#make sure $report_dir ends with '/'
$report_dir .= '/' unless $report_dir =~ /\/$/;

my $seriesfile = $report_dir . $uniquename . '_series.txt';
my $samplefile = $report_dir . $uniquename . '_sample.txt';

my ($seriesFH, $sampleFH);
open $seriesFH, ">", $seriesfile;
open $sampleFH, ">", $samplefile;
$reporter->chado2series($reader, $experiment, $seriesFH, $uniquename);
print "done with series\n";
my ($raw_datafiles, $normalize_datafiles) = $reporter->chado2sample($reader, $experiment, $seriesFH, $sampleFH, $report_dir);
print "done with sample\n";
close $sampleFH;
close $seriesFH;

my @nr_raw_datafiles = nr(@$raw_datafiles);
my @nr_normalized_datafiles = nr(@$normalized_datafiles);

#make a tar ball at report_dir for series, sample files and all datafiles
my $metafile = $uniquename . ".soft";
my $tarfile = $uniquename . '.tar';
chdir $report_dir;
my $dir = dirname($seriesfile);
my $file1 = basename($seriesfile);
my $file2 = basename($samplefile);
my @cat = ("cat $file1 $file2 > $metafile");
system(@cat) == 0 || die "can not cate: $?";
my @tar = ('tar', 'cf', $tarfile, $metafile);
system(@tar) == 0 || die "can not make tar: $?";
system("rm $metafile") == 0 || die "can not remove metafile: $?";
my @datafiles = (@nr_raw_datafiles, @nr_normalized_datafiles);
for my $datafile (@datafiles) {
    my $path = $report_dir . $datafile;
    my $dir = dirname($path);
    my $file = basename($path);
    move($tarfile, $dir);
    chdir $dir;
    my @tar = ('tar', 'rf', $tarfile, $file);
    system(@tar) == 0 || die "can not make tar: $?";
}
move($tarfile, $report_dir);
chdir $report_dir;
#system('gzip', $tarfile) == 0 || die "can not zip the tar: $?";

#submit to GEO
if ($submitnow) {
    my $submit_url = 'http://www.ncbi.nlm.nih.gov/geo/submission/depslip.cgi';
    my $submitter = new LWP::UserAgent;
    $submitter->cookie_jar({});
    $submitter->credentials('http://www.ncbi.nlm.nih.gov/', 'geo/submission/depslip.cgi', $username, $passwd);
    my $subtype = $newsubmission ? 'new' : 'update';
    my $request = POST($submit_url,
		       Content_Type => 'form-data',
		       Content => [state => '2',
				   subtype => $subtype,
				   filename => [$tarballfile],
				   release_immed_date => 'SELECTED',]);
    my $response = $submitter->request($request);
    die $response->message unless $response->is_success;
}

sub nr {
    my @files = @_;
    my @nr_files = ();
    for my $file (@files) {
	my $already_in = 0;
	for my $nr_file (@nr_files) {
	    $already_in = 1 and last if $file eq $nr_file;
	}
	push @nr_files, $file unless $already_in;
    }
    return @nr_files;
}

sub unzipp {
    my $path = shift;
    my ($file, $dir, $suffix) = fileparse($path, qr/\.\D.*/);
    if (($suffix eq '.tar.gz') || ($suffix eq '.tgz')) {
    }
    if ($suffix eq '.bz2') {
    }
    if ($suffix eq '.zip' || $suffix eq '.ZIP' || $suffix eq '.Z') {
    }
    if ($suffix eq '.gz') {
    }
    if ($suffix eq '.tar') {
    }
}
