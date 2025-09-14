// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { IContractMetadata } from "./IContractMetadata.sol";

contract DocumentMetadata is IContractMetadata {
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