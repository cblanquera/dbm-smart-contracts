//to run this on testnet:
// $ npx hardhat run scripts/1-deploy-metadata.js

const hardhat = require('hardhat')
const { deploy } = require('./utils')

//main
async function main() {
  //get network and admin
  const network = hardhat.config.networks[hardhat.config.defaultNetwork]
  const admin = new ethers.Wallet(network.accounts[0])

  console.log('Deploying DocumentMetadata ...')
  const metadata = await deploy('DocumentMetadata')
  const address = await metadata.getAddress();

  console.log('')
  console.log('-----------------------------------')
  console.log('DocumentMetadata deployed to:', address)
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