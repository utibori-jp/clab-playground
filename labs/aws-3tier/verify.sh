#!/bin/bash
# 誰から誰へ届くかを一覧で確認する
c() { docker exec "clab-aws-3tier-$1" "${@:2}" >/dev/null 2>&1 && echo "OK" || echo "NG"; }
tcp() { c "$1" nc -z -w2 "$2" "$3"; }
row() { printf "  %-42s %s\n" "$1" "$2"; }

echo "[インターネットから]"
row "user -> proxy:80        (Public)"   "$(c user curl -s -m2 http://10.0.1.10)"
row "user -> bastion-pub:22  (Public)"   "$(tcp user 10.0.1.20 22)"
row "user -> app:80          (Private)"  "$(c user curl -s -m2 http://10.0.2.10)"
row "user -> db:5432         (Trusted)"  "$(tcp user 10.0.3.10 5432)"
echo "[Public から]"
row "proxy -> app:80         (Private)"  "$(c proxy wget -q -T2 -O- http://10.0.2.10)"
row "bastion-pub -> db:5432  (Trusted)"  "$(tcp bastion-pub 10.0.3.10 5432)"
echo "[Private から]"
row "bastion-db -> db:5432   (Trusted)"  "$(c bastion-db pg_isready -h 10.0.3.10 -t 2)"
row "app -> user             (Internet)" "$(c app ping -c1 -W2 203.0.113.10)"
echo "[Trusted から]"
row "db -> app               (Private)"  "$(c db ping -c1 -W2 10.0.2.10)"
echo
echo "[通しの動き] user が proxy にアクセス -> proxy が app に中継:"
echo -n "  "; docker exec clab-aws-3tier-user curl -s -m2 http://10.0.1.10
