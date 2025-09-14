// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ITokenMetadata } from "../ITokenMetadata.sol";
import { IDocumentMintable } from "../IDocumentMintable.sol";

error TokenExists(uint256 tokenId);
error InvalidFilter(bytes32 filter);
error InvalidDocumentID(bytes32 documentId);
error EmptyDocumentSet();

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

  // Latest 5 recently viewed document IDs
  string[] private _recentlyViewed;
  // Mapping of document ID to view count
  mapping(string => uint256) private _documentViews;

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
  function getCount() external view returns (uint256) {
    return _documentIds.length;
  }

  /**
   * @dev Returns the data for a given document ID.
   */
  function getData(string memory documentId)
    external view returns (Metadata memory) 
  {
    bytes32 idHash = keccak256(bytes(_documentData[documentId].ncaNumber));
    if (idHash == keccak256(bytes(""))){
      revert InvalidDocumentID(keccak256(bytes(documentId)));
    } else {
      return _documentData[documentId];
    }
  }

  function getDocumentToken(string memory documentId) 
    external view returns (uint256[] memory) 
  {
    // Make an unsized array
    uint256[] memory tokens;
    // Serialize the document ID for comparison
    bytes32 idHash = keccak256(bytes(documentId));
    // Loop through all tokens
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // If the token maps to the document ID
      if (keccak256(bytes(_tokenDocuments[_tokenIds[i]])) == idHash) {
        // Add it
        tokens[tokens.length - 1] = _tokenIds[i];
      }
    }
    return tokens;
  }

  /**
   * @dev Returns the last token id minted.
   */
  function getIndex() external view returns (uint256) {
    return _tokenIds[_tokenIds.length - 1];
  }

  /**
   * @dev Returns the last 5 recently viewed document IDs.
   */
  function getRecentlyViewed() external view returns (string[] memory) {
    return _recentlyViewed;
  }

  /**
   * @dev Returns the top 5 most viewed document IDs and their view counts.
   */
  function getTopSearched() 
    public view returns (string[] memory, uint256[] memory) 
  {
    uint256 length = _documentIds.length;

    if (length == 0) {
      revert EmptyDocumentSet();
    }

    // Create arrays for sorting
    string[] memory ids = new string[](length);
    uint256[] memory views = new uint256[](length);

    // Populate arrays
    for (uint256 i = 0; i < length; i++) {
      ids[i] = _documentIds[i];
      views[i] = _documentViews[_documentIds[i]];
    }

    // Sort using bubble sort (for simplicity)
    for (uint256 i = 0; i < length; i++) {
      for (uint256 j = i + 1; j < length; j++) {
        if (views[i] < views[j]) {
          // Swap views
          uint256 tempView = views[i];
          views[i] = views[j];
          views[j] = tempView;

          // Swap IDs
          string memory tempId = ids[i];
          ids[i] = ids[j];
          ids[j] = tempId;
        }
      }
    }

    // Extract the top 5
    string[] memory topId = new string[](1);
    uint256[] memory topView = new uint256[](1);

    for (uint256 i = 0; i < 1; i++) {
      topId[i] = ids[i];
      topView[i] = views[i];
    }

    return (topId, topView);
  }

  /**
   * @dev Returns the total count of departments.
   */
  function getTotalDeptFilterCount() external view returns (uint256) {
    return _getDepartments(0, 0).length;
  }

  /**
   * @dev Returns the total count of agencies.
   */
  function getTotalAgencyFilterCount() external view returns (uint256) {
    return _getAgencies(0, 0).length;
  }

  /**
   * @dev Returns the total count of operating units.
   */
  function getTotalOperatingUnitFilterCount() 
    external view returns (uint256)
  {
    return _getOperatingUnits(0, 0).length;
  }

  /**
   * @dev Returns the total count of years.
   */
  function getTotalYearFilterCount() 
    external view returns (uint256) 
  {
    return _getYears(0, 0).length;
  }

  /**
   * @dev Returns the total number of documents filtered by department, agency, unit, or year.
   */
  function getFilteredDocumentsLength(string memory filter) 
    external view returns (uint256) 
  {
    return getDocumentsUnderFilter(filter, 0, 0).length;
  }

  /**
   * @dev Returns departments for a given year.
   */
  function getDepartmentCategory(string memory year) 
    external view returns (string[] memory) 
  {
    // Serialize the year for comparison
    bytes32 filter = keccak256(bytes(year));
    // Make an unsized array
    string[] memory departments;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Get the release date
      string memory released = _documentReleases[_documentIds[i]];
      // If the year matches
      if (filter == keccak256(bytes(_getYear(released)))
        // and, If it doesn't exist in the array
        && !_stringArrayExists(
          keccak256(bytes(data.department)), 
          departments
        )
      ) {
        // Add it
        departments[departments.length - 1] = data.department;
      }
    }
    return departments;
  }

  /**
   * @dev Returns agencies for a given year and department.
   */
  function getAgencyCategory(
    string memory year, 
    string memory department
  ) 
    external view returns (string[] memory) 
  {
    // Serialize the filters for comparison
    bytes32 yearFilter = keccak256(bytes(year));
    bytes32 departmentFilter = keccak256(bytes(department));
    // Make an unsized array
    string[] memory agencies;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Get the release date
      string memory released = _documentReleases[_documentIds[i]];
      // If the year matches
      if (yearFilter == keccak256(bytes(_getYear(released)))
        // and, If the department matches
        && departmentFilter == keccak256(bytes(data.department))
        // and, If it doesn't exist in the array
        && !_stringArrayExists(
          keccak256(bytes(data.agency)), 
          agencies
        )
      ) {
        // Add it
        agencies[agencies.length - 1] = data.agency;
      }
    }
    return agencies;
  }

  /**
   * @dev Returns operating units for a given year, department, and agency.
   */
  function getOperatingUnitCategory(
    string memory year, 
    string memory department, 
    string memory agency
  ) 
    external view returns (string[] memory) 
  {
    // Serialize the filters for comparison
    bytes32 yearFilter = keccak256(bytes(year));
    bytes32 departmentFilter = keccak256(bytes(department));
    bytes32 agencyFilter = keccak256(bytes(agency));
    // Make an unsized array
    string[] memory units;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Get the release date
      string memory released = _documentReleases[_documentIds[i]];
      // If the year matches
      if (yearFilter == keccak256(bytes(_getYear(released)))
        // and, If the department matches
        && departmentFilter == keccak256(bytes(data.department))
        // and, If the agency matches
        && agencyFilter == keccak256(bytes(data.agency))
      ) {
        // Loop through the operating units
        for (uint j = 0; j < data.operatingUnit.length; j++) {
          // If it doesn't exist in the array
          if (!_stringArrayExists(
            keccak256(bytes(data.operatingUnit[j])), 
            units
          )) {
            // Add it
            units[units.length - 1] = data.operatingUnit[j];
          }
        }
      }
    }
    return units;
  }

  function getAllFilters(
    string memory filterType, 
    uint256 skip, 
    uint256 take
  ) 
    external view returns (string[] memory) 
  {
    bytes32 filterHash = keccak256(bytes(filterType));
    if(filterHash == keccak256(bytes("department"))){
      return _getDepartments(skip, take);
    } else if(filterHash == keccak256(bytes("agency"))){
      return _getAgencies(skip, take);
    } else if(filterHash == keccak256(bytes("year"))){
      return _getYears(skip, take);
    } else if(filterHash == keccak256(bytes("operatingUnit"))){
      return _getOperatingUnits(skip, take);
    } else {
      revert InvalidFilter(filterHash);
    }
  }

  function getDocumentsUnderFilter(
    string memory filter, 
    uint256 skip, 
    uint256 take
  ) 
    public view returns (string[] memory) 
  {
    // Make an unsized array
    string[] memory ids;
    // Setup paginators
    uint256 skipped = 0;
    // Serialize the filter for comparison
    bytes32 filterHash = keccak256(bytes(filter));
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      if (_hasFilter(_documentIds[i], filterHash)) {
        // If we haven't skipped enough yet
        if ((skipped++) < skip) {
          continue;
        }
        // Add it
        ids[ids.length - 1] = _documentIds[i];
        // If we have taken enough, break
        if (take > 0 && ids.length >= take) {
          break;
        }
      }
    }

    return ids;
  }

  function getDocumentIds(uint256 skip, uint256 take) 
    external view returns (string[] memory) 
  {
    // Make unsized array
    string[] memory ids;
    // Setup paginators
    uint256 taken = 0;
    // Loop through the document ids
    for (uint256 i = skip; i < _documentIds.length; i++) {
      // If we haven't skipped enough yet
      if (i < skip) {
        continue;
      }
      // Add it
      ids[ids.length - 1] = _documentIds[i];
      // If we have taken enough, break
      if (take > 0 && ++taken >= take) {
        break;
      }
    }
    return ids;
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

  /**
   * @dev Records a view for a given document ID.
   */
  function viewed(string memory documentId) external {
    // If the recently viewed list is full
    if (_recentlyViewed.length > 4) {
      // Remove the first element and shift all elements left
      for (uint i = 0; i < _recentlyViewed.length - 1; i++) {
        _recentlyViewed[i] = _recentlyViewed[i + 1];
      }
      // Remove the last element (duplicate)
      _recentlyViewed[_recentlyViewed.length - 1] = documentId;
    } else {
      // Add new item at the end
      _recentlyViewed.push(documentId);
    }
    _documentViews[documentId]++;
  }

  // ============ Readonly Helpers ============

  /**
   * @dev Returns a list of agencies.
   */
  function _getAgencies(uint256 skip, uint256 take) 
    private view returns (string[] memory) 
  {
    // Make an unsized array
    string[] memory agencies;
    // Setup paginators
    uint256 skipped = 0;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Get the agency
      string memory agency = data.agency;
      // If it doesn't exist in the array
      if (!_stringArrayExists(keccak256(bytes(agency)), agencies)) {
        // If we haven't skipped enough yet
        if ((skipped++) < skip) {
          continue;
        }
        // Add it
        agencies[agencies.length - 1] = agency;
        // If we have taken enough, break
        if (take > 0 && agencies.length >= take) {
          break;
        }
      }
    }
    return agencies;
  }

  /**
   * @dev Returns a list of departments.
   */
  function _getDepartments(uint256 skip, uint256 take) 
    private view returns (string[] memory) 
  {
    // Make an unsized array
    string[] memory departments;
    // Setup paginators
    uint256 skipped = 0;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Get the department
      string memory department = data.department;
      // If it doesn't exist in the array
      if (!_stringArrayExists(
        keccak256(bytes(department)), 
        departments
      )) {
        // If we haven't skipped enough yet
        if ((skipped++) < skip) {
          continue;
        }
        // Add it
        departments[departments.length - 1] = department;
        // If we have taken enough, break
        if (take > 0 && departments.length >= take) {
          break;
        }
      }
    }

    return departments;
  }

  /**
   * @dev Returns a list of operating units.
   */
  function _getOperatingUnits(uint256 skip, uint256 take) 
    private view returns (string[] memory) 
  {
    // Make an unsized array
    string[] memory units;
    // Setup paginators
    uint256 skipped = 0;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the data
      Metadata memory data = _documentData[_documentIds[i]];
      // Loop through the operating units
      for (uint j = 0; j < data.operatingUnit.length; j++) {
        // If it doesn't exist in the array
        if (!_stringArrayExists(
          keccak256(bytes(data.operatingUnit[j])), 
          units
        )) {
          // If we haven't skipped enough yet
          if ((skipped++) < skip) {
            continue;
          }
          // Add it
          units[units.length - 1] = data.operatingUnit[j];
          // If we have taken enough, break
          if (take > 0 && units.length >= take) {
            break;
          }
        }
      }
    }
    return units;
  }

  /**
   * @dev Returns a list of years.
   */
  function _getYears(uint256 skip, uint256 take) 
    public view returns (string[] memory) 
  {
    // Make an unsized array
    string[] memory anums;
    // Setup paginators
    uint256 skipped = 0;
    // Loop through all documents
    for (uint256 i = 0; i < _documentIds.length; i++) {
      // Get the release date
      string memory released = _documentReleases[_documentIds[i]];
      // Get the year
      string memory year = _getYear(released);
      // If it doesn't exist in the array
      if (!_stringArrayExists(keccak256(bytes(year)), anums)) {
        // If we haven't skipped enough yet
        if ((skipped++) < skip) {
          continue;
        }
        // Add it
        anums[anums.length - 1] = year;
        // If we have taken enough, break
        if (take > 0 && anums.length >= take) {
          break;
        }
      }
    }

    return anums;
  }

  /**
   * @dev Checks if a document has a specific filter (department, agency, unit, year).
   */
  function _hasFilter(string memory documentId, bytes32 filter) 
    private view returns (bool) 
  {
    // Get the data
    Metadata memory data = _documentData[documentId];
    // Check if the filter exists in the department
    if (filter == keccak256(bytes(data.department))) {
      return true;
    }
    // Check if the filter exists in the agency
    if (filter == keccak256(bytes(data.agency))) {
      return true;
    }
    // Check if release year matches the filter
    string memory year = _getYear(data.releasedDate);
    if (filter == keccak256(bytes(year))) {
      return true;
    }
    // Check if the filter exists in the operating units
    for (uint i = 0; i < data.operatingUnit.length; i++) {
      if (filter == keccak256(bytes(data.operatingUnit[i]))) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Checks if a string exists in an array of strings.
   */
  function _stringArrayExists(
    bytes32 value, 
    string[] memory array
  ) private pure returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (keccak256(bytes(array[i])) == value) {
        return true;
      }
    }
    return false;
  }

  // ============ Write Helpers ============

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