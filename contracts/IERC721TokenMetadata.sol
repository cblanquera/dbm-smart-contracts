// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

/**
 * @dev Interface for token metadata management. This is used by 
 * the main document contract to delegate token metadata management to 
 * separate contracts, enabling more flexible and modular metadata 
 * handling.
 */
interface IERC721TokenMetadata {
  /**
   * @dev Returns the token URI for a given token ID.
   */
  function tokenURI(uint256 tokenId) external view returns(string memory);
}