// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { IERC721ContractMetadata } from "./IERC721ContractMetadata.sol";

/**
  * @dev This contracts gets attached to the main document contract
  * in order to provide contract metadata (name, symbol, contractURI).
  *
  * You can change deploy another version of this contract to update 
  * the main contract's metadata.
 */
contract DocumentMetadata is IERC721ContractMetadata {
  // ============ Read Methods ============

  /**
   * @dev Returns the token collection name.
   */
  function name() external pure returns(string memory) {
    return "DBM Documents";
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure returns(string memory) {
    return "DBMDocu";
  }

  /**
   * @dev Returns the contract URI.
   */
  function contractURI() external pure returns(string memory) {
    return "ipfs://QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco";
  }
}