pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Document is Ownable, ERC721 {
    using Address for address;
    using Counters for Counters.Counter;
    using Strings for uint256;

    string private _tokenBaseURI;
    Counters.Counter private _tokenIds;
    Counters.Counter private _saroCount;
    Counters.Counter private _ncaIndex;
    Counters.Counter private _ncaCount;
    // address internal _contractOwner;
    string[] public documentIds;
    string[] public saroRecentlyViewed;
    string[] public ncaRecentlyViewed;
    string[] public departmentFilterList;
    string[] public agencyFilterList;
    string[] public yearFilterList;
    string[] public operatingUnitFilterList;

    struct SAROMetadata {
        string saroNumber;
        string amount;
        string department;
        string agency;
        string operatingUnit;
        string purpose;
        string qrId;
        string releasedDate; 
    }

    struct NCAMetadata {
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

    mapping(string => SAROMetadata) private _saroData;
    mapping(string => NCAMetadata) private _ncaData;
    mapping(uint256 => string) private _tokenPaths;
    mapping(string => uint256) private _saroSearchCount;
    mapping(string => uint256) private _ncaSearchCount;
    mapping(uint256 => string) public documentTokenId;
    mapping(string => uint256) public tokenIdToDocu; // mapping Document Number to Token ID, stupid variable name 
    mapping(string => bool) private _ncaExists;
    mapping(string => bool) private _saroExists;
    mapping(string => string[]) public documentFilters;
    mapping(string => bool) private _isFilterExists;

    // year => documentType
    mapping(string => string[]) private _documentTypeCategory; 
    mapping(string => mapping(string => bool)) private _isDocumentTypeCategoryExisting;
    // year => documentType => department
    mapping(string => mapping(string => string[])) private _departmentCategory; 
    mapping(string => mapping(string => mapping(string => bool))) private _isDepartmentCategoryExisting;
    // year => documentType => department => agency
    mapping(string => mapping(string => mapping(string => string[]))) private _agencyCategory; 
    mapping(string => mapping(string => mapping(string => mapping(string => bool)))) private _isAgencyCategoryExisting; 
    // year => documentType => department => agency => operating unit
    mapping(string => mapping(string => mapping(string => mapping(string => string[])))) private _operatingUnitCategory; 
    mapping(string => mapping(string => mapping(string => mapping(string => mapping(string => bool))))) private _isOperatingUnitCategoryExisting;  
    

    event DocumentsTokenized(string[] documentNumbers, uint256[] tokenIds, string documentType);


    constructor(string memory _baseURI) ERC721("DBM Documents", "DBMDocu") {
        _tokenBaseURI = _baseURI;
        // _contractOwner = msg.sender;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        if (interfaceId == type(IERC721).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function getSaroCount() public view returns (uint256) {
        return _saroCount.current();
    }

    function getNcaCount() public view returns (uint256) {
        return _ncaCount.current();
    }

    function getNcaIndex() public view returns (uint256) {
        return _ncaIndex.current();
    }

    function getSaroRecentlyViewed() public view returns (string[] memory) {
        return saroRecentlyViewed;
    }

    function getNCARecentlyViewed() public view returns (string[] memory) {
        return ncaRecentlyViewed;
    }

    function getTotalDocumentCount() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getTotalDeptFilterCount() public view returns (uint256) {
        return departmentFilterList.length;
    }

    function getTotalAgencyFilterCount() public view returns (uint256) {
        return agencyFilterList.length;
    }

    function getTotalOperatingUnitFilterCount() public view returns (uint256) {
        return operatingUnitFilterList.length;
    }

    function getTotalYearFilterCount() public view returns (uint256) {
        return yearFilterList.length;
    }

    function getFilteredDocumentsLength(string memory _filter) public view returns (uint256) {
        return documentFilters[_filter].length;
    }

    //hierarchical filters
    function getDocumentTypeCategory(string memory year) public view returns (string[] memory) {
        return _documentTypeCategory[year];
    }

    function getDepartmentCategory(string memory year, string memory documentType) public view returns (string[] memory) {
        return _departmentCategory[year][documentType];
    }

    function getAgencyCategory(string memory year, string memory documentType, string memory department) public view returns (string[] memory) {
        return _agencyCategory[year][documentType][department];
    }

    function getOperatingUnitCategory(string memory year, string memory documentType, string memory department, string memory agency) public view returns (string[] memory) {
        return _operatingUnitCategory[year][documentType][department][agency];
    }

    function _batchFilterReturn(string[] memory _arrayOfFilters, uint256 start, uint256 count) internal pure returns (string[] memory) {
        require(start < _arrayOfFilters.length, "Start index is greater than the total number of documents under this filter");
        uint256 end = start + count;
        if (end > _arrayOfFilters.length) {
            end = _arrayOfFilters.length;
        }
        string[] memory batch = new string[](end - start);
        for (uint256 i = start; i < end; i++) {
            batch[i - start] = _arrayOfFilters[i];
        }
        return batch;
    }

    function getAllFilters(string memory _filterType, uint256 start, uint256 count) public view returns (string[] memory) {
        if(keccak256(bytes(_filterType)) == keccak256(bytes("department"))){
            return _batchFilterReturn(departmentFilterList, start, count);
        }else if(keccak256(bytes(_filterType)) == keccak256(bytes("agency"))){
            return _batchFilterReturn(agencyFilterList, start, count);
        }else if(keccak256(bytes(_filterType)) == keccak256(bytes("year"))){
            return _batchFilterReturn(yearFilterList, start, count);
        }else if(keccak256(bytes(_filterType)) == keccak256(bytes("operatingUnit"))){
            return _batchFilterReturn(operatingUnitFilterList, start, count);
        }else{
            revert("Invalid filter type");
        }
    }

    // function getDocumentsUnderDepartment(string memory _filter) public view returns (string[] memory) {
    //     return departmentFilters[_filter];
    // }

    // function getDocumentsUnderAgency(string memory _filter) public view returns (string[] memory) {
    //     return agencyFilters[_filter];
    // }

    // function getDocumentsUnderYear(string memory _filter) public view returns (string[] memory) {
    //     return yearFilters[_filter];
    // }

    function getDocumentsUnderFilter(string memory _filter, uint256 start, uint256 count) public view returns (string[] memory) {
        require(start < documentFilters[_filter].length, "Start index is greater than the total number of documents under this filter");
        uint256 end = start + count;
        if (end > documentFilters[_filter].length) {
            end = documentFilters[_filter].length;
        }
        string[] memory batch = new string[](end - start);
        for (uint256 i = start; i < end; i++) {
            batch[i - start] = documentFilters[_filter][i];
        }
        return batch;
    }

    function getDocumentIds(uint256 start, uint256 count) public view returns (string[] memory) {
        require(start < _tokenIds.current(), "Start index is greater than the total number of documents");

        uint256 end = start + count;
        if (end > _tokenIds.current()) {
            end = _tokenIds.current();
        }

        string[] memory batch = new string[](end - start);
        for (uint256 i = start; i < end; i++) {
            batch[i - start] = documentTokenId[i];
        }
        return batch;
    }

    function _getFirst4Chars(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length < 4) {
            return str; // Return the whole string if it's shorter than 4 characters
        }

        bytes memory result = new bytes(4);
        for (uint i = 0; i < 4; i++) {
            result[i] = strBytes[i];
        }

        return string(result);
    }

    function _getSaroYear(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length < 4) {
            return str; // Return the whole string if it's shorter than 4 characters
        }

        bytes memory result = new bytes(4);
        for (uint i = 0; i < 4; i++) {
            result[i] = strBytes[i + 6];
        }

        return string(result);
    }

    function _getTokenURI(uint256 _tokenID) 
	internal
	view 
	virtual  
	returns (string memory) {
		if (!_exists(_tokenID)) revert('The token does not exist.');

		string memory _tokenPath = _tokenPaths[_tokenID];
		return string(abi.encodePacked(_tokenBaseURI, _tokenPath));
	}

    function tokenURI(uint256 tokenId) public view override returns(string memory) {        
        return _getTokenURI(tokenId);
    }

    function getTokenIdToDocu(string memory _documentNumber) public view returns (uint256) {
        return tokenIdToDocu[_documentNumber];
    }
    
    function tokenizeSaro(
        string[] memory _tokenPathsArr,
        SAROMetadata[] memory _saroDataArr,
        string[] memory _releaseDates
    ) external onlyOwner {
        require(_tokenPathsArr.length == _saroDataArr.length, "Arrays don't match");
        uint256 mintCount = _tokenPathsArr.length;
        uint256 [] memory arrItemID = new uint256 [](mintCount);
        string [] memory _documentNumberArr = new string [](mintCount);

        for(uint i = 0; i < mintCount; i++) {
            string memory _saroNumber = _saroDataArr[i].saroNumber;
            if(_saroExists[_saroNumber]) {
                continue;
            }
            uint256 newItemId = _tokenIds.current(); 
            address _contractOwner = owner();
		    _safeMint(_contractOwner, newItemId);
		    _tokenPaths[newItemId] = _tokenPathsArr[i];
            _saroData[_saroNumber] = _saroDataArr[i];
            documentTokenId[newItemId] = _saroNumber;
            tokenIdToDocu[_saroNumber] = newItemId;

            string memory releaseYear = _getSaroYear(_releaseDates[i]);

            if (!_isDocumentTypeCategoryExisting[releaseYear]['saro']){
                _documentTypeCategory[releaseYear].push('saro');
                _isDocumentTypeCategoryExisting[releaseYear]['saro'] = true;
            }
            if (!_isDepartmentCategoryExisting[releaseYear]['saro'][_saroDataArr[i].department]) {
                _departmentCategory[releaseYear]['saro'].push(_saroDataArr[i].department);
                _isDepartmentCategoryExisting[releaseYear]['saro'][_saroDataArr[i].department] = true; 
            }
            if(!_isFilterExists[_saroDataArr[i].department]){
                departmentFilterList.push(_saroDataArr[i].department);
                _isFilterExists[_saroDataArr[i].department] = true;
            }
            documentFilters[_saroDataArr[i].department].push(_saroNumber);

            if (!_isAgencyCategoryExisting[releaseYear]['saro'][_saroDataArr[i].department][_saroDataArr[i].agency]) {
                _agencyCategory [releaseYear]['saro'][_saroDataArr[i].department].push(_saroDataArr[i].agency);
                _isAgencyCategoryExisting[releaseYear]['saro'][_saroDataArr[i].department][_saroDataArr[i].agency] = true;
            }
            if(!_isFilterExists[_saroDataArr[i].agency]){
                agencyFilterList.push(_saroDataArr[i].agency);
                _isFilterExists[_saroDataArr[i].agency] = true;
            }
            documentFilters[_saroDataArr[i].agency].push(_saroNumber);

            if (!_isOperatingUnitCategoryExisting[releaseYear]['saro'][_saroDataArr[i].department][_saroDataArr[i].agency][_saroDataArr[i].operatingUnit]) {
                _operatingUnitCategory[releaseYear]['saro'][_saroDataArr[i].department][_saroDataArr[i].agency].push(_saroDataArr[i].operatingUnit);
                _isOperatingUnitCategoryExisting[releaseYear]['saro'][_saroDataArr[i].department][_saroDataArr[i].agency][_saroDataArr[i].operatingUnit] = true;
            }
            if(!_isFilterExists[_saroDataArr[i].operatingUnit]){
                operatingUnitFilterList.push(_saroDataArr[i].operatingUnit);
                _isFilterExists[_saroDataArr[i].operatingUnit] = true;
            }
            documentFilters[_saroDataArr[i].operatingUnit].push(_saroNumber);

            if(!_isFilterExists[releaseYear]){
                yearFilterList.push(releaseYear);
                _isFilterExists[releaseYear] = true;
            }
            documentFilters[releaseYear].push(_saroNumber);


            _documentNumberArr[i] = _saroNumber;            
            arrItemID[i] = newItemId;
            _saroExists[_saroNumber] = true;
            _tokenIds.increment();
            _saroCount.increment();
            documentIds.push(_saroDataArr[i].saroNumber);
        }

        emit DocumentsTokenized(_documentNumberArr, arrItemID, "SARO");

    }

    function tokenizeNca(
        string[] memory _tokenPathsArr,
        NCAMetadata[] memory _ncaDataArr,
        string[] memory _releaseDates
    ) external onlyOwner {
        require(_tokenPathsArr.length == _ncaDataArr.length, "Arrays don't match");
        uint256 mintCount = _tokenPathsArr.length;
        uint256[] memory arrItemID = new uint256[](mintCount);
        string[] memory _ncaNumbers = new string[](mintCount);
        uint256 trueMints = 0;

        for(uint i = 0; i < mintCount; i++) {
            string memory _ncaNumber = _ncaDataArr[i].ncaNumber;
            if(_ncaExists[_ncaNumber]){
                if(!_pairExists(_ncaNumber, _ncaDataArr[i].operatingUnit[0], _ncaDataArr[i].amount[0])){
                   _pushNcaData(_ncaNumber, _ncaDataArr[i].operatingUnit[0], _ncaDataArr[i].amount[0]);
                   _ncaIndex.increment();
                }
                continue;
            }
            uint256 newItemId = _tokenIds.current(); 
            address _contractOwner = owner();
		    _safeMint(_contractOwner, newItemId);
		    _tokenPaths[newItemId] = _tokenPathsArr[i];
            _ncaData[_ncaNumber] = _ncaDataArr[i];
            documentTokenId[newItemId] = _ncaNumber;
            tokenIdToDocu[_ncaNumber] = newItemId;
            _ncaNumbers[trueMints] = _ncaNumber;


            string memory releaseYear = _getFirst4Chars(_releaseDates[i]);

            if (!_isDocumentTypeCategoryExisting[releaseYear]['nca']){
                _documentTypeCategory[releaseYear].push('nca');
                _isDocumentTypeCategoryExisting[releaseYear]['nca'] = true;
            }
            if (!_isDepartmentCategoryExisting[releaseYear]['nca'][_ncaDataArr[i].department]) {
                _departmentCategory[releaseYear]['nca'].push(_ncaDataArr[i].department);
                _isDepartmentCategoryExisting[releaseYear]['nca'][_ncaDataArr[i].department] = true; 
            }
            if(!_isFilterExists[_ncaDataArr[i].department]){
                departmentFilterList.push(_ncaDataArr[i].department);
                _isFilterExists[_ncaDataArr[i].department] = true;
            }
            documentFilters[_ncaDataArr[i].department].push(_ncaNumber);

            if (!_isAgencyCategoryExisting[releaseYear]['nca'][_ncaDataArr[i].department][_ncaDataArr[i].agency]) {
                _agencyCategory [releaseYear]['nca'][_ncaDataArr[i].department].push(_ncaDataArr[i].agency);
                _isAgencyCategoryExisting[releaseYear]['nca'][_ncaDataArr[i].department][_ncaDataArr[i].agency] = true;
            }
            if(!_isFilterExists[_ncaDataArr[i].agency]){
                agencyFilterList.push(_ncaDataArr[i].agency);
                _isFilterExists[_ncaDataArr[i].agency] = true;
            }
            documentFilters[_ncaDataArr[i].agency].push(_ncaNumber);
            
            
            for(uint indexOperUnit; indexOperUnit < _ncaDataArr[i].operatingUnit.length; indexOperUnit++){
                if (!_isOperatingUnitCategoryExisting[releaseYear]['nca'][_ncaDataArr[i].department][_ncaDataArr[i].agency][_ncaDataArr[i].operatingUnit[indexOperUnit]]) {
                _operatingUnitCategory[releaseYear]['nca'][_ncaDataArr[i].department][_ncaDataArr[i].agency].push(_ncaDataArr[i].operatingUnit[indexOperUnit]);
                _isOperatingUnitCategoryExisting[releaseYear]['nca'][_ncaDataArr[i].department][_ncaDataArr[i].agency][_ncaDataArr[i].operatingUnit[indexOperUnit]] = true;
                }

                if(!_isFilterExists[_ncaDataArr[i].operatingUnit[indexOperUnit]]){
                    operatingUnitFilterList.push(_ncaDataArr[i].operatingUnit[indexOperUnit]);
                    _isFilterExists[_ncaDataArr[i].operatingUnit[indexOperUnit]] = true;
                }
                documentFilters[_ncaDataArr[i].operatingUnit[indexOperUnit]].push(_ncaNumber);
            }

            if(!_isFilterExists[releaseYear]){
                yearFilterList.push(releaseYear);
                _isFilterExists[releaseYear] = true;
            }
            documentFilters[releaseYear].push(_ncaNumber);

            arrItemID[trueMints] = newItemId;
            _ncaExists[_ncaNumber] = true;
            _tokenIds.increment();
            _ncaIndex.increment();
            _ncaCount.increment();
            trueMints++;
            documentIds.push(_ncaDataArr[i].ncaNumber);

        }

        uint256[] memory _trueTokenIds = new uint256[](trueMints);
        string[] memory _trueNcaNumbers = new string[](trueMints);
        for(uint j = 0; j < trueMints; j++){
            _trueTokenIds[j] = arrItemID[j];
            _trueNcaNumbers[j] = _ncaNumbers[j];
        }

            emit DocumentsTokenized(_trueNcaNumbers, _trueTokenIds, "NCA");
        }

    function _pushNcaData(string memory _ncaNumber, string memory _operatingUnit, string memory _amount)
    internal {
        _ncaData[_ncaNumber].operatingUnit.push(_operatingUnit);
        _ncaData[_ncaNumber].amount.push(_amount);
    }

    function _pairExists(string memory _ncaNumber, string memory unit, string memory amount) internal view returns (bool) {
        NCAMetadata storage existing = _ncaData[_ncaNumber];
        for (uint i = 0; i < existing.operatingUnit.length; i++) {
            if (
                keccak256(bytes(existing.operatingUnit[i])) == keccak256(bytes(unit)) &&
                keccak256(bytes(existing.amount[i])) == keccak256(bytes(amount))
            ) {
                return true;
            }
        }
        return false;
}

    function countSearchedSaro(string memory _saroNumber)
    external
    {
        saroRecentlyViewed.push(_saroNumber); // Add new item at the end
        if (saroRecentlyViewed.length > 5) {
            // Remove the first element and shift all elements left
            for (uint i = 0; i < saroRecentlyViewed.length - 1; i++) {
                saroRecentlyViewed[i] = saroRecentlyViewed[i + 1];
            }
            saroRecentlyViewed.pop(); // Remove the last element (duplicate)
        }
        _saroSearchCount[_saroNumber]++;
    }

    function countSearchedNCA(string memory _ncaNumber)
    external
    {
        ncaRecentlyViewed.push(_ncaNumber); // Add new item at the end
        if (ncaRecentlyViewed.length > 5) {
            // Remove the first element and shift all elements left
            for (uint i = 0; i < ncaRecentlyViewed.length - 1; i++) {
                ncaRecentlyViewed[i] = ncaRecentlyViewed[i + 1];
            }
            ncaRecentlyViewed.pop(); // Remove the last element (duplicate)
        }
        _ncaSearchCount[_ncaNumber]++;
    }

    function getSaroData(string memory _saroNumber)
    public
    view
    returns (SAROMetadata memory) {
        if(keccak256(bytes(_saroData[_saroNumber].saroNumber)) == keccak256(bytes(""))){
            revert("This document has not been tokenized yet");
        }else{
            return _saroData[_saroNumber];
        }
        
    }

    function getNcaData(string memory _ncaNumber)
    public
    view
    returns (NCAMetadata memory) {
        if(keccak256(bytes(_ncaData[_ncaNumber].ncaNumber)) == keccak256(bytes(""))){
            revert("This document has not been tokenized yet");
        }else{
            return _ncaData[_ncaNumber];
        }
    }

    function getDocumentTopSearched() public view returns (string[] memory, uint256[] memory) {
        uint256 length = documentIds.length;

        if (length == 0) {
            revert('length equals 0');
        }

        // Create arrays for sorting
        string[] memory ids = new string[](length);
        uint256[] memory views = new uint256[](length);

        // Populate arrays
        for (uint256 i = 0; i < length; i++) {
            ids[i] = documentIds[i];
            if(_ncaSearchCount[documentIds[i]] >= _saroSearchCount[documentIds[i]]){
                views[i] = _ncaSearchCount[documentIds[i]];
            }else{
                views[i] = _saroSearchCount[documentIds[i]];
            }
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
}
