#!/usr/bin/perl
use strict;
use warnings;

my %search_results;
my %search_list=(
	'sega' => [ 'buy','free' ],
	'nintendo' => [ 'buy','free' ],
	'tv stand' => [ 'free' ],
	'kayak' => [ 'buy','free' ],
	'road bike' => [ 'buy' ],
	'book shelf' => [ 'buy','free' ],
	'tool box' => [ 'buy','free' ],
#	'norwood' => [ 'housing' ],
);

my %search_type=(
	'buy' => { 
		'item_start_tag' => '\<p\>',
		'item_end_tag' => '\<\/p\>',
		'search_url' => 'http://boston.craigslist.org/search/?areaID=4&subAreaID=&query=QUERY&catAbb=sss',
	 },
	'housing' => { 
		'item_start_tag' => '<p>',
		'item_end_tag' => '\<\/p\>',
		'search_url' => 'http://boston.craigslist.org/search/aap?query=QUERY&srchType=A&minAsk=&maxAsk=1350&bedrooms=2&addTwo=purrr',
	 },
	'free' => { 
		'item_start_tag' => '<p>',
		'item_end_tag' => '\<\/p\>',
		'search_url' => 'http://boston.craigslist.org/search/zip?query=QUERY&srchType=A&minAsk=&maxAsk=',
	 },
);

my $output_file="/tmp/clresults";
my $recipient="chase1124\@gmail.com";
my $recipient="kurt2439\@aol.com";
my $extra_recipient="";
my $tracking_file="/tmp/database";
my $error_file="/tmp/cl2.log";
my $tmp_location="/tmp/";
my $email_recipient="chase1124\@gmail.com";
my @processed_results;

#Vary the level of debugging...
my $debug=1;
#my $debug=2;

my $new_counter=0;
my $bad_counter=0;
my $del_counter=0;

#Open file for logging
unless (-e $error_file){ system("touch $error_file")};
open(my $err_log,">>","$error_file") or die "Could not open error log: $!";

#Fill up the processed_results variable
sub load_database{	
	my $database_file=shift;
	my @previous_result_ids;
	open(my $dfh, "<", "$database_file") or die "Could not open database file for reading: $!";
	while (my $result_id = <$dfh>){
		push(@previous_result_ids,$result_id)
	}
	close($dfh);
	return @previous_result_ids;
}

print "Previously Processed Links: \n@processed_results\n\n" if ($debug>1);

#Open file for appending
sub open_file_append{
	my $file=shift;
	open(my $fh, ">>", "$file") or die "Could not open file for appending: $!";
	return $fh;
}

#Open file for clobber write 
sub open_file_clobber{
	my $file=shift;
	open(my $fh, ">", "$file") or die "Could not open file for writing (clobber): $!";
	return $fh;
}

#Open file for read
sub open_file_read{
	my $file=shift;
	open(my $fh, "<", "$file") or die "Could not open file for reading: $!";
	return $fh;
}

#Now go through the list of items to search through and try and find links
#But don't report any links that have been emailed in the past (processed)
foreach my $query (keys %search_list){
	#For the search to work, spaces in the query should be converted to '+' characters	
	my $formatted_query=$query;
	$formatted_query=~s/\s/+/g;

	print "Query: $query\n" if $debug;
	my $type_array_ref=$search_list{$query};
	foreach my $type (@$type_array_ref){
		print "\tType: $type\n" if $debug;
		print "\tStart Tag: $search_type{$type}->{item_start_tag}\n" if ($debug>1);
		#A unique search output file for each search, for debugging purposes if there is an issue
		my $search_output_file=$output_file."-".$formatted_query;
		
		#OK, now do the search and save the results in a file	
		do_search($formatted_query,$search_type{$type}->{search_url},$search_output_file);
	
		#Open the search file and pull out a block of html with the results	
		my $saved_search_handle=open_file_read($search_output_file);
		my @search_result_html_block=parse_search_results($saved_search_handle);

		print "\nHTML BLOCK: @search_result_html_block\n" if ($debug>1);
		my $results_hash=parse_html_block(\@search_result_html_block);
		
		#No need to process any results or display nonsense if there are no results...next query
		if (grep(/Nothing found for that search/,@$results_hash)) { print "NO RESULTS FOUND\n" if $debug; next; }
		#Else (implicityly) continue on to parse the results
		
		#Open the database of previous results to make sure we aren't processing already reported links
		my $hash_file="$query-$type";
		open(my $hash_write_handle,">>","$tmp_location$hash_file") or die "Could not open hash write handle: $!";
		open(my $hash_read_handle,"<","$tmp_location$hash_file") or die "Could not open hash write handle: $!";
		my $hash_array=get_hash_array($hash_read_handle);

		foreach my $result (@$results_hash){
			my $hash=hash_it($result);
			if (result_hash_match($hash,$hash_array)){
				next;
			}
			$search_results{$query}{$hash}=parse_result($result);
			print "IMG: $search_results{$query}{$hash}{img}\n" if ($debug && defined $search_results{$query}{$hash}{img});
			print "URL: $search_results{$query}{$hash}{url}\n" if ($debug && defined $search_results{$query}{$hash}{url});
			print "SUBJECT: $search_results{$query}{$hash}{subject}\n" if ($debug && defined $search_results{$query}{$hash}{subject});
			print "TOWN: $search_results{$query}{$hash}{town}\n" if ($debug && defined $search_results{$query}{$hash}{town});
			print "DATE: $search_results{$query}{$hash}{date}\n" if ($debug && defined $search_results{$query}{$hash}{town});
			print $hash_write_handle "$hash\n";
		}
	}
}

