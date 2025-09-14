// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Verifier } from "./utils/Verifier.sol";

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
   * @dev Allows ITokenMetadata to batch mint to `recipient`. This is a 
   * 2FA because the ITokenMetadata also must be the minter role. 
   * This ensures that only audited metadata contracts can mint.
   */
  function batch(address recipient, uint256 amount) 
    external onlyRole(_MINTER_ROLE) nonReentrant
  {
    _batchMintAndMap(IERC721TokenMetadata(_msgSender()), recipient, amount);
  }

  /**
   * @dev Allows the minter role to batch mint to `recipient` with 
   * specific `data`. This is used in the case platforms want to 
   * facilitate the mint (ie. to save on gas).
   */
  function batch(IERC721TokenMetadata data, address recipient, uint256 amount) 
    external onlyRole(_MINTER_ROLE) nonReentrant
  {
    // Mint the token and map the metadata
    _batchMintAndMap(data, recipient, amount);
  }

  /**
   * @dev Allows anyone to batch mint tokens that was approved by the 
   * minter role. (ie. moves the burden of gas to the minter)
   */
  function batch(
    IERC721TokenMetadata data, 
    address recipient,
    uint256 amount, 
    bytes memory proof
  ) external nonReentrant {
    // Make sure the minter signed this off
    if (!hasRole(_MINTER_ROLE, Verifier.author(
      abi.encodePacked("batch", address(data), recipient), 
      proof
    ))) {
      revert InvalidProof();
    }
    // Mint the token and map the metadata
    _batchMintAndMap(data, recipient, amount);
  }

  /**
   * @dev Allows ITokenMetadata to mint to `recipient`. This is a 
   * 2FA because the ITokenMetadata also must be the minter role. 
   * This ensures that only audited metadata contracts can mint.
   */
  function mint(address recipient) 
    external onlyRole(_MINTER_ROLE) nonReentrant
  {
    _mintAndMap(IERC721TokenMetadata(_msgSender()), recipient);
  }

  /**
   * @dev Allows the minter role to mint to `recipient` with 
   * specific `data`. This is used in the case platforms want to 
   * facilitate the mint (ie. to save on gas).
   */
  function mint(IERC721TokenMetadata data, address recipient) 
    external onlyRole(_MINTER_ROLE) nonReentrant
  {
    // Mint the token and map the metadata
    _mintAndMap(data, recipient);
  }

  /**
   * @dev Allows anyone to mint tokens that was approved by the minter 
   * role. (ie. moves the burden of gas to the minter)
   */
  function mint(
    IERC721TokenMetadata data, 
    address recipient, 
    bytes memory proof
  ) external nonReentrant {
    // Make sure the minter signed this off
    if (!hasRole(_MINTER_ROLE, Verifier.author(
      abi.encodePacked("mint", address(data), recipient), 
      proof
    ))) {
      revert InvalidProof();
    }
    // Mint the token and map the metadata
    _mintAndMap(data, recipient);
  }

  /**
   * @dev Override to return the total supply.
   */
  function totalSupply() 
    public 
    view 
    override(IERC721Mintable, ERC721DocumentSpec) 
    returns(uint256) 
  {
    return super.totalSupply();
  }

  // ============ Internal Methods ============

  /**
   * @dev Batch mints token and maps its metadata.
   */
  function _batchMintAndMap(
    IERC721TokenMetadata data, 
    address recipient, 
    uint256 amount
  ) internal {
    // Get the start token ID
    uint256 startTokenId = _lastTokenId + 1;
    // Then, mint the amount of tokens
    _mintAmount(recipient, amount, "", false);
    // Then, get the ending token ID
    uint256 endTokenId = _lastTokenId;
    do {
      // Map the token metadata
      _mapData(startTokenId++, data);
    } while (startTokenId <= endTokenId);
  }

  /**
   * @dev Mints token and maps its metadata.
   */
  function _mintAndMap(
    IERC721TokenMetadata data, 
    address recipient
  ) internal {
    // Get the next token ID
    uint256 tokenId = _lastTokenId + 1;
    // Mint the token
    _safeMint(recipient, tokenId);
    // Map the token metadata
    _mapData(tokenId, data);
  }
}