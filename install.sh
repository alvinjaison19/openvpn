*** original.sh	2025-08-19
--- modified.sh	2025-08-19
***************
*** 196,221 ****
  function installQuestions() {
  	echo "Welcome to the OpenVPN installer!"
  	echo "The git repository is available at: https://github.com/angristan/openvpn-install"
  	echo ""
  
  	echo "I need to ask you a few questions before starting the setup."
  	echo "You can leave the default options and just press enter if you are okay with them."
  	echo ""
  	echo "I need to know the IPv4 address of the network interface you want OpenVPN listening to."
  	echo "Unless your server is behind NAT, it should be your public IPv4 address."
  
- 	# Detect public IPv4 address and pre-fill for the user
- 	IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | head -1)
- 
- 	if [[ -z $IP ]]; then
- 		# Detect public IPv6 address
- 		IP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
- 	fi
+ 	# Detect public IP using curl ifconfig.me (requested change)
+ 	IP=$(curl -4 -fsS https://ifconfig.me 2>/dev/null || true)
+ 	# Fallbacks in case ifconfig.me is unreachable
+ 	if [[ -z $IP ]]; then
+ 		IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | head -1)
+ 		[[ -z $IP ]] && IP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
+ 	fi
  	APPROVE_IP=${APPROVE_IP:-n}
  	if [[ $APPROVE_IP =~ n ]]; then
  		read -rp "IP address: " -e -i "$IP" IP
  	fi
  	# If $IP is a private IP address, the server must be behind NAT
  	if echo "$IP" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
  		echo ""
  		echo "It seems this server is behind NAT. What is its public IPv4 address or hostname?"
  		echo "We need it for the clients to connect to the server."
  
  		if [[ -z $ENDPOINT ]]; then
  			DEFAULT_ENDPOINT=$(resolvePublicIP)
  		fi
  
  		until [[ $ENDPOINT != "" ]]; do
  			read -rp "Public IPv4 address or hostname: " -e -i "$DEFAULT_ENDPOINT" ENDPOINT
  		done
  	fi
  
  	echo ""
- 	echo "Checking for IPv6 connectivity..."
- 	echo ""
- 	# "ping6" and "ping -6" availability varies depending on the distribution
- 	if type ping6 >/dev/null 2>&1; then
- 		PING6="ping6 -c3 ipv6.google.com > /dev/null 2>&1"
- 	else
- 		PING6="ping -6 -c3 ipv6.google.com > /dev/null 2>&1"
- 	fi
- 	if eval "$PING6"; then
- 		echo "Your host appears to have IPv6 connectivity."
- 		SUGGESTION="y"
- 	else
- 		echo "Your host does not appear to have IPv6 connectivity."
- 		SUGGESTION="n"
- 	fi
- 	echo ""
- 	# Ask the user if they want to enable IPv6 regardless its availability.
- 	until [[ $IPV6_SUPPORT =~ (y|n) ]]; do
- 		read -rp "Do you want to enable IPv6 support (NAT)? [y/n]: " -e -i $SUGGESTION IPV6_SUPPORT
- 	done
+ 	# Enable IPv6 support by default (requested change)
+ 	IPV6_SUPPORT="y"
+ 	echo "IPv6 support: enabled"
  	echo ""
  	echo "What port do you want OpenVPN to listen to?"
  	echo "   1) Default: 1194"
  	echo "   2) Custom"
  	echo "   3) Random [49152-65535]"
- 	until [[ $PORT_CHOICE =~ ^[1-3]$ ]]; do
- 		read -rp "Port choice [1-3]: " -e -i 1 PORT_CHOICE
- 	done
- 	case $PORT_CHOICE in
- 	1)
- 		PORT="1194"
- 		;;
- 	2)
- 		until [[ $PORT =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; do
- 			read -rp "Custom port [1-65535]: " -e -i 1194 PORT
- 		done
- 		;;
- 	3)
- 		# Generate random number within private ports range
- 		PORT=$(shuf -i49152-65535 -n1)
- 		echo "Random Port: $PORT"
- 		;;
- 	esac
+ 	# Force default port 1194 (requested change)
+ 	PORT="1194"
+ 	echo "Port: $PORT"
  	echo ""
  	echo "What protocol do you want OpenVPN to use?"
  	echo "UDP is faster. Unless it is not available, you shouldn't use TCP."
  	echo "   1) UDP"
  	echo "   2) TCP"
- 	until [[ $PROTOCOL_CHOICE =~ ^[1-2]$ ]]; do
- 		read -rp "Protocol [1-2]: " -e -i 1 PROTOCOL_CHOICE
- 	done
- 	case $PROTOCOL_CHOICE in
- 	1)
- 		PROTOCOL="udp"
- 		;;
- 	2)
- 		PROTOCOL="tcp"
- 		;;
- 	esac
+ 	# Use UDP by default (requested change)
+ 	PROTOCOL="udp"
+ 	echo "Protocol: $PROTOCOL"
  	echo ""
  	echo "What DNS resolvers do you want to use with the VPN?"
  	echo "   1) Current system resolvers (from /etc/resolv.conf)"
  	echo "   2) Self-hosted DNS Resolver (Unbound)"
  	echo "   3) Cloudflare (Anycast: worldwide)"
  	echo "   4) Quad9 (Anycast: worldwide)"
  	echo "   5) Quad9 uncensored (Anycast: worldwide)"
  	echo "   6) FDN (France)"
  	echo "   7) DNS.WATCH (Germany)"
  	echo "   8) OpenDNS (Anycast: worldwide)"
  	echo "   9) Google (Anycast: worldwide)"
  	echo "   10) Yandex Basic (Russia)"
  	echo "   11) AdGuard DNS (Anycast: worldwide)"
  	echo "   12) NextDNS (Anycast: worldwide)"
  	echo "   13) Custom"
- 	until [[ $DNS =~ ^[0-9]+$ ]] && [ "$DNS" -ge 1 ] && [ "$DNS" -le 13 ]; do
- 		read -rp "DNS [1-12]: " -e -i 11 DNS
- 		if [[ $DNS == 2 ]] && [[ -e /etc/unbound/unbound.conf ]]; then
- 			echo ""
- 			echo "Unbound is already installed."
- 			echo "You can allow the script to configure it in order to use it from your OpenVPN clients"
- 			echo "We will simply add a second server to /etc/unboun
