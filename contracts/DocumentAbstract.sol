// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IContractMetadata } from "./IContractMetadata.sol";
import { ITokenMetadata } from "./ITokenMetadata.sol";
import { ERC721Abstract } from "./ERC721Abstract.sol";

error MetadataNotSet();
error MetadataAlreadySet();

abstract contract DocumentAbstract is 
  Ownable,
  AccessControl, 
  ERC721Abstract 
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
  IContractMetadata internal _contractData;
  // Mapping of token ID to TokenMetadata contract
  mapping(uint256 => ITokenMetadata) internal _tokenData;
  
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
  ) public view override(AccessControl, ERC721Abstract) returns(bool) {
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
  function updateMetadata(IContractMetadata data) 
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
  function _mapData(uint256 tokenId, ITokenMetadata data) 
    internal virtual
  {
    //prevent assigning to a non-existent token
    _requireOwned(tokenId);
    //if metadata is already set (immutable)
    if (address(_tokenData[tokenId]) != address(0)) {
      revert MetadataAlreadySet();
    }
    _tokenData[tokenId] = data;
  }
}