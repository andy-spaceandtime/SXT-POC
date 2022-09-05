import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";

import { Proxy, Proxy__factory } from "../../typechain-types";
import { writeContract, readContract } from "../utils/io";
import { API_CALL_CONTRACT_NAME } from "./api-call";

export const API_CALL_PROXY_CONTRACT_NAME = "ApiCallProxy";

task(
  "deploy:ApiCallProxy",
  "Deploy ApiCallProxy contract",
  async (_taskArgs, hre) => {
    const accounts: Signer[] = await hre.ethers.getSigners();
    const account = accounts[0];

    const proxyFactory: Proxy__factory = <Proxy__factory>(
      await hre.ethers.getContractFactory("Proxy", account)
    );
    const proxy: Proxy = <Proxy>(
      await proxyFactory.deploy(API_CALL_PROXY_CONTRACT_NAME)
    );
    await proxy.deployed();

    writeContract(API_CALL_PROXY_CONTRACT_NAME, proxy.address, []);
    console.info("ApiCallProxy contract deployed at: ", proxy.address);

    const apiCall = readContract(API_CALL_CONTRACT_NAME);
    if (!apiCall.address) {
      console.info("ApiCall contract is not deployed yet");
      return;
    }

    // Set Implementation
    const tx = await proxy.setImplementation(apiCall.address);
    await tx.wait();
  }
);

task(
  "verify:ApiCallProxy",
  "Verify ApiCallProxy contract",
  async (_taskArgs, hre) => {
    const proxy = readContract(API_CALL_PROXY_CONTRACT_NAME);
    await hre.run("verify:verify", {
      address: proxy.address,
      constructorArguments: [API_CALL_PROXY_CONTRACT_NAME],
    });
  }
);
