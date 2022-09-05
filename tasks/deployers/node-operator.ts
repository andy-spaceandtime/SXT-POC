import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";

import { SXTOperator, SXTOperator__factory } from "../../typechain-types";
import { writeContract, readContract, getNetwork } from "../utils/io";
import { LINK_ADDRESS } from "../utils/constants";

export const SXT_OPERATOR_CONTRACT_NAME = "SXTOperator";

task(
  "deploy:SXTOperator",
  "Deploy SXTOperator contract",
  async (_taskArgs, hre) => {
    const accounts: Signer[] = await hre.ethers.getSigners();
    const account = accounts[0];

    const NETWORK = getNetwork();
    const owner = await account.getAddress();

    const sxtOperatorFactory: SXTOperator__factory = <SXTOperator__factory>(
      await hre.ethers.getContractFactory(SXT_OPERATOR_CONTRACT_NAME, account)
    );
    const sxtOperator: SXTOperator = <SXTOperator>(
      await sxtOperatorFactory.deploy((LINK_ADDRESS as any)[NETWORK], owner)
    );
    await sxtOperator.deployed();

    writeContract(SXT_OPERATOR_CONTRACT_NAME, sxtOperator.address, [
      (LINK_ADDRESS as any)[NETWORK],
      owner,
    ]);
    console.info("SXTOperator contract deployed at: ", sxtOperator.address);
  }
);

task(
  "verify:SXTOperator",
  "Verify SXTOperator contract",
  async (_taskArgs, hre) => {
    const sxtOperator = readContract(SXT_OPERATOR_CONTRACT_NAME);
    await hre.run("verify:verify", {
      address: sxtOperator.address,
      constructorArguments: sxtOperator.args,
      contract: "contracts/SXTOperator.sol:SXTOperator",
    });
  }
);
