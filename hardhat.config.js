require("@nomicfoundation/hardhat-toolbox");

require("dotenv").config({ path: __dirname + "/.env" });
require("hardhat-deploy");
const DEPLOYER_PKs = {
  amoy: [process.env.WALLET_PK_AMOY],
  // zkevm_test: [process.env.WALLET_PK_ZKEVM_TEST],
  polygon_main: [process.env.WALLET_PK_PROD],
};

const etherscanKey = process.env.ETHERSCAN_KEY;
const okLinkAPIKey = process.env.OKLINK_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  // defaultNetwork: "amoy",
  defaultNetwork: "amoy",
  // defaultNetwork: "polygon_main",
  networks: {
    hardhat: {
      chainId: 1011,
    },
    amoy: {
      url: "https://rpc-amoy.polygon.technology",
      chainId: 80002,
      accounts: DEPLOYER_PKs.amoy,
      // blockConfirmations: 6,
    },
    // zkevm_test: {
    //   url: "https://endpoints.omniatech.io/v1/polygon-zkevm/testnet/public",
    //   chainId: 1442,
    //   accounts: DEPLOYER_PKs.zkevm_test
    // },
    polygon_main: {
      url: "https://polygon-rpc.com/",
      chainId: 137,
      accounts: DEPLOYER_PKs.polygon_main,
    },
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    // apiKey: etherscanKey,
    // apiKey: okLinkAPIKey,
    apiKey: {
      polygon: etherscanKey,
      amoy: okLinkAPIKey,
    },
    customChains: [
      {
        network: "amoy",
        chainId: 80002,
        urls: {
          apiURL:
            "https://www.oklink.com/api/explorer/v1/contract/verify/async/api/polygonAmoy",
          browserURL: "https://www.oklink.com/amoy",
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
  },
  mocha: {
    timeout: 500000, // 500 seconds max for running tests
  },
};
