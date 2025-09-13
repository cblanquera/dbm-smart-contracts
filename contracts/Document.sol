// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { 
  IContractMetadata,
  ITokenMetadata,
  Ownable,
  DocumentAbstract 
} from "./DocumentAbstract.sol";

error InvalidProof();

contract Document is ReentrancyGuard, DocumentAbstract {
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
   * @dev Allows anyone to mint tokens that was approved by the owner
   */
  function mint(ITokenMetadata metadata, bytes memory proof) 
    external payable nonReentrant 
  {
    address recipient = _msgSender();

    // Note: We are doing it this way instead of creating a variable...
    //4. Make sure the minter signed this off
    if (!hasRole(
      _MINTER_ROLE, 
      // 3. Then recover the signer (address)
      ECDSA.recover(
        // 2. Then convert to bytes32
        MessageHashUtils.toEthSignedMessageHash(
          // 1. Make a message hash
          keccak256(
            abi.encodePacked(
              "mint", 
              recipient, 
              address(metadata)
            )
          )
        ),
        proof
      )
    )) {
      revert InvalidProof();
    }

    // Get the next token ID
    uint256 tokenId = super.totalSupply() + 1;
    // Mint the token
    _safeMint(recipient, tokenId);
    // Map the token metadata
    _mapData(tokenId, metadata);
  }

  // ============ Admin Methods ============

  /**
   * @dev Allows the _MINTER_ROLE to mint any to anyone
   */
  function mint(ITokenMetadata metadata) 
    external onlyRole(_MINTER_ROLE) nonReentrant 
  {
    // Get the next token ID
    uint256 tokenId = super.totalSupply() + 1;
    // Get the recipient
    address recipient = _msgSender();
    // Mint the token
    _safeMint(recipient, tokenId);
    // Map the token metadata
    _mapData(tokenId, metadata);
  }
}