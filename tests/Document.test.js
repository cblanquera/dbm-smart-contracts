const { expect, deploy, bindContract, getRole } = require('../utils');
const { nca, saro } = require('./fixtures');

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
    const [ admin, curator, approve, minter ] = signers;

    //1. Deploy DocumentMetadata Contract (no constructor args)
    const info = await deploy('DocumentMetadata');
    //2. Deploy Document Contract 
    //   - ARG1: DocumentMetadata Contract
    //   - ARG2: Admin Address
    const document = await deploy('Document', info.address, admin.address);
    await bindContract('withDocument', 'Document', document, signers);
    //3. Document Contract - Set CURATOR_ROLE, APPROVE_ROLE, MINTER_ROLE
    await admin.withDocument.grantRole(getRole('CURATOR_ROLE'), curator.address);
    await admin.withDocument.grantRole(getRole('APPROVE_ROLE'), approve.address);
    await admin.withDocument.grantRole(getRole('MINTER_ROLE'), minter.address);
    //4. Deploy NCA Document Contract
    //   - ARG1: Base URI
    //   - ARG2: Document Contract
    //   - ARG2: Admin Address
    const nca = await deploy('NCADocument', 'ipfs://', document.address, admin.address);
    await bindContract('withNca', 'NCADocument', nca, signers);
    //5. Document Contract - MINTER_ROLE to NCA Document Contract
    await admin.withDocument.grantRole(getRole('MINTER_ROLE'), nca.address);
    //6. NCA Document Contract - Set MINTER_ROLE
    await nca.grantRole(getRole('MINTER_ROLE'), minter.address);
    //7. Deploy NCA Search Contract
    //   - ARG1: NCA Document Contract
    const ncaSearch = await deploy('NCADocumentSearch', nca.address);
    await bindContract('withNcaSearch', 'NCADocumentSearch', ncaSearch, signers);
    //8. Deploy SARO Document Contract
    //   - ARG1: Base URI
    //   - ARG2: Document Contract
    //   - ARG2: Admin Address
    const saro = await deploy('SARODocument', 'ipfs://', document.address, admin.address);
    await bindContract('withSaro', 'SARODocument', saro, signers);
    //9. Document Contract - MINTER_ROLE to SARO Document Contract
    await admin.withDocument.grantRole(getRole('MINTER_ROLE'), saro.address);
    //10. SARO Document Contract - Set MINTER_ROLE
    await saro.grantRole(getRole('MINTER_ROLE'), minter.address);
    //11. Deploy SARO Search Contract
    //   - ARG1: SARO Document Contract
    const saroSearch = await deploy('SARODocumentSearch', saro.address);
    await bindContract('withSaroSearch', 'SARODocumentSearch', saroSearch, signers);

    this.signers = { 
      admin, 
      curator, 
      approve, 
      minter,
      others: signers.slice(4)
    }
  })

  it('Should mint with NCA', async function () {
    const { admin, minter } = this.signers;
    await minter.withNca.mint(
      admin, 
      nca.singles[0].cid, 
      nca.singles[0].data, 
      nca.singles[0].released
    );
    await minter.withNca.mint(
      admin, 
      nca.singles[1].cid, 
      nca.singles[1].data, 
      nca.singles[1].released
    );

    expect(await admin.withNca.ownerOf(1)).to.equal(admin.address);
    expect(await admin.withNca.ownerOf(2)).to.equal(admin.address);
  })

  it('Should mint with SARO', async function () {
    const { admin, minter } = this.signers;
    await minter.withSaro.mint(
      admin, 
      saro.singles[0].cid, 
      saro.singles[0].data, 
      saro.singles[0].released
    );
    await minter.withSaro.mint(
      admin, 
      saro.singles[1].cid, 
      saro.singles[1].data, 
      saro.singles[1].released
    );

    expect(await admin.withSaro.ownerOf(1)).to.equal(admin.address);
    expect(await admin.withSaro.ownerOf(2)).to.equal(admin.address);
  })
})