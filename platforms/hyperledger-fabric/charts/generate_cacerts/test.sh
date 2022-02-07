#!/usr/bin/env sh

echo "hello shell world!"

validateVaultResponse () {
	if echo ${2} | grep "errors"; then
		echo "ERROR: unable to retrieve ${1}: ${2}"
		exit 1
	fi
	if [ "$3" == "LOOKUPSECRETRESPONSE" ]
	then
		http_code=$(curl -sS -o /dev/null -w "%{http_code}" \
		--header "X-Vault-Token: ${VAULT_TOKEN}" \
		http://127.0.0.1:9000/v1/${1})
		curl_response=$?
		if test "$http_code" != "200" ; then
			echo "Http response code from Vault- $http_code and curl_response - $curl_response"
			if test "$curl_response" != "0"; then
				echo "Error: curl command failed with error code - $curl_response"
				exit 1
			fi
		fi
	fi
}

# setting up env to get secrests/certificates from Vault
echo "Getting secrets/certificates from Vault server"
KUBE_SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
VAULT_TOKEN=$(curl -sS --request POST http://127.0.0.1/v1/auth/devsupplychain-net-auth/login -H "Content-Type: application/json" -d '{"role":"'"vault-role"'","jwt":"'"${KUBE_SA_TOKEN}"'"}' | jq -r 'if .errors then . else .auth.client_token end')
validateVaultResponse 'vault login token' "${VAULT_TOKEN}"
echo "Logged into Vault"
