const { expect, deploy, bindContract, getRole } = require('../utils');

function authorize(recipient, maxMint, maxFree) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(
      ['string', 'address', 'uint256', 'uint256'],
      ['mint', recipient, maxMint, maxFree]
    ).slice(2),
    'hex'
  )
}

describe('Document Tests', function () {
  before(async function() {
    const signers = await ethers.getSigners();

    const nft = await deploy('Document', signers[0].address)

    
  })
})