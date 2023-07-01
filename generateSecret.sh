#!/bin/bash

function showHelp {
  echo
  echo "This script generates a configuration file needed to deploy "
  echo "an orderer or peer node using the IBP APIs"
  echo
	echo "Ensure that you have already deployed your CA first"
  echo
  echo "Download your CA connection information and from your console"
  echo "and paste it inside the folder {PWD}/ca-file"
  echo "make sure there are no spaces in the file name"
	echo
  echo "Complete the org_config.json template file named org_config.json"
  echo "using the information about your organization and component"
  echo
	echo "Usage:"
  echo "  generateSecret.sh [command] [flags]"
  echo
  echo "Available commands: "
  echo "  registerEnroll         Register the node and node admin and generate MSP folders without creating the configuration secret"
  echo
  echo "  generateConfig         After enrolling and generating the MSP folders, create the configuration secret"
  echo
  echo "  enrollGenerateConfig   Generate new certiicates MSP folders and create configuration secret with one command"
  echo
  echo "  createMSP              After running registerEnroll, create your organization MSP definition file"
  echo
  echo "  createWalletFile      After running registerEnroll, create your the wallet file needed to load your organization"
  echo "                        admin to the IBM Blockchain console and operate your node"
}


fabric-ca-client version > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "ERROR! did not find fabric-ca-client"
  echo
  echo "Download the client by running 'curl -sSL http://bit.ly/2ysbOFE | bash -s 1.2.1 1.2.1 -d -s'"
  echo
  echo "Set the path to the clint by running 'export PATH=$PATH:<full/path/to/fabric-client/bin>'"
  exit 1
fi

