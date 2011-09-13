#!/usr/bin/perl
use strict;
use warnings;
use Net::SMTP;

my $mailhost='mail.mandala-designs.com';
my $recipient='chase1124@gmail.com';

#Open a mail process
my $smtp=Net::SMTP->new(
	'mailhost' => '$mailhost',
	);

$smtp->auth('jchase@shambhala.com','chase02052');
$smtp->mail($ENV{USER});
$smtp->to("$recipient");

$smtp->data();
    $smtp->datasend("To: James Chase\n");
    $smtp->datasend("\n");
    $smtp->datasend("A simple test message\n");
    $smtp->dataend();
    $smtp->quit;
#Print formatting lines for the e-mail	
#print SENDMAIL "From: Craigslist Finder <jchase\@thinkpad.local>\n";
#print SENDMAIL "To: James Chase <$email_recipient>\n";
#print SENDMAIL "Subject: $query\n";
#print SENDMAIL "Content-Type: text/html; charset=ISO-8859-1\n";
#print SENDMAIL "Content-Transfer-Encoding: quoted-printable\n";

#Print out the search results via email of each of the found results
#	print SENDMAIL "<p>";
#	print SENDMAIL "<div><img src=3D\"http://images.craigslist.org/$search_results{$query}{$hash}{img}\" alt=3D\"$search_results{$query}{$hash}{img}\" title=3D\"$search_results{$query}{$hash}{img}\"><br clear=3D\"all\"><br clear=3D\"all\"></div>" if defined $search_results{$query}{$hash}{img};
#	print SENDMAIL "<div>PRICE: $$hashhack_two{price}</div>" if defined $$hashhack_two{price};
#	print SENDMAIL "<div>SUBJECT: $$hashhack_two{subject}</div>" if defined $$hashhack_two{subject};
#	print SENDMAIL "SUBJECT: $search_results{$query}{$hash}{subject}\n" if defined $search_results{$query}{subject};
#	print SENDMAIL "<div>TOWN: $$hashhack_two{town}</div>" if defined $$hashhack_two{town};
#	print SENDMAIL "TOWN: $search_results{$query}{$hash}{town}\n" if defined $search_results{$query}{town};
#	print SENDMAIL "<div>DATE: $search_results{$query}{$hash}{date}</div>" if defined $search_results{$query}{$hash}{date};
#	print SENDMAIL "<div>URL: $search_results{$query}{$hash}{url}Take me to your leader</a></div>\n" if defined $search_results{$query}{$hash}{url};
#	print SENDMAIL "</p>";

#	close(SENDMAIL)     or warn "sendmail didn't close nicely";
