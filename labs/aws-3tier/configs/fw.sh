#!/bin/sh
# VPCルータ + セキュリティグループ/NACL 相当のルール
set -e
ip addr add 203.0.113.1/24 dev eth1   # インターネット側
ip addr add 10.0.1.1/24 dev eth2      # Public
ip addr add 10.0.2.1/24 dev eth3      # Private
ip addr add 10.0.3.1/24 dev eth4      # Trusted
sysctl -qw net.ipv4.ip_forward=1

PUB=10.0.1.0/24; PRI=10.0.2.0/24; TRU=10.0.3.0/24; NET=203.0.113.0/24

iptables -F FORWARD
iptables -P FORWARD DROP                                              # 書いてない通信は全部遮断
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT   # 戻りの通信は許可 (SG のステートフル動作)

iptables -A FORWARD -s $NET -d 10.0.1.10 -p tcp --dport 80 -j ACCEPT  # Internet -> proxy :80
iptables -A FORWARD -s $NET -d 10.0.1.20 -p tcp --dport 22 -j ACCEPT  # Internet -> bastion-pub :22
iptables -A FORWARD -s $PUB -d $PRI -j ACCEPT                          # Public  -> Private
iptables -A FORWARD -s $PRI -d $TRU -p tcp --dport 5432 -j ACCEPT      # Private -> Trusted (DB だけ)
iptables -A FORWARD -s $PRI -d $NET -j ACCEPT                          # Private -> Internet (NAT GW 相当)
iptables -A FORWARD -s $PUB -d $NET -j ACCEPT                          # Public  -> Internet
iptables -t nat -A POSTROUTING -s $PRI -o eth1 -j MASQUERADE           # Private はルータの IP に化けて外へ
