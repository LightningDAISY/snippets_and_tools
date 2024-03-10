#! /usr/bin/env perl
use strict;
use warnings;
use AnyEvent;
use AnyEvent::RipeRedis;
use feature qw{ say };

my $expireSeconds = 30;

sub connection
{
	AnyEvent::RipeRedis->new(
		host => '127.0.0.1',
		port => 6379,
	) or die
}

sub removeLock
{
	my($index, $lockName, $value) = @_;
	my $redis = connection();
	my $cv = AE::cv;
	$redis->select($index, sub { $cv->send });
	$cv->recv;
	
	$cv = AE::cv;
	$redis->execute('DEL', $lockName, sub {
		my($reply, $error) = @_;
		$cv->send;
	});
	$cv->recv;
}

sub insertNewLock
{
	my($index, $lockName) = @_;
	my $redis = connection();
	my $cv = AE::cv;
	$redis->select($index, sub { $cv->send });
	$cv->recv;

	my $value = time; #
	my $result;

	$cv = AE::cv;
	$redis->execute('SET', $lockName, $value, 'EX', $expireSeconds, 'NX', sub {
		my($reply, $error) = @_;
		$cv->send($reply);
	});
	$cv->recv
}

sub acceptLock
{
	my($index, $lockName) = @_;
	my $redis = connection();
	my $cv = AE::cv;

	my $str;
	$redis->subscribe('__keyspace@' . $index . '__:' . $lockName, sub {
		my($message, $key) = @_;
		if($message eq 'del')
		{
			say $lockName . ' is unlocked!';
			$redis->quit;
			$cv->send;
		}
		elsif($message eq 'expired')
		{
			say $lockName . ' is expired!';
			$redis->quit;
			$cv->send;
		}
		else
		{
			say 'MESSAGE : ' . $message;
		}
	});
	$cv->recv;
	$lockName
}

sub main
{
	return 1 if insertNewLock(1, 'lock');
	while(acceptLock(1, 'lock'))
	{
		return 1 if insertNewLock(1, 'lock');
	}
}

main;
1

