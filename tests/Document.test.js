const { 
  expect, 
  deploy, 
  bindContract, 
  getRole
} = require('./utils');

function authorizeMint(contract, recipient) {
  return Buffer.from(
    ethers.solidityPackedKeccak256(
      [ 'string', 'address', 'address' ],
      [ 'mint', contract, recipient ]
    ).slice(2),
    'hex'
  )
}

function authorizeBatch(contract, recipient, amount) {
  return Buffer.from(
    ethers.solidityPackedKeccak256(
      [ 'string', 'address', 'address', 'uint256' ],
      [ 'batch', contract, recipient, amount ]
    ).slice(2),
    'hex'
  )
}

describe('Document Tests', function () {
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

    //fix minting overrides
    //['mint(address)']
    //['mint(address,address)']
    //['mint(address,address,bytes)']
    for (let i = 0; i < signers.length; i++) {
      signers[i].withDocument.mint = function(...args) {
        switch (args.length) {
          case 1: return signers[i].withDocument['mint(address)'](...args)
          case 2: return signers[i].withDocument['mint(address,address)'](...args)
          case 3: return signers[i].withDocument['mint(address,address,bytes)'](...args)
        }
      }
    }

    //fix batch overrides
    //['batch(address,uint256)']
    //['batch(address,address,uint256)']
    //['batch(address,address,uint256,bytes)']
    for (let i = 0; i < signers.length; i++) {
      signers[i].withDocument.batch = function(...args) {
        switch (args.length) {
          case 1: return signers[i].withDocument['batch(address)'](...args)
          case 2: return signers[i].withDocument['batch(address,address)'](...args)
          case 3: return signers[i].withDocument['batch(address,address,uint256)'](...args)
          case 4: return signers[i].withDocument['batch(address,address,uint256,bytes)'](...args)
        }
      }
    }

    this.signers = { 
      admin, 
      curator, 
      approve, 
      minter,
      others: signers.slice(4)
    }
  })

  it('Should mint with MINTER_ROLE', async function () {
    const { admin, minter } = this.signers;
    await minter.withDocument.mint(this.contracts.nca, admin.address);
    await minter.withDocument.mint(this.contracts.nca, admin.address);

    expect(await admin.withDocument.ownerOf(1)).to.equal(admin.address);
    expect(await admin.withDocument.ownerOf(2)).to.equal(admin.address);
    expect(await admin.withDocument.totalSupply()).to.equal(2);
    expect(await admin.withDocument.balanceOf(admin.address)).to.equal(2);
  })

  it('Should mint with MINTER_ROLE permission', async function () {
    const { admin, minter, others } = this.signers;

    const proof = await minter.signMessage(
      authorizeMint(
        this.contracts.nca, 
        others[0].address
      )
    )
  
    await others[0].withDocument.mint(
      this.contracts.nca, 
      others[0].address, 
      proof
    )

    expect(await admin.withDocument.ownerOf(3)).to.equal(others[0].address);
    expect(await admin.withDocument.totalSupply()).to.equal(3);
    expect(await admin.withDocument.balanceOf(admin.address)).to.equal(2);
    expect(await admin.withDocument.balanceOf(others[0].address)).to.equal(1);
  })

  it('Should batch mint with MINTER_ROLE', async function () {
    const { admin, minter } = this.signers;
    await minter.withDocument.batch(this.contracts.nca, admin.address, 4);
    await minter.withDocument.batch(this.contracts.nca, admin.address, 6);
    await minter.withDocument.batch(this.contracts.nca, admin.address, 8);
    await minter.withDocument.batch(this.contracts.nca, admin.address, 10);
    for (let i = 4; i <= 30; i++) {
      expect(await admin.withDocument.ownerOf(i)).to.equal(admin.address);
    }
    expect(await admin.withDocument.totalSupply()).to.equal(31);
    expect(await admin.withDocument.balanceOf(admin.address)).to.equal(30);
  })

  it('Should batch mint with MINTER_ROLE permission', async function () {
    const { admin, minter, others } = this.signers;

    const proof = await minter.signMessage(
      authorizeBatch(
        this.contracts.nca, 
        others[0].address,
        4
      )
    )
  
    await others[0].withDocument.batch(
      this.contracts.nca, 
      others[0].address, 
      4,
      proof
    )

    for (let i = 32; i <= 35; i++) {
      expect(await admin.withDocument.ownerOf(i)).to.equal(others[0].address);
    }
    expect(await admin.withDocument.totalSupply()).to.equal(35);
  })

  it('Should update contract metadata', async function () {
    const { admin, curator } = this.signers;
    expect(await admin.withDocument.name()).to.equal('DBM Documents');
    expect(await admin.withDocument.symbol()).to.equal('DBMDocu');
    expect(await admin.withDocument.contractURI()).to.equal('ipfs://QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco');

    await curator.withDocument.updateMetadata(this.contracts.info);

    expect(await admin.withDocument.name()).to.equal('DBM Documents');
    expect(await admin.withDocument.symbol()).to.equal('DBMDocu');
    expect(await admin.withDocument.contractURI()).to.equal('ipfs://QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco');
  })

  it('Should transfer', async function () {
    const { admin } = this.signers
    const [ tokenOwner1, tokenOwner2 ] = this.signers.others;

    await admin.withDocument.transferFrom(admin.address, tokenOwner1.address, 1)
    await admin.withDocument.transferFrom(admin.address, tokenOwner2.address, 2)
    await tokenOwner2.withDocument.transferFrom(tokenOwner2.address, tokenOwner1.address, 2)

    expect(await admin.withDocument.ownerOf(1)).to.equal(tokenOwner1.address)
    expect(await admin.withDocument.ownerOf(2)).to.equal(tokenOwner1.address)
  })

  it('Should approve', async function () {
    const { admin } = this.signers
    const [ tokenOwner1, tokenOwner2 ] = this.signers.others;

    await tokenOwner1.withDocument.approve(tokenOwner2.address, 1)
    expect(await admin.withDocument.getApproved(1)).to.equal(tokenOwner2.address)

    await admin.withDocument.setApprovalForAll(tokenOwner1.address, true)
    expect(
      await admin.withDocument.isApprovedForAll(
        admin.address,
        tokenOwner1.address
      )
    ).to.equal(true)
  })

  it('Should not mint without MINTER_ROLE', async function () {
    const { admin, others } = this.signers;

    await expect(
      others[0].withDocument.mint(this.contracts.nca, others[0].address)
    ).to.be.reverted;
  })

  it('Should not mint without MINTER_ROLE permission', async function () {
    const { admin, others } = this.signers;

    const proof = await admin.signMessage(
      authorizeMint(
        this.contracts.nca,
        others[0].address
      )
    )

    await expect(
      others[0].withDocument.mint(this.contracts.nca, others[0].address, proof)
    ).to.be.reverted;
  })

  it('Should not batch mint without MINTER_ROLE', async function () {
    const { others } = this.signers;

    await expect(
      others[0].withDocument.batch(this.contracts.nca, others[0].address, 4)
    ).to.be.reverted;
  })

  it('Should not batch mint without MINTER_ROLE permission', async function () {
    const { admin, others } = this.signers;

    const proof = await admin.signMessage(
      authorizeBatch(
        this.contracts.nca,
        others[0].address,
        1000
      )
    )

    await expect(
      others[0].withDocument.batch(this.contracts.nca, others[0].address, 1000, proof)
    ).to.be.reverted;
  })

  it('Should not transfer', async function () {
    const { others } = this.signers;

    await expect(
      others[4].withDocument.transferFrom(others[0].address, others[1].address, 1)
    ).to.be.reverted;
  })

  it('Should not approve', async function () {
    const { others } = this.signers;

    await expect(
      others[4].withDocument.approve(others[1].address, 1)
    ).to.be.reverted;
  })
})