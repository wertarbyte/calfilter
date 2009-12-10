#!/usr/bin/perl
#
# calfilter.pl by Stefan Tomanek <stefan.tomanek@wertarbyte.de>

use utf8;
use CGI;
use Data::ICal;
use LWP::Simple;
use DateTime;

my $q = new CGI();

my $url = $q->param("url");
my $regex = ($q->param("regex") || '');
my $name = ($q->param("name") || '');
my $tzoffset = 0;
if (defined $q->param("tzoffset") && $q->param("tzoffset") =~ /^[+-]?[0-9]+$/) {
    $tzoffset += $q->param("tzoffset");
}

sub add_offset {
    my ($timestring, $offset) = @_;
    if ($timestring =~ /^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})([0-9]{2})$/) {
        my $dt = DateTime->new( year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6 );
        $dt = $dt->add( minutes => $offset );

        return $dt->strftime('%Y%m%dT%H%M%S');
    }
    return $timestring;
}

sub change_tz_entry {
    my ($e, $key, $offset) = @_;
    my $p = $e->property($key)->[0];
    my $new = add_offset($p->decoded_value(), $tzoffset);
    $p->value($new);
}

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
            change_tz_entry( $e, "DTSTART", $tzoffset);
            change_tz_entry( $e, "DTEND", $tzoffset);
            
            $ncal->add_entry($e);
        }
    }
    print $ncal->as_string;
} else {
    print $q->header("text/plain");

    print "Invalid calendar URL or data!\n";
}
