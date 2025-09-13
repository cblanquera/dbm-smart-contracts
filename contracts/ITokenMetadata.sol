// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

interface ITokenMetadata {
  /**
   * @dev Returns the token URI for a given token ID.
   */
  function tokenURI(uint256 tokenId) external view returns(string memory);
}