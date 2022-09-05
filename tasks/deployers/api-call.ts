import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";

import { ApiCall, ApiCall__factory } from "../../typechain-types";
import { writeContract, readContract } from "../utils/io";

export const API_CALL_CONTRACT_NAME = "ApiCall";

task("deploy:ApiCall", "Deploy ApiCall contract", async (_taskArgs, hre) => {
  const accounts: Signer[] = await hre.ethers.getSigners();
  const account = accounts[0];

  const apiCallFactory: ApiCall__factory = <ApiCall__factory>(
    await hre.ethers.getContractFactory(API_CALL_CONTRACT_NAME, account)
  );
  const apiCall: ApiCall = <ApiCall>await apiCallFactory.deploy();
  await apiCall.deployed();

  writeContract(API_CALL_CONTRACT_NAME, apiCall.address, []);
  console.info("ApiCall contract deployed at: ", apiCall.address);
});

task("verify:ApiCall", "Verify ApiCall contract", async (_taskArgs, hre) => {
  const apiCall = readContract(API_CALL_CONTRACT_NAME);
  await hre.run("verify:verify", {
    address: apiCall.address,
    constructorArguments: [],
  });
});
