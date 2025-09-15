//to run this on testnet:
// $ npx hardhat run scripts/1-deploy-nca.js

const hardhat = require('hardhat')
const { deploy, getRole } = require('./utils')

//config
const baseURI = 'ipfs://';

//main
async function main() {
  //get network and admin
  const network = hardhat.config.networks[hardhat.config.defaultNetwork]
  const admin = new ethers.Wallet(network.accounts[0])
  const document = { address: network.contracts.document }

  console.log('Deploying NCADocument ...')
  const nca = await deploy('NCADocument', baseURI, document.address, admin.address)
  const address = await nca.getAddress();

  console.log('')
  console.log('-----------------------------------')
  console.log('NCADocument deployed to:', address)
  console.log('')
  console.log('Roles: MINTER_ROLE')
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
  console.log('In Document contract, grant MINTER_ROLE to NCADocument')
  console.log(` - ${network.scanner}/address/${document.address}#writeContract`)
  console.log(` - grantRole( ${getRole('MINTER_ROLE')}, ${address} )`)
  console.log('In NCADocument contract, grant MINTER_ROLE to admin (choose another wallet)')
  console.log(` - ${network.scanner}/address/${address}#writeContract`)
  console.log(` - grantRole( ${getRole('MINTER_ROLE')}, ${admin.address} )`)
  console.log('')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
});