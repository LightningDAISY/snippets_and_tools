#! /usr/bin/env perl
use strict;
use warnings;
use threads;
use threads::shared;
use Data::Printer;
use Time::HiRes qw(tv_interval gettimeofday);
use feature qw{say};

# config begin
my $UserLimit = 3;
my $ThreadLimit = 10;
my %FinishedThreads :shared;	# 完了スレッドカウンタ
my $Timeout = 60;				# タイムアウトエラー秒数
# config end

my %Result:shared;
my $ParentPid = $$;

sub timeout
{
	say "Timeout T^T";
	exit;
}

sub aThread
{
    my($i) = @_;
    {
        my $beginSec = [gettimeofday];
        $Result{$$}{$i + 1} = &share({});

        # JOB-BEGIN
        #
        sleep(1);
        #
        # JOB-END
        my $diffSec = tv_interval($beginSec);
        $Result{$$}{$i + 1}{"timeRequired"} = sprintf "%.3fsec", $diffSec;
	}
	$FinishedThreads{$$} += 1;
}

sub createChildren
{
	$Result{$$} ||= &share({});
	for(my $i=0; $i<$ThreadLimit; $i++)
	{
	    my $thread = threads->create(\&aThread, $i);
	    $thread->detach;
	}

}

sub main
{
	if($Timeout)
	{
		local $SIG{ALRM} = \&timeout;
		alarm $Timeout;
	}

	# fork 3 children
	for(my $uno=0; $uno < $UserLimit; $uno++)
	{
		fork and wait if $$ eq $ParentPid;
	}

	# am I forked-chlid?
	if($$ ne $ParentPid)
	{
		$FinishedThreads{$$} ||= 0;
		createChildren();
		my $beginSec = [gettimeofday];
		sleep(1) while($FinishedThreads{$$} < $ThreadLimit);
		my $diffSec = tv_interval($beginSec);
		printf "$$ Total %.3fsec\n", $diffSec;
		p(%Result);
	}
}

main();
1
