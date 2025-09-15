# ERC721 Transparent Documents Specifications

A working implementation of tokenizing documents and storing in the 
blockchain. These specifications are abstractions that cover the 
following principles.

 - Contract must be ownable; Owner manages the roles. This is a 
   provision for DAO.
 - Contract has roles and permissions:
   - `CURATOR_ROLE` can update contract's metadata (ex. DAO)
   - `APPROVED_ROLE` are for trusted platforms that can perform 
     token transfers
   - Only contracts that follow `IERC721TokenMetadata` could have 
     the `MINTER_ROLE`
 - Contract's metadata is managed by a separate contract that 
   follows `IERC721ContractMetadata`
 - Each token's metadata is managed by a separate `IERC721TokenMetadata` 
   contract. This means, tokens can be mapped to different metadata 
   contracts.
 - The purpose of `IERC721TokenMetadata` contract is to interface with 
   the main contract while providing unique search tools for advance 
   cases.

The contract architecture looks like the following:

```
Document.sol <- NCADocument.sol     <- NCASearch.sol
             <- SARODocument.sol    <- SAROSearch.sol
             <- [X]Document.sol     <- [X]Search.sol
             <- DocumentMetadata.sol
```

The purposes for each contract are as follows.

 - `Document.sol` 
   - The main implementation of ERC721
   - Single source of all the transparent documents
 - `[X]Document.sol`
   - A type of document with its own specifics
 - `[X]Search.sol`
   - A search indexer for `[X]Document.sol`
 - `DocumentMetadata.sol`
   - The main `Document.sol` general information

## 1. Auditing

Clone this repo in terminal and cd to that folder. Run the following commands.

```bash
$ cp .env.sample to .env
$ npm install
```

Sign up to [CoinmarketCap](https://pro.coinmarketcap.com/signup) and generate an API key. In `.env` to set the `CMC_KEY` to your API key.

## 2. Testing

Make sure in `.env` to set the `DEFAULT_NETWORK` to hardhat.

```bash
$ npm test
```

## 3. Reports

The following is an example gas report from the tests ran in this project and could change based on the cost of `POL` itself.

```
···············································································································
|  Solidity and Network Configuration                                                                         │
··························|·················|···············|·················|································
|  Solidity: 0.8.29       ·  Optim: true    ·  Runs: 200    ·  viaIR: false   ·     Block: 30,000,000 gas     │
··························|·················|···············|·················|································
|  Network: POLYGON       ·  L1: 30 gwei                    ·                 ·         0.27 usd/pol          │
··························|·················|···············|·················|················|···············
|  Contracts / Methods    ·  Min            ·  Max          ·  Avg            ·  # calls       ·  usd (avg)   │
··························|·················|···············|·················|················|···············
|  Document               ·                                                                                   │
··························|·················|···············|·················|················|···············
|      approve            ·              -  ·            -  ·         48,641  ·             1  ·    0.000394  │
··························|·················|···············|·················|················|···············
|      batch              ·        225,390  ·      506,220  ·        365,805  ·             4  ·    0.002963  │
··························|·················|···············|·················|················|···············
|      batch              ·              -  ·            -  ·        231,302  ·             1  ·    0.001874  │
··························|·················|···············|·················|················|···············
|      grantRole          ·         51,474  ·       51,498  ·         51,491  ·            11  ·    0.000417  │
··························|·················|···············|·················|················|···············
|      mint               ·         87,411  ·      121,611  ·        104,511  ·             2  ·    0.000847  │
··························|·················|···············|·················|················|···············
|      mint               ·              -  ·            -  ·        107,967  ·             1  ·    0.000875  │
··························|·················|···············|·················|················|···············
|      setApprovalForAll  ·              -  ·            -  ·         46,214  ·             1  ·    0.000374  │
··························|·················|···············|·················|················|···············
|      transferFrom       ·         38,133  ·       60,033  ·         47,033  ·             3  ·    0.000381  │
··························|·················|···············|·················|················|···············
|      updateMetadata     ·              -  ·            -  ·         26,427  ·             1  ·    0.000214  │
··························|·················|···············|·················|················|···············
|  NCADocument            ·                                                                                   │
··························|·················|···············|·················|················|···············
|      batch              ·      1,513,704  ·    4,346,072  ·      2,516,602  ·             3  ·    0.020384  │
··························|·················|···············|·················|················|···············
|      grantRole          ·              -  ·            -  ·         51,498  ·             1  ·    0.000417  │
··························|·················|···············|·················|················|···············
|      mint               ·        270,090  ·      689,905  ·        479,998  ·             2  ·    0.003888  │
··························|·················|···············|·················|················|···············
|      tokenize           ·              -  ·            -  ·        584,286  ·             1  ·    0.004733  │
··························|·················|···············|·················|················|···············
|  SARODocument           ·                                                                                   │
··························|·················|···············|·················|················|···············
|      batch              ·      1,766,515  ·    5,620,136  ·      3,051,132  ·             3  ·    0.024714  │
··························|·················|···············|·················|················|···············
|      grantRole          ·              -  ·            -  ·         51,520  ·             1  ·    0.000417  │
··························|·················|···············|·················|················|···············
|      mint               ·        584,996  ·      619,568  ·        602,282  ·             2  ·    0.004878  │
··························|·················|···············|·················|················|···············
|      tokenize           ·              -  ·            -  ·        513,883  ·             1  ·    0.004162  │
··························|·················|···············|·················|················|···············
|  Deployments                              ·                                 ·  % of limit    ·              │
··························|·················|···············|·················|················|···············
|  Document               ·              -  ·            -  ·      1,749,266  ·         5.8 %  ·    0.014169  │
··························|·················|···············|·················|················|···············
|  DocumentMetadata       ·              -  ·            -  ·        136,313  ·         0.5 %  ·    0.001104  │
··························|·················|···············|·················|················|···············
|  NCADocument            ·              -  ·            -  ·      2,461,989  ·         8.2 %  ·    0.019942  │
··························|·················|···············|·················|················|···············
|  SARODocument           ·              -  ·            -  ·      2,180,164  ·         7.3 %  ·    0.017659  │
··························|·················|···············|·················|················|···············
|  Key                                                                                                        │
···············································································································
|  ◯  Execution gas for this method does not include intrinsic gas overhead                                   │
···············································································································
|  △  Cost was non-zero but below the precision setting for the currency display (see options)                │
···············································································································
|  Toolchain:  hardhat                                                                                        │
···············································································································
```