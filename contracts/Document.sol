// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IDocumentMintable } from "./IDocumentMintable.sol";
import { 
  IContractMetadata,
  ITokenMetadata,
  Ownable,
  DocumentAbstract 
} from "./DocumentAbstract.sol";

error InvalidProof();

contract Document is 
  IDocumentMintable, 
  ReentrancyGuard, 
  DocumentAbstract 
{
  // ============ Constants ============

  //additional roles
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");

  // ============ Deploy ============
  /**
   * @dev Sets the data contract and the default owner.
   */
  constructor(IContractMetadata data, address admin) Ownable(admin)  {
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
    _mapData(tokenId, ITokenMetadata(_msgSender()));
    return tokenId;
  }
}