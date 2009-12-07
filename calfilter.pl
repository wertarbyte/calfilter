#!/usr/bin/perl
#
# calfilter.pl by Stefan Tomanek <stefan.tomanek@wertarbyte.de>

use CGI;
use Data::ICal;
use LWP::Simple;

my $q = new CGI();

my $url = $q->param("url");
my $regex = ($q->param("regex") || '');
my $name = ($q->param("name") || '');

my $data = get($url);

my $ocal = Data::ICal->new(data => $data);

if ($ocal) {
    print $q->header("text/calendar");

    # create new calendar
    my $ncal = new Data::ICal();
    $ncal->add_property( 'PRODID', 'calfilter.pl' );
    $ncal->add_property( 'X-WR-CALDESC', $name );
    
    for my $e (@{$ocal->entries}) {
        if ($e->property('SUMMARY')->[0]->as_string =~ $regex) {
            $ncal->add_entry($e);
        }
    }
    print $ncal->as_string;
} else {
    print $q->header("text/plain");

    print "Invalid calendar URL or data!\n";
}
