// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { IERC721TokenMetadata } from "../IERC721TokenMetadata.sol";
import { IERC721Mintable } from "../IERC721Mintable.sol";

interface ISARODocument is IERC721TokenMetadata {
  // ============ Structs ============

  struct Metadata {
    string saroNumber;
    string amount;
    string department;
    string agency;
    string operatingUnit;
    string purpose;
    string qrId;
    string releasedDate; 
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the document data for a given `documentId`.
   */
  function documentData(string memory documentId) 
    external view returns(Metadata memory);

  /**
   * @dev Returns whether a `documentId` exists.
   */
  function documentExists(string memory documentId) 
    external view returns(bool);

  /**
   * @dev Returns the document file (IPFS CID) for a given `documentId`.
   */
  function documentFiles(string memory documentId) 
    external view returns(string memory);

  /**
   * @dev Returns the document ID at a given `index` (for enumeration).
   */
  function documentIds(uint256 index) 
    external view returns(string memory);

  /**
   * @dev Returns all the document IDs (for enumeration).
   */
  function documentIds() 
    external view returns(string[] memory);

  /**
   * @dev Returns the size of the document IDs (for enumeration).
   */
  function documentIdsSize() 
    external view returns(uint256);

  /**
   * @dev Returns the document release date for a given `documentId`.
   */
  function documentReleases(string memory documentId) 
    external view returns(string memory);

  /**
   * @dev Returns the minter contract.
   */
  function minter() external view returns(IERC721Mintable);

  /**
   * @dev Returns the document ID for a given `tokenId`.
   */
  function tokenDocuments(uint256 tokenId) 
    external view returns(string memory);

  /**
   * @dev Returns whether a `tokenId` exists.
   */
  function tokenExists(uint256 tokenId) 
    external view returns(bool);

  /**
   * @dev Returns the token ID at a given `index` (for enumeration).
   */
  function tokenIds(uint256 index) 
    external view returns(uint256);

  /**
   * @dev Returns all the token IDs (for enumeration).
   */
  function tokenIds() 
    external view returns(uint256[] memory);

  /**
   * @dev Returns the size of the token IDs (for enumeration).
   */
  function tokenIdsSize() 
    external view returns(uint256);

  /**
   * @dev Returns the token URI for a given `tokenId`.
   */
  function tokenURI(uint256 tokenId) 
    external view returns(string memory);
}