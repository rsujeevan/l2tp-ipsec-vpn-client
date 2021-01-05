#!/bin/sh

# template out all the config files using env vars
sed -i 's/right=.*/right='$VPN_SERVER_IPV4'/' /etc/ipsec.conf
echo ': PSK "'$VPN_PSK'"' > /etc/ipsec.secrets
sed -i 's/lns = .*/lns = '$VPN_SERVER_IPV4'/' /etc/xl2tpd/xl2tpd.conf
sed -i 's/name .*/name '$VPN_USERNAME'/' /etc/ppp/options.l2tpd.client
sed -i 's/password .*/password '$VPN_PASSWORD'/' /etc/ppp/options.l2tpd.client

# startup ipsec tunnel
ipsec initnss
sleep 1
ipsec pluto --stderrlog --config /etc/ipsec.conf
sleep 5
ipsec auto --up L2TP-PSK
sleep 3
ipsec --status
sleep 3

# startup xl2tpd ppp daemon then send it a connect command
(sleep 7 && echo "c myVPN" > /var/run/xl2tpd/l2tp-control) &
/usr/sbin/xl2tpd -p /var/run/xl2tpd.pid -c /etc/xl2tpd/xl2tpd.conf -C /var/run/xl2tpd/l2tp-control -D &

TUNNEL_NAME="${VPN_TUNEL_NAME-ppp0}"

is_ppp_up() {
    ip ad show ${TUNNEL_NAME} 2>&1 | grep -q "inet "
}

get_vpn_ip() {
    ip add show ${TUNNEL_NAME} | grep "inet " | sed 's/^[ ]*//' | cut -f2 -d' '
}

route_traffic() {
    VPN_GATEWAY="$(get_vpn_ip)"
    echo "Routing ${1} via ${VPN_GATEWAY} on tunnel ${TUNNEL_NAME}"
    ip route add ${1} via ${VPN_GATEWAY} dev ${TUNNEL_NAME}
}

TIMEOUT=${VPN_TIMEOUT-6}
i=0
# Until ppp0 is up with an IP or timeout expires
while ! is_ppp_up && [ $i -le ${TIMEOUT} ]; do
  sleep 1
  ((i=i+1))
done

$VPN_MAX_ROUTE=${VPN_MAX_ROUTE-5}

if is_ppp_up; then
    # ppp is up
    for varindex in $(seq 1 $VPN_MAX_ROUTE)
    do
        varname="VPN_TUNNEL_ROUTE_NETWORK_$varindex"
        NETWORK=$(eval echo \$${varname})
        if [ ! -z "${NETWORK}" ]; then
            route_traffic ${NETWORK}
        fi
    done
else
    echo "Error: ${TUNNEL_NAME} is not up"
fi

echo "waiting for xl2tpd to exit"
wait $(cat /var/run/xl2tpd.pid)
