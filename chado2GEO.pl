#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Cookies;

my $validator_path;
BEGIN {
    $validator_path = "/home/zheng/validator";
    push @INC, $validator_path;
}

#replace with your own validator dir 
#use lib $validator_path;

use ModENCODE::Parser::Chado;
use GEO::Reporter;

#use AE::Reporter;

#my $experiment_id = $ARGV[0];
#my $report_dir = $ARGV[1];

my $experiment_id = '1';
my $report_dir = '/home/zheng/data';

#is this a new submission?
my $newsubmission = 1;
my $username = 'zheng';
my $passwd = 'weigaocn';

#my $dbname = 'modencode_chado';
#my $host = 'heartbroken.lbl.gov';
#my $username = 'db_public';
#my $passwd = 'ir84#4nm';

my $dbname = 'modencode2';
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
#print "experiment loaded";

my $reporter = new GEO::Reporter();

#make sure $report_dir ends with '/'
$report_dir .= '/' unless $report_dir =~ /\/$/;

my $seriesfile = $report_dir . "experiment_". $experiment_id . '_series.txt';
my $samplefile = $report_dir . "experiment_". $experiment_id . '_sample.txt';

my ($seriesFH, $sampleFH);
open $seriesFH, ">", $seriesfile;
open $sampleFH, ">", $samplefile;
$reporter->chado2series($experiment, $seriesFH);
my ($raw_datafiles, $normalize_datafiles) = $reporter->chado2sample($reader, $experiment, $seriesFH, $sampleFH, $report_dir);
close $sampleFH;
close $seriesFH;

#make a tar ball at report_dir for series, sample files and all datafiles
my $tarballfile = $report_dir . 'experiment_' . $experiment_id . '.tar.gz';
my @tar = ('tar czf', $tarballfile, $seriesfile, $samplefile);
push @tar, @$raw_datafiles;
push @tar, @$normalize_datafiles;
system(@tar) || die "can not make tar ball: $?";

#submit to GEO
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
			       release_immed_date => 'on',]);
die $response->message unless $response->is_success;

