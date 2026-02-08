function ksecret
  set secret_data (kubectl get secret $argv -o jsonpath='{.data}')

  for key in (echo $secret_data | jq -r 'keys[]')
    echo $secret_data | jq -r ".\"$key\"" | base64 -d | string collect --no-trim-newlines | read -z value
    printf "$key:\n"
    echo "$value" | sed 's/^/  /'
  end
end
