import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

import "./tasks";
import { SUPPORTED_RPC_ENDPOINTS } from "./tasks/utils/constants";

dotenv.config();

const SUPPORTED_CHAINS = {
  goerli: 5,
};

const SUPPORTED_CHAIN_NAMES = ["goerli"];

const AVAILABLE_NETWORKS = ["mainnet", "kovan", "hardhat"];

const DEPLOYER: string = process.env.DEPLOYER_PRIVATE_KEY || "";
if (!DEPLOYER) {
  throw new Error("Please set your DEPLOYER_PRIVATE_KEY in a .env file");
}

const INFURA_PROJECT_ID: string = process.env.INFURA_PROJECT_ID || "";
if (!INFURA_PROJECT_ID) {
  throw new Error("Please set your INFURA_PROJECT_ID in a .env file");
}

const ETHERSCAN_API_KEY: string = process.env.ETHERSCAN_API_KEY || "";
if (!ETHERSCAN_API_KEY) {
  throw new Error("Please set ETHERSCAN_API_KEY in a .env file");
}

const DEFAULT_NETWORK = process.env.DEPLOY_NETWORK || "";
if (!DEFAULT_NETWORK && AVAILABLE_NETWORKS.includes(DEFAULT_NETWORK)) {
  throw new Error("Please set correct DEFAULT_NETWORK in a .env file");
}

function getChainConfig(
  chain: keyof typeof SUPPORTED_CHAINS
): NetworkUserConfig {
  return {
    accounts: [DEPLOYER],
    chainId: SUPPORTED_CHAINS[chain],
    url: SUPPORTED_RPC_ENDPOINTS[chain],
  };
}

function getNetworkConfig() {
  return SUPPORTED_CHAIN_NAMES.reduce((value, CHAIN_NAME) => {
    value[CHAIN_NAME] = getChainConfig(
      CHAIN_NAME as keyof typeof SUPPORTED_CHAINS
    );
    return value;
  }, {} as any);
}

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
      },
      {
        version: "0.7.0",
        settings: {},
      },
    ],
  },
  defaultNetwork: DEFAULT_NETWORK,
  networks: getNetworkConfig(),
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};

export default config;
