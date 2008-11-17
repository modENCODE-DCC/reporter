package AE::Reporter;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;

sub report {
    #wrapper for all functions
}

sub write_idf {
    #input a ModENCODE::Chado::Experiment obj, a filehandle writable for IDF
    my ($self, $experiment, $idf, $rel_sdrf) = @_;
    open my $idfh, '>', $idf or croak "can't open $idf";
    my %people = ();
    my $num_of_people = 0; 
    undef my $termsources;

    foreach my $property (@{$experiment->get_properties()}) {
	my ($name, $value, $type, $rank, $termsource) = ($property->get_name(),
							 $property->get_value(),
							 $property->get_type(),
							 $property->get_rank(),
							 $property->get_termsource());

	if ($name eq 'Investigation Title' || 
	    $name eq 'Experimental Design' ||
	    $name eq 'Experimental Factor Name' ||
	    $name eq 'Experimental Factor Type' ||
	    $name eq 'Project Group' ||
	    $name eq 'Project Subgroup' ||
	    $name eq 'Quality Control Type' ||
	    $name eq 'Replicate Type' ||
	    $name eq 'Date of Experiment' ||
	    $name eq 'Public Release Date' ||
	    $name eq 'PubMed ID' ||
	    $name eq 'Project URL') {
	    #unless Experimental Factor; Quality Control Type; 
	    #Replicate Type; PubMed ID have multiple entries
	    #which is highly unlikely for ModENCODE projects.
	    print $idfh join("\t", ($name, $value));
	    print $idfh "\n";
	    #print term source ref row
	    my $cv = $type->get_cv()->to_string();
	    if ($cv ne 'xsd') {
		$name =~ s/\s+Type\s?$//;
		my $title = $name . " Term Source REF";
		my $db = $termsource->get_db()->get_name();
		print $idfh join("\t", ($title, $db));
		print $idfh "\n";
	    }	    
	}
	if ($name =~ /^Person/) {
	    $people{$name}{$rank} = [$value, $type, $termsource];
	    if ($rank > $num_of_people) {$num_of_people = $rank}
	}
    }

    my @q = ("Person Last Name",
	     "Person First Name",
	     "Person Mid Initials",
	     "Person Email",
	     "Person Phone",
	     "Person Address",
	     "Person Affiliation",
	     "Person Roles");
    for my $name (@q) {
	my $str = $name;
	my $cv_sign = 0;
	my $str_termsource = $name . " Term Source REF";
	if (defined($people{$name})) {
	    for my $rank (0 .. $num_of_people) {
		if (defined($people{$name}{$rank})) {
		    my ($value, $type, $termsource) = @{$people{$name}{$rank}};
		    $str .= "\t". $value;
		    my $cv = $type->get_cv()->to_string();
		    if ($cv ne 'xsd') {
			$cv_sign = 1;
			my $db = $termsource->get_db()->get_name();
			$str_termsource .= "\t" . $db;
		    }
		} else {
		    $str .= "\t";
		}
	    }
	} else {
	    for my $rank (0 .. $num_of_people) {$str .= "\t"} 
	}
	print $idfh $str, "\n";
	print $idfh $str_termsource, "\n" if $cv_sign;
    }

    my @protocol_names = ('Protocol Name');
    my @protocol_types = ();
    my @protocol_type_termsourcerefs = ();
    my @protocol_parameters = ();

    for my $applied_protocol_slot (@{$experiment->get_applied_protocol_slots()}) {
	my $applied_protocol = ${$applied_protocol_slot}[0];
	my $protocol = $applied_protocol->get_protocol();
	my $input_data = $applied_protocol->get_input_data();

	my @this_protocol_types = ();
	my @this_protocol_type_termsourcerefs = ();
	my @this_protocol_parameters = ();

	push @protocol_names, $protocol->get_name();

	for my $attribute (@{$protocol->get_attributes()}) {
	    #don't think rank is important here
	    if ($attribute->get_heading() eq 'Protocol Type') {
		my $db = $attribute->get_termsource()->get_db()->get_name();
		push @this_protocol_types, join(':', ($db, $attribute->get_value()));
		push @this_protocol_type_termsourcerefs, $db;
	    }
	}
	push @protocol_types, \@this_protocol_types;
	push @protocol_type_termsourcerefs, \@this_protocol_type_termsourcerefs;

	for my $input_datum (@$input_data) {
	    if ($input_datum->get_heading() eq 'Parameter Value') {
		my $parameter_name = $input_datum->get_name();
		
		#I still suspect we need to report in the form of namespace:cvterm [alias]
		#although validated idf only contains alias
		my $parameter_type = $input_datum->get_type();
		my ($parameter_cv, $parameter_cvterm) = ($parameter_type->get_cv()->get_name(),
							 $parameter_type->get_name());
		my $str_this_protocol_parameter = $parameter_cv . ":" . $parameter_cvterm . " [" . $parameter_name . "]";
		push @this_protocol_parameters, $str_this_protocol_parameter;
	    }
	}
	push @protocol_parameters, \@this_protocol_parameters;
    }
    
    print $idfh join("\t", @protocol_names), "\n";

    my $str_types = "Protocol Type\t";
    for my $this_protocol_types (@protocol_types) {
	my $str_this_protocol_type = '';
	for my $this_protocol_type (@{$this_protocol_types}) {
	    $str_this_protocol_type .= $this_protocol_type . ";";
	}
	#remove the last semi colon
	$str_this_protocol_type = substr($str_this_protocol_type, 0, -1);
	$str_types .= $str_this_protocol_type . "\t";
    }
    print $idfh $str_types, "\n";

    my $str_parameters = "Protocol Parameters\t";
    for my $this_protocol_parameters (@protocol_parameters) {
	my $str_this_protocol_parameters = '';
	if (scalar @{$this_protocol_parameters}) {
	    for my $this_protocol_parameter (@{$this_protocol_parameters}) {
	      $str_this_protocol_parameters .= $this_protocol_parameter . ";";
	    }
	    #remove the last semi colon
	    $str_this_protocol_parameters = substr($str_this_protocol_parameters, 0, -1);
	}
	$str_parameters .= $str_this_protocol_parameters . "\t";	
    }
    print $idfh $str_parameters, "\n";    

    print $idfh join("\t",('SDRF File', $rel_sdrf)), "\n";


    my $termsources = $self->_get_all_termsources($experiment);
    
    my ($str_termsourcename, $str_termsourcefile, $str_termsourceversion, $str_termsourcetype) = ("Term Source Name",
												  "Term Source File",
												  "Term Source Version", 
												  "Term Source Type");
    for my $this_termsource (@$termsources) {
	my ($ts_name, $ts_file, $ts_version, $ts_type) = @$this_termsource;
	$str_termsourcename .= "\t" . $ts_name;
	$str_termsourcefile .= "\t" . $ts_file;
	$str_termsourceversion .= "\t" . $ts_version;
	$str_termsourcetype .= "\t" . $ts_type;
    }
    print $idfh $str_termsourcename, "\n";
    print $idfh $str_termsourcefile, "\n";
    print $idfh $str_termsourceversion, "\n";
    print $idfh $str_termsourcetype, "\n";
    close($idfh);
}

