require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();

const env = {
  amoy: {
    rpc: process.env.AMOY_RPC || 'https://rpc-amoy.polygon.technology',
    pk: process.env.AMOY_PK || '',
    scan: process.env.AMOY_SCAN || ''
  },
  polygon: {
    rpc: process.env.POLYGON_RPC || 'https://polygon-rpc.com/',
    pk: process.env.POLYGON_PK || '',
    scan: process.env.POLYGON_SCAN || ''
  },
  cmc: process.env.CMC_KEY || ''
};

module.exports = {
  defaultNetwork: 'testnet',
  networks: {
    hardhat: {
      chainId: 1011
    },
    testnet: {
      url: env.amoy.rpc,
      accounts: env.amoy.pk !== '' ? [ env.amoy.pk ] : [],
      chainId: 80002
    },
    mainnet: {
      url: env.polygon.rpc,
      accounts: env.polygon.pk !== '' ? [ env.polygon.pk ] : [],
      chainId: 137
    },
  },
  etherscan: {
    apiKey: {
      testnet: env.amoy.scan,
      mainnet: env.polygon.scan
    }
  },
  solidity: {
    version: '0.8.29',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  // Other configurations like paths, mocha, etc. can be added here
  paths: {
    sources: './contracts',
    tests: './tests',
    cache: './cache',
    artifacts: './artifacts'
  },
  mocha: {
    timeout: 40000
  },
  gasReporter: {
    currency: 'USD',
    coinmarketcap: env.cmc,
    gasPrice: 20
  }
};