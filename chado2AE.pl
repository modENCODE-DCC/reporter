#!/usr/bin/perl

use strict;

#replace with your own validator dir 
use lib '/home/zheng/validator';

use ModENCODE::Parser::Chado;
use AE::Reporter;

#my $experiment_id = $ARGV[0];
#my $report_dir = $ARGV[1];

my $experiment_id = '6';
my $report_dir = '/home/zheng/data';

#my $dbname = 'modencode_chado';
#my $host = 'heartbroken.lbl.gov';
#my $username = 'db_public';
#my $passwd = 'ir84#4nm';

my $dbname = 'modencode';
my $host = 'localhost';
my $username = 'zheng';
my $passwd = 'weigaocn';


my $reader = new ModENCODE::Parser::Chado({
	'dbname' => $dbname,
	'host' => $host,
	'username' => $username,
	'password' => $passwd,
   });

if (!$experiment_id) {
    #print out all experiment id
} else {
    #check whether experiment id is valid
}

$reader->load_experiment($experiment_id);
my $experiment = $reader->get_experiment();

my $reporter = new AE::Reporter();

#make sure $report_dir ends with '/'
$report_dir .= '/' unless $report_dir =~ /\/$/;
my $idf = $report_dir . "experiment_". $experiment_id . '_idf.txt';
my $rel_sdrf = "experiment_". $experiment_id . '_sdrf.txt';
my $sdrf = $report_dir . "experiment_". $experiment_id . '_sdrf.txt';

#$reporter->write_idf($experiment, $idf, $rel_sdrf);
#$reporter->write_sdrf($experiment, $sdrf);
$reporter->write_sdrf($reader, $sdrf);