sub _get_all_termsources :PRIVATE {
    my ($self, $experiment) = @_;
    undef my $termsources;
    my $compare_version = 0;

    foreach my $property (@{$experiment->get_properties()}) {
	my $termsourceref = $property->get_termsource();
	$termsources = $self->_update_termsources($termsources, $termsourceref, $compare_version) if $termsourceref;
    }

    for my $applied_protocol_slot (@{$experiment->get_applied_protocol_slots()}) {
	my $applied_protocol = ${$applied_protocol_slot}[0];
	my $protocol = $applied_protocol->get_protocol();
	for my $attribute (@{$protocol->get_attributes()}) {
	    if ($attribute->get_termsource()) {
		$termsources = $self->_update_termsources($termsources, $attribute->get_termsource(), $compare_version);
	    }
	}
	
	my $input_data = $applied_protocol->get_input_data();	
	for my $input_datum (@$input_data) {
	    $termsources = $self->_update_termsources($termsources, 
						      $input_datum->get_type()->get_dbxref(), 
						      $compare_version);
	    for my $attribute (@{$input_datum->get_attributes()}) {
		if ($attribute->get_termsource()) {
		    $termsources = $self->_update_termsources($termsources, 
							      $attribute->get_termsource(),
							      $compare_version);
		}		
	    }
	}

	my $output_data = $applied_protocol->get_output_data();	
	for my $output_datum (@$output_data) {
	    $termsources = $self->_update_termsources($termsources, 
						      $output_datum->get_type()->get_dbxref(),
						      $compare_version);
	    for my $attribute (@{$output_datum->get_attributes()}) {
		if ($attribute->get_termsource()) {
		    $termsources = $self->_update_termsources($termsources, 
							      $attribute->get_termsource(),
							      $compare_version);	
		}
	    }
	}
    }    
    return $termsources;
}


