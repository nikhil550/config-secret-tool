# IBM Blockchain Platform API script

Use this script to create the configuration JSON file required to deploy an orderer or peer using the IBM Blockchain Platform APIs.

* First deploy a CA using the on the IBM Blockchain platform console.
* Download the CA connection information using the console and place it in the ca-file folder
* Complete an org_config file named `org_config .json` with the information about your organization and the component. You can find a sample file in the script repo.
  - `orgName` is your organizations informal name
  - `mspid` is your organizations MSPID
  - `adminName` will be the name of your org admin in your console wallet
  - `admin_enrollid` is the enroll ID of your admin identity
  - `admin_enrollsecret` is the enroll secret of your admin identity
  - `type` specify whether you are creating an orderer or peer
  - `enrollid` is the enroll id of your node
  - `enrollsecret` is the enroll secret of your node
  - `affiliation` is the affiliation of your node
  - `tls_enrollid` is the enroll id of your node with your tlsca. If you leave blank, the script will use the value for `enrollid`.
  - `tls_enrollsecret` is the enroll id of your node with your tlsca. If you leave blank, the script will use the value for `enrollsecret`.
  - `hostname1` specify a hostname for your node. This field is optional.
* Once you have completed the file and dowloaded the CA file, you can run `./generateSecret.sh [command]`. See the help text below

## Help

```
./generateSecret.sh -help

This script generates a configuration file needed to deploy
an orderer or peer node using the IBP APIs

Ensure that you have already deployed your CA first

Download your CA connection information and from your console
and paste it inside the folder {PWD}/ca-file
make sure there are no spaces in the file name

Complete the org_config.json template file named org_config.json
using the information about your organization and component

Usage:
  generateSecret.sh [command]

Available commands:
  registerEnroll         Register the node and node admin and generate MSP folders without creating the configuration secret

  generateConfig         After enrolling and generating the MSP folders, create the configuration secret

  enrollGenerateConfig   Generate new certificates MSP folders and create configuration secret with one command

  createMSP              After running registerEnroll, create your organization MSP definition file

  createWalletFile      After running registerEnroll, create your the wallet file needed to load your organization
                        admin to the IBM Blockchain console and operate your node
```

## Example flows

This example commands demonstrate how you would use the scripts to create configuration files and deploy a node using the APIs

After creating a CA using the console UI and downloading the CA connection information, use the scripts to generate the necessary certificates. This will override any local certificates.
```
./generateSecret.sh registerEnroll
```

You can then use those certificates to create the configuration file that will deploy an orderer or peer. You can find an example configuration file named `secret.json` in the repo.
```
./generateSecret.sh generateConfig
```

You can generate the organization MSP file before deploying the node. You can find an example file named `orgMSP.json` in the repo.
```
./generateSecret.sh createMSP
```

To operate these components using the console, you can create file containing your organizations admin certificate and private key that can be imported directly into your console. You can find an example file named `adminWallet.json` in the repo.
```
./generateSecret.sh createWalletFile
```

You can also generate the certificates and the configuration file all in one run.
```
./generateSecret.sh enrollGenerateConfig
```