export CA_FILE_NAME=$(ls ${PWD}/ca-file/*)
if [[ ! $CA_FILE_NAME ]] ; then
    echo "Error: CA file not found ${PWD}/ca-file/"
    echo "Download your CA connection information from your console"
    exit 1
  fi

export checkconfig=$(cat ${PWD}/org_config.json)
if [[ ! $checkconfig ]] ; then
    echo "Script requires a configuration file at ${PWD}/org_config.json"
    exit 1
  fi


function parseCaFile {

## Gets the ca connection infomration from the file downloaded from your
## console

export NAME=$(cat ${CA_FILE_NAME} | jq --raw-output '.ca_name')
export TLS_NAME=$(cat ${CA_FILE_NAME} | jq --raw-output '.tlsca_name')

export FULLURL=$(cat ${CA_FILE_NAME} | jq --raw-output '.ca_url')
export URL_PORT=$(echo ${FULLURL}| sed 's_https://__')

export CA_ID=admin
export CA_SECRET=adminpw

export TLSPEM=$(cat ${CA_FILE_NAME} | jq --raw-output '.pem')
export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
echo $TLSPEM | base64 --decode $FLAG > ${PWD}/catls/tls.pem

}


function getFromFile {

## Gets information about your org and component from the template file named org_config.json

export DISPLAY_NAME=$(cat ${PWD}/org_config.json | jq --raw-output '.org.orgName')
export MSPID=$(cat ${PWD}/org_config.json | jq --raw-output '.org.mspid')

export WALLET_NAME=$(cat ${PWD}/org_config.json | jq --raw-output '.org.adminName')

export ADMIN_ID=$(cat ${PWD}/org_config.json | jq --raw-output '.org.admin_enrollid')
export ADMIN_SECRET=$(cat ${PWD}/org_config.json | jq --raw-output '.org.admin_enrollsecret')

export ADMIN_ID=$(cat ${PWD}/org_config.json | jq --raw-output '.org.admin_enrollid')
export ADMIN_SECRET=$(cat ${PWD}/org_config.json | jq --raw-output '.org.admin_enrollsecret')

export COMPONENT=$(cat ${PWD}/org_config.json | jq --raw-output '.component.type')

export NODE_ID=$(cat ${PWD}/org_config.json | jq --raw-output '.component.enrollid')
export NODE_SECRET=$(cat ${PWD}/org_config.json | jq --raw-output '.component.enrollsecret')

export AFFIL=$(cat ${PWD}/org_config.json | jq --raw-output '.component.affiliation')

export TLS_NODE_ID=$(cat ${PWD}/org_config.json | jq --raw-output '.component.tls_enrollid')
export TLS_NODE_SECRET=$(cat ${PWD}/org_config.json | jq --raw-output '.component.tls_enrollsecret')

echo $TLS_NODE_ID
echo $TLS_NODE_SECRET

if [[ ! $TLS_NODE_ID ]] ; then
  export TLS_NODE_ID="$NODE_ID"
  fi

if [[ ! $TLS_NODE_SECRET ]] ; then
  export TLS_NODE_SECRET="$NODE_SECRET"
   fi

export HOST1=$(cat ${PWD}/org_config.json | jq --raw-output '.component.hostname1')
export HOST2=$(cat ${PWD}/org_config.json | jq --raw-output '.component.hostname2')
export HOST3=$(cat ${PWD}/org_config.json | jq --raw-output '.component.hostname3')

}


# Ask user for confirmation to proceed
function askProceed {
  echo
  echo "Warning: running this script will overwrite any material in {PWD}/fabric-ca-client/ca-admin, {PWD}/fabric-ca-client/peer-admin, {PWD}/fabric-ca-client/tlsca-admin."
  echo
  read -p "Continue? [y/n] " ans
  case "$ans" in
  y | Y | yes | Yes | YES |"")
    echo "proceeding ..."
    ;;
  n | N | no | No | NO )
    echo "exiting..."
    exit 1
    ;;
  *)
    echo "invalid response"
    askProceed
    ;;
  esac
}

function registerEnroll {

	if [[ ! $TLS_NODE_SECRET || ! $TLS_NODE_ID || ! $TLS_NAME || ! $AFFIL || ! $ADMIN_SECRET || \
	 			! $ADMIN_ID || ! $NODE_SECRET || ! $NODE_ID || ! $CA_SECRET || ! $CA_ID || \
				! $NAME || ! $URL_PORT || ! $COMPONENT ]] ; then
		echo "Field Missing"
		echo ""
		showHelp
		exit 1
	fi

  echo
	echo "Enroll the CA admin"
  echo
  set -x
	mkdir fabric-ca-client
	mkdir -p fabric-ca-client/ca-admin
  set +x

	export FABRIC_CA_CLIENT_HOME=${PWD}/fabric-ca-client/ca-admin
  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://${CA_ID}:${CA_SECRET}@${URL_PORT} --caname $NAME --tls.certfiles ${PWD}/catls/tls.pem
  set +x

  if [ $? -ne 0 ]; then
    echo "ERROR ! Unable to enroll the CA admin"
    exit 1
  fi

  echo
	echo "Register the peer or orderer"
  echo
  set -x
	fabric-ca-client register --caname $NAME --id.name $NODE_ID --id.type $COMPONENT --id.secret $NODE_SECRET --tls.certfiles ${PWD}/catls/tls.pem
  set +x

  echo
  echo "Register the peer or orderer admin"
  echo
  set -x
  fabric-ca-client register --caname $NAME --id.name $ADMIN_ID --id.type $COMPONENT --id.secret $ADMIN_SECRET --tls.certfiles ${PWD}/catls/tls.pem
  set +x

  rm -rf fabric-ca-client/peer-admin
  set -x
	mkdir -p fabric-ca-client/peer-admin
  set +x

  echo
  echo "## Generate the node admin signCert"
  echo
  set -x
	fabric-ca-client enroll -u https://${ADMIN_ID}:${ADMIN_SECRET}@${URL_PORT}  --caname $NAME -M ${PWD}/fabric-ca-client/peer-admin/msp --tls.certfiles ${PWD}/catls/tls.pem
  set +x

  if [ $? -ne 0 ]; then
    echo "ERROR ! Unable to enroll the node admin"
    exit 1
  fi

	## enroll with the tls ca

  set -x
	mkdir -p fabric-ca-client/ca-admin
  set +x

  export FABRIC_CA_CLIENT_HOME=$HOME/fabric-ca-client/tlsca-admin
  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  echo
  echo "Enroll the TLS CA admin"
  echo
  set -x
	fabric-ca-client enroll -u https://${CA_ID}:${CA_SECRET}@${URL_PORT} --caname $TLS_NAME --tls.certfiles ${PWD}/catls/tls.pem
  set +x

  if [ $? -ne 0 ]; then
    echo "ERROR ! Unable to enroll the TLS CA admin"
    exit 1
  fi

  echo
  echo "Register the peer or orderer with the TLS CA"
  echo
  set -x
	fabric-ca-client register --caname $TLS_NAME --id.name ${TLS_NODE_ID} --id.type $COMPONENT --id.secret ${TLS_NODE_SECRET} --tls.certfiles ${PWD}/catls/tls.pem
  set +x
}

function printSecret {

## convert the sign cert to base 64

export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
export ADMINCERT=$(cat ${PWD}/fabric-ca-client/peer-admin/msp/signcerts/cert.pem | base64 $FLAG)

## convert and export tls certificate

export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
export TLSCERT=$(cat ${PWD}/catls/tls.pem | base64 $FLAG)

## Check if TLS cert is there

if [[ ! $TLSCERT ]] ; then
    echo "Error: CA TLS cert not found at ${PWD}/catls/tls.pem  "
    exit 1
  fi

URL=$(echo ${URL_PORT} | cut -d ':' -f 1)
PORT=$(echo ${URL_PORT} | cut -d ':' -f 2)

echo
echo "printing secret"
echo '{
	"enrollment": {
		"component": {
			"cahost": "'"$URL"'",
			"caport": "'"$PORT"'",
			"caname": "'"$NAME"'",
			"catls": {
				"cacert": "'"$TLSCERT"'"
			},
			"enrollid": "'"$NODE_ID"'",
			"enrollsecret": "'"$NODE_SECRET"'",
			"admincerts": ["'"$ADMINCERT"'"]
		},
		"tls": {
			"cahost": "'"$URL"'",
			"caport": "'"$PORT"'",
			"caname": "'"$TLS_NAME"'",
			"catls": {
				"cacert": "'"$TLSCERT"'"
			},
			"enrollid": "'"$TLS_NODE_ID"'",
			"enrollsecret": "'"$TLS_NODE_SECRET"'",
			"csr": {
				"hosts": ["'"$HOST1"'","'"$HOST2"'","'"$HOST3"'"]
			}
		}
	}
}' > secret.json
}

function createWalletFile {

  ## convert and export admin signing certificate

  export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
  export PUBLIC_KEY=$(cat ${PWD}/fabric-ca-client/peer-admin/msp/signcerts/cert.pem | base64 $FLAG)

  ## Check if certificate is there

  if [[ ! $PUBLIC_KEY ]] ; then
    echo "Error: cert not found at ${PWD}/fabric-ca-client/peer-admin/signcerts/cert.pem"
    echo
    echo "First run ./generateConfig/sh registerEnroll"
    exit 1
  fi

  ## convert and export admin private key

  export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
  export PRIVATE_KEY_NAME=$(ls ${PWD}/fabric-ca-client/peer-admin/msp/keystore/*)
  export PRIVATE_KEY=$(cat ${PRIVATE_KEY_NAME} | base64 $FLAG)

  echo
  echo "Printing Admin Wallet File"
  echo
  echo '{
    "name": "'"$WALLET_NAME"'",
    "private_key": "'"$PRIVATE_KEY"'",
    "cert": "'"$PUBLIC_KEY"'"
}'  > adminWallet.json
}

function createMSP {

  ## create Organization MSP definition that can be imported into the console using the APIs or UI

  ## convert and export admin signing certificate

  export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
  export ADMIN_PUBLIC_KEY=$(cat ${PWD}/fabric-ca-client/peer-admin/msp/signcerts/cert.pem | base64 $FLAG)

  ## Check if certificate is there

  if [[ ! $ADMIN_PUBLIC_KEY ]] ; then
    echo "Error: cert not found at ${PWD}/fabric-ca-client/peer-admin/signcerts/cert.pem"
    echo
    echo "First run ./generateConfig/sh registerEnroll"
    exit 1
  fi

  ## convert and export admin private key

  export ROOT_CA_CERT_NAME=$(ls ${PWD}/fabric-ca-client/ca-admin/msp/cacerts/*)
  export ROOT_CA_CERT=$(cat ${ROOT_CA_CERT_NAME} | base64 $FLAG)

  export ROOT_TLSCA_CERT_NAME=$(ls ${PWD}/fabric-ca-client/tlsca-admin/msp/cacerts/*)
  export ROOT_TLSCA_CERT=$(cat ${ROOT_TLSCA_CERT_NAME} | base64 $FLAG)

  echo
  echo "Printing MSP Definition File"
  echo
  echo '{
    "name": "'"$DISPLAY_NAME"'",
    "msp_id": "'"$MSPID"'",
    "type": "msp",
    "root_certs": [
        "'"$ADMIN_PUBLIC_KEY"'"
    ],
    "admins": [
        "'"$ROOT_CA_CERT"'"
    ],
    "tls_root_certs": [
        "'"$ROOT_TLSCA_CERT"'"
    ]
}'  > orgMSP.json
}


## export function to variable. If not, call help.
export MODE=$1
shift

while [[ $# -ge 1 ]] ; do
	key="$1"
	case $key in
		-h|--help )
			showHelp
			exit 0
			;;
		* )
      echo
			echo "Unknown flag: $key"
      echo
      showHelp
			exit 1
			;;
	esac
	shift
done

if [ "$MODE" == "registerEnroll" ]; then
  askProceed
  parseCaFile
  getFromFile
	registerEnroll
elif [ "$MODE" == "generateConfig" ]; then
  parseCaFile
  getFromFile
	printSecret
elif [ "$MODE" == "enrollGenerateConfig" ]; then
  askProceed
  parseCaFile
  getFromFile
	registerEnroll
  printSecret
elif [ "$MODE" == "createWalletFile" ]; then
  getFromFile
  createWalletFile
elif [ "$MODE" == "createMSP" ]; then
  getFromFile
  createMSP
else
	showHelp
  exit 1
fi
