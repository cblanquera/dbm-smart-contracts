const { expect, deploy, bindContract, getRole } = require('./utils');
const data = require('./fixtures');

describe('SAROSearch Tests', function () {
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
    //7. Deploy SARO Search Contract
    //   - ARG1: SARO Document Contract
    const saroSearch = await deploy('SAROSearch', this.contracts.saro);
    await bindContract('withSaroSearch', 'SAROSearch', saroSearch, signers);

    this.signers = { 
      admin, 
      curator, 
      approve, 
      minter,
      others: signers.slice(4)
    }
  })
})