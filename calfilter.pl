#!/usr/bin/perl
#
# calfilter.pl by Stefan Tomanek <stefan.tomanek@wertarbyte.de>

use strict;
use utf8;
use CGI;
use Data::ICal;
use LWP::Simple;
use DateTime;
use DateTime::TimeZone;

my $q = new CGI();

my $url = $q->param("url");
my $regex = ($q->param("regex") || '');
my $name = ($q->param("name") || '');
my $tz = undef;

if (defined $q->param("tz") && DateTime::TimeZone->is_valid_name( $q->param("tz") )) {
    $tz = DateTime::TimeZone->new( name => $q->param("tz") );
}

my $url_only = $q->param("url_only");

sub add_offset {
    my ($timestring) = @_;
    if ($timestring =~ /^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})([0-9]{2})$/) {
        my $dt = DateTime->new( year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6 );

        my $offset = $tz->offset_for_datetime( $dt );

        $dt = $dt->subtract( seconds => $offset );

        return $dt->strftime('%Y%m%dT%H%M%SZ');
    }
    return $timestring;
}

sub change_tz_entry {
    my ($e, $key) = @_;
    return unless $e->property($key);
    for (@{ $e->property($key) }) {
        my $new = add_offset($_->decoded_value());
        $_->value($new);
    }
}

if ($url_only) {
    print $q->header("text/plain");
    $q->delete('url_only');
    $q->delete('regex') unless defined $regex;
    $q->delete('tz') unless defined $tz;
    print $q->self_url();
} else {
    my $data = get($url);

    my $ocal = Data::ICal->new(data => $data);

    if ($ocal) {
        print $q->header(-type => "text/calendar", -charset => 'utf-8');

        # create new calendar
        my $ncal = new Data::ICal();
        $ncal->add_property( 'PRODID', 'calfilter.pl' );
        $ncal->add_property( 'X-WR-CALDESC', $name );
        
        for my $e (@{$ocal->entries}) {
            if ($e->property('SUMMARY')->[0]->as_string =~ $regex) {
                if ($tz) {
                    change_tz_entry( $e, "DTSTART");
                    change_tz_entry( $e, "DTEND");
                }
                
                $ncal->add_entry($e);
            }
        }
        print $ncal->as_string;
    } else {
        print $q->header("text/plain");

        print "Invalid calendar URL or data!\n";
    }
}