sub _update_termsources :PRIVATE {
    my ($self, $termsources, $this_termsourceref, $compare_version) = @_;
    my ($this_dbname, $this_dbfile, $this_dbversion, $this_dbtype)= ($this_termsourceref->get_db()->get_name(),
								     $this_termsourceref->get_db()->get_url(),
								     $this_termsourceref->get_version(),
								     $this_termsourceref->get_db()->get_description());
    if (defined $termsources) {
	for my $termsource (@$termsources) {
	    my ($dbname, undef, $dbversion, undef) = @$termsource;
	    if ($compare_version) {
		return $termsources if $this_dbname eq $dbname && $this_dbversion eq $dbversion;
	    } else {
		return $termsources if $this_dbname eq $dbname;
	    }
	}
    }
    push @$termsources, [$this_dbname, $this_dbfile, $this_dbversion, $this_dbtype];
    return $termsources;
}

sub write_sdrf {
    my ($self, $reader, $sdrf) = @_;
    open my $sdrfh, ">", $sdrf or croak "can't open $sdrf";
    #treat all data as input, either a real input of a protocol or a output of a protocol
    #yet is an input to the next protocol;
    #hand-written sdrf has Source/Sample/Extract Name at the left to the protocol,
    #yet has Hybridization/Normalization Name at the right.
    my @input_to_left_of_protocol = ('Source', 'Sample', 'Extract', 'Data', 'Result');
    #omit all expanded dbfields in sdrf heading.
    my @allowed_attribute_headings = ("Characteristics", "Comment", "Unit", "Factor");

    my $denorm_slots = $reader->get_full_denormalized_protocol_slots();
    my @headers= ();
    my @matrix = ();
    my $k = 0; #trace total number of headers
    for my $denorm_protocol_slot (@$denorm_slots) {
	my $header_already_written = 0; #1 for header already written
	for (my $j=0; $j<scalar(@$denorm_protocol_slot); $j++) { 
	    my $ap = $denorm_protocol_slot->[$j]->{'applied_protocol'};
	    my $i = 0; #trace headers for this protocol
	    for my $input_datum ($self->mged_data_sort($ap->get_input_data())) {
		my $heading = $input_datum->get_heading();
		if (scalar(grep {$heading =~ /$_/} @input_to_left_of_protocol)) {
		    $i = $self->_write_datum($input_datum, \@headers, \@matrix, $i, $j, $k,
					     $header_already_written, \@allowed_attribute_headings);
		}
	    }
	    
	    $i = $self->_write_protocol($ap, \@headers, \@matrix, $i, $j, $k, 
					$header_already_written, \@allowed_attribute_headings);
	    
	    for my $input_datum ($self->mged_data_sort($ap->get_input_data())) {
		my $heading = $input_datum->get_heading();
		next if $heading =~ /Anonymous Datum/;
		if (!scalar(grep {$heading =~ /$_/} @input_to_left_of_protocol)) {
		    $i = $self->_write_datum($input_datum, \@headers, \@matrix, $i, $j, $k, 
					     $header_already_written, \@allowed_attribute_headings);
		}
	    }
	    $header_already_written = 1;
	}
	$k = scalar @headers;
    }
    #get output of the last protocol
    my $last_header_already_written = 0;
    my $j = 0;
    for my $denorm_protocol (@{$denorm_slots[-1]}) {
	my $ap = $denorm_protocol->{'applied_protocol'};
	my $i = 0;
	for my $output_datum ($self->mged_data_sort($ap->get_output_data())) {
	    $i = $self->_write_datum($output_datum, \@headers, \@matrix, $i, $j, $k, 
				     $last_header_already_written, \@allowed_attribute_headings);
	}
	$last_header_already_written = 1;
	$j++;
    }

    print $sdrfh join("\t", @headers), "\n";
    #remove redundant rows since visible sdrf is a simplified sdrf (with many possible dbfields columns removed.
    for my $row (@matrix) {
	print $sdrfh join("\t", @$row), "\n";
    }
    close($sdrfh);
}

