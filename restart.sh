#! /bin/bash
PID=`cat tmp/pids/unicorn_s.pid`
echo $PID
ps ax|grep unicorn
kill -USR2 $PID
echo "waiting..."
sleep 10
kill -QUIT $PID
echo "waiting..."
sleep 5
ps ax|grep unicorn
echo "ok?"