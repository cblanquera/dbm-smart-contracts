//to run this on testnet:
// $ npx hardhat run scripts/1-deploy-nca-search.js

const hardhat = require('hardhat')
const { deploy } = require('./utils')

//main
async function main() {
  //get network and admin
  const network = hardhat.config.networks[hardhat.config.defaultNetwork]
  const admin = new ethers.Wallet(network.accounts[0])
  const nca = { address: network.contracts.nca }

  console.log('Deploying NCASearch ...')
  const search = await deploy('NCASearch', nca.address)
  const address = await search.getAddress();

  console.log('')
  console.log('-----------------------------------')
  console.log('NCASearch deployed to:', address)
  console.log('')
  console.log(
    'npx hardhat verify --show-stack-traces --network',
    hardhat.config.defaultNetwork,
    address,
    `"${preview}"`,
    `"${admin.address}"`
  )
  console.log('')
  console.log('-----------------------------------')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});