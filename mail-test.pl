#!/usr/bin/perl
use strict;
use warnings;
use Net::SMTP::SSL;
#send_authenticated_mail
#Arguments: mailhost, sender, recipient, username, password, subject, body
#All arguments are scalar variables, no lists allowed currently
sub send_authenticated_mail{
	my $mailhost=shift;
	my $sender=shift;
	my $recipient=shift;
	my $username=shift;
	my $password=shift;

	#Open a mail process
	my $smtps=Net::SMTP::SSL->new(
		"$mailhost",
		'Port' => '465',
		'Debug' => '0',
		);
	unless ($smtps) {die "Could not connect to server\n"}

	$smtps->auth("$username","$password") or die "Authentication failed\n";

	$smtps->mail($sender.'\n');
	$smtps->to("$recipient");

	$smtps->data();
    	$smtps->datasend("From: $sender\n");
    	$smtps->datasend("To: $recipient\n");
    	$smtps->datasend("Subject: $subject\n");
    	$smtps->datasend("\n");
    	$smtps->datasend("$body\n");
    	$smtps->dataend();
    	$smtps->quit;
}
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
