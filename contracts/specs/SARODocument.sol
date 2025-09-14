// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Verifier } from "../utils/Verifier.sol";

import { ISARODocument } from "./ISARODocument.sol";
import { IERC721Mintable } from "../IERC721Mintable.sol";

error InvalidProof();
error InvalidSize();
error TokenExists(uint256 tokenId);
error DocumentExists(bytes32 tokenId);

contract SARODocument is 
  ISARODocument, 
  Ownable,
  AccessControl,
  ReentrancyGuard 
{
  // ============ Constants ============

  //additional roles
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");

  // ============ Storage ============

  IERC721Mintable public minter;
  string private _baseURI;

  // Mapping of document ID (for conditionals)
  mapping(string => bool) public documentExists;
  // Mapping of token ID (for conditionals)
  mapping(uint256 => bool) public tokenExists;

  // Mapping of token ID to document IDs
  mapping(uint256 => string) public tokenDocuments;
  // Mapping of document ID to IPFS CIDs
  mapping(string => string) public documentFiles;
  // Mapping of document ID to release dates
  mapping(string => string) public documentReleases;

  // Mapping of document ID to data
  // NOTE: Solidity cant auto convert storage to 
  // memory for auto-generated getters
  mapping(string => Metadata) private _documentData;
  // Raw list of document ids (for enumeration)
  // NOTE: Solidity cant auto convert storage to 
  // memory for auto-generated getters
  string[] private _documentIds;
  // Raw list of token ids (for enumeration)
  // NOTE: Solidity cant auto convert storage to 
  // memory for auto-generated getters
  uint256[] private _tokenIds;

  // ============ Deploy ============

  /**
   * @dev Sets the minter contract.
   */
  constructor(
    string memory baseURI, 
    IERC721Mintable minterContract,
    address admin
  ) Ownable(admin) {
    _baseURI = baseURI;
    minter = minterContract;
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the document data for a given `documentId`.
   */
  function documentData(string memory documentId) 
    external view returns(Metadata memory) 
  {
    return _documentData[documentId];
  }

  /**
   * @dev Returns the document ID at a given `index` (for enumeration).
   */
  function documentIds(uint256 index) external view returns(string memory) {
    return _documentIds[index];
  }

  /**
   * @dev Returns all the document IDs (for enumeration).
   */
  function documentIds() external view returns(string[] memory) {
    return _documentIds;
  }

  /**
   * @dev Returns the size of the document IDs (for enumeration).
   */
  function documentIdsSize() external view returns(uint256) {
    return _documentIds.length;
  }

  /**
   * @dev Returns the token ID at a given `index` (for enumeration).
   */
  function tokenIds(uint256 index) external view returns(uint256) {
    return _tokenIds[index];
  }

  /**
   * @dev Returns all the token IDs (for enumeration).
   */
  function tokenIds() external view returns(uint256[] memory) {
    return _tokenIds;
  }

  /**
   * @dev Returns the size of the token IDs (for enumeration).
   */
  function tokenIdsSize() external view returns(uint256) {
    return _tokenIds.length;
  }

  /**
   * @dev Returns the token URI for a given `tokenId`.
   */
  function tokenURI(uint256 tokenId) 
    external view returns(string memory) 
  {
    return string(
      abi.encodePacked(_baseURI, documentFiles[tokenDocuments[tokenId]])
    );
  }

  // ============ Write Methods ============

  /**
   * @dev Batch mints a new token to the `recipient` using the minter 
   * contract. Maps `file`, `data`, and `released` to the document.
   */
  function batch(
    address recipient,
    string[] memory files,
    Metadata[] memory data,
    string[] memory released
  ) external nonReentrant onlyRole(_MINTER_ROLE) {
    // Batch mint the tokens and tokenize the documents
    _batchMintAndTokenize(recipient, files, data, released);
  }

  /**
   * @dev Mints a new token to the `recipient` using the minter 
   * contract. Maps `file`, `data`, and `released` to the document.
   */
  function mint(
    address recipient,
    string memory file,
    Metadata memory data,
    string memory released
  ) external nonReentrant onlyRole(_MINTER_ROLE) {
    // Mint the token and tokenize the document
    _mintAndTokenize(recipient, file, data, released);
  }

  /**
   * @dev Allows anyone to mint tokens that was approved by the minter 
   * role. (ie. moves the burden of gas to the minter)
   */
  function mint(
    address recipient, 
    string memory file,
    Metadata memory data,
    string memory released,
    bytes memory proof
  ) external nonReentrant {
    // Make sure the minter signed this off
    if (!hasRole(_MINTER_ROLE, Verifier.author(
      abi.encodePacked("mint", file, recipient), 
      proof
    ))) {
      revert InvalidProof();
    }
    // Mint the token and tokenize the document
    _mintAndTokenize(recipient, file, data, released);
  }

  /**
   * @dev Maps `tokenId`, `file`, `data`, and `released` to the document.
   * This is used in the case platforms want to facilitate the mint 
   * (ie. to save on gas).
   */
  function tokenize(
    uint256 tokenId,
    string memory file,
    Metadata memory data,
    string memory released
  ) external onlyRole(_MINTER_ROLE) nonReentrant {
    _tokenize(tokenId, file, data, released);
  }

  /**
   * @dev Allows anyone to mint tokens that was approved by the minter 
   * role. (ie. moves the burden of gas to the minter)
   */
  function tokenize(
    uint256 tokenId,
    string memory file,
    Metadata memory data,
    string memory released,
    bytes memory proof
  ) external nonReentrant {
    // Make sure the minter signed this off
    if (!hasRole(_MINTER_ROLE, Verifier.author(
      abi.encodePacked("tokenize", file, _msgSender()), 
      proof
    ))) {
      revert InvalidProof();
    }

    _tokenize(tokenId, file, data, released);
  }

  // ============ Internal Methods ============

  /**
   * @dev Batch mints new tokens to the `recipient` using the minter 
   * contract. Maps `file`, `data`, and `released` to each document.
   */
  function _batchMintAndTokenize(
    address recipient,
    string[] memory files,
    Metadata[] memory data,
    string[] memory released
  ) internal {
    // Make sure the sizes match
    if (files.length != data.length
      || files.length != released.length
      || files.length == 0
    ) {
      revert InvalidSize();
    }
    // Get the starting token ID
    uint256 startTokenId = minter.totalSupply() + 1;
    // Mint the token (all in one go)
    minter.batch(recipient, files.length);

    // For each token
    for (uint i = 0; i < files.length; i++) {
      // Tokenize the document
      _tokenize(startTokenId + i, files[i], data[i], released[i]);
    }
  }

  /**
   * @dev Mints a new token to the `recipient` using the minter 
   * contract. Maps `file`, `data`, and `released` to the document.
   */
  function _mintAndTokenize(
    address recipient,
    string memory file,
    Metadata memory data,
    string memory released
  ) internal {
    // Mint the token
    minter.mint(recipient);
    // Tokenize the document
    _tokenize(minter.totalSupply(), file, data, released);
  }

  /**
   * @dev Maps `tokenId`, `file`, `data`, and `released` to the document.
   */
  function _tokenize(
    uint256 tokenId,
    string memory file,
    Metadata memory data,
    string memory released
  ) private {
    // Error if the token already exists (should never happen)
    if (tokenExists[tokenId]) {
      revert TokenExists(tokenId);
    }
    // Get the document id
    string memory documentId = data.saroNumber;
    // If the document exists
    if (documentExists[documentId]) {
      revert DocumentExists(keccak256(abi.encodePacked(documentId)));
    }
    // Map document ID (ex. NCA-XXXX-12-3456789) to data
    _documentData[documentId] = data;
    // Map document ID to IPFS CIDs
    documentFiles[documentId] = file;
    // Map document ID to release dates
    documentReleases[documentId] = released;
    // Map the document id as existing
    documentExists[documentId] = true;
    // Map the token id as existing
    tokenExists[tokenId] = true;
    // Map token ID to document IDs
    tokenDocuments[tokenId] = documentId;
  }
}