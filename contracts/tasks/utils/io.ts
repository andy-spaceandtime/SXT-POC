import * as dotenv from "dotenv";
import * as fs from "fs";
import * as path from "path";

dotenv.config();

type FileName =
  | "ApiCall"
  | "ApiCallProxy"
  | "SXTOperator"
  | "Proxy"
  | "SXTToken";

export const getNetwork = () => {
  return process.env.DEPLOY_NETWORK || "hardhat";
};

export const writeContract = (
  contractFileName: FileName,
  address: string,
  args: any = []
) => {
  const NETWORK = getNetwork();

  fs.writeFileSync(
    path.join(__dirname, `${NETWORK}/${contractFileName}.json`),
    JSON.stringify(
      {
        address,
        args,
      },
      null,
      2
    )
  );
};

export const readContract = (contractFileName: FileName): any => {
  const NETWORK = getNetwork();

  try {
    const rawData = fs.readFileSync(
      path.join(__dirname, `${NETWORK}/${contractFileName}.json`)
    );
    const info = JSON.parse(rawData.toString());
    return {
      address: info.address,
      args: info.args,
    };
  } catch (error) {
    return {
      address: null,
      args: [],
    };
  }
};

export const writeABI = (
  contractPath: string,
  contractFileName: FileName
): any => {
  try {
    const rawData = fs.readFileSync(
      path.join(__dirname, "../../artifacts/contracts", contractPath)
    );
    const info = JSON.parse(rawData.toString());

    fs.writeFileSync(
      path.join(__dirname, "../../abis", `${contractFileName}.json`),
      JSON.stringify(info.abi, null, 2)
    );
  } catch (error) {
    console.error("Writing ABI error: ", error);
  }
};
