// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IERC721Mintable } from "./IERC721Mintable.sol";
import { 
  IERC721ContractMetadata,
  IERC721TokenMetadata,
  Ownable,
  ERC721DocumentSpec
} from "./ERC721DocumentSpec.sol";

error InvalidProof();

/**
 * @dev Covers configuration and minting. See ERC721DocumentSpec 
 * for underlying logic.
 */
contract Document is 
  IERC721Mintable, 
  ReentrancyGuard, 
  ERC721DocumentSpec
{
  // ============ Constants ============

  //additional roles
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");

  // ============ Deploy ============
  /**
   * @dev Sets the data contract and the default owner.
   */
  constructor(IERC721ContractMetadata data, address admin) Ownable(admin)  {
    _contractData = data;
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
  }

  // ============ Write Methods ============

  /**
   * @dev Allows ITokenMetadata to mint. This is a 2FA because 
   * the ITokenMetadata also must be the minter role. This ensures
   * that only audited metadata contracts can mint.
   */
  function mint(address recipient) 
    external onlyRole(_MINTER_ROLE) nonReentrant returns(uint256) 
  {
    // Get the next token ID
    uint256 tokenId = super.totalSupply() + 1;
    // Mint the token
    _safeMint(recipient, tokenId);
    // Map the token metadata
    _mapData(tokenId, IERC721TokenMetadata(_msgSender()));
    return tokenId;
  }
}