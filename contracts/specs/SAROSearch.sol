// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ISARODocument } from "./ISARODocument.sol";

error InvalidFilter(bytes32 filter);
error InvalidDocumentID(bytes32 documentId);
error EmptyDocumentSet();

contract SAROSearch {
  // ============ Storage ============

  ISARODocument public documents;

  // Latest 5 recently viewed document IDs
  string[] public recentlyViewed;
  // Mapping of document ID to view count
  mapping(string => uint256) public documentViews;

  // ============ Deploy ============

  /**
   * @dev Sets the documents contract.
   */
  constructor(ISARODocument documentContract) {
    documents = documentContract;
  }

  // ============ Index Methods ============

  /**
   * @dev Returns the total count of documents.
   */
  function getCount() external view returns (uint256) {
    return documents.documentIdsSize();
  }

  /**
   * @dev Returns the data for a given `documentId`.
   */
  function getData(string memory documentId)
    external view returns (ISARODocument.Metadata memory) 
  {
    // Get the data from the documents contract
    ISARODocument.Metadata memory data = documents.documentData(documentId);
    // Serialize the document ID for comparison
    bytes32 filter = keccak256(bytes(data.saroNumber));
    // If the document ID doesn't exist, revert
    if (filter == keccak256(bytes(""))){
      revert InvalidDocumentID(keccak256(bytes(documentId)));
    }
    return data;
  }

  /**
   * @dev Returns the token IDs associated with a given `documentId`.
   */
  function getDocumentToken(string memory documentId) 
    external view returns (uint256) 
  {
    // Serialize the document ID for comparison
    bytes32 filter = keccak256(bytes(documentId));
    // Loop through all tokens
    for (uint256 i = 0; i < documents.tokenIds().length; i++) {
      // Get the token ID
      uint256 tokenId = documents.tokenIds(i);
      // Now get the document ID for the token
      string memory tokenDocumentId = documents.tokenDocuments(tokenId);
      // If the token document ID matches the filter
      if (keccak256(bytes(tokenDocumentId)) == filter) {
        // Return the first one found
        return tokenId;
      }
    }
    return 0;
  }

  /**
   * @dev Returns the last token id minted.
   */
  function getIndex() external view returns (uint256) {
    uint256[] memory tokenIds = documents.tokenIds();
    return tokenIds[tokenIds.length - 1];
  }

  /**
   * @dev Returns the top 5 most viewed document IDs and their view counts.
   */
  function getTopSearched() 
    public view returns (string[] memory, uint256[] memory) 
  {
    uint256 length = documents.documentIdsSize();

    if (length == 0) {
      revert EmptyDocumentSet();
    }

    // Create arrays for sorting
    string[] memory ids = new string[](length);
    uint256[] memory views = new uint256[](length);

    // Populate arrays
    for (uint256 i = 0; i < length; i++) {
      ids[i] = documents.documentIds(i);
      views[i] = documentViews[ids[i]];
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
  function getTotalYearFilterCount() external view returns (uint256) {
    return _getYears(0, 0).length;
  }

  /**
   * @dev Returns the total number of documents filtered by department, 
   * agency, unit, or year.
   */
  function getFilteredDocumentsLength(string memory filter) 
    external view returns (uint256) 
  {
    return getDocumentsUnderFilter(filter, 0, 0).length;
  }

  /**
   * @dev Returns departments for a given `year`.
   */
  function getDepartmentCategory(string memory year) 
    external view returns (string[] memory) 
  {
    // Serialize the year for comparison
    bytes32 filter = keccak256(bytes(year));
    // Make an unsized array
    string[] memory departments;
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      // Get the data
      ISARODocument.Metadata memory data = documents.documentData(documentId);
      // Get the release date
      string memory released = documents.documentReleases(documentId);
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
   * @dev Returns agencies for a given `year` and `department`.
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
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      // Get the data
      ISARODocument.Metadata memory data = documents.documentData(documentId);
      // Get the release date
      string memory released = documents.documentReleases(documentId);
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
   * @dev Returns operating units for a given `year`, `department`, 
   * and `agency`.
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
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      // Get the data
      ISARODocument.Metadata memory data = documents.documentData(documentId);
      // Get the release date
      string memory released = documents.documentReleases(documentId);
      // If the year matches
      if (yearFilter == keccak256(bytes(_getYear(released)))
        // and, If the department matches
        && departmentFilter == keccak256(bytes(data.department))
        // and, If the agency matches
        && agencyFilter == keccak256(bytes(data.agency))
        // and, If it doesn't exist in the array
        && !_stringArrayExists(
          keccak256(bytes(data.operatingUnit)), 
          units
        )
      ) {
        // Add it
        units[units.length - 1] = data.operatingUnit;
      }
    }
    return units;
  }

  /**
   * @dev Returns all filters of a given `filterType` (department, 
   * agency, unit, year).
   */
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

  /**
   * @dev Returns documents under a given `filter`.
   */
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
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      if (_hasFilter(documentId, filterHash)) {
        // If we haven't skipped enough yet
        if ((skipped++) < skip) {
          continue;
        }
        // Add it
        ids[ids.length - 1] = documentId;
        // If we have taken enough, break
        if (take > 0 && ids.length >= take) {
          break;
        }
      }
    }

    return ids;
  }

  /**
   * @dev Returns document IDs with pagination.
   */
  function getDocumentIds(uint256 skip, uint256 take) 
    external view returns (string[] memory) 
  {
    // Make unsized array
    string[] memory ids;
    // Setup paginators
    uint256 taken = 0;
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through the document ids
    for (uint256 i = skip; i < length; i++) {
      // If we haven't skipped enough yet
      if (i < skip) {
        continue;
      }
      // Add it
      ids[ids.length - 1] = documents.documentIds(i);
      // If we have taken enough, break
      if (take > 0 && ++taken >= take) {
        break;
      }
    }
    return ids;
  }

  // ============ Write Methods ============

  /**
   * @dev Records a view for a given `documentId`.
   */
  function viewed(string memory documentId) external {
    // If the recently viewed list is full
    if (recentlyViewed.length > 4) {
      // Remove the first element and shift all elements left
      for (uint i = 0; i < recentlyViewed.length - 1; i++) {
        recentlyViewed[i] = recentlyViewed[i + 1];
      }
      // Remove the last element (duplicate)
      recentlyViewed[recentlyViewed.length - 1] = documentId;
    } else {
      // Add new item at the end
      recentlyViewed.push(documentId);
    }
    documentViews[documentId]++;
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
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      // Get the data
      ISARODocument.Metadata memory data = documents.documentData(documentId);
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
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      // Get the data
      ISARODocument.Metadata memory data = documents.documentData(documentId);
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
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      // Get the data
      ISARODocument.Metadata memory data = documents.documentData(documentId);
      // If it doesn't exist in the array
      if (!_stringArrayExists(
        keccak256(bytes(data.operatingUnit)), 
        units
      )) {
        // If we haven't skipped enough yet
        if ((skipped++) < skip) {
          continue;
        }
        // Add it
        units[units.length - 1] = data.operatingUnit;
        // If we have taken enough, break
        if (take > 0 && units.length >= take) {
          break;
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
    // Get the length of document IDs
    uint256 length = documents.documentIdsSize();
    // Loop through all documents
    for (uint256 i = 0; i < length; i++) {
      // Get the document ID
      string memory documentId = documents.documentIds(i);
      // Get the release date
      string memory released = documents.documentReleases(documentId);
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
    ISARODocument.Metadata memory data = documents.documentData(documentId);
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
    return filter == keccak256(bytes(data.operatingUnit));
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
      year[i] = dateBytes[i + 6];
    }
    // Return the year as a string
    return string(year);
  }
}