import { Signer } from "@ethersproject/abstract-signer";
import { Contract } from "@ethersproject/contracts";
import { task } from "hardhat/config";

import { ApiCall, Proxy } from "../../typechain-types";
import { readContract, getNetwork } from "../utils/io";
import {
  SXT_GATEWAY_ENDPOINT,
  SXT_JOB_ID,
  LINK_ADDRESS,
} from "../utils/constants";
import {
  SXT_OPERATOR_CONTRACT_NAME,
  API_CALL_PROXY_CONTRACT_NAME,
  API_CALL_CONTRACT_NAME,
} from "../deployers";
import ApiCallArtifact from "../../artifacts/contracts/ApiCall.sol/ApiCall.json";
import ApiCallProxyArtifact from "../../artifacts/contracts/proxy/Proxy.sol/Proxy.json";

task(
  "action:ApiCall:implementation",
  "Set ApiCallProxy implementation",
  async (_taskArgs, hre) => {
    const accounts: Signer[] = await hre.ethers.getSigners();
    const account = accounts[0];

    const apicall = readContract(API_CALL_CONTRACT_NAME);
    const apicallProxy = readContract(API_CALL_PROXY_CONTRACT_NAME);

    // Set implementation
    const proxyContract = new Contract(
      apicallProxy.address,
      ApiCallProxyArtifact.abi,
      account
    ) as Proxy;

    const tx = await proxyContract.setImplementation(apicall.address);
    await tx.wait();

    console.info("Set implementation contract address");
  }
);

task(
  "action:ApiCall:initialization",
  "Initialize ApiCallProxy contract",
  async (_taskArgs, hre) => {
    const accounts: Signer[] = await hre.ethers.getSigners();
    const account = accounts[0];

    // Initialize
    const sxtOperator = readContract(SXT_OPERATOR_CONTRACT_NAME);
    const apicallProxy = readContract(API_CALL_PROXY_CONTRACT_NAME);

    const network = getNetwork();

    // initialize
    const contract = new Contract(
      apicallProxy.address,
      ApiCallArtifact.abi,
      account
    ) as ApiCall;

    const tx = await contract.initialize(
      sxtOperator.address,
      (LINK_ADDRESS as any)[network],
      (SXT_JOB_ID as any)[network],
      (SXT_GATEWAY_ENDPOINT as any)[network]
    );

    await tx.wait();

    console.info("Initialize contract");
  }
);
