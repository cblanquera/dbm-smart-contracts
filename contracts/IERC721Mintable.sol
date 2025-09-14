// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

/**
 * @dev Interface for minting. This is used by a document spec
 * (ie. NCA, SARO) in order to delegate minting to the main contract.
 */
interface IERC721Mintable {
  /**
   * @dev Allows ITokenMetadata to mint to the `recipient`. 
   */
  function mint(address recipient) external returns(uint256);
}