// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IERC721ContractMetadata } from "./IERC721ContractMetadata.sol";
import { IERC721TokenMetadata } from "./IERC721TokenMetadata.sol";
import { ERC721Utils } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol";
import { ERC721Spec } from "./ERC721Spec.sol";

error InvalidAmount();
error MetadataNotSet();
error MetadataAlreadySet();

/**
 * @dev This is actually the main logic of the document contract.
 * The main contract should cover configuration and minting. Things
 * covered in this abstract are:
 * - Contract is ownable; Owners manages the roles
 * - Contract has roles and permissions
 *   - Curator role can update contract's metadata (ex. DAO)
 *   - Approved role are for trusted platforms that can perform token xfers
 *   - Only document specs (ie. NCA, SARO) should have the minter role
 * - Contract's metadata is managed by a separate contract
 * - Each token's metadata is managed by a document spec. This means,
 * - Tokens are mapped to different metadata contracts (document specs)
 * - The purpose of document specs is to provide unique search tools
 */
abstract contract ERC721DocumentSpec is 
  Ownable,
  AccessControl, 
  ERC721Spec 
{
  // ============ Constants ============

  // Curator role can update metadata (ex. DAO)
  bytes32 internal constant _CURATOR_ROLE = keccak256("CURATOR_ROLE");
  // Approved role can be approved for all (ex. web2 platforms)
  bytes32 internal constant _APPROVED_ROLE = keccak256("APPROVED_ROLE");

  // ============ Storage ============

  // The last token id minted
  uint256 internal _lastTokenId;
  // Contract Metadata interface
  IERC721ContractMetadata internal _contractData;
  // Mapping of token ID to TokenMetadata contract
  mapping(uint256 => IERC721TokenMetadata) internal _tokenData;

  // ============ Read Methods ============

  /**
   * @dev Returns the contract URI.
   */
  function contractURI() external view returns(string memory) {
    return _contractData.contractURI();
  }

  /**
   * @dev Override isApprovedForAll to whitelist Web2 platforms 
   * (ex. to enable gas-less listings).
   */
  function isApprovedForAll(
    address owner, 
    address operator
  ) public view override returns(bool) {
    return hasRole(_APPROVED_ROLE, operator) 
      || super.isApprovedForAll(owner, operator);
  }

  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns(string memory) {
    return _contractData.name();
  }

  /**
   * @dev Adding support for ERC2981
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl, ERC721Spec) returns(bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns(string memory) {
    return _contractData.symbol();
  }

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public virtual view returns(uint256) {
    return _lastTokenId;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for 
   * `tokenId` token.
   */
  function tokenURI(
    uint256 tokenId
  ) external view returns(string memory) {
    // Make sure the token exists
    _requireOwned(tokenId);
    // If metadata is not set
    if (address(_tokenData[tokenId]) == address(0)) {
      revert MetadataNotSet();
    }
    return _tokenData[tokenId].tokenURI(tokenId);
  }

  // ============ Admin Methods ============

  /**
   * @dev Updates the contract metadata location
   */
  function updateMetadata(IERC721ContractMetadata data) 
    external onlyRole(_CURATOR_ROLE) 
  {
    _contractData = data;
  }

  // ============ Internal Methods ============

  /**
   * @dev Maps a tokenId to a TokenMetadata contract
   */
  function _mapData(uint256 tokenId, IERC721TokenMetadata data) 
    internal virtual
  {
    // NOTE: no need to check if token exists because this 
    // method is only called after mint...

    // NOTE: Chicken and egg, can't check if uri exists
    // because the data contract needs the tokenID first...

    // If metadata is already set (immutable)
    if (address(_tokenData[tokenId]) != address(0)) {
      revert MetadataAlreadySet();
    }
    
    // Map the metadata
    _tokenData[tokenId] = data;
  }

  /**
   * @dev Mints `amount` of tokens and transfers them to `to`.
   * If `safeCheck` is true, it will check if the receiver is a 
   * contract and if so, check if it implements `onERC721Received`.
   * This is an internal method that doesn't do any permission checks.
   * It is up to the caller to do the necessary checks.
   */
  function _mintAmount(
    address to, 
    uint256 amount, 
    bytes memory data,
    bool safeCheck
  ) internal virtual {
    // Make sure amount is not zero
    if(amount == 0) {
      revert InvalidAmount();
    }
    // Can't mint to zero address
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    // Get the starting and ending index
    // (must be done before we increment _lastTokenId)
    uint256 updatedIndex = _lastTokenId + 1;
    uint256 endIndex = updatedIndex + amount;
    unchecked {
      // Then, bulk increment the last token id
      _lastTokenId += amount;
      // Bulk increment the balance of the receiver
      _balances[to] += amount;
    }
    //if do safe check and,
    //check if contract one time (instead of loop)
    //see: @openzep/utils/Address.sol
    if (safeCheck && to.code.length > 0) {
      //loop emit transfer and received check
      do {
        _owners[updatedIndex] = to;
        emit Transfer(address(0), to, updatedIndex);
        ERC721Utils.checkOnERC721Received(
          _msgSender(), 
          address(0), 
          to, 
          updatedIndex++, 
          data
        );
      } while (updatedIndex != endIndex);
      return;
    }

    do {
      _owners[updatedIndex] = to;
      emit Transfer(address(0), to, updatedIndex++);
    } while (updatedIndex != endIndex);
  }

  /**
   * @dev Override to increment the tokenId on mints
   */
  function _update(address to, uint256 tokenId, address auth) 
    internal virtual override returns (address) 
  {
    // Do the normal update logic and get the previous owner
    address previousOwner = super._update(to, tokenId, auth);
    // If the previous owner was address(0) and we are sending to a 
    // valid address, then we are minting a new token
    if (previousOwner == address(0) && to != address(0)) {
      // Increment the tokenId for the next mint
      unchecked {
        _lastTokenId++;
      }
    }

    return previousOwner;
  }
}