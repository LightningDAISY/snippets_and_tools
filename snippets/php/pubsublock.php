#! /usr/bin/env php
<?php

$hostname = '127.0.0.1';
$port = 6379;
$expireSeconds = 60;
$propertyLockName;

#
# * : __keyspace@0__:lock1
# * : __keyevent@0__:set
#
# * : __keyspace@0__:lock1
# * : __keyevent@0__:del
#
function unlocked($redis, $channel, $message)
{
	global $propertyLockName;

	$key = '';
	if(preg_match('/^__keyspace@\d+__:' . $propertyLockName . '/', $message))
	{
		print "MESSAGE: key\n";
		$key = $propertyLockName;
	}
	elseif(preg_match('/^__keyevent@\d+__:del/', $message))
	{
		print "MESSAGE: deleted\n";
		$redis->close();
	}
	elseif(preg_match('/^__keyevent@\d+__:expired/', $message))
	{
		print "MESSAGE: expired\n";
		$redis->close();
	}
	else
	{
		print "OTHER MESSAGE : $message\n";
		$key = '';
	}
	return true;
}


function getLock($redis, $index, $name, $value)
{
	if(insertNewLock($redis, $index, $name, $value)) { return true; }

	RETRY:
	$propertyLockName = $name;
	$space  = sprintf('__keyspace@%d__:%s', $index, $name);
	$del    = sprintf('__keyevent@%d__:del', $index);
	$expire = sprintf('__keyevent@%d__:expired', $index);

	$redis = connection();
	$redis->pSubscribe([$space, $del, $expire], 'unlocked');
	print "unlocked!!\n";

	# 仮想割り込み
	#insertNewLock($redis, $index, $name, "warikomi");

	if(insertNewLock($redis, $index, $name, $value))
	{
		print "locked!!\n";
	}
	else
	{
		print "failed\n";
		goto RETRY;
	}
	return true;
}

function insertNewLock($redis, $index, $lockName, $lockValue)
{
	global $expireSeconds;

	$redis = connection();
	$redis->select($index);
	return $redis->set($lockName, $lockValue, ['nx', 'ex' => $expireSeconds]);
}

function connection()
{
	global $hostname;
	global $port;

	$redis = new Redis;
	$redis->connect($hostname, $port);
	return $redis;
}

function main()
{
	$redis = connection();
	$index = 1;
	$lockName = 'EXAMPLE_LOCK';
	$lockValue = time();
	$isLocked = getLock($redis, $index, $lockName, $lockValue);
	print $isLocked ? "completed\n" : "failed...\n";
}

main();

/*
 * 1. このスクリプトをコマンドラインで実行します。
 * 2. たぶん初回はキーEXAMPLE_LOCKが無いので locked!! と言われます。
 * 2. もっかい実行すると、プロンプトが行方不明になります。
 * 3. ターミナルもうひとつ立ち上げます。（60秒以内）
 * 4. redis-cliで接続して、以下の順でコマンドを叩きます。
 *   4-1. SELECT 1
 *   4-1. DEL EXAMPLE_LOCK
 *   4-2. GET EXAMPLE_LOCK
 * 5. スクリプトが挿入したロックが返れば成功
 *
 * 6. 実行後60秒待つとexpiredでロック取れます。
 *
 * 7. "仮想割り込み"のinsertNewLock()をコメント外すと他ユーザに割り込まれた状況を再現できます。
 *
 * 8. 100個立ち上げるとロックの争奪戦を鑑賞できます。
 */

