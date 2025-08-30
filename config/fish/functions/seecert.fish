function seecert
  set domain $argv[1]
  nslookup $domain
  echo "Q" | openssl s_client -showcerts -servername $domain -connect $domain:443 | openssl x509 -text | grep -iA2 "Validity"
end
