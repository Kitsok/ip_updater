#!/bin/bash

source secret.sh

_curl()
{
	curl -s $@ -H "$TOKEN" -H "Content-Type: application/json"
}

cf_get_zone_id()
{
	_curl -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE"  | jq -r '.result[0].id'
}

cf_get_record_json()
{
	_curl -X GET "https://api.cloudflare.com/client/v4/zones/$1/dns_records?type=A&name=HOST" -o $2
}

cf_get_record_id()
{
	_curl -X GET "https://api.cloudflare.com/client/v4/zones/$1/dns_records?type=A&name=$HOST" | jq -r '.result[0].id'
}

cf_get_record_addr()
{
	_curl -X GET "https://api.cloudflare.com/client/v4/zones/$1/dns_records?type=A&name=$HOST" | jq -r '.result[0].content'
}

cf_update_record()
{
	local data="{\"type\":\"A\",\"name\":\"$HOST\",\"content\":\"$3\",\"ttl\":1,\"proxied\":false}"
	_curl -X PUT "https://api.cloudflare.com/client/v4/zones/$1/dns_records/$2" --data $data -o /dev/null
}

get_ip()
{
	curl -s 'https://api.ipify.org' 2>/dev/null
}

get_saved()
{
	cat /tmp/my_ip.txt 2>/dev/null || :
}

set_saved()
{
	echo $1 > /tmp/my_ip.txt
}

ip4market_update()
{
	local url="http://tb.ip4market.ru/?page=update&apikey=$IPMARKET_KEY"
	curl "$url" >/dev/null 2>&1 || :
}

# Update tunnel broker
ip4market_update

my_ip=$(get_ip)
zone_id=$(cf_get_zone_id)
[ -z "$zone_id" -o "$zone_id" = "null" ] && exit 0
rec_id=$(cf_get_record_id $zone_id)
cf_addr=$(cf_get_record_addr $zone_id)
[ "$cf_addr" = "$my_ip" ] && exit 0
echo "$cf_addr -> $my_ip"
cf_update_record $zone_id $rec_id $my_ip
