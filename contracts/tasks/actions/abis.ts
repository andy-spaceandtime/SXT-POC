import { task } from "hardhat/config";
import { writeABI } from "../utils/io";

task("action:abis", "Export contract abis", async () => {
  // Export ApiCall ABI
  await writeABI("ApiCall.sol/ApiCall.json", "ApiCall");

  // Export Proxy ABI
  await writeABI("proxy/Proxy.sol/Proxy.json", "Proxy");

  // Export SXTOperator ABI
  await writeABI("SXTOperator.sol/SXTOperator.json", "SXTOperator");

  // Export SXTToken ABI
  await writeABI("SXTToken.sol/SXTToken.json", "SXTToken");
});
