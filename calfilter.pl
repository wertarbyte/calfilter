#!/usr/bin/perl
#
# calfilter.pl by Stefan Tomanek <stefan.tomanek@wertarbyte.de>

use CGI;
use Data::ICal;
use LWP::Simple;

my $q = new CGI();

my $url = $q->param("url");
my $regex = ($q->param("regex") || '');

my $data = get($url);

my $cal = Data::ICal->new(data => $data);

if ($cal) {
    print $q->header("text/calendar");

    for my $e (@{$cal->entries}) {
        if ($e->property('SUMMARY')->[0]->as_string =~ $regex) {
            print $e->as_string;
        }
    }
} else {
    print $q->header("text/plain");

    print "Invalid calendar URL or data!\n";
}
