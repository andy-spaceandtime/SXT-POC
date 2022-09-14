# SpaceAndTime POC

## Environment variables (.env.example)

```
DEPLOYER_PRIVATE_KEY=
ETHERSCAN_API_KEY=
INFURA_PROJECT_ID=
DEPLOY_NETWORK=mainnet | goerli | hardhat
REPORT_GAS=true
```


## How to deploy & verify contracts with hardhat

```
yarn

npx hardhat typechain

npx hardhat compile

npx hardhat deploy:ApiCall --network goerli

npx hardhat verify:ApiCall --network goerli
```

## Here are the available hardhat tasks

```
  accounts                          	Prints the list of account

  action:ApiCall:initialization     	Initialize ApiCall contract
  action:ApiCallProxy:implementation	Set ApiCallProxy implementation
  action:ApiCallProxy:initialization	Initialize ApiCallProxy contract

  check                             	Check whatever you need
  clean                             	Clears the cache and deletes all artifacts
  compile                           	Compiles the entire project, building all artifacts
  console                           	Opens a hardhat console
  coverage                          	Generates a code coverage report for test

  deploy:ApiCall                    	Deploy ApiCall contract
  deploy:ApiCallProxy               	Deploy ApiCallProxy contract
  deploy:SXTOperator                	Deploy SXTOperator contract
  deploy:SXTToken                   	Deploy SXTToken contract

  flatten                           	Flattens and prints contracts and their dependencies
  gas-reporter:merge                	
  help                              	Prints this message
  node                              	Starts a JSON-RPC server on top of Hardhat Network
  run                               	Runs a user-defined script after compiling the project
  test                              	Runs mocha tests
  typechain                         	Generate Typechain typings for compiled contracts

  verify                            	Verifies contract on Etherscan
  verify:ApiCall                    	Verify ApiCall contract
  verify:ApiCallProxy               	Verify ApiCallProxy contract
  verify:SXTOperator                	Verify SXTOperator contract
  verify:SXTToken                   	Verify SXTToken contract

```
