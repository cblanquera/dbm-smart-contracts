require('dotenv').config()

async function deploy(name, ...params) {
  const ContractFactory = await ethers.getContractFactory(name);
  const contract = await ContractFactory.deploy(...params);
  await contract.waitForDeployment();
  return contract;
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
  deploy,
  getRole
}