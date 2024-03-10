#! /usr/bin/env perl
use strict;
use warnings;
use feature qw{ say };

sub aHasB
{
    my($numberA, $numberB) = @_;
    return 0 if $numberA < $numberB;
    my $ored = $numberA | $numberB;
    $ored == $numberA ? 1 : 0
}

for my $pair([5,4], [5,1], [128,4], [127,4], [128,15], [127,15])
{
    say aHasB(@$pair) ? "$pair->[0] has $pair->[1]" : "$pair->[0] has no $pair->[1]";
}

1

__END__