sub _write_protocol :PRIVATE {
    my ($self, $ap, $headers, $matrix, $i, $j, $k, $header_already_written, $allowed_attribute_headings) = @_;    
    push @$headers, "Protocol REF" unless $header_already_written;
    $matrix->[$j]->[$i+$k] = $ap->get_protocol()->get_name(), "\n";
    $i++;
    for my $attribute (@{$ap->get_protocol()->get_attributes()}) {
	my $heading = $attribute->get_heading();
	$heading .= ' [' . $attribute->get_name() . ']' if $attribute->get_name();
	if (scalar(grep {$heading =~ /$_/} @$allowed_attribute_headings)) {
	    my ($attr_heading, $attr_value) = $self->_write_attribute($attribute);
	    push @$headers, @$attr_heading unless $header_already_written;
	    for (my $l=0; $l<scalar @$attr_value; $l++) {
		$matrix->[$j]->[$i+$k+$l] = $attr_value->[$l];
	    }
	    $i += scalar @$attr_heading;
	}
    }    
    return $i;
}

sub _write_datum :PRIVATE {
    my ($self, $datum, $headers, $matrix, $i, $j, $k, $header_already_written, $allowed_attribute_headings) = @_;
    my $heading = $datum->get_heading();
    $heading .= ' [' . $datum->get_name() . ']' if $datum->get_name();
    push @$headers, $heading unless $header_already_written;
    $matrix->[$j]->[$i+$k] = $datum->get_value();
    $i++;
    if ($datum->get_termsource()) {
	push @$headers, "Term Source REF" unless $header_already_written;
	$matrix->[$j]->[$i+$k] = $datum->get_termsource()->get_db()->get_name();	
	$i++;
    }
    if ($datum->get_value() eq '' && $datum->get_type()->get_cv()->get_name() ne 'xsd') {
	push @$headers, "Term Source REF" unless $header_already_written;
	$matrix->[$j]->[$i+$k] = '';
	$i++;
    }
    for my $attribute (@{$datum->get_attributes()}) {
	my $heading = $attribute->get_heading();
	$heading .= ' [' . $attribute->get_name() . ']' if $attribute->get_name();
	if (scalar(grep {$heading =~ /$_/} @$allowed_attribute_headings)) {
	    my ($attr_heading, $attr_value) = $self->_write_attribute($attribute);
	    push @$headers, @$attr_heading unless $header_already_written;
	    for (my $l=0; $l<scalar @$attr_value; $l++) {
		$matrix->[$j]->[$i+$k+$l] = $attr_value->[$l];
	    }
	    $i += scalar @$attr_heading;
	}
    }
    return $i;
}

sub _write_attribute :PRIVATE {
    my ($self, $attribute) = @_;
    my @headers = ();
    my @values = ();
    my $heading = $attribute->get_heading();
    $heading .= ' [' . $attribute->get_name() . ']' if $attribute->get_name();
    push @headers, $heading;
    push @values, $attribute->get_value();
    if ($attribute->get_termsource()) {
	push @headers, "Term Source REF";
	push @values,  $attribute->get_termsource()->get_db()->get_name();
    }
    #trick, add term source ref, check sdrf later to see this column has any value in any cell
    #this solves the problem that the first protocol may not contain blank term source ref columns
    if ($attribute->get_value() eq '' && $attribute->get_type()->get_cv()->get_name() ne 'xsd') {
	#this is a column contains cvterm in the header, thus need a term source ref
	#but the value is NULL,
	push @headers, "Term Source REF";
	push @values, '';
    }
    return (\@headers, \@values);
}

sub mged_data_sort {
    my ($self, $data) = @_;
    my @non_name_data = grep {$_->get_heading() !~ /Name/i} @$data;
    my @name_data = grep {$_->get_heading() =~ /Name/i} @$data;
    sort mged_data_order @non_name_data;
    return @non_name_data unless scalar @name_data;
    return (@non_name_data, @name_data);
}

sub mged_data_order :PRIVATE {
    my $aheading = $a->get_heading();
    $aheading .= ' [' . $a->get_name() . ']' if $a->get_name();
    my $bheading = $b->get_heading();
    $bheading .= ' [' . $b->get_name() . ']' if $b->get_name();
    $aheading cmp $bheading;    
}
    
sub write_data {
    #take an arrayref to data
}

1;
