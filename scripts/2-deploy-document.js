//to run this on testnet:
// $ npx hardhat run scripts/1-deploy-document.js

const hardhat = require('hardhat')
const { deploy, getRole } = require('./utils')

//config

//main
async function main() {
  //get network and admin
  const network = hardhat.config.networks[hardhat.config.defaultNetwork]
  const admin = new ethers.Wallet(network.accounts[0])
  const metadata = { address: network.contracts.metadata }

  console.log('Deploying Document ...')
  const document = await deploy('Document', metadata.address, admin.address)
  const address = await document.getAddress();

  console.log('')
  console.log('-----------------------------------')
  console.log('Document deployed to:', address)
  console.log('')
  console.log('Roles: MINTER_ROLE, CURATOR_ROLE, APPROVED_ROLE')
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
  console.log('Next Steps:')
  console.log('In Document contract, grant CURATOR_ROLE to admin (choose another wallet)')
  console.log(` - ${network.scanner}/address/${address}#writeContract`)
  console.log(` - grantRole( ${getRole('CURATOR_ROLE')}, ${admin.address} )`)
  console.log('')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});