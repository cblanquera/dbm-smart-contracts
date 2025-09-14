// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

/**
 * @dev Interface for minting. This is used by a document spec
 * (ie. NCA, SARO) in order to delegate minting to the main contract.
 */
interface IERC721Mintable {
  /**
   * @dev Allows ITokenMetadata to mint. This is a 2FA because 
   * the ITokenMetadata also must be the minter role. This ensures
   * that only audited metadata contracts can mint.
   */
  function mint(address recipient) external returns(uint256);
}