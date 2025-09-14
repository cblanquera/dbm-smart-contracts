// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IERC721ContractMetadata } from "./IERC721ContractMetadata.sol";
import { IERC721TokenMetadata } from "./IERC721TokenMetadata.sol";
import { ERC721Spec } from "./ERC721Spec.sol";

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
  uint256 private _lastTokenId;
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
  function totalSupply() public view returns(uint256) {
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

  // ============ Overrides ============

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
      _lastTokenId++;
    }

    return previousOwner;
  }

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
}