#Now go through the results:
foreach my $query (keys %search_list){
	print $query."\n";
	my $hashhack=$search_results{$query};

	#Skip any blank results
	if ( ! defined $hashhack ){ next }
	
	#Open a mail process
	open(SENDMAIL, "|/usr/lib/sendmail -oi -t")
#	open(SENDMAIL, ">","/tmp/${query}-mail.txt")
		or die "Can't fork for sendmail: $!\n";
	#Print formatting lines for the e-mail	
	print SENDMAIL "From: Craigslist Finder <jchase\@thinkpad.local>\n";
	print SENDMAIL "To: James Chase <$email_recipient>\n";
	print SENDMAIL "Subject: $query\n";
	print SENDMAIL "Content-Type: text/html; charset=ISO-8859-1\n";
	print SENDMAIL "Content-Transfer-Encoding: quoted-printable\n";

	#Print out the search results via email of each of the found results
	foreach my $hash (keys %$hashhack){
		my $hashhack_two=$$hashhack{$hash};
		print SENDMAIL "<p>";
		print SENDMAIL "<div><img src=3D\"http://images.craigslist.org/$search_results{$query}{$hash}{img}\" alt=3D\"$search_results{$query}{$hash}{img}\" title=3D\"$search_results{$query}{$hash}{img}\"><br clear=3D\"all\"><br clear=3D\"all\"></div>" if defined $search_results{$query}{$hash}{img};
		print SENDMAIL "<div>PRICE: $$hashhack_two{price}</div>" if defined $$hashhack_two{price};
		print SENDMAIL "<div>SUBJECT: $$hashhack_two{subject}</div>" if defined $$hashhack_two{subject};
#		print SENDMAIL "SUBJECT: $search_results{$query}{$hash}{subject}\n" if defined $search_results{$query}{subject};
		print SENDMAIL "<div>TOWN: $$hashhack_two{town}</div>" if defined $$hashhack_two{town};
#		print SENDMAIL "TOWN: $search_results{$query}{$hash}{town}\n" if defined $search_results{$query}{town};
		print SENDMAIL "<div>DATE: $search_results{$query}{$hash}{date}</div>" if defined $search_results{$query}{$hash}{date};
		print SENDMAIL "<div>URL: $search_results{$query}{$hash}{url}Take me to your leader</a></div>\n" if defined $search_results{$query}{$hash}{url};
		print SENDMAIL "</p>";
	}
	close(SENDMAIL)     or warn "sendmail didn't close nicely";
}
exit;

sub do_search{
	my $query=shift;
	my $search_url=shift;
	my $search_output_file=shift;
	
	#Replace the string holder QUERY with the actual query i nthe url	
	$search_url=~s/QUERY/$query/;
	system("wget","-q","-O","$search_output_file","$search_url");
}

sub get_hash_array{
	my $hash_read_handle=shift;
	my @hash_array;
	while(my $entry=readline($hash_read_handle)){
		chomp($entry);
		push(@hash_array,$entry);
	}
	return \@hash_array;
}

sub hash_it{
	my $result=shift;
	my $hash;
	while ($result=~/(.)/g){
		$hash.=ord($1);	
	}
	return $hash;
}

sub parse_html_block{
	my $html_array=shift;
	my $result_array;
	my $num=0;
	foreach my $line (@$html_array){
		next unless defined $line;
		if ($line =~ /\<\/p\>/){
			$line =~ /(.*?\<\/p\>)(.*)/;
			$result_array->[$num].=$1;
			$num++;
		}else{
			$result_array->[$num].=$line;
		}
	}
	
	return $result_array;
}

sub parse_result{
	my $result=shift;
	my %result_hash;
	if ($result=~m/id\=\"images\:(.*?\.jpg)\"/){
		$result_hash{img}=$1;
	}
	if ($result=~m/\<\/span\>(.*?)\-/s){
		$result_hash{date}=$1;
		$result_hash{date}=~s/^\s+//s;
	}
	if ($result=~m/(\<a href\=.*?\>)/){
		$result_hash{url}=$1;
	}
	if ($result=~m/\<a href\=.*?\>(.*?)\-\<\/a\>/){
		$result_hash{subject}=$1;
	}
	if ($result=~m/(\$.*?)\<font.*?\>/){
		$result_hash{price}=$1;
	}
	if ($result=~m/\<font.*?\>(.*?)\<\/font\>/){
		$result_hash{town}=$1;
		$result_hash{town}=~s/\(|\)//g;
	}
	return \%result_hash;
}

sub parse_search_results{
	my $saved_search_handle=shift;
	my @html_block;
	while (my $line = <$saved_search_handle>){
		last if $line =~ /sphinx/;
	}
	
	while (my $line = <$saved_search_handle>){
		if ($line =~ /\<div\>/){
			$line=~s/\<div\>.*$//;
			push(@html_block,$line);
			last;
		}
		next if $line =~/^$/;
		push(@html_block,$line);
	}	
	return @html_block;
}

sub result_hash_match{
	chomp(my $hash=shift);
	my $hash_array_ref=shift;
	foreach my $hash_try (@$hash_array_ref){	
		if ($hash=~/^$hash_try$/){
			print "Hash match!\n" if $debug;
			return 1;
		}
	}
	print "hash not matched\n" if $debug;
	return 0;
}