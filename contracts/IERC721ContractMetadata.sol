// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

/**
 * @dev Interface for contract metadata management. This is used by 
 * the main document contract to delegate contract metadata management 
 * to a separate contract, enabling more flexible and modular metadata 
 * handling.
 */
interface IERC721ContractMetadata {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns(string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns(string memory);

  /**
   * @dev Returns the contract URI.
   */
  function contractURI() external view returns(string memory);
}