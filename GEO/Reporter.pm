package GEO::Reporter;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Basename;

my $validator_path;
BEGIN {
    $validator_path = '/home/zheng/validator';
    push @INC, $validator_path;
}

use ModENCODE::Config;

sub chado2series {
    my ($self, $reader, $experiment, $seriesFH, $uniquename) = @_;
    my $uniquename = $experiment->get_uniquename();
    print $seriesFH "^Series = ", $uniquename, "\n";

    #API changed! foreach my $property (@{$experiment->get_properties()}) {
    foreach my $property ($experiment->get_properties()) {
	#API changed!
	my ($name, $value, $rank, $type) = ($property->get_object()->get_name(), 
					    $property->get_object()->get_value(), 
					    $property->get_object()->get_rank(), 
					    $property->get_object()->get_type());	
#	my ($name, $value, $rank, $type) = ($property->get_name(), 
#					    $property->get_value(), 
#					    $property->get_rank(), 
#					    $property->get_type());
	print $seriesFH "!Series_title = modENCODE $uniquename", substr($value, 0, 108-length($uniquename)), "\n" if $name =~ /Investigation\s*Title/i;
	my $str = 'DATA USE POLICY: This dataset was generated under the auspices of the modENCODE (http://www.modencode.org) project, which has a specific data release policy stating that the data may be used, but not published, until 9 months from the date of public release. If any data used for the analysis are derived from unpublished data prior to the expiration of the nine-month protected period, then the resource users should obtain the consent of respective resource producers prior to submission of a manuscript.';	
	print $seriesFH "!Series_summary = Project Goal:", $value, $str, "\n" if $name =~ /Experiment\s*Description/i;
	print $seriesFH "!Series_pubmed_id = ", $value, "\n" if $name =~ /Pubmed_id/i;
    }

#    my $design = $self->get_design($experiment);
    $self->write_series_overall_design($reader, $experiment, $seriesFH);
    $self->write_series_type($experiment, $seriesFH);
    print $seriesFH "!Series_web_link = http://www.modencode.org\n";
    $self->write_contributors($experiment, $seriesFH);

    my $factor = $self->get_factor($experiment);
#    $self->write_series_variable($factor, $seriesFH);
}

sub write_contributors {
    #further improvement: summary line specific for this experiment, 
    #using factor, data type, number of replicates, characteristics;
    #summary line for keywords
    my ($self, $experiment, $seriesFH) = @_;
    my %person;
    my $project;
#    my %contact = ('waterston' => 'nicole',
#		   'lieb' => 'marc',
#		   'snyder' => 'marc',
#		   'henikoff' => 'marc',
#		   'piano' => 'nicole',
#		   'celniker' => 'nicole',
#		   'karpen' => 'marc',
#		   'white' => 'marc',
#		   'lai' => 'peter',
#		   'macalpine' => 'peter',
#    );
    my %contact = ('waterston' => 'dcc',
	           'lieb' => 'dcc',
	           'snyder' => 'dcc',
                   'henikoff' => 'dcc',
	           'piano' => 'dcc',
	           'celniker' => 'dcc',
                   'karpen' => 'dcc',
                   'white' => 'dcc',
                   'lai' => 'dcc',
                   'macalpine' => 'dcc');
    my %contact_info = (
	'marc' => {'first' => 'Marc',
		   'middle' => 'D',
		   'last' => 'Perry',
		   'email' => 'marc.perry@oicr.on.ca',
		   'phone' => '416-673-8593',
		   'institute' => 'Ontario Institute for Cancer Research',
		   'address' => '101 College Street, Suite 800',
		   'city' => 'Toronto', 
		   'state' => 'Ontario', 
		   'country' => 'Canada',
		   'zip code' => 'M5G 0A3',
	},
	'peter' => {'first' => 'Peter',
		   'last' => 'Ruzanov',
		   'email' => 'Peter.Ruzanov@oicr.on.ca',
		   'phone' => '416-673-8579',
		   'institute' => 'Ontario Institute for Cancer Research',
		   'address' => '101 College Street, Suite 800',
		   'city' => 'Toronto', 
		   'state' => 'Ontario', 
		   'country' => 'Canada',
		   'zip code' => 'M5G 0A3',
	},
	'nicole' => {'first' => 'Nicole',
		     'middle' => 'L',
		     'last' => 'Washington',
		     'email' => 'NLWashington@lbl.gov',
		     'phone' => '510-486-6217',
		     'institute' => 'Life Sciences Division, Lawrence Berkeley National Laboratory',
		     'address' => '1 Cyclotron Rd. MS 64-121, Berkeley, CA 94720',
		     'city' => 'Berkeley',
		     'state' => 'Califonia',
		     'country' => 'USA',
		     'zip code' => '94720',
	},
        'dcc' => {'first' => 'DCC',
		  'last'  => 'modENCODE',
		  'email' => 'help@modencode.org',
		  'phone' => '416-673-8579',
		  'institute' => 'Ontario Institute for Cancer Research',
		  'address' => '101 College Street, Suite 800',
		  'city' => 'Toronto', 
		  'state' => 'Ontario', 
		  'country' => 'Canada',
		  'zip code' => 'M5G 0A3',                  
	});

    #API changed! foreach my $property (@{$experiment->get_properties()}) {
    foreach my $property ($experiment->get_properties()) {
	#API changed! my ($name, $value, $rank, $type) = ($property->get_name(), 
	#                				  $property->get_value(), 
	#			                	  $property->get_rank(), 
	#				                  $property->get_type());
	my ($name, $value, $rank, $type) = ($property->get_object()->get_name(), 
					    $property->get_object()->get_value(), 
					    $property->get_object()->get_rank(), 
					    $property->get_object()->get_type());	

	$person{$rank}{'affiliation'} = $value if $name =~ /Person\s*Affiliation/i;
	$person{$rank}{'address'} = $value if $name =~ /Person\s*Address/i;
	$person{$rank}{'phone'} = $value if $name =~ /Person\s*Phone/i;
	$person{$rank}{'first'} = $value if $name =~ /Person\s*First\s*Name/i;
	$person{$rank}{'last'} = $value if $name =~ /Person\s*Last\s*Name/i;
	$person{$rank}{'middle'} = $value if $name =~ /Person\s*Mid\s*Initials/i;
	$person{$rank}{'email'} = $value if $name =~ /Person\s*Email/i;
	$person{$rank}{'roles'} = $value if $name =~ /Person\s*Roles/i;

	$project = lc($value) if $name =~ /Project\s*$/i;
    }	
    
    foreach my $k (sort keys %person) {
	my $str = $person{$k}{'first'} . ",";
	if ($person{$k}{'mid'}) {
	    $str .= $person{$k}{'mid'}[0] . ",";
	} #else {
	  #  $str .= " ,";
	#}
	$str .= $person{$k}{'last'};
	print $seriesFH "!Series_contributor = ", $str, "\n";
    }

    print $seriesFH "!Series_contributor = ", "DCC, modENCODE\n";

#    my $person = $contact{$project};
#    my $str;
#    if ($person ne 'dcc') {
#	$str = $contact_info{$person}{'first'} . ",";    
#	$str .= $contact_info{$person}{'middle'} . "," if defined($contact_info{$person}{'middle'});
#	$str .= $contact_info{$person}{'last'};
#    } else {
#	$str .= $contact_info{$person}{'first'} . ",";
#	$str .= $contact_info{$person}{'last'}; 
#    }
#    print $seriesFH "!Series_contact_name = ", $str, "\n";
#    print $seriesFH "!Series_contact_email = ", $contact_info{$person}{'email'}, "\n";
#    print $seriesFH "!Series_contact_phone = ", $contact_info{$person}{'phone'}, "\n";
#    print $seriesFH "!Series_contact_institute = ", $contact_info{$person}{'institute'}, "\n";
#    print $seriesFH "!Series_contact_address = ", $contact_info{$person}{'address'}, "\n";
#    print $seriesFH "!Series_contact_city = ", $contact_info{$person}{'city'}, "\n";
#    print $seriesFH "!Series_contact_state = ", $contact_info{$person}{'state'}, "\n";
#    print $seriesFH "!Series_contact_country = ", $contact_info{$person}{'country'}, "\n";
#    print $seriesFH "!Series_contact_zip/postal-code = ", $contact_info{$person}{'zip code'}, "\n";
}

