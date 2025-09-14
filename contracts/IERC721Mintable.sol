// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { IERC721TokenMetadata } from "./IERC721TokenMetadata.sol";

/**
 * @dev Interface for minting. This is used by a document spec
 * (ie. NCA, SARO) in order to delegate minting to the main contract.
 */
interface IERC721Mintable {
  /**
   * @dev Allows ITokenMetadata to mint to the `recipient`. 
   */
  function mint(address recipient) external returns(uint256);

  /**
   * @dev Allows anyone to mint tokens that was approved by the owner.
   * (ie. moves the burden of gas to the minter)
   */
  function mint(
    IERC721TokenMetadata metadata, 
    address recipient, 
    bytes memory proof
  ) external;

  /**
   * @dev Allows the minter role to mint to `recipient` with 
   * specific `data`. This is used in the case platforms want to 
   * facilitate the mint (ie. to save on gas).
   */
  function mint(IERC721TokenMetadata data, address recipient) 
    external returns(uint256);
}