// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ITokenMetadata } from "../ITokenMetadata.sol";
import { IDocumentMintable } from "../IDocumentMintable.sol";

contract NCADocument is ITokenMetadata {
  // ============ Structs ============

  struct Metadata {
    string ncaNumber;
    string ncaType;
    string department;
    string agency;
    string[] operatingUnit;
    string[] amount;
    string totalAmount;
    string purpose;
    string qrId;
    string releasedDate;
  }

  error TokenExists(uint256 tokenId);

  // ============ Storage ============

  IDocumentMintable public minter;
  string private _baseURI;

  // Raw list of document ids (for enumeration)
  string[] private _documentIds;
  // Raw list of token ids (for enumeration)
  uint256[] private _tokenIds;

  // Mapping of document ID (ex. NCA-XXXX-12-3456789) (for conditionals)
  mapping(string => bool) private _documentExists;
  // Mapping of token ID (for conditionals)
  mapping(uint256 => bool) private _tokenExists;

  // Mapping of document ID (ex. NCA-XXXX-12-3456789) to data
  mapping(string => Metadata) private _documentData;
  // Mapping of document ID to IPFS CIDs
  mapping(string => string) private _documentFiles;
  // Mapping of document ID to release dates
  mapping(string => string) private _documentReleases;
  // Mapping of token ID to document IDs
  mapping(uint256 => string) private _tokenDocuments;

  // ============ Deploy ============

  /**
   * @dev Sets the minter contract.
   */
  constructor(string memory baseURI, IDocumentMintable minterContract) {
    _baseURI = baseURI;
    minter = minterContract;
  }

  // ============ Index Methods ============

  /**
   * @dev Returns the total count of documents.
   */
  function getCount() public view returns (uint256) {
    return _documentIds.length;
  }

  /**
   * @dev Returns the last token id minted.
   */
  function getIndex() public view returns (uint256) {
    return _tokenIds[_tokenIds.length - 1];
  }

  function getRecentlyViewed() 
    public view returns (string[] memory) 
  {
    
  }

  /**
   * @dev Returns the total count of departments.
   */
  function getTotalDeptFilterCount() public view returns (uint256) {
    return _getDepartments().length;
  }

  /**
   * @dev Returns the total count of agencies.
   */
  function getTotalAgencyFilterCount() public view returns (uint256) {
    return _getAgencies().length;
  }

  /**
   * @dev Returns the total count of operating units.
   */
  function getTotalOperatingUnitFilterCount() 
    public view returns (uint256)
  {
    return _getOperatingUnits().length;
  }

  /**
   * @dev Returns the total count of years.
   */
  function getTotalYearFilterCount() 
    public view returns (uint256) 
  {
    return _getYears().length;
  }

  /**
   * @dev Returns the total number of documents filtered by department, agency, unit, or year.
   */
  function getFilteredDocumentsLength(string memory filter) 
    public view returns (uint256) 
  {
    
  }

  function getDocumentTypeCategory(string memory year) 
    public view returns (string[] memory) 
  {
    
  }

  function getDepartmentCategory(string memory year) 
    public view returns (string[] memory) 
  {
    
  }

  function getAgencyCategory(
    string memory year, 
    string memory department
  ) 
    public view returns (string[] memory) 
  {
    
  }

  function getOperatingUnitCategory(
    string memory year, 
    string memory department, 
    string memory agency
  ) 
    public view returns (string[] memory) 
  {
    
  }

  function getAllFilters(
    string memory filterType, 
    uint256 start, 
    uint256 count
  ) 
    public view returns (string[] memory) 
  {
    
  }

  function getDocumentsUnderFilter(
    string memory filter, 
    uint256 start, 
    uint256 count
  ) 
    public view returns (string[] memory) 
  {
    
  }

  function getDocumentIds(uint256 start, uint256 count) 
    public view returns (string[] memory) 
  {
    
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the token URI for a given token ID.
   */
  function tokenURI(uint256 tokenId) 
    external view returns(string memory) 
  {
    return string(
      abi.encodePacked(_baseURI, _documentFiles[_tokenDocuments[tokenId]])
    );
  }

  // ============ Write Methods ============

  /**
   * @dev Mints a new token to the recipient using the minter contract.
   */
  function mint(
    address recipient,
    string memory file,
    Metadata memory data,
    string memory released
  ) external returns(uint256) {
    // Get the document id
    string memory documentId = data.ncaNumber;
    // If the document exists
    if (_documentExists[documentId]) {
      // If the pair does not exist
      if(!_pairExists(documentId, data.operatingUnit[0], data.amount[0])) {
        // Add the new pair
        _pushData(documentId, data.operatingUnit[0], data.amount[0]);
      }
    //otherwise dont change the document mapping
    } else {
      // Map document ID (ex. NCA-XXXX-12-3456789) to data
      _documentData[documentId] = data;
      // Map document ID to IPFS CIDs
      _documentFiles[documentId] = file;
      // Map document ID to release dates
      _documentReleases[documentId] = released;
      // Map the document id as existing
      _documentExists[documentId] = true;
    }
    // Mint the token and get the token id
    uint256 tokenId = minter.mint(recipient);
    // Error if the token already exists (should never happen)
    if (_tokenExists[tokenId]) {
      revert TokenExists(tokenId);
    }
    // Map the token id as existing
    _tokenExists[tokenId] = true;
    // Map token ID to document IDs
    _tokenDocuments[tokenId] = documentId;

    return tokenId;
  }

  // ============ Private Methods ============

  /**
   * @dev Checks if a string exists in an array of strings.
   */
  function _stringArrayExists(
    string memory value, 
    string[] memory array
  ) private pure returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (keccak256(bytes(array[i])) == keccak256(bytes(value))) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Returns the year (first 4 characters) from a date string.
   */
  function _getYear(string memory date) 
    private pure returns (string memory) 
  {
    // Get the bytes of the date
    bytes memory dateBytes = bytes(date);
    // If the string is less than 4 characters
    if (dateBytes.length < 4) {
      // Return the whole string
      return date; 
    }
    // Create a new bytes array (4 chars) for the year
    bytes memory year = new bytes(4);
    // Copy the first 4 characters
    for (uint i = 0; i < 4; i++) {
      year[i] = dateBytes[i];
    }
    // Return the year as a string
    return string(year);
  }

  /**
   * @dev Returns a list of departments.
   */
  function _getDepartments() private view returns (string[] memory) {
    // Make an unsized array
    string[] memory departments;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Get the department
      string memory department = data.department;
      // If it doesn't exist in the array
      if (!_stringArrayExists(department, departments)) {
        // Add it
        departments[departments.length - 1] = department;
      }
    }

    return departments;
  }

  /**
   * @dev Returns a list of agencies.
   */
  function _getAgencies() private view returns (string[] memory) {
    // Make an unsized array
    string[] memory agencies;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Get the agency
      string memory agency = data.agency;
      // If it doesn't exist in the array
      if (!_stringArrayExists(agency, agencies)) {
        // Add it
        agencies[agencies.length - 1] = agency;
      }
    }
    return agencies;
  }

  /**
   * @dev Returns a list of operating units.
   */
  function _getOperatingUnits() private view returns (string[] memory) {
    // Make an unsized array
    string[] memory units;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Loop through the operating units
      for (uint j = 0; j < data.operatingUnit.length; j++) {
        // If it doesn't exist in the array
        if (!_stringArrayExists(data.operatingUnit[j], units)) {
          // Add it
          units[units.length - 1] = data.operatingUnit[j];
        }
      }
    }
    return units;
  }

  /**
   * @dev Returns a list of years.
   */
  function _getYears() public view returns (string[] memory) {
    // Make an unsized array
    string[] memory anums;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the release date
      string memory released = _documentReleases[_documentIds[i]];
      // Get the year
      string memory year = _getYear(released);
      // If it doesn't exist in the array
      if (!_stringArrayExists(year, anums)) {
        // Add it
        anums[anums.length - 1] = year;
      }
    }

    return anums;
  }

  /**
   * @dev Checks if a given operating unit and amount pair exists for an NCA number.
   */
  function _pairExists(
    string memory documentId, 
    string memory unit, 
    string memory amount
  ) 
    internal view returns(bool) 
  {
    // Get the data
    Metadata storage existing = _documentData[documentId];
    // Hash the inputs for comparison (in the loop)
    bytes32 unitHash = keccak256(bytes(unit));
    bytes32 amountHash = keccak256(bytes(amount));
    // For each operating unit
    for (uint i = 0; i < existing.operatingUnit.length; i++) {
      // Check if both the operating unit and amount match
      if (keccak256(bytes(existing.operatingUnit[i])) == unitHash
        && keccak256(bytes(existing.amount[i])) == amountHash
      ) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Pushes a new operating unit and amount pair to an NCA number.
   */
  function _pushData(
    string memory documentId, 
    string memory unit, 
    string memory amount
  )
    internal 
  {
    _documentData[documentId].operatingUnit.push(unit);
    _documentData[documentId].amount.push(amount);
  }
}