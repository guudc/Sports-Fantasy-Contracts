// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The contract `Royalty` provides a system for managing a collection of farms, 
// where each farm has associated buying and selling fees.
contract Royalty is Ownable {
    
    // Define structure for a farm collection.
    struct FARM_COLLECTION {
        uint256 farmCollectionID;        // Unique identifier for the farm collection.
        address farmOwner;               // Address of the farm owner.
        uint256 buyingFeePercentage;     // Buying fee percentage.
        uint256 sellingFeePercentage;    // Selling fee percentage.
        bool flag;                       // Flag to indicate if the collection exists.
    }

    // Mapping from collection ID to farm collection.
    mapping(uint256 => FARM_COLLECTION) public FARM_COLLECTION_DATA;

    // Constructor of the contract. Initializes the owner of the contract.
    constructor() {
        _transferOwnership(msg.sender);
    }
    
    // Function to create a new farm collection data.
    // _farmCollectionId: Unique identifier for the farm collection.
    // _farmOwner: Address of the farm owner.
    // _buyingFeePercentage: Buying fee percentage.
    // _sellingFeePercentage: Selling fee percentage.
    function CreateFarmCollectionData(
        uint256 _farmCollectionId, 
        address _farmOwner, 
        uint256 _buyingFeePercentage, 
        uint256 _sellingFeePercentage
    ) external onlyOwner returns(bool) {
        require(_farmOwner!= address(0),"Farmowner must not be zero Address");
        FARM_COLLECTION_DATA[_farmCollectionId] = FARM_COLLECTION(
            _farmCollectionId,
            _farmOwner,
            _buyingFeePercentage,
            _sellingFeePercentage,
            true
        );
        return true;
    }
    
    // Function to update the buying fee percentage of a farm collection.
    // _farmCollectionId: Unique identifier for the farm collection.
    // _buyingFeePercentage: New buying fee percentage.
    function updateBuyingFeePercentage(
        uint256 _farmCollectionId, 
        uint256 _buyingFeePercentage
    ) external onlyOwner returns(bool) {
        require(FARM_COLLECTION_DATA[_farmCollectionId].flag,"Collection does not exist!");
        FARM_COLLECTION_DATA[_farmCollectionId].buyingFeePercentage = _buyingFeePercentage;
        return true;
    }

    // Function to update the selling fee percentage of a farm collection.
    // _farmCollectionId: Unique identifier for the farm collection.
    // _sellingFeePercentage: New selling fee percentage.
    function updateSellingFeePercentage(
        uint256 _farmCollectionId, 
        uint256 _sellingFeePercentage
    ) external onlyOwner returns(bool) {
        require(FARM_COLLECTION_DATA[_farmCollectionId].flag,"Collection does not exist!");
        FARM_COLLECTION_DATA[_farmCollectionId].sellingFeePercentage = _sellingFeePercentage;
        return true;
    }

    // Function to update the owner of a farm collection.
    // _farmCollectionId: Unique identifier for the farm collection.
    // _farmOwner: Address of the new farm owner.
    function updateFarmOwner(
        uint256 _farmCollectionId, 
        address _farmOwner
    ) external onlyOwner returns(bool) {
        require(_farmOwner!= address(0),"Farmowner must not be zero Address");
        require(FARM_COLLECTION_DATA[_farmCollectionId].flag,"Collection does not exist!");
        FARM_COLLECTION_DATA[_farmCollectionId].farmOwner = _farmOwner;
        return true;
    }

    // Function to get the buying fee percentage of a farm collection.
    // _farmCollectionId: Unique identifier for the farm collection.
    function getBuyingFeePercentage(uint256 _farmCollectionId) public view returns(uint256) {
        return FARM_COLLECTION_DATA[_farmCollectionId].buyingFeePercentage;
    }

    // Function to get the selling fee percentage of a farm collection.
    // _farmCollectionId: Unique identifier for the farm collection.
    function getSellingFeePercentage(uint256 _farmCollectionId) public view returns(uint256) {
        return FARM_COLLECTION_DATA[_farmCollectionId].sellingFeePercentage;
    }

    // Function to get the owner of a farm collection.
    // _farmCollectionId: Unique identifier for the farm collection.
    function getFarmOwner(uint256 _farmCollectionId) public view returns(address) {
        return FARM_COLLECTION_DATA[_farmCollectionId].farmOwner;
    }

    // Function to get the details of a farm collection.
    // _farmCollectionId: Unique identifier for the farm collection.
    function getFarmCollectionDetails(uint256 _farmCollectionId) public view returns (
        uint256, address, uint256, uint256
    ) {
        FARM_COLLECTION storage FarmCollectionDetailsTemp = FARM_COLLECTION_DATA[_farmCollectionId];
        return (FarmCollectionDetailsTemp.farmCollectionID, FarmCollectionDetailsTemp.farmOwner, FarmCollectionDetailsTemp.buyingFeePercentage, FarmCollectionDetailsTemp.sellingFeePercentage);
    }
}
