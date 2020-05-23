ovpn=./client-config.ovpn

[ -f $ovpn ] && {
  sed -i 's/^remote cvpn-endpoint/remote xyz.cvpn-endpoint/' $ovpn

  echo '<cert>' >> $ovpn
  cat ./certs/client.$1.crt >> $ovpn
  echo '</cert>' >> $ovpn

  echo '<key>' >> $ovpn
  cat ./certs/client.$1.key >> $ovpn
  echo '</key>' >> $ovpn
}

