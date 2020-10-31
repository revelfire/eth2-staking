# ETH2 Staking with Prysm and Lighthouse in AWS (and with Raspberry)

2 choices:
- Raspberry Pi: for testing purpose (see [guide](raspberry_setup.md))
- Or server in AWS cloud: for better performance/availability, recommanded for mainnet (this guide below vv)

## Prerequites
- AWS account
- Terraform cli and cloud account (free)

## Deploy server Infra
- Clone this repo and go to dir: `cd terraform/lighthouse` 
- Init: `terraform init`
- Plan: `terraform plan`
- Deploy: `terraform apply`
- If error `no valid credential sources for Terraform AWS Provider found`: don't forget to change `execution mode -> local` in [settings](https://app.terraform.io/app/gregbkr/workspaces/eth2-prysm-testnet/settings/general)
- Ssh on server: `ssh eth@<public_IP>`

## Run Prysm beacon
- Check that cloud-init is finished: `tail /var/log/cloud-init-output.log -n1000 -f`
- Run beacon with: `sudo systemctl start prysm-beacon`
- Check logs: `journalctl -u prysm-beacon -ef`
- Before going further you need to assure that your node is synced and reached the last block listed on this [page](https://beaconscan.com/)


## Validator key to store the 32 ETH
It is a good practive to open the [launchpad](https://medalla.launchpad.ethereum.org/) and read about the process.

### Create the seed
The most critical part is to create the validator key which will receive the funds (32+ ETH) and will validate block.

Format a fresh USB stick to download the latest deposit CLI from [the official repository](https://github.com/ethereum/eth2.0-deposit-cli/releases/) (double check this link from this official documentation!!)

**On the secure and air-gapped laptop/raspberry**: 
- connect the USB stick to get the CLI, and run the command: 
```
./deposit --num_validators 1 --chain medalla
```
- You should provide a `keystore password` and the cli should output a seed like
```
cabbage garden word3 word4 .... word24
```
- And a directory structure like:
```
/home/myuser/Documents/eth2/validator_keys/validator_keys/
    |   deposit_data-1602056423.json                  # public key = the ETH address where you will send the 32 ETH (ok to share)
    |   keystore-m_12381_3600_0_0_0-1602056423.json   # private key (critical, do not share!!)

```
- Copy the `seed` and the `keystore password` on a piece of paper and keep it safe, this paper is CRITICAL as it contains the keys to recover the 32 ETH.
- Copy on your USB stick the validator keys located here: `/home/myuser/Documents/eth2/validator_keys`, and transfer them (via SCP) to your VPS server.

### Deposit 32 ETH
Follow again the [launchpad](https://medalla.launchpad.ethereum.org/), go to the section to deposit the 32 ETH. You should need to provide the file `deposit_data-1602056423.json` from your USD stick.

Send 32 ETH (Goerli testnet). **Do not send mainnet ETH, please check 3 times!**

### Import validator account into Prysm
Following this [doc](https://docs.prylabs.network/docs/testnet/medalla#step-5-import-your-validator-accounts-into-prysm):
- We will import the account from the USB stick.
```
/home/eth/prysm/prysm.sh validator --medalla accounts import --keys-dir=~/validator_keys
```
- Input your wallet password in a file to auto-unlock when you will run prysm-validator : `nano ~/.eth2validators/prysm-wallet-v2/wallet.password`
- And secure the permission: `chmod 600  ~/.eth2validators/prysm-wallet-v2/wallet.password` 
- Run validator: `sudo systemctl start prysm-validator`
- Check logs: `journactl -u prysm-validator -ef`
  - You should see in logs: `Waiting for deposit to be observed by beacon node`, as it takes around 5 to 12h for your deposit to be active in the smart contract.
  - Monitoring your validator status [beaconcha.in](https://beaconcha.in/validator/863592ae2c05450139c5ede142d734136c40f321f125d9312816094067b6ec2ff42451dfee2386461c6f7a6f9f328021) or []() (get your pubkey from `cat validator_keys/keystore-m_12381_3600_0_0_0-1604174082.jso`): 


### Monitor node