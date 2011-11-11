#! /bin/bash
echo "purging ...http://192.168.110.7$1"
curl -X PURGE "http://192.168.110.7$1"
echo "purging ...http://modeverv.dyndns.org$1"
ssh -i  ~/.ssh/id_dsa_lisonal modeverv@modeverv.a.lisonal.com curl -X PURGE "http://modeverv.dyndns.org$1"
echo "ok?"