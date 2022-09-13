const Web3 = require("web3");
const Tx = require("ethereumjs-tx");
const fs = require("fs");
const path = require("path");
const axios = require("axios").default;

const { validateEnv } = require("./envutils");

// create intial web3 provider
const providerUrl = validateEnv("WEB3_PROVIDER_URL");
const web3 = new Web3(new Web3.providers.HttpProvider(providerUrl));

const providerUrlWSS = validateEnv("WEB3_PROVIDER_WSS_URL");
const web3wss = new Web3(new Web3.providers.WebsocketProvider(providerUrlWSS));

const serviceAccount = web3.eth.accounts.wallet.add(
  validateEnv("SERVICE_PRIVATE_KEY")
);
const apiContractAddress = validateEnv("API_CONTRACT_ADDRESS");

// log some info out to keep the user informed
console.log(`Provider URL.............: ${providerUrl}`);
console.log(`Service Account Address..: ${serviceAccount.address}`);
console.log(`API contract address.: ${apiContractAddress}`);

// build up web3 components needed for the service
const apiContractSON = JSON.parse(
  fs.readFileSync(path.join(__dirname, "./contract-abi/Api.json"))
);
const apiContract = new web3.eth.Contract(apiContractSON, apiContractAddress, {
  from: serviceAccount.address,
  gasLimit: 3000000,
});
const apiContractWss = new web3wss.eth.Contract(
  apiContractSON,
  apiContractAddress,
  { from: serviceAccount.address, gasLimit: 3000000 }
);

// listen to an event
apiContractWss.events
  .ExecuteApi({}) //ExecuteApi is the event name
  .on("data", async function (event) {
    let stringObj = JSON.stringify(event.returnValues);
    let jsonObj = JSON.parse(stringObj);

    axios
      .get(jsonObj.url) // here url is the request from the user.
      .then(async function (response) {
        console.log(response.data);
        // make a web3 call here to write the response.data to user address.
      })
      .catch(function (error) {
        console.log(error);
      })
      .then(function () {});
  })
  .on("error", console.error);
