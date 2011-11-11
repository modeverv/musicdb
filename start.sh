#! /bin/bash
unicorn -c ./unicorns.conf --env production -D
echo "waiting..."
sleep 5
ps ax|grep unicorn

