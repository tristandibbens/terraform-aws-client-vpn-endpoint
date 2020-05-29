ovpn=./client-config.ovpn

[ -f $ovpn ] && {
  sed -i 's/^remote cvpn-endpoint/remote xyz.cvpn-endpoint/' $ovpn

  # add dns servers
  for i in $2
  do
    echo "dhcp-option DNS $i" >> $ovpn
  done

  cat <<EOF >> $ovpn

# Next three lines refresh the dns server provided by the openvpn server.
# Openvpn server will do something like this: push "dhcp-option DNS <dns-server-ip>"
# However, the resolver does not get updated on linux, hence the settings below.
# These are settings provided by openvpn and the assumption is the client is openvpn.
# I assume the settings are the same for macos or even windows if using openvpn client.
# If this does not work, then set the dns server/s manually in your client.
script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf

EOF

  echo '<cert>' >> $ovpn
  cat ./certs/client.$1.crt >> $ovpn
  echo '</cert>' >> $ovpn

  echo '<key>' >> $ovpn
  cat ./certs/client.$1.key >> $ovpn
  echo '</key>' >> $ovpn
}

