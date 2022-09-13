import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";

import { SXTToken, SXTToken__factory } from "../../typechain-types";
import { writeContract, readContract } from "../utils/io";

export const SXTTOKEN_CONTRACT_NAME = "SXTToken";

task("deploy:SXTToken", "Deploy SXTToken contract", async (_taskArgs, hre) => {
  const accounts: Signer[] = await hre.ethers.getSigners();
  const account = accounts[0];

  const SXT: SXTToken__factory = <SXTToken__factory>(
    await hre.ethers.getContractFactory(SXTTOKEN_CONTRACT_NAME, account)
  );
  const sxtToken: SXTToken = <SXTToken>await SXT.deploy();
  await sxtToken.deployed();

  writeContract(SXTTOKEN_CONTRACT_NAME, sxtToken.address, []);
  console.info("SXTToken contract deployed at: ", sxtToken.address);
});

task("verify:SXTToken", "Verify SXTToken contract", async (_taskArgs, hre) => {
  const sxtToken = readContract(SXTTOKEN_CONTRACT_NAME);
  await hre.run("verify:verify", {
    address: sxtToken.address,
    constructorArguments: sxtToken.args,
    contract: "contracts/SXTToken.sol:SXTToken",
  });
});
