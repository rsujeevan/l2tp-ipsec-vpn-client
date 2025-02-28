l2tp-ipsec-vpn-client
===
[![License](https://img.shields.io/github/license/rsujeevan/l2tp-ipsec-vpn-client)](https://github.com/rsujeevan/l2tp-ipsec-vpn-client/blob/master/LICENSE)

A tiny Alpine based docker image to quickly setup an L2TP over IPsec VPN client w/ PSK.

## Motivation
Does your office or a client have a VPN server already setup and you
just need to connect to it? Do you use Linux and are jealous that the
one thing a MAC can do better is quickly setup this kind of VPN? Then
here is all you need:

1. VPN Server Address
2. Pre Shared Key
3. Username
4. Password

## Run
Setup environment variables for your credentials and config:

    export VPN_SERVER_IPV4='1.2.3.4'
    export VPN_PSK='my pre shared key'
    export VPN_USERNAME='myuser@myhost.com'
    export VPN_PASSWORD='mypass'
    export VPN_PASSWORD='mypass'
    export VPN_TUNNEL_ROUTE_NETWORK_1=10.10.10.0/24  # automatically add a route to forward all traffic for 10.10.10.0/24 network via VPN
    
Now run it (you can daemonize of course after debugging):

    docker run --rm -it --privileged --net=host \
               -v /lib/modules:/lib/modules:ro \
               -e VPN_SERVER_IPV4 \
               -e VPN_PSK \
               -e VPN_USERNAME \
               -e VPN_PASSWORD \
               -e VPN_TUNNEL_ROUTE_NETWORK_1 \
                  sjnet/l2tp-ipsec-vpn-client

## Route
From the host machine configure traffic to route through VPN link:

    # confirm the ppp0 link and get the peer e.g. (192.0.2.1) IPV4 address
    ip a show ppp0
    # route traffic for a specific target ip through VPN tunnel address
    sudo ip route add 1.2.3.4 via 192.0.2.1 dev ppp0
    # route all traffice through VPN tunnel address
    sudo ip route add default via 192.0.2.1 dev ppp0
    # or
    sudo route add -net default gw 192.0.2.1 dev ppp0
    # and delete old default routes e.g.
    sudo route del -net default gw 10.0.1.1 dev eth0
    # when your done add your normal routes and delete the VPN routes
    # or just `docker stop` and you'll probably be okay


## Debugging
On your VPN client localhost machine you may need to `sudo modprobe af_key`
if you're getting this error when starting:
```
pluto[17]: No XFRM/NETKEY kernel interface detected
pluto[17]: seccomp security for crypto helper not supported
```

## References
* [Original Repo](https://github.com/ubergarm/l2tp-ipsec-vpn-client)
* [royhills/ike-scan](https://github.com/royhills/ike-scan)
* [libreswan reference config](https://libreswan.org/wiki/VPN_server_for_remote_clients_using_IKEv1_with_L2TP)
* [Useful Config Example](https://lists.libreswan.org/pipermail/swan/2016/001921.html)
* [libreswan and Cisco ASA 5500](https://sgros.blogspot.com/2013/08/getting-libreswan-connect-to-cisco-asa.html)
* [NetDev0x12 IPSEC and IKE Tutorial](https://youtu.be/7oldcYljp4U?t=1586)
