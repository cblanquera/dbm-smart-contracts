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