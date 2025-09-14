const { expect } = require('chai');
require('dotenv').config()

if (process.env.DEFAULT_NETWORK !== 'hardhat') {
  console.error('Exited testing with network:', process.env.DEFAULT_NETWORK);
  process.exit(1);
}

async function deploy(name, ...params) {
  const ContractFactory = await ethers.getContractFactory(name);
  const contract = await ContractFactory.deploy(...params);
  await contract.waitForDeployment();
  return contract;
}

async function bindContract(key, name, contract, signers) {
  const address = await contract.getAddress();
  for (let i = 0; i < signers.length; i++) {
    const Factory = await ethers.getContractFactory(name, signers[i]);
    signers[i][key] = Factory.attach(address);
  }
  return signers;
}

function getRole(name) {
  if (!name || name === 'DEFAULT_ADMIN_ROLE') {
    return '0x' + '00'.repeat(32);
  }
  // OpenZeppelin role IDs are keccak256 of the string
  // v6: use ethers.id (keccak256(utf8))
  return ethers.id(name);
}

module.exports = {
  expect,
  deploy,
  bindContract,
  getRole
}