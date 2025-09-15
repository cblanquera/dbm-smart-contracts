const { expect, deploy, bindContract, getRole } = require('./utils');
const data = require('./fixtures');

describe('SARODocument Tests', function () {
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
    //4. Deploy SARO Document Contract
    //   - ARG1: Base URI
    //   - ARG2: Document Contract
    //   - ARG2: Admin Address
    const saro = await deploy('SARODocument', 'ipfs://', this.contracts.document, admin.address);
    //save address for later use
    this.contracts.saro = await saro.getAddress();
    await bindContract('withSaro', 'SARODocument', saro, signers);
    //5. Document Contract - MINTER_ROLE to SARO Document Contract
    await admin.withDocument.grantRole(getRole('MINTER_ROLE'), this.contracts.saro);
    //6. SARO Document Contract - Set MINTER_ROLE
    await saro.grantRole(getRole('MINTER_ROLE'), minter.address);

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
      await minter.withSaro.mint(
        admin.address, 
        data.saro.singles[0].cid, 
        data.saro.singles[0].data, 
        data.saro.singles[0].released
      );
      await minter.withSaro.mint(
        admin.address, 
        data.saro.singles[1].cid, 
        data.saro.singles[1].data, 
        data.saro.singles[1].released
      );
  
      expect(await admin.withDocument.ownerOf(1)).to.equal(admin.address);
      expect(await admin.withDocument.ownerOf(2)).to.equal(admin.address);
      expect(await admin.withDocument.totalSupply()).to.equal(2);
      expect(await admin.withDocument.balanceOf(admin.address)).to.equal(2);
    })
  
    it('Should batch mint', async function () {
      const { admin, minter } = this.signers;
      await minter.withSaro.batch(
        admin.address, 
        data.saro.batches[0].cids, 
        data.saro.batches[0].data, 
        data.saro.batches[0].released
      );
      await minter.withSaro.batch(
        admin.address, 
        data.saro.batches[1].cids, 
        data.saro.batches[1].data, 
        data.saro.batches[1].released
      );
      await minter.withSaro.batch(
        admin.address, 
        data.saro.batches[2].cids, 
        data.saro.batches[2].data, 
        data.saro.batches[2].released
      );
  
      for (let i = 3; i <= 18; i++) {
        expect(await admin.withDocument.ownerOf(i)).to.equal(admin.address);
      }
      expect(await admin.withDocument.totalSupply()).to.equal(18);
      expect(await admin.withDocument.balanceOf(admin.address)).to.equal(18);
    })
  
    it('Should tokenize', async function () {
      const { admin, minter } = this.signers;
      await minter.withSaro.tokenize(
        admin.address, 
        data.saro.singles[0].cid + 'xxx', 
        {
          ...data.saro.singles[0].data,
          saroNumber: data.saro.singles[0].data.saroNumber + 'xxx'
        }, 
        data.saro.singles[0].released
      );
  
      expect(await admin.withDocument.ownerOf(17)).to.equal(admin.address);
    })
})