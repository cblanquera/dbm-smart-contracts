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
  cmc: process.env.CMC_KEY || '',
  network: process.env.DEFAULT_NETWORK || 'hardhat'
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: env.network,
  networks: {
    hardhat: {
      chainId: 1337,
      mining: {
        //set this to false if you want localhost to mimick a real blockchain
        auto: true,
        interval: 5000
      }
    },
    amoy: {
      url: env.amoy.rpc,
      accounts: env.amoy.pk !== '' ? [ env.amoy.pk ] : [],
      chainId: 80002
    },
    polygon: {
      url: env.polygon.rpc,
      accounts: env.polygon.pk !== '' ? [ env.polygon.pk ] : [],
      chainId: 137
    }
  },
  solidity: {
    version: '0.8.29',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    }
  },
  paths: {
    sources: './contracts',
    tests: './tests',
    cache: './cache',
    artifacts: './artifacts'
  },
  etherscan: {
    apiKey: {
      testnet: env.amoy.scan,
      mainnet: env.polygon.scan
    }
  },
  mocha: {
    timeout: 40000
  },
  gasReporter: {
    L1: 'polygon',
    currency: 'USD',
    currencyDisplayPrecision: 6,
    coinmarketcap: env.cmc,
    etherscan: env.polygon.scan,
    gasPrice: 30
  }
};