sub write_series_variable {
    my ($self, $factor, $seriesFH) = @_;
    foreach my $f (sort keys %$factor) {
	my $str = "";
	$str .= "Ontology:" . $factor->{$f}->[2] . " accession:" . $factor->{$f}->[3] . " term:" . $factor->{$f}->[1] if defined($factor->{$f}->[1]);
	$str .= " $factor->{$f}->[0]";	
	print $seriesFH "!Series_variable_", $f, " = ", $str, "\n"; 
    }    
}

sub get_factor {
    my ($self, $experiment) = @_;
    my %factor;
    #API changed! foreach my $property (@{$experiment->get_properties()}) {
    foreach my $property ($experiment->get_properties()) {
	#API changed! my ($name, $value, $rank, $type) = ($property->get_name(), 
	#                				  $property->get_value(), 
	#			                	  $property->get_rank(), 
	#				                  $property->get_type());
	my ($name, $value, $rank, $type) = ($property->get_object()->get_name(), 
					    $property->get_object()->get_value(), 
					    $property->get_object()->get_rank(), 
					    $property->get_object()->get_type());

	if ($name =~ /Experimental\s*Factor\s*Name/i) {
	    $factor{$rank} = [$value];
	}
	if ($name =~ /Experimental\s*Factor\s*Type/i) {
	    push @{$factor{$rank}}, $value;
	    #API changed! if (defined($property->get_termsource())) {
	    if (defined($property->get_object()->get_termsource())) {
		#API changed!
		push @{$factor{$rank}} , ($type->get_object()->get_cv()->get_object()->get_name(), 
					  $property->get_object()->get_termsource()->get_object()->get_accession());
	    }
	}	
    }
    return \%factor;
}

sub get_lab {
    my ($self, $experiment) = @_;
    #API changed! foreach my $property (@{$experiment->get_properties()}) {
    foreach my $property ($experiment->get_properties()) {
	#API changed! my ($name, $value, $rank, $type) = ($property->get_name(), 
	#                				  $property->get_value(), 
	#			                	  $property->get_rank(), 
	#				                  $property->get_type());
	my ($name, $value, $rank, $type) = ($property->get_object()->get_name(), 
					    $property->get_object()->get_value(), 
					    $property->get_object()->get_rank(), 
					    $property->get_object()->get_type());

	return $value if ($name =~ /^\s*lab\s*$/i); 
    }    
}

sub write_series_overall_design {
    my ($self, $reader, $experiment, $seriesFH) = @_;
    my $str = '';
    my $design = $self->get_design($experiment);
    foreach my $k (sort keys %$design) {
#	$str .= "Ontology:" . $design->{$k}->[1] . " accession:" . $design->{$k}->[2] if defined($design->{$k}->[1]);
	$str .= $design->{$k}->[1] if defined($design->{$k}->[1]);
	$str .= "DESIGN ONTOLOGY: MO::$design->{$k}->[0]";
	$str .= ", ";
    }
    $str .= 'EXPERIMENT TYPE: ' . $self->get_series_type($experiment) . ", ";
    my $ap_slots = $self->get_slotnum_for_geo_sample($experiment, 'group');
    my $denorm_slots = $reader->get_denormalized_protocol_slots();
    $str .= 'BIOLOGICAL SOURCE: ' . $self->get_biological_source($denorm_slots, $ap_slots);
    my $grps = $self->get_groups($ap_slots, $denorm_slots);
    my $num_of_grps = keys %$grps;
    $str .= "REPLICATES: " . $num_of_grps . ", ";
    my $dye_swap_status_written = 0;
    for (my $extraction=0; $extraction<$num_of_grps; $extraction++) {
	my $num_of_array = keys %{$grps->{$extraction}};
	$str .= "replicate $extraction applied to $num_of_array arrays, ";
	for (my $array=0; $array<$num_of_array; $array++) {
	    for (my $channel=0; $channel<scalar(@{$grps->{$extraction}->{$array}}); $channel++) {
		my $row = $grps->{$extraction}->{$array}->[$channel];
		if ($self->get_dye_swap_status($denorm_slots, $row, $channel, $ap_slots) eq 'dye swap') {
		    my $sample_id = $self->get_sample_id($denorm_slots, $extraction, $array, $row, $ap_slots);
		    $str .= "replicate $extraction array $array (sample id: $sample_id) is dye swap, ";
		    $dye_swap_status_written = 1;
		}
	    }
	}
    }
    if (not $dye_swap_status_written) {
	$str .= 'NO dye swap,';
    }
    my $factors = $self->get_factor($experiment);
    $str .= "EXPERIMENTAL FACTORS: ";
    for my $rank (keys %$factors) {
	$str .= $factors->{$rank}->[0];
    }
    
    print $seriesFH "!Series_overall_design = ", $str, "\n";     
}

sub get_design {
    my ($self, $experiment) = @_;
    my (%design, %quality_control, %replicate);
    #API changed! foreach my $property (@{$experiment->get_properties()}) {
    foreach my $property ($experiment->get_properties()) {
	#API changed! my ($name, $value, $rank, $type) = ($property->get_name(), 
	#                				  $property->get_value(), 
	#			                	  $property->get_rank(), 
	#				                  $property->get_type());
	my ($name, $value, $rank, $type) = ($property->get_object()->get_name(), 
					    $property->get_object()->get_value(), 
					    $property->get_object()->get_rank(), 
					    $property->get_object()->get_type());

	if ($name =~ /Experimental\s*Design/i) {
	    $design{$rank} = [$value];
	    #API changed! if (defined($property->get_termsource())) {
	    if (defined($property->get_object()->get_termsource())) {
		#API changed!
		push @{$design{$rank}}, ($type->get_object->get_cv()->get_object->get_name(), 
					 $property->get_object()->get_termsource()->get_object()->get_accession());
	    }
	}
    }
    return \%design;
}

sub get_series_type {
    my ($self, $experiment) = @_;
    my $ap_slots = $self->get_slotnum_for_geo_sample($experiment, 'group');
    my $design = $self->get_design($experiment);
    return "ChIP-chip" if  $ap_slots->{'immunoprecipitation'};
    return "FAIRE-chip" if $ap_slots->{'faire'};
    for my $d (values %$design) {
	if ($d =~ /transcript/i) {
	    last and return "transcription tiling array analysis";
	}
    }
    return "tiling array analysis";
}

sub write_series_type {
    my ($self, $experiment, $seriesFH) = @_;
    print $seriesFH "!Series_type = ", $self->get_series_type($experiment), "\n";
}

#sub write_series_type {
#    my ($self, $experiment, $seriesFH) = @_;
#    my $ap_slots = $self->get_slotnum_for_geo_sample($experiment);
#    my $design = $self->get_design($experiment);

#    my $written = 0;
#    print $seriesFH "!Series_type = ", "ChIP-chip\n" and $written = 1 if $ap_slots->{'immunoprecipitation'};
#    print $seriesFH "!Series_type = ", "FAIRE-chip\n" and $written = 1 if $ap_slots->{'faire'};
#    for my $dd (values %$design) {
#	for my $d (@$dd) {
#	    if ($d =~ /transcript/i) {
#		print $seriesFH "!Series_type = ", "transcription tiling array analysis\n"; 
#		$written = 1 and last;
#	    }
#	}
#    }
#    print $seriesFH "!Series_type = ", "tiling array analysis\n" unless $written;
#}

sub get_groups {
    my ($self, $ap_slots, $denorm_slots) = @_;
    #my $ap_slots = $self->get_slotnum_for_geo_sample($experiment);
    #my $denorm_slots = $reader->get_denormalized_protocol_slots();
    my ($nr_grp, $all_grp) = $self->group_applied_protocols($denorm_slots->[$ap_slots->{'extraction'}], 1);
    my $all_grp_by_array = $self->group_applied_protocols_by_data($denorm_slots->[$ap_slots->{'hybridization'}],
								  'input', 'name', '\s*array\s*');
    my %combine_grp = ();
    while (my ($row, $extract_grp) = each %$all_grp) {
	my $array_grp = $all_grp_by_array->{$row};
	if (exists $combine_grp{$extract_grp}{$array_grp}) {
	    my $this_extract_ap = $denorm_slots->[$ap_slots->{'extraction'}]->[$row];
	    my $this_hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
	    my $ignore = 0;
	    for my $that_row (@{$combine_grp{$extract_grp}{$array_grp}}) {
		my $that_extract_ap = $denorm_slots->[$ap_slots->{'extraction'}]->[$that_row];
		my $that_hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$that_row];
		$ignore = 1 and last if ($this_extract_ap->equals($that_extract_ap) && $this_hyb_ap->equals($that_hyb_ap));
	    }
	    push @{$combine_grp{$extract_grp}{$array_grp}}, $row unless $ignore;
	} else {
	    $combine_grp{$extract_grp}{$array_grp} = [$row]; 
	}
    }
    return \%combine_grp;
}

sub chado2sample {
    my ($self, $reader, $experiment, $seriesFH, $sampleFH, $report_dir) = @_;
    #get various biological protocol slots 
    my $ap_slots = $self->get_slotnum_for_geo_sample($experiment, 'group');
    #get the more-than-applied-protocols matrix    
    my $denorm_slots = $reader->get_denormalized_protocol_slots();
#    my $denorm_slots = $reader->get_full_denormalized_protocol_slots();
    
    #sort out how many samples in this experiment. for GEO, one sample is defined by one array instance. 
    #this is done by grouping hybridization protocols first by extraction and then by array.
    my ($nr_grp, $all_grp) = $self->group_applied_protocols($denorm_slots->[$ap_slots->{'extraction'}], 1);
#    my ($nr_grp, $all_grp) = $self->group_applied_protocols_fast($denorm_slots->[$ap_slots->{'extraction'}], 1);
    my $all_grp_by_array = $self->group_applied_protocols_by_data($denorm_slots->[$ap_slots->{'hybridization'}],
								  'input', 'name', '\s*array\s*');
#    my $all_grp_by_array = $self->group_applied_protocols_by_data_fast($denorm_slots->[$ap_slots->{'hybridization'}],
#								       'input', 'name', '\s*array\s*');

#    my %combine_grp = ();
#    while (my ($row, $extract_grp) = each %$all_grp) {
#	my $array_grp = $all_grp_by_array->{$row};
#	if (exists $combine_grp{$extract_grp}{$array_grp}) {
#	    my $this_extract_ap = $denorm_slots->[$ap_slots->{'extraction'}]->[$row];
#	    my $this_hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
#	    my $ignore = 0;
#	    for my $that_row (@{$combine_grp{$extract_grp}{$array_grp}}) {
#		my $that_extract_ap = $denorm_slots->[$ap_slots->{'extraction'}]->[$that_row];
#		my $that_hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$that_row];
#		$ignore = 1 and last if ($this_extract_ap->equals($that_extract_ap) && $this_hyb_ap->equals($that_hyb_ap));
#	    }
#	    push @{$combine_grp{$extract_grp}{$array_grp}}, $row unless $ignore;
#	} else {
#	    $combine_grp{$extract_grp}{$array_grp} = [$row]; 
#	}
#    }

    my %combine_grp = %{$self->get_groups($ap_slots, $denorm_slots)};
    my $most_complex_extraction_ap_slot = $ap_slots->{'extraction'};
    my @raw_datafiles;
    my @normalize_datafiles;

    my $ap_slots = $self->get_slotnum_for_geo_sample($experiment, 'protocol');
    for my $extraction (keys %combine_grp) {
	for my $array (keys %{$combine_grp{$extraction}}) {
	    #first write the !Series_sample_id line in Series and ^Sample, !Sample_title lines
	    $self->write_series_sample($denorm_slots, $extraction, $array, 
				       $combine_grp{$extraction}{$array}->[0], 
				       $ap_slots, $seriesFH, $sampleFH);
	    for (my $i=0; $i<scalar(@{$combine_grp{$extraction}{$array}}); $i++) {
		$self->write_sample_source($denorm_slots, $combine_grp{$extraction}{$array}->[$i],
					   $i, $ap_slots, $sampleFH);
		$self->write_characteristics($denorm_slots, $combine_grp{$extraction}{$array}->[$i],
					     $i, $ap_slots, $sampleFH);
		$self->write_sample_description($denorm_slots, $combine_grp{$extraction}{$array}->[$i],
						$i, $ap_slots, $sampleFH);
		$self->write_sample_growth($denorm_slots, $combine_grp{$extraction}{$array}->[$i],
					   $i, $ap_slots, $sampleFH);
		$self->write_sample_extraction($denorm_slots, $combine_grp{$extraction}{$array}->[$i],
					       $i, $ap_slots, $sampleFH,  $most_complex_extraction_ap_slot);
		$self->write_sample_label($denorm_slots, $combine_grp{$extraction}{$array}->[$i],
					  $i, $ap_slots, $sampleFH);	
		push @raw_datafiles, $self->write_raw_data($denorm_slots, $combine_grp{$extraction}{$array}->[$i],
						       $i, $ap_slots, $sampleFH);
	    }
	    $self->write_sample_hybridization($denorm_slots, $combine_grp{$extraction}{$array}->[0],
					      $ap_slots, $sampleFH);		    
	    $self->write_sample_scan($denorm_slots, $combine_grp{$extraction}{$array}->[0],
				     $ap_slots, $sampleFH);
	    $self->write_sample_normalization($denorm_slots, $combine_grp{$extraction}{$array}->[0],
					      $ap_slots, $sampleFH);
	    $self->write_platform($denorm_slots, $combine_grp{$extraction}{$array}->[0],
				  $ap_slots, $sampleFH);
	    push @normalize_datafiles, $self->write_normalized_data($denorm_slots, $combine_grp{$extraction}{$array}->[0],
					 $ap_slots, $sampleFH, $report_dir);
	}
    }
    return (\@raw_datafiles, \@normalize_datafiles);
}

sub get_sample_id {
    my ($self, $denorm_slots, $extraction, $array, $row, $ap_slots) = @_;
    my $hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
    my @hyb_names = map {$_->get_value()} @{_get_datum_by_info($hyb_ap, 'input', 'heading', 'Hybridization\s*Name')};
    if (scalar(@hyb_names)) {
	return $hyb_names[0];
    } else {
	return "extraction" . $extraction . "_" . "array" . $array;
    }
}

sub write_series_sample {#improvement: generate more meaning sample title using factor, characteristics
    my ($self, $denorm_slots, $extraction, $array, $row, $ap_slots, $seriesFH, $sampleFH) = @_;
    my $name = $self->get_sample_id($denorm_slots, $extraction, $array, $row, $ap_slots);
    print $seriesFH "!Series_sample_id = GSM for ", $name, "\n";
    print $sampleFH "^Sample = GSM for ", $name, "\n";
    print $sampleFH "!Sample_title = ", $name, "\n";
#    #use hybridization name if possible
#    my $hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
#    my $hyb_data = _get_datum_by_info($hyb_ap, 'input', 'heading', 'Hybridization\s*Name');    
#    if (scalar(@$hyb_data)) {
#	my @hyb_names = map {$_->get_object->get_value()} @$hyb_data;
#	print $seriesFH "!Series_sample_id = GSM for ", $hyb_names[0], "\n";
#	print $sampleFH "^Sample = GSM for ", $hyb_names[0], "\n";
#	print $sampleFH "!Sample_title = ", $hyb_names[0], "\n";
#    } else {#no hybridization name column, autogenerate
#	my $name = "extraction" . $extraction . "_" . "array" . $array;
#	print $seriesFH "!Series_sample_id = GSM for ", $name, "\n";
#	print $sampleFH "^Sample = GSM for ", $name, "\n";
#	print $sampleFH "!Sample_title = ", $name, "\n";	
#    }
}

sub write_sample_source {
    my ($self, $denorm_slots, $row, $channel, $ap_slots, $sampleFH) = @_;    
    #use Sample name if exists, otherwise use Source name if exists, if none of them, auto-generate.
    my $extract_ap = $denorm_slots->[$ap_slots->{'extraction'}]->[$row];
    my $sample_data = _get_datum_by_info($extract_ap, 'input', 'heading', 'Sample\s*Name');
    if (scalar(@$sample_data) == 0) {
	$sample_data = _get_datum_by_info($extract_ap, 'output', 'heading', 'Result');	
    }
    if (scalar(@$sample_data)) {
	my @sample_names = map {$_->get_object->get_value()} @$sample_data;
	print $sampleFH "!Sample_source_name_ch$channel = ", $sample_names[0], " channel_$channel\n";
    }
    else {
        #use the first protocol to generate source name
	my $source_ap = $denorm_slots->[0]->[$row];
	my $source_data = _get_datum_by_info($source_ap, 'input', 'heading', 'Source\s*Name');	
	if (scalar(@$source_data)) {
	    my @source_names = map {$_->get_object->get_value()} @$source_data;
	    print $sampleFH "!Sample_source_name_ch$channel = ", $source_names[0], " channel_$channel\n";
	} else {#autogenerate
	    print $sampleFH "!Sample_source_name_ch$channel = ", "source at row $row channel_$channel\n";
	}
    }
    my @organism_name = map {$_->get_value()} @{_get_attr_by_info($extract_ap->get_protocol(), 'heading', 'species')};
    print $sampleFH "!Sample_organism_ch$channel = $organism_name[0]\n",    
}

sub get_dye_swap_status {
    #this function only works for CHIP
    my ($self, $denorm_slots, $row, $channel, $ap_slots) = @_;
    return "NA" unless $ap_slots->{'immunoprecipitation'}; 
    my $ip_ap = $denorm_slots->[$ap_slots->{'immunoprecipitation'}]->[$row];
    my $antibodies = _get_datum_by_info($ip_ap, 'input', 'name', 'antibody');
    my $antibody = $antibodies->[0];
    my $label_ap = $denorm_slots->[$ap_slots->{'labeling'}]->[$row];
    my $labels = _get_datum_by_info($label_ap, 'input', 'name', 'label');
    my $label = $labels->[0];
    if ($antibody->get_value() && lc($label->get_value()) =~ /cy3/) {
	return 'dye swap';
    }
}

sub write_sample_description {
    my ($self, $denorm_slots, $row, $channel, $ap_slots, $sampleFH) = @_;
    my $ip_ap = $denorm_slots->[$ap_slots->{'precipitation'}]->[$row];
    my $antibodies = _get_datum_by_info($ip_ap, 'input', 'name', 'antibody');
    if (scalar(@$antibodies)) {
	for my $antibody (@$antibodies) {
	    if ($antibody->get_object->get_value()) {
		my $str = "!Sample_description = channel $channel is ChIP; ";
		for my $attr_cache ($antibody->get_object->get_attributes()) {
		    my $attr = $attr_cache->get_object;
		    my ($name, $heading, $value) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
		    $str .= "$heading";
		    $str .= "[$name] " if $name;
		    if ($attr->get_termsource()) {
			$str .= $attr->get_termsource()->get_object->get_db()->get_object->get_name() . "::";
			#$str .= $attr->get_termsource()->get_db()->get_name() . "|" . $attr->get_termsource()->get_accession();
		    }
		    $str .= ": $value; ";		
		}
	    }
	    else {
		$str .= "channel ch$channel is control channel;"
	    }		
	    print $sampleFH $str, "\n";
	}
    }
}

sub write_characteristics {
    my ($self, $denorm_slots, $row, $channel, $ap_slots, $sampleFH) = @_;
    #use Characteristics columns
    #or search Parameter Value columns which has attributes, 
    #for both extraction ap and any ap before it
    for (my $i=0; $i<=$ap_slots->{'extraction'}; $i++) {
	my $ap = $denorm_slots->[$i]->[$row];
	$self->ap_write_characteristics($ap, $channel, $sampleFH);
    }
}

sub ap_write_characteristics {
    my ($self, $ap, $channel, $sampleFH) = @_;
    for my $datum ($ap->get_input_data()) {
	for my $attr_cache ($datum->get_object->get_attributes()) {
	    my $str .= "!Sample_characteristics_ch$channel = ";
	    my $attr = $attr_cache->get_object;
	    my ($name, $heading, $value) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
	    $str .= "$heading";
	    $str .= "[$name]" if $name;
	    $str .= ": ";
	    if ($attr->get_termsource()) {
		$str .= $attr->get_termsource()->get_object->get_db()->get_object->get_name() . "::";
		#$str .= $attr->get_termsource()->get_db()->get_name() . "|" . $attr->get_termsource()->get_accession();
	    }
	    $str .= $value;
	    print $sampleFH $str, "\n";
	}
    }
}

sub get_biological_source {#cell line, strain, tissue,
    my ($self, $denorm_slots, $ap_slots) = @_;
    my $str = '';
    #my $str = 'BIOLOGICAL SOURCE: ';
    for (my $i=0; $i<=$ap_slots->{'extraction'}; $i++) {
	my $ap = $denorm_slots->[$i]->[0];
	for my $datum (@{$ap->get_input_data()}) {
	    #my ($dname, $dheading, $dvalue) = ($datum->get_name(), $datum->get_heading(), $datum->get_value());
	    for my $attr (@{$datum->get_attributes()}) {
		my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
		#print $aname, ":", $aheading, ":", $avalue, "\n";
		if (lc($aheading) =~ /official\s*name/) {
		    #$str .= $dname . ":", $avalue . ", ";
		    $str .= 'official name:' . "$avalue" . ", ";
		}
		if (lc($aname) =~ /strain/) {#this is internal name
		    #$str .= $dname . ":", $avalue . ", ";
		    $str .= 'strain official name:' . $avalue . ", ";
		}		
		if (lc($aheading) =~ /strain/) {#this is internal name
		    #$str .= $dname . ":", $avalue . ", ";
		    $str .= 'strain name from lab:' . $avalue . ", ";
		}
		if (lc($aheading) =~ /genotype/) {
		    $str .= $aheading . ":" . $avalue . ", ";
		}
		if ((lc($aname) =~ /developmental\s*stage/) || (lc($aheading) =~ /developmental\s*stage/)) {
		    $str .= 'developmental stage' . ":" . $avalue . ", ";
		}
	    }
	}
    }
    return $str;
}

sub write_sample_growth {
    #all protocols before extractions
    my ($self, $denorm_slots, $row, $channel, $ap_slots, $sampleFH) = @_;
    for (my $i=0; $i<$ap_slots->{'extraction'}; $i++) {
	my $ap = $denorm_slots->[$i]->[$row];
	my $protocol_text = $self->get_protocol_text($ap);
	$protocol_text =~ s/\n//g; #one line
	print $sampleFH "!Sample_growth_protocol_ch$channel = ", $protocol_text, "\n";
    }
}

sub write_sample_extraction {
    #molecule and extraction protocols
    my ($self, $denorm_slots, $row, $channel, $ap_slots, $sampleFH, $most_complex_extraction_ap_slot) = @_;
    my $extract_ap = $denorm_slots->[$most_complex_extraction_ap_slot]->[$row];
    my $molecule;
#    my %allowed_mol_type = ('total RNA', 'polyA RNA', 'cytoplasmic RNA', 'nuclear RNA', 
#			    'genomic DNA', 'protein', 'other');
    for my $datum (@{$extract_ap->get_output_data()}) {
	my $type = $datum->get_type()->get_name();
	$molecule='genomic DNA' and last if ($type =~ /dna/i);
	if ($type =~ /rna/i) {
	    $molecule = 'total RNA' and last if $type =~ /total/i;
	    $molecule = 'polyA RNA' and last if $type =~ /polyA/i;
	    $molecule = 'cytoplasmic RNA' and last if $type =~ /cyto/i;
	    $molecule = 'nuclear RNA' and last if $type =~ /nuc/i;
	    $molecule = 'total RNA' and last;
	}
	$molecule='protein' and last if ($type =~ /protein/i);
	$molecule='other' and last;
    }
    croak("is the type of molecule extracted dna, total_rna, nucleic rna, ...?") unless $molecule;
    print $sampleFH "!Sample_molecule_ch$channel = ", $molecule, "\n";
    
    for (my $i=$ap_slots->{'extraction'}; $i<$ap_slots->{'labeling'}; $i++) {
	my $ap = $denorm_slots->[$i]->[$row];
	my $protocol_text = $self->get_protocol_text($ap);
	$protocol_text =~ s/\n//g; #one line
	print $sampleFH "!Sample_extract_protocol_ch$channel = ", $protocol_text, "\n";
	$self->ap_write_characteristics($ap, $channel, $sampleFH); 
    }
}

sub write_sample_label {
    #label and label protocols
    my ($self, $denorm_slots, $row, $channel, $ap_slots, $sampleFH) = @_;
    my $label_ap = $denorm_slots->[$ap_slots->{'labeling'}]->[$row];

    my $label;
    for my $datum ($label_ap->get_input_data()) {
	$label = $datum->get_object->get_value() if $datum->get_object->get_name() =~ /label/i;
    }
    print $sampleFH "!Sample_label_ch$channel = ", $label, "\n";    

    my $protocol_text = $self->get_protocol_text($label_ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_label_protocol_ch$channel = ", $protocol_text, "\n";
}

sub write_sample_hybridization {
    #hybridization protocol
    my ($self, $denorm_slots, $row, $ap_slots, $sampleFH) = @_;    
    my $hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
    my $protocol_text = $self->get_protocol_text($hyb_ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_hyb_protocol = ", $protocol_text, "\n";
}

sub write_sample_scan {
    #scan protocol
    my ($self, $denorm_slots, $row, $ap_slots, $sampleFH) = @_;
    my $scan_ap = $denorm_slots->[$ap_slots->{'scanning'}]->[$row];
    my $protocol_text = $self->get_protocol_text($scan_ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_scan_protocol = ", $protocol_text, "\n";    
}

sub write_sample_normalization {
    #data-processing
    my ($self, $denorm_slots, $row, $ap_slots, $sampleFH) = @_;
    print $sampleFH "!Sample_data_processing = "; 
    for (my $i=$ap_slots->{'scanning'}+1; $i<=$ap_slots->{'normalization'}; $i++) {
	my $ap = $denorm_slots->[$i]->[$row];
	my $protocol_text = $self->get_protocol_text($ap);
	$protocol_text =~ s/\n//g; #one line
	print $sampleFH $protocol_text, " _end of protocol text_ ";
	for my $datum (@{$ap->get_input_data()}) {
	    print $sampleFH "parameter: ", $datum->get_object->get_name(), " is ", $datum->get_object->get_value(), "   " if $datum->get_object->get_heading() =~ /Parameter/i;
	}	
    }
    print $sampleFH "\n";
#    my $normalize_ap = $denorm_slots->[$ap_slots->{'normalization'}]->[$row];
#    my $protocol_text = $self->get_protocol_text($normalize_ap);
#    $protocol_text =~ s/\n//g; #one line
#    print $sampleFH "!Sample_data_processing = ", $protocol_text, " _end of protocol text_ ";
#    for my $datum ($normalize_ap->get_input_data()) {
#	print $sampleFH "parameter: ", $datum->get_object->get_name(), " is ", $datum->get_object->get_value() if $datum->get_object->get_heading() =~ /Parameter/i;
#    }
#    print $sampleFH "\n";       
}

sub get_protocol_text {
    my ($self, $ap) = @_;
    my $protocol = $ap->get_protocol();
    #use short description
    if (my $txt = $protocol->get_object->get_description()) {
	return $txt;
    } else {
	my @url = map {$_->get_value()} @{_get_attr_by_info($protocol, 'heading', 'Protocol\s*URL')};
	return _get_full_protocol_text($url[0]);
    }
}

sub _get_full_protocol_text {
    my ($url) = @_;
    require URI;
    require LWP::UserAgent;
    require HTTP::Request::Common;
    require HTTP::Response;
    require HTTP::Cookies;
    require HTML::TreeBuilder;
    require HTML::FormatText;
    #use wiki render action to get the context instead of left/top panels
    $url .= '&action=render';
    my $uri = URI->new($url);

    ModENCODE::Config::set_cfg($validator_path . '/validator.ini'); 
    my $username = ModENCODE::Config::get_cfg()->val('wiki', 'username');
    my $password = ModENCODE::Config::get_cfg()->val('wiki', 'password');

    my $fetcher = new LWP::UserAgent;
    my @ns_headers = (
	'User-Agent' => 'reporter by zheng',
	'Accept' => 'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*',
	'Accept-Charset' => 'iso-8859-1,*,utf-8',
	'Accept-Language' => 'en-US',
	);
    $fetcher->cookie_jar({});

    my $login_query = "title=Special:Userlogin&action=submitlogin";
    my $login = $uri->scheme. "://" . $uri->host . $uri->path . "?" . $login_query;
    my $response = $fetcher->post($login, @ns_headers, Content=>[wpName=>$username, wpPassword=>$password,wpRemember=>"1",wpLoginAttempt=>"Log in"]);
    if ($response->code != 302) {
	print "modencode private wiki login failed!";
	exit 1;
    }
    
    my $request = $fetcher->request(HTTP::Request->new('GET' => $url));
    my $content = $request->content();

    my $tree = HTML::TreeBuilder->new_from_content($content);
    my $formatter = HTML::FormatText->new();
    my $txt = $formatter->format($tree);

    $txt =~ s/(.*)Validation\s*Form.*/{$txt = $1;}/gsex; #find the last match, just in case
    $txt =~ s/(.*)Notes\s*\n.*/{$txt = $1;}/gsex;
    return $txt;    
}

sub get_array {
    my ($self, $denorm_slots, $row, $ap_slots) = @_;
    my $hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
    my $array = _get_datum_by_info($hyb_ap, 'input', 'heading', 'ArrayDesign\s*REF');
    if (scalar(@$array) == 0) {
        $array = _get_datum_by_info($hyb_ap, 'input', 'name', 'array');
    }
    my $gpl;
    if (scalar(@$array)) {
	my $attr = _get_attr_by_info($array->[0], 'heading', '\s*adf\s*');
	$gpl = $1 if $attr->[0]->get_value() =~ /(GPL\d*)\s*$/;
    }
    return $gpl;
}

sub write_platform {
    my ($self, $denorm_slots, $row, $ap_slots, $sampleFH) = @_;
#    my $hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
#    my $array = _get_datum_by_info($hyb_ap, 'input', 'heading', 'ArrayDesign\s*REF');
#    if (scalar(@$array) == 0) {
#	$array = _get_datum_by_info($hyb_ap, 'input', 'name', 'array');
#    }
#    my $gpl;
#    if (scalar(@$array)) {
#	my $attr = _get_attr_by_info($array->[0], 'heading', '\s*adf\s*');
#	
#	$gpl = $1 if $attr->[0]->get_value() =~ /(GPL\d*)\s*$/;
#    }
    my $gpl = $self->get_array($denorm_slots, $row, $ap_slots);
    print $sampleFH "!Sample_platform_id = ", $gpl, "\n";
}

sub write_normalized_data {
    #normalized data is in wiggle_data
    #supplement a file, don't need liftover/pulldown, thank god!
    my ($self, $denorm_slots, $row, $ap_slots, $sampleFH, $report_dir) = @_;
    my $normalization_ap = $denorm_slots->[$ap_slots->{'normalization'}]->[$row];
    my @suffixs = ('.bz2', '.z', '.gz', '.zip', '.rar');
    my @normalization_datafiles;
    for my $datum (@{$normalization_ap->get_output_data()}) {
# I have decided not to use wiggle_datas, since it is easy
#but I keep the code here for using wiggle_datas just in case someday the submission data dissappear.
	my $path = $datum->get_value();
	my ($file, $dir, $suffix) = fileparse($path, qr/\.[^.]*/);
	if (scalar grep {lc($suffix) eq $_} @suffixs) {
	    print $sampleFH "!Sample_supplementary_file = ", $file, "\n";
	} else {
	    print $sampleFH "!Sample_supplementary_file = ", $file . $suffix, "\n";
	}
#	for my $wiggle_data (@{$datum->get_wiggle_datas()}) {
#	    my $datafile = $report_dir . $wiggle_data->get_name();
#	    open my $dataFH, ">", $datafile || die "can not open $datafile to write out data. $!\n";
#	    print $dataFH $wiggle_data->get_data();
#	    close $dataFH;
#	    print $sampleFH "!Sample_supplementary_file = ", $datafile, "\n";
#	    push @normalize_datafiles, $datafile;
#	}
	push @normalization_datafiles, $path; 


    }
    return @normalization_datafiles;
}

sub write_raw_data {
    my ($self, $denorm_slots, $row, $channel, $ap_slots, $sampleFH) = @_;
    my $ap = $denorm_slots->[$ap_slots->{'raw'}]->[$row];
    my @suffixs = ('.bz2', '.z', '.gz', '.zip', '.rar');
    my @raw_datafiles;
    for my $datum_cache ($ap->get_output_data()) {
	my $datum = $datum_cache->get_object;
	if (($datum->get_heading() =~ /Array\s*Data\s*File/i) || ($datum->get_heading() =~ /Result\s*File/i)) {
	    my $path = $datum->get_value();
	    my ($file, $dir, $suffix) = fileparse($path, qr/\.[^.]*/);
	    if (scalar grep {lc($suffix) eq $_} @suffixs) {
		print $sampleFH "!Sample_supplementary_file = ", $file, "\n";
	    } else {
		print $sampleFH "!Sample_supplementary_file = ", $file . $suffix, "\n";
	    }
	    push @raw_datafiles, $path;
	}
    }
    return @raw_datafiles;
}


sub group_applied_protocols_fast {
    my ($self, $full_ap_slot, $rtn) = @_; 
    #these applied protocols are HASH with keys 'applied_protocol', 'previous_applied_protocol_id'
    my @ids = map {$_->{'applied_protocol'}->get_chadoxml_id()} @$full_ap_slot;
    return _group(\@ids, $rtn);
}

sub group_applied_protocols {
    my ($self, $ap_slot, $rtn) = @_; #these applied protocols are simple obj from AppliedProtocol.pm
    return _group($ap_slot, $rtn);
}

sub group_applied_protocols_by_data_fast {
    my ($self, $ap_slot, $direction, $field, $fieldtext, $rtn) = @_;
    #these applied protocols are HASH with keys 'applied_protocol', 'previous_applied_protocol_id'
    my @yap_slot = map {$_->{'applied_protocol'}} @$ap_slot;
    my $data = _get_data_by_info(\@yap_slot, $direction, $field, $fieldtext);
    my @ids = map {$_->get_object->get_chadoxml_id()} @$data;
    return _group(\@ids, $rtn);
}

sub group_applied_protocols_by_data {
    my ($self, $ap_slot, $direction, $field, $fieldtext, $rtn) = @_;
    my $data_cache = _get_data_by_info($ap_slot, $direction, $field, $fieldtext);
    my @data = map {$_->get_object} @$data_cache;
    return _group(\@data, $rtn);
}

sub _group {
    my ($alist, $rtn) = @_;
    my $x = $alist->[0];

    my @nr = (0);
    my %grp = ();
    for (my $i=0; $i<scalar(@$alist); $i++) {
	my $o = $alist->[$i];
	my $found = 0;
	for (my $j=0; $j<scalar(@nr); $j++) {
	    my $nro = $alist->[$nr[$j]];
	    if (ref($o)) {
		if ($o->equals($nro)) {
		    $grp{$i} = $j;
		    $found = 1;
		    last;
		}
	    } else {
		if ($o == $nro) {
		    $grp{$i} = $j;
		    $found = 1;
		    last;		    
		}
	    }
	}
	if (! $found) {
	    push @nr, $i;
	    $grp{$i} = $#nr; 
	}		
    }
    return (\@nr, \%grp) if $rtn;
    return \%grp;    
}

sub get_slotnum_for_geo_sample {
    my ($self, $experiment, $option) = @_;
    my %ap_slots;
    #find hybridization or sequencing protocol
    $ap_slots{'hybridization'} = $self->get_slotnum_hyb($experiment);
    #find extraction protocol to determine the samples in this experiment
    $ap_slots{'extraction'} = $self->get_slotnum_extract($experiment, $option);
    #find other protocols
    $ap_slots{'labeling'} = $self->get_slotnum_label($experiment);
    $ap_slots{'scanning'} = $self->get_slotnum_scan($experiment);
    $ap_slots{'normalization'} = $self->get_slotnum_normalize($experiment);
    $ap_slots{'raw'} = $self->get_slotnum_raw($experiment);
    $ap_slots{'immunoprecipitation'} = $self->get_slotnum_ip($experiment);
    $ap_slots{'faire'} = $self->get_slotnum_faire($experiment);
    return \%ap_slots;
}

sub get_slotnum_hyb {#this could go into a subclass of experiment
    my ($self, $experiment) = @_;
    #find hybridization protocol
    my $type = "hybrid";
    my @aps = $self->get_slotnum_by_protocol_property($experiment, 1, 'heading', 'Protocol\s*Type', $type);
    if (scalar(@aps) > 1) {
	croak("you confused me with more than 1 hybridization protocols.");
    } elsif (scalar(@aps) == 0) {
	croak("no hybridization protocol has been found.");
    } else {#this is an array experiment
	return $aps[0];
    }
}

sub get_slotnum_extract {#this could go into a subclass of experiment
    my ($self, $experiment, $option) = @_;
    my $type = "extract";
    my @aps = $self->get_slotnum_by_protocol_property($experiment, 1, 'heading', 'Protocol\s*Type', $type);
    if (scalar(@aps) > 1) {
        #croak("you confused me with more than 1 extraction protocols.");
        # we even have submissions with multiple extraction steps
        #croak("you confused me with more than 1 extraction protocols.");
#       warn("this experiment has more than one extraction protocols.");
        if ($option eq 'group') {#report this one to group arrays
            return $self->check_complexity($experiment, \@aps);
        } elsif ($option eq 'protocol') {#report this one to write out protocol
            return $aps[0];
        }
    } elsif (scalar(@aps) == 0) {
	croak("every experiment must have a protocol with type of extraction. maybe you forgot the extraction protocol in SDRF?");
    } else {
	return $aps[0];
    }
}

sub get_slotnum_ip {
    my ($self, $experiment) = @_;
    my @types = ("immunoprecipitation");
    for my $type (@types) {
	my @aps = $self->get_slotnum_by_protocol_property($experiment, 1, 'heading', 'Protocol\s*Type', $type);
	return $aps[-1] if scalar(@aps);
    }
    warn("warning! can not find IP protocol.");
    return;
}

sub get_slotnum_faire {
    my ($self, $experiment) = @_;
    my @types = ("FAIRE");
    for my $type (@types) {
	my @aps = $self->get_slotnum_by_protocol_property($experiment, 1, 'heading', 'Protocol\s*Type', $type);
	return $aps[-1] if scalar(@aps);
    }
}

sub get_slotnum_label {#this could go into a subclass of experiment.pm
    my ($self, $experiment) = @_;
    my $type = "label";
    my @aps = $self->get_slotnum_by_protocol_property($experiment, 1, 'heading', 'Protocol\s*Type', $type);
    #even there are more than 1 labeling protocol, choose the last one since it is the nearest to hyb protocol.
    return $aps[-1] if scalar(@aps);
    croak("can not find the labeling protocol.");
}

sub get_slotnum_scan {#this could go into a subclass of experiment
    my ($self, $experiment) = @_;
    my $type = "scan";
    my @aps = $self->get_slotnum_by_protocol_property($experiment, 1, 'heading', 'Protocol\s*Type', $type);
    #even there are more than 1 labeling protocols, choose the last one since it is the nearest to hyb protocol.
    return $aps[-1] if scalar(@aps);
    croak("can not find the scanning protocol.");
}

sub get_slotnum_raw {#this could go into a subclass of experiment
    my ($self, $experiment) = @_;
    #first search by output data type, such as modencode-helper:nimblegen_microarray_data_file (pair) [pair]
    #or modencode-helper:CEL [Array Data File], or agilent_raw_microarray_data_file (TXT)
    my @types = ('nimblegen_microarray_data_file\s*\(pair\)', 'CEL', 'agilent_raw_microarray_data_file');
    for my $type (@types) {
#	my $i = 0;
#	for my $ap_slot (@{$experiment->get_applied_protocol_slots()}) {
#	    my $ap = $ap_slot->[0];
#	    for my $datum (@{$ap->get_output_data()}) {
#		return $i if $datum->get_type()->get_name() =~ /$type/i;
#	    }
#	    $i++;
#	}

	my @aps = $self->get_slotnum_by_datum_property($experiment, 'output', 0, 'type', undef, $type);
	#even there are more than 1 raw-data-generating protocols, choose the first one since it is the nearest to hyb protocol
	return $aps[0] if scalar(@aps);
    }
    croak("can not find the protocol that generates raw data");
}

sub get_slotnum_normalize {#this could go into a subclass of experiment 
    my ($self, $experiment) = @_;
    #first search by output data type, such as modencode-helper:Signal_Graph_File [sig gr]
    my @types = ('Signal_Graph_File', 'normalized\s*data', 'scaled\s*data', 'signal\s*intensities');
    for my $type (@types) {
	my @aps = $self->get_slotnum_by_datum_property($experiment, 'output', 0, 'type', undef, $type);
	#even there are more than 1 normalization protocols, choose the first one since it is the nearest to hyb protocol
	return $aps[0] if scalar(@aps);
    }

    my @aps;
    #then search by protocol type
    my $type = "normalization";
    @aps = $self->get_slotnum_by_protocol_property($experiment, 1, 'heading', 'Protocol\s*Type', $type);
    #even there are more than 1 normalization protocols, return the first one, since it is the nearest to hyb protocol
    return $aps[0] if scalar(@aps);

    #finally search by protocol name
    my $name = "normalization";
    @aps = $self->get_slotnum_by_protocol_property($experiment, 0, 'name', undef, $name);
    return $aps[0] if scalar(@aps);
    croak('can not find the normalization protocol.');
}

sub get_slotnum_by_protocol_property {
    my ($self, $experiment, $isattr, $field, $fieldtext, $value) = @_;
    my @slots = ();
    my $found = 0;
    for (my $i=0; $i<scalar(@{$experiment->get_applied_protocol_slots()}); $i++) {
	for my $ap (@{$experiment->get_applied_protocol_slots()->[$i]}) {
	    last if $found;
	    if ($isattr) {#protocol attribute
		#API changed twice! for my $attr (@{$ap->get_protocol()->get_attributes()}) {
		for my $attr_cache ($ap->get_protocol()->get_object()->get_attributes()) {
		    my $attr = $attr_cache->get_object;
		    if (_get_attr_value($attr, $field, $fieldtext) =~ /$value/i) {
			push @slots, $i;
			$found = 1 and last;
		    }
		}
	    } else {#protocol
		if (_get_protocol_info($ap->get_protocol()->get_object, $field) =~ /$value/i) {
		    push @slots, $i;
		    $found = 1 and last;
		}
	    }
	}
	$found = 0;
    }
    return @slots;
}

sub get_slotnum_by_datum_property {#this could go into a subclass of experiment 
    #direction for input/output, field for heading/name, value for the text of heading/name
    my ($self, $experiment, $direction, $isattr, $field, $fieldtext, $value) = @_;
    my @slots = ();
    my $found = 0;
    for (my $i=0; $i<scalar(@{$experiment->get_applied_protocol_slots()}); $i++) {
	for my $applied_protocol (@{$experiment->get_applied_protocol_slots()->[$i]}) {
	    last if $found;
	    if ($direction eq 'input') {
		for my $input_datum_cache ($applied_protocol->get_input_data()) {
		    #API changed!
		    my $input_datum = $input_datum_cache->get_object();
		    if ($isattr) {
			#API changed! for my $attr (@{$input_datum->get_attributes()}) {
			for my $attr_cache ($input_datum->get_attributes()) {
			    my $attr = $attr_cache->get_object;
			    if (_get_attr_value($attr, $field, $fieldtext) =~ /$value/i) {
				push @slots, $i;
				$found = 1 and last;
			    }
			}			
		    } else {
			if (_get_datum_info($input_datum, $field) =~ /$value/i) {
			    push @slots, $i;
			    $found = 1 and last;
			}
		    }
		}
	    }
	    if ($direction eq 'output') {
		for my $output_datum_cache ($applied_protocol->get_output_data()) {
		    #API changed!
		    my $output_datum = $output_datum_cache->get_object();
		    if ($isattr) {
			for my $attr_cache ($output_datum->get_attributes()) {
			    my $attr = $attr_cache->get_object;
			    if (_get_attr_value($attr, $field, $fieldtext) =~ /$value/i) {
				push @slots, $i;
				$found = 1 and last;
			    }
			}			
		    } else {
			if (_get_datum_info($output_datum, $field) =~ /$value/i) {
			    push @slots, $i;
			    $found = 1 and last;
			}
		    }
		}
	    }
	}
	$found = 0;
    }
    return @slots;
}

sub _get_data_by_info {#this could go into a subclass of experiment
    my ($aps, $direction, $field, $fieldtext) = @_;
    my @data = ();
    for my $ap (@$aps) {
	push @data, @{_get_datum_by_info($ap, $direction, $field, $fieldtext)};
    }
    return \@data;
}

sub _get_datum_by_info {#this could go into a subclass of experiment
    my ($ap, $direction, $field, $fieldtext) = @_;
    my @data = ();

    if ($direction eq 'input') {
	for my $datum_cache ($ap->get_input_data()) {
	    #API changed!
	    my $datum = $datum_cache->get_object();
	    if ($field eq 'name') {push @data, $datum_cache if $datum->get_name() =~ /$fieldtext/i;}
	    if ($field eq 'heading') {push @data, $datum_cache if $datum->get_heading() =~ /$fieldtext/i;}	    
	}
    }
    if ($direction eq 'output') {
	for my $datum_cache ($ap->get_output_data()) {
	    #API changed!
	    my $datum = $datum_cache->get_object();
	    if ($field eq 'name') {push @data, $datum_cache if $datum->get_name() =~ /$fieldtext/i;}
	    if ($field eq 'heading') {push @data, $datum_cache if $datum->get_heading() =~ /$fieldtext/i;}
	}
    }
    return \@data;
}

sub _get_attr_by_info {
    my ($obj, $field, $fieldtext) = @_;
    my @attributes = ();
    my $func = "get_$field";
    #API changed! for my $attr (@{$obj->get_attributes()}) {
    for my $attr_cache ($obj->get_object()->get_attributes()) {
	my $attr = $attr_cache->get_object;
	push @attributes, $attr if $attr->$func() =~ /$fieldtext/i;
    }
    return \@attributes;
}


sub _get_protocol_info {#this could go to protocol.pm
    my ($protocol, $field) = @_;
    my $func = "get_$field";
    return $protocol->$func();
#    return $protocol->get_name() if $field eq 'name';
#    return $protocol->get_version() if $field eq 'version';
#    return $protocol->get_description() if $field eq 'description';
}

sub _get_datum_info {#this could go to data.pm
    my ($datum, $field) = @_;
    return $datum->get_name() if $field eq 'name';
    return $datum->get_heading() if $field eq 'heading';
    return $datum->get_type()->get_object->get_name() if $field eq 'type';
    return $datum->get_termsource()->get_object->get_db()->get_object->get_name() . ":" . $datum->get_termsource()->get_object->get_accession() if $field eq 'dbxref';
}

sub _get_datum_value {#this could go to data.pm
    my ($datum, $field, $fieldtext) = @_;
    return $datum->get_value() if (($field eq 'name') && ($datum->get_name() =~ /$fieldtext/i));
    return $datum->get_value() if (($field eq 'heading') && ($datum->get_heading() =~ /$fieldtext/i)); 
    return undef;
}

sub _get_attr_info {
    my ($attr_cache, $field) = @_;
    #API changed!
    my $attr = $attr_cache->get_object();
    return $attr->get_name() if $field eq 'name';
    return $attr->get_heading() if $field eq 'heading';
    return $attr->get_type()->get_name() if $field eq 'type';
    return $attr->get_termsource()->get_db()->get_name() . "|" . $attr->get_termsource()->get_accession() if $field eq 'dbxref';
}

sub _get_attr_value {#this could go to attibute.pm
    my ($attr, $field, $fieldtext) = @_;
    return $attr->get_value() if (($field eq 'name') && ($attr->get_name() =~ /$fieldtext/i));
    return $attr->get_value() if (($field eq 'heading') && ($attr->get_heading() =~ /$fieldtext/i));
    return undef;
}


1;
