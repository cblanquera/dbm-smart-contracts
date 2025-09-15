const { expect, deploy, bindContract, getRole } = require('./utils');
const data = require('./fixtures');

describe('NCADocument Tests', function () {
  before(async function() {
    const signers = await ethers.getSigners();
    const [ admin, curator, approve, minter ] = signers;

    this.contracts = {};

    //1. Deploy DocumentMetadata Contract (no constructor args)
    const info = await deploy('DocumentMetadata');
    //save address for later use
    this.contracts.info = await info.getAddress();
    //2. Deploy Document Contract
    //   - ARG1: DocumentMetadata Contract
    //   - ARG2: Admin Address
    const document = await deploy('Document', this.contracts.info, admin.address);
    //save address for later use
    this.contracts.document = await document.getAddress();
    await bindContract('withDocument', 'Document', document, signers);
    //3. Document Contract - Set CURATOR_ROLE, APPROVE_ROLE, MINTER_ROLE
    await admin.withDocument.grantRole(getRole('CURATOR_ROLE'), curator.address);
    await admin.withDocument.grantRole(getRole('APPROVE_ROLE'), approve.address);
    await admin.withDocument.grantRole(getRole('MINTER_ROLE'), minter.address);
    //4. Deploy NCA Document Contract
    //   - ARG1: Base URI
    //   - ARG2: Document Contract
    //   - ARG2: Admin Address
    const nca = await deploy('NCADocument', 'ipfs://', this.contracts.document, admin.address);
    //save address for later use
    this.contracts.nca = await nca.getAddress();
    await bindContract('withNca', 'NCADocument', nca, signers);
    //5. Document Contract - MINTER_ROLE to NCA Document Contract
    await admin.withDocument.grantRole(getRole('MINTER_ROLE'), this.contracts.nca);
    //6. NCA Document Contract - Set MINTER_ROLE
    await nca.grantRole(getRole('MINTER_ROLE'), minter.address);

    this.signers = { 
      admin, 
      curator, 
      approve, 
      minter,
      others: signers.slice(4)
    }
  })

  it('Should mint', async function () {
    const { admin, minter } = this.signers;
    await minter.withNca.mint(
      admin.address, 
      data.nca.singles[0].cid, 
      data.nca.singles[0].data, 
      data.nca.singles[0].released
    );
    await minter.withNca.mint(
      admin.address, 
      data.nca.singles[1].cid, 
      data.nca.singles[1].data, 
      data.nca.singles[1].released
    );

    expect(await admin.withDocument.ownerOf(1)).to.equal(admin.address);
    expect(await admin.withDocument.ownerOf(2)).to.equal(admin.address);
    expect(await admin.withDocument.totalSupply()).to.equal(2);
    expect(await admin.withDocument.balanceOf(admin.address)).to.equal(2);
  })

  it('Should batch mint', async function () {
    const { admin, minter } = this.signers;
    await minter.withNca.batch(
      admin.address, 
      data.nca.batches[0].cids, 
      data.nca.batches[0].data, 
      data.nca.batches[0].released
    );
    await minter.withNca.batch(
      admin.address, 
      data.nca.batches[1].cids, 
      data.nca.batches[1].data, 
      data.nca.batches[1].released
    );
    await minter.withNca.batch(
      admin.address, 
      data.nca.batches[2].cids, 
      data.nca.batches[2].data, 
      data.nca.batches[2].released
    );

    for (let i = 3; i <= 18; i++) {
      expect(await admin.withDocument.ownerOf(i)).to.equal(admin.address);
    }
    expect(await admin.withDocument.totalSupply()).to.equal(18);
    expect(await admin.withDocument.balanceOf(admin.address)).to.equal(18);
  })

  it('Should tokenize', async function () {
    const { admin, minter } = this.signers;
    await minter.withNca.tokenize(
      admin.address, 
      data.nca.singles[0].cid + 'xxx', 
      {
        ...data.nca.singles[0].data,
        ncaNumber: data.nca.singles[0].data.ncaNumber + 'xxx'
      }, 
      data.nca.singles[0].released
    );

    expect(await admin.withDocument.ownerOf(17)).to.equal(admin.address);
  })
})