// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

interface IContractMetadata {
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