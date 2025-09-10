// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Escrow.sol";
import "./Royalty.sol";
   

contract Offer is Ownable{

/**
    * @dev Address of the ERC20 token contract used as the native cryptocurrency (SNC) for trading NFTs.
*/
    address public sncAddress;

/**
    * @dev Address of the ERC1155 token contract used for minting, transferring, and burning NFTs.
*/
    address public nftAddress;

/**
     * @dev Address of the wallet where all platform fees (Buying, Selling) will be sent.
*/
    address public changeFee;

/**
     * @dev The percentage value (in basis points) deducted from the offer price as the seller's fee.
*/
    uint256 public sellerFeePercent;

/**
    * @dev The percentage value (in basis points) deducted from the offer price as the buyer's fee.
*/
    uint256 public buyerFeePercent;

/**
    * @dev Address of the royalty smart contract used to give royalty to the farm owner whenever their NFTs are traded in the Secondary Market.
*/
    address public royaltyContractAddress;

/**
     * @dev Interface for the ERC20 token contract used as the native cryptocurrency (SNC) for trading NFTs.
     * This interface provides access to standard ERC20 functions, such as transfer, balanceOf, and transferFrom.
*/
    IERC20 private snc;

/**
     * @dev Interface for the ERC1155 token contract used for minting, transferring, and burning NFTs.
     * This interface provides access to standard ERC1155 functions, such as safeTransferFrom and balanceOf.
*/
    IERC1155 private nft;

/**
     * @dev Interface for the royalty smart contract used to give royalty to the farm owner whenever their NFTs are traded in the Secondary Market.
     * This interface provides access to functions specific to the royalty smart contract, allowing interaction with the royalty mechanism.
*/
    Royalty private royalty;

/**
     * @dev Struct representing an offer made by a buyer for an NFT.
     * 
     * @param _offerID The unique identifier of the offer.
     * @param _price The price offered by the buyer for the NFT.
     * @param _tokenID The token ID of the NFT for which the offer is made.
     * @param _duration The timestamp representing the expiration time of the offer.
     * @param _buyer The address of the buyer making the offer.
     * @param _seller The address of the seller who owns the NFT receiving the offer.
     * @param _escrow The address of the escrow contract that holds the SNC tokens and NFT until the offer is accepted or canceled.
     * @param _collectionID The collection ID of the farm associated with the NFT. This is used to calculate royalty fees for the farm owner.
     * 
     * This struct represents an offer made by a buyer for a specific NFT. It stores essential information about the offer,
     * including the offer ID, offer price, expiration time, buyer and seller addresses, and the associated escrow contract.
     * The collection ID is also stored to determine the royalty fees for the farm owner whenever their NFT is traded.
*/
    struct offer {
        uint256 _offerID;
        uint256 _price;
        uint256 _tokenID;
        uint256 _duration;
        address _buyer;
        address _seller;
        address _escrow;
        uint256 _collectionID;
    }
 
/**
     * @dev Mapping to store offers made by buyers for each NFT token.
     * 
     * @ uint256 The token ID of the NFT.
     * @ offer[] An array containing all the offers made for the specific NFT token.
     * 
     * This mapping keeps track of all the offers made by buyers for each NFT token. It uses the token ID as the key to access
     * the corresponding array of offers. Each element of the array represents a single offer made by a buyer, storing the offer details
     * such as offer ID, offer price, expiration time, buyer, seller, escrow address, and the associated collection ID.
*/

    mapping(uint256 => offer[]) private NFT_OFFERS;

/**
     * @dev Mapping to track whether an NFT token has already accepted an offer.
     * 
     * @ uint256 The token ID of the NFT.
     * @ bool A boolean flag indicating whether an offer has been accepted for the specific NFT token (true) or not (false).
     * 
     * This mapping keeps track of whether an NFT token has already accepted an offer. It uses the token ID as the key to access
     * the corresponding boolean value. If the value is true, it means the NFT has accepted an offer, and no further offers will be accepted.
     * If the value is false, it means the NFT is still available for offers to be made.
*/
    mapping(uint256 => bool) public NFT_OFFER_COMPLETED;    
  
/**
     * @dev Emitted when a new offer is made by a buyer for an NFT.
     * 
     * @param _buyer The address of the buyer making the offer.
     * @param _amount The price offered by the buyer for the NFT.
     * @param _duration The duration of the offer in unix time seconds.
     * @param _tokenId The token ID of the NFT for which the offer is made.
     * 
     * This event is emitted when a buyer makes a new offer for an NFT. It provides information about the buyer's address,
     * the offered amount, the duration of the offer, and the token ID of the NFT. This event can be used to track new offers
     * and monitor the NFT trading activity.
 */
    event newOffer(address _buyer, uint _amount, uint _duration, uint _tokenId);

/**
     * @dev Emitted when an offer is canceled by the buyer or seller.
     * 
     * @param _offerId The ID of the canceled offer.
     * @param _buyer The address of the buyer who canceled the offer.
     * @param _cancelType A string indicating the type of cancellation, either "buyer" or "seller".
     * 
     * This event is emitted when an offer is canceled by either the buyer or the seller. It provides the offer ID that was canceled,
     * the address of the canceling party, and a string indicating whether it was canceled by the buyer or the seller. This event can be
     * used to track offer cancellations and take appropriate actions based on the cancellation type.
 */
    event cancelOffer(uint _offerId, address _buyer, string _cancelType);

/**
     * @dev Emitted when all offers for a specific NFT are canceled by the seller.
     * 
     * @param _tokenId The token ID of the NFT for which all offers were canceled.
     * @param _seller The address of the seller who canceled all the offers.
     * 
     * This event is emitted when the seller cancels all the offers made for a specific NFT. It provides the token ID of the NFT for which
     * the offers were canceled and the address of the seller who initiated the cancellation. This event can be used to track the cancellation
     * of all offers for an NFT and take appropriate actions accordingly.
 */
    event cancelAllOffer(uint _tokenId, address _seller);

/**
     * @dev Emitted when an offer is accepted by the seller for an NFT.
     * 
     * @param _offerId The ID of the accepted offer.
     * @param _buyer The address of the buyer whose offer was accepted.
     * @param _price The price at which the NFT was sold.
     * 
     * This event is emitted when the seller accepts an offer made by a buyer for an NFT. It provides the offer ID that was accepted,
     * the address of the buyer whose offer was accepted, and the final price at which the NFT was sold. This event can be used to track
     * successful offers and record the final selling price of the NFT.
 */
    event acceptedOffer(uint _offerId, address _buyer, uint256 _price);

/**
     * @dev Emitted when an offer for an NFT expires.
     * 
     * @param _tokenId The token ID of the expired offer.
     * @param _offerId The ID of the expired offer.
     * @param _buyer The address of the buyer who made the expired offer.
     * @param _duration The original duration of the offer in unix time seconds.
     * 
     * This event is emitted when an offer for an NFT expires due to the offer duration elapsing. It provides the token ID and offer ID of the expired offer,
     * the address of the buyer who made the offer, and the original duration of the offer. This event can be used to track expired offers and take appropriate
     * actions based on the expiration of the offer.
 */
    event expiredOffer(uint256 _tokenId, uint _offerId, address _buyer, uint256 _duration);

/**
     * @dev Emitted when the seller fee or buyer fee percentage is changed.
     * 
     * @param _newFee The new fee percentage value that was set.
     * @param _type A string indicating the type of fee changed, either "SELLER FEE PERCENT" or "BUYER FEE PERCENT".
     * 
     * This event is emitted when the seller fee or buyer fee percentage is changed by the contract owner. It provides the new fee percentage value
     * that was set and a string indicating whether it was the seller fee or buyer fee percentage that was changed. This event can be used to track changes
     * in the fee structure and notify users about updated fee percentages.
*/
    event changeFeePercentageValue(uint _newFee, string _type);

/**
     * @dev Emitted when the address of the royalty contract (SMC5) is changed.
     * 
     * @param _newRoyaltyContractAddress The new address of the royalty contract.
     * 
     * This event is emitted when the address of the royalty contract (SMC5) is changed by the contract owner. It provides the new address of the royalty contract.
     * This event can be used to track changes in the royalty contract address and notify users about the updated contract address.
 */
    event changeRoyaltyAddress(address _newRoyaltyContractAddress);

/**
     * @dev Emitted when the amount is sent to the seller after an offer is accepted.
     * 
     * @param _seller The address of the seller who received the amount.
     * @param _price The amount received by the seller after the offer is accepted.
     * 
     * This event is emitted when the seller receives the amount after accepting a buyer's offer for an NFT. It provides the address of the seller who received
     * the amount and the actual amount transferred to the seller. This event can be used to track successful transactions and record the amounts received by sellers.
 */
    event tranferPriceToSeller(address _seller, uint256 _price);

/**
     * @dev Emitted when the seller fee is sent to the change fee address.
     * 
     * @param _changeFee The address of the change fee contract where the seller fee is sent.
     * @param _fee The amount of the seller fee sent to the change fee contract.
     * 
     * This event is emitted when the seller fee is sent to the change fee contract. It provides the address of the change fee contract
     * where the seller fee is sent and the amount of the seller fee. This event can be used to track the distribution of seller fees
     * and monitor the flow of funds.
*/
    event sellerFeeToChangeFee(address _changeFee, uint256 _fee);

/**
     * @dev Emitted when the royalty fee percentage is sent to the farm owner.
     * 
     * @param _farmOwner The address of the farm owner who received the royalty fee.
     * @param _royaltySellerFee The amount of the royalty fee sent to the farm owner.
     * 
     * This event is emitted when the royalty fee percentage is sent to the farm owner. It provides the address of the farm owner
     * who received the royalty fee and the amount of the royalty fee. This event can be used to track royalty fee payments to
     * the farm owner and monitor royalty distributions.
*/
    event sellingRoyaltyFeePercentageToFarmOwner(address _farmOwner, uint256 _royaltySellerFee);

/**
     * @dev Emitted when the buyer fee is sent to the change fee address.
     * 
     * @param _changeFee The address of the change fee contract where the buyer fee is sent.
     * @param _buyerFee The amount of the buyer fee sent to the change fee contract.
     * 
     * This event is emitted when the buyer fee is sent to the change fee contract. It provides the address of the change fee contract
     * where the buyer fee is sent and the amount of the buyer fee. This event can be used to track the distribution of buyer fees
     * and monitor the flow of funds.
 */
    event buyerFeeToChangeFee(address _changeFee, uint256 _buyerFee);

/**
     * @dev Emitted when the buyer royalty fee percentage is sent to the farm owner.
     * 
     * @param _farmOwner The address of the farm owner who received the buyer royalty fee.
     * @param _buyerFee The amount of the buyer royalty fee sent to the farm owner.
     * 
     * This event is emitted when the buyer royalty fee percentage is sent to the farm owner. It provides the address of the farm owner
     * who received the buyer royalty fee and the amount of the buyer royalty fee. This event can be used to track buyer royalty fee payments to
     * the farm owner and monitor royalty distributions.
 */
    event buyerRoyaltyFeePercentageToFarmOwner(address _farmOwner, uint256 _buyerFee);

/**
     * @dev Emitted when the NFT contract address is changed.
     * 
     * @param _newNFTAddress The new address of the NFT contract.
     * 
     * This event is emitted when the NFT contract address is changed by the contract owner. It provides the new address of the NFT contract.
     * This event can be used to track changes in the NFT contract address and notify users about the updated contract address.
 */
    event changeNFTAddress(address _newNFTAddress);

/**
     * @dev Emitted when the SNC contract address is changed.
     * 
     * @param _newSNCAddress The new address of the SNC contract.
     * 
     * This event is emitted when the SNC contract address is changed by the contract owner. It provides the new address of the SNC contract.
     * This event can be used to track changes in the SNC contract address and notify users about the updated contract address.
 */
    event changeSNCAddress(address _newSNCAddress);
    
    /*
        @params buyerFee and sellerFee : in percentage, uses a multiplier of 100 as the bps
        i.e 1.5% should be represented as 150 and 100% should be represented as 10000

        2) Include Royalty Smarrtcontract address in this while deploying
    */

/**
     * @dev Contract constructor. Initializes the contract with the provided parameters.
     * 
     * @ _sncAddress The address of the SNC (Stablecoin) contract.
     * @ _nftAddress The address of the NFT (ERC1155) contract.
     * @ _changeFee The address of the change fee contract for handling fee distributions.
     * @ _buyerFee The percentage of the buyer fee for each NFT purchase. It should be 
     * @ _sellerFee The percentage of the seller fee for each NFT sale.
     * @ _royaltyAddress The address of the Royalty contract for handling royalty distributions.
     * @ _admin The address of the admin or contract owner.
     * 
     * This constructor is called when deploying the contract. It takes the addresses of the SNC contract, NFT contract, change fee contract,
     * and Royalty (SMC5) contract as well as the buyer fee and seller fee percentages, and the admin address. It initializes the contract by
     * setting these parameters and transferring the ownership to the admin. It also creates instances of the IERC20 and IERC1155 interfaces
     * for the SNC and NFT contracts, respectively, to interact with them throughout the contract functions.
     * 
     * Note:
     * @ buyerFee and sellerFee : In percentage, uses a multiplier of 100 as the bps
        i.e 1.5% should be represented as 150 and 100% should be represented as 10000

 */  

    constructor (address _sncAddress, address _nftAddress, address _changeFee, uint256 _buyerFee, uint256 _sellerFee,address _royaltyAddress, address _admin) {
        snc = IERC20(_sncAddress);
        nft = IERC1155(_nftAddress);
        royalty = Royalty(_royaltyAddress);
        changeFee = _changeFee;
        sncAddress = _sncAddress;
        nftAddress = _nftAddress;
        buyerFeePercent = _buyerFee;
        sellerFeePercent = _sellerFee;
        royaltyContractAddress = _royaltyAddress;
        _transferOwnership(_admin);
    }
/**
     * @dev Internal function to retrieve the details of a farm collection.
     * 
     * @param _collectionId The ID of the farm collection for which the details are requested.
     * @return id The ID of the farm collection.
     * @return farmOwner The address of the farm owner who owns the collection.
     * @return buyingRoyaltyFeePercentage The percentage of royalty fee to be paid to the farm owner on buying an NFT from the collection.
     * @return sellingRoyaltyFeePercentage The percentage of royalty fee to be paid to the farm owner on selling an NFT from the collection.
     * 
     * This internal function is used to fetch the details of a farm collection. It takes the `_collectionId` as input and calls the
     * `getFarmOwnerdetails` function of the `Royalt1` (Royalty) contract to retrieve the necessary information. The function then returns
     * the ID of the collection, the address of the farm owner, and the royalty fee percentages for buying and selling NFTs from the collection.
 */
    function getFarmCollectionDetails(uint256 _collectionId) internal view returns (uint256, address, uint256, uint256) {
        (
            uint256 id,
            address farmOwner,
            uint256 buyingRoyaltyFeePercentage,
            uint256 sellingRoyaltyFeePercentage
        ) = royalty.getFarmOwnerdetails(_collectionId);

        return (id, farmOwner, buyingRoyaltyFeePercentage, sellingRoyaltyFeePercentage);
    }

/**
     * @dev Calculate the total buyer fee for purchasing an NFT from a farm collection.
     * 
     * @param _offerPrice The price of the NFT being offered by the seller.
     * @param _cId The ID of the farm collection from which the NFT is being purchased.
     * @return _totalBuyerFee The total fee to be paid by the buyer for the NFT purchase, including both the base buyer fee and the royalty fee.
     * 
     * This function calculates the total buyer fee to be paid by the buyer when purchasing an NFT from a farm collection. The buyer fee includes both
     * the base buyer fee (defined as a percentage of the offer price) and the royalty fee (a percentage of the offer price paid to the farm owner).
     * It takes the `_offerPrice` and `_cId` as inputs, fetches the royalty fee percentage for the specific farm collection using the `getFarmOwnerdetails`
     * function of the `Royalt1` (Royalty) contract, and then calculates the individual buyer fee and royalty fee amounts. Finally, it returns the total
     * buyer fee to be paid by the buyer for the NFT purchase.
 */
    function getBuyerFee(uint256 _offerPrice, uint256 _cId) public view returns (uint256) {
        // Calculate the base buyer fee as a percentage of the offer price
        uint256 _buyerFee = (_offerPrice * buyerFeePercent) / 10000;

        // Fetch the royalty fee percentage for the specified farm collection from the Royalty contract
        (, , 
         uint256 buyingRoyaltyFeePercentage, 
         ) = royalty.getFarmOwnerdetails(_cId);

        // Calculate the royalty fee as a percentage of the offer price
        uint256 _royaltyBuyerFee = (_offerPrice * buyingRoyaltyFeePercentage) / 10000;

        // Calculate the total buyer fee by summing the base buyer fee and the royalty fee
        uint256 _totalBuyerFee = _buyerFee + _royaltyBuyerFee;

        return _totalBuyerFee;
    }

/**
     * @dev Create a new offer for purchasing an NFT from a seller.
     * 
     * @param _tokenId The ID of the NFT being offered for sale.
     * @param _offerPrice The price at which the NFT is being offered for sale.
     * @param _duration The duration (in unix time) for which the offer is valid.
     * @param _buyerAddress The address of the buyer making the offer.
     * @param _seller The address of the seller who owns the NFT.
     * @param _buyerFee The buyer's fee for purchasing the NFT (Buyer Fee + Buyer Royalty Fee).
     * @param _collectionId The ID of the farm collection to which the NFT belongs.
     * @return _offerId The ID of the newly created offer.
     * 
     * This function allows a buyer to make a new offer to purchase an NFT from a seller. The buyer specifies the `_tokenId`, `_offerPrice`, `_duration`,
     * `_buyerAddress`, `_seller`, `_buyerFee`, and `_collectionId` as inputs. Before creating the offer, several conditions are checked to ensure the validity
     * of the offer:
     * - The function checks that the `_buyerAddress` matches the sender of the transaction (the buyer must be the signer of the transaction).
     * - It checks if the NFT being offered exists and belongs to the specified `_seller`.
     * - It verifies that the buyer has not already made an offer for the same `_tokenId`.
     * - The buyer must have enough SNC tokens to cover the offer price and the `_buyerFee`.
     * - The offer duration must not have expired (current block timestamp must be less than `_duration`).
     * 
     * If all the conditions are met, the function moves the required amount of SNC tokens (offer price + buyer fee) to an Escrow contract for holding the
     * payment during the offer duration. The function creates a new offer entry and adds it to the `NFT_OFFERS` mapping with relevant details, including the
     * offer ID, offer price, buyer's address, seller's address, Escrow contract address, and the collection ID. The buyer fee is calculated using the
     * `getBuyerFee` function. Finally, the function emits the `newOffer` event and returns the ID of the newly created offer.
 */
    function makeOffer(uint256 _tokenId, uint256 _offerPrice, uint256 _duration, address _buyerAddress, address _seller, uint256 _buyerFee, uint256 _collectionId) public returns(uint256) {
        // Verify that the buyer is the signer of the transaction
        require(_buyerAddress == msg.sender, "Buyer is not signer!");

        // Check if the NFT being offered exists and belongs to the specified seller
        require(nft.balanceOf(_seller, _tokenId) == 1, "NFT does not exist!");

        // Check if the buyer has not already made an offer for the same tokenId
        (bool hasMade, ) = checkIfOfferMade(_buyerAddress, _tokenId);
        require(!hasMade, "You have already made an offer");

        // Check if the buyer has enough SNC tokens to cover the offer price and buyer fee
        require(snc.balanceOf(_buyerAddress) >= (_offerPrice + _buyerFee), "Insufficient SNC tokens for this offer");

        // Check if the offer duration has not expired
        require(block.timestamp < _duration, "Offer duration expired");

        // Create an Escrow contract to hold the payment during the offer duration
        Escrow escrow = new Escrow(nftAddress, _tokenId, sncAddress);

        // Create a new offer entry and add it to the NFT_OFFERS mapping
        NFT_OFFERS[_tokenId].push(offer(
            NFT_OFFERS[_tokenId].length,
            _offerPrice,
            _tokenId,
            _duration,
            _buyerAddress,
            _seller,
            address(escrow),
            _collectionId
        ));

        // Calculate the actual buyer fee based on the offer price and collection ID
        uint256 _calculateBuyerFee = getBuyerFee(_offerPrice, _collectionId);

        // Verify that the provided buyer fee matches the calculated buyer fee
        require(_calculateBuyerFee == _buyerFee, "Buyer Fee is not correct!");

        // Transfer the required amount of SNC tokens (offer price + buyer fee) to the Escrow contract
        require(snc.transferFrom(msg.sender, address(escrow), (_offerPrice + _buyerFee)), "Unable to transfer SNC tokens to escrow");

        // Emit the newOffer event
        emit newOffer(_buyerAddress, _offerPrice, _duration, _tokenId);

        // Return the ID of the newly created offer
        return (NFT_OFFERS[_tokenId].length - 1);
    }

/**
     * @dev Accepts an offer for purchasing an NFT from the seller.
     * 
     * @param _tokenId The ID of the NFT being offered for sale.
     * @param _offerId The ID of the offer to be accepted.
     * @param _seller The address of the seller who owns the NFT.
     * @param _forceReject A flag indicating whether to reject all pending offers after accepting the current one (if `true`).
     * @return true if the offer is accepted successfully, otherwise false.
     * 
     * This function allows the seller to accept a specific offer for purchasing an NFT. The seller specifies the `_tokenId`, `_offerId`, `_seller`,
     * and `_forceReject` as inputs. Before accepting the offer, several checks and interactions are performed:
     * - The function checks if the seller has already accepted an offer for the same `_tokenId`.
     * - It verifies that the offer exists for the given `_tokenId` and `_offerId`.
     * - Only the seller of the NFT can call this function.
     * - The function retrieves the necessary information, such as the buyer's address, the Escrow contract, and the offer price.
     * - The function ensures that there are enough SNC tokens in the Escrow contract to cover the offer price and the calculated buyer fee.
     * - The offer is canceled before transferring any funds to prevent reentrancy attacks.
     * - The NFT is directly transferred from the seller to the buyer using the Escrow contract as an intermediary.
     * - The necessary amounts of SNC tokens are transferred to the seller and the respective fee addresses (CHNAGE_FEE and farmOwner).
     * - The function emits various events to record the accepted offer, the transferred amounts, and other relevant information.
     * - Optionally, if `_forceReject` is set to `true`, the function will reject all pending offers for the same `_tokenId` except the one being accepted.
     * 
     * Please note that this function does not loop through all the buyers to refund their SNC tokens if `_forceReject` is used. Instead, it sets a flag,
     * `NFT_OFFER_COMPLETED[_tokenId]`, to prevent the seller from accepting multiple offers for the same `_tokenId`. If needed, buyers can reclaim their
     * offers by calling the `cancelOffer` function. The `forceReject` flag allows for overriding this behavior if the seller wants to accept the current
     * offer and reject all other pending offers for the same `_tokenId` in a single transaction. However, using `_forceReject` may result in higher gas
     * costs and is not recommended if the number of pending offers is substantial.
     * 
     * @ return true if the offer is accepted successfully, otherwise false.
 */
    function acceptOffer(uint256 _tokenId, uint256 _offerId, address _seller, bool _forceReject) public returns (bool) {
        // Check if the seller has already accepted an offer for the given tokenId
        require(!NFT_OFFER_COMPLETED[_tokenId], "Has already accepted an offer");
        //setting state variable before interaction to prevent Reetrancy
        NFT_OFFER_COMPLETED[_tokenId] = true;
        // Check if the offer exists for the given tokenId and offerId
        require(NFT_OFFERS[_tokenId][_offerId]._buyer != address(0), "This offer does not exist");

        // Only the seller of the NFT can call this function
        require(NFT_OFFERS[_tokenId][_offerId]._seller == msg.sender, "This function can only be called by the seller of this NFT");

        // Get the buyer's address, Escrow contract, and offer price
        address buyer = NFT_OFFERS[_tokenId][_offerId]._buyer;
        Escrow escrow = Escrow(NFT_OFFERS[_tokenId][_offerId]._escrow);
        uint256 price = NFT_OFFERS[_tokenId][_offerId]._price;

        // Get the collection ID to calculate buyer and seller royalty fees
        uint256 Collectionid = NFT_OFFERS[_tokenId][_offerId]._collectionID;
            (,
                address farmOwner, 
                uint256 buyingRoyaltyFeePercentage, 
                uint256 sellingRoyaltyFeePercentage) = getFarmCollectionDetails(Collectionid);

        // Calculate the buyer fee and seller fee as the balance after the price has been taken away
        uint256 buyerFee = snc.balanceOf(address(escrow)) - price;

        // Check if the Escrow contract has enough SNC tokens to cover the offer price and buyer fee
        require(snc.balanceOf(address(escrow)) >= (price + buyerFee), "Not enough SNC tokens in escrow to allow for transfer");

        // Cancel the offer before transferring any funds to prevent reentrancy attack
        doMiniCancel(_tokenId, _offerId, buyer, false);

        // Transfer the NFT directly from seller to buyer using the Escrow contract
        require(nft.safeTransferFrom(_seller, address(escrow), _tokenId, 1, ""), "Unable to transfer NFT to escrow");
        escrow.transferNFTFromEscrowtoUser(buyer);

        // Emit the acceptedOffer event
        emit acceptedOffer(_offerId, buyer, price);

        // Calculate the buyer and seller fees after accounting for royalty fees
        uint256 buyerRoyaltyFee = (price * buyingRoyaltyFeePercentage) / 10000;
        buyerFee = buyerFee - buyerRoyaltyFee;
        uint256 sellerFee = (price * sellerFeePercent) / 10000;
        uint256 totalSellerPrice = price - sellerFee;

        // Calculate the seller royalty fee
        uint256 sellerRoyaltyFee = (price * sellingRoyaltyFeePercentage) / 10000;
        totalSellerPrice = totalSellerPrice - sellerRoyaltyFee;

        // Transfer the offer price to the seller and the buyer fee with seller fee to the fee changer
        require(escrow.transferFromEscrowtoUser(_seller, totalSellerPrice), "Unable to transfer NFT to escrow");
        require(escrow.transferFromEscrowtoUser(changeFee, buyerFee), "Unable to transfer NFT to escrow");
        require(escrow.transferFromEscrowtoUser(farmOwner, buyerRoyaltyFee), "Unable to transfer NFT to escrow");
        require(escrow.transferFromEscrowtoUser(changeFee, sellerFee), "Unable to transfer NFT to escrow");
        require(escrow.transferFromEscrowtoUser(farmOwner, sellerRoyaltyFee), "Unable to transfer NFT to escrow");

        // Emit various events to record the transferred amounts and other relevant information
        emit tranferPriceToSeller(_seller, price);
        emit buyerFeeToChangeFee(changeFee, buyerFee);
        emit buyerRoyaltyFeePercentageToFarmOwner(farmOwner, buyerRoyaltyFee);
        emit sellerFeeToChangeFee(changeFee, sellerFee);
        emit sellingRoyaltyFeePercentageToFarmOwner(farmOwner, sellerRoyaltyFee);


        // Optionally, reject all pending offers for the same tokenId if _forceReject is set to true
        if(_forceReject && NFT_OFFERS[_tokenId].length > 0) {
            /*
                You want to do batch transfer, may cost more gas and its unadvisable
            */
           
            //loop through and do batch transfer
           uint _offerIdAfterAcceptingOneOffer = 0;
           address _buyerAfterAcceptingOneOffer = address(0);
           uint numberOfOffers = NFT_OFFERS[_tokenId].length;

           //reseting the has accepted flag using check
           NFT_OFFER_COMPLETED[_tokenId] = false;
           //effects and interactions
           for(uint i=0; i< numberOfOffers;i++) {
                _buyerAfterAcceptingOneOffer = NFT_OFFERS[_tokenId][0]._buyer; //use base offer
                doMiniCancel(_tokenId, _offerIdAfterAcceptingOneOffer, _buyerAfterAcceptingOneOffer, true);
            }       
            
        }
       

        return true;

    }
    
/**
     * @dev Allows a buyer to cancel their outstanding offer for a specific NFT token.
     * @param _buyer The address of the buyer who wants to cancel their offer.
     * @param _tokenId The ID of the NFT token for which the offer needs to be canceled.
     * @return A boolean value indicating whether the offer was successfully canceled.
     *
     * Requirements:
     * - The buyer must have made an offer for the given NFT token.
     * - The function will cancel the offer made by the buyer.
     * - Emits a `cancelOffer` event to notify that the offer has been canceled.
*/
    function cancelOfferBuyer(address _buyer, uint256 _tokenId) public returns (bool) {
        // Check if the buyer has made any offer, and get its offer ID.
        (bool hasMade, uint256 offerId) = checkIfOfferMade(_buyer, _tokenId);
        require(hasMade, "No offer has been made by this buyer");

        // Call the internal function `doMiniCancel` to cancel the offer.
        doMiniCancel(_tokenId, offerId, _buyer, true);

        // Emit a `cancelOffer` event to notify that the offer has been canceled by the buyer.
        emit cancelOffer(offerId, _buyer, "buyer");

        return true;
    }

/**
     * @dev Retrieves the total seller fee percentage for a specific NFT offer.
     * @param _tokenId The ID of the NFT token for which the offer was made.
     * @param _offerId The ID of the offer within the NFT token's offers list.
     * @return The total seller fee percentage calculated for the offer.
     *
     * This function calculates the total seller fee percentage for a given NFT offer,
     * including both the standard seller fee and any additional royalty fee set by the collection.
     * It fetches the offer price and the collection ID, then queries the royalty contract to get
     * the selling royalty fee percentage associated with the collection.
     * Finally, it calculates the total seller fee by summing the standard seller fee and the royalty fee.
 */
    function getSellerfeePercentage(uint256 _tokenId, uint256 _offerId) public view returns (uint256) {
        // Get the offer price for the given NFT token and offer ID.
        uint256 price = NFT_OFFERS[_tokenId][_offerId]._price;

        // Get the collection ID associated with the NFT offer.
        uint256 collectionId = NFT_OFFERS[_tokenId][_offerId]._collectionID;

        // Get the selling royalty fee percentage and the standard seller fee percentage associated with the collection.
        (, , , 
         uint256 sellingRoyaltyFeePercentage) = getFarmCollectionDetails(collectionId);

        // Calculate the seller royalty fee based on the offer price and the selling royalty fee percentage.
        uint256 sellerRoyaltyFee = (price * sellingRoyaltyFeePercentage) / 10000;

        // Calculate the standard seller fee based on the offer price and the contract's standard seller fee percentage.
        uint256 sellerFee = (price * sellerFeePercent) / 10000;

        // Calculate the total seller fee by summing the seller royalty fee and the standard seller fee.
        uint256 totalSellerFee = sellerRoyaltyFee + sellerFee;

        // Return the total seller fee for the offer.
        return totalSellerFee;
    }   

/**
     * @dev Retrieves the fee percentages applicable for making offers on NFTs within a specific collection.
     * @param _collectionID The ID of the collection for which the fee percentages are queried.
     * @return The seller fee percentage, buyer fee percentage, buying royalty fee percentage, and selling royalty fee percentage.
     *
     * This function fetches the fee percentages associated with a specific collection of NFTs.
     * It calls the `getFarmCollectionDetails` function to retrieve the buying and selling royalty fee percentages.
     * The contract's own `sellerFeePercent` and `buyerFeePercent` are also returned.
     * These percentages determine the fees that sellers and buyers will be charged when making offers on NFTs.
 */
    function getOfferFeepercentage(uint256 _collectionID) public view returns (uint256, uint256, uint256, uint256) {
        // Get the buying and selling royalty fee percentages associated with the given collection.
        (, , 
         uint256 buyingRoyaltyFeePercentage, 
         uint256 sellingRoyaltyFeePercentage) = getFarmCollectionDetails(_collectionID);

        // Return the seller fee percentage, buyer fee percentage, buying royalty fee percentage, and selling royalty fee percentage.
        return (sellerFeePercent, buyerFeePercent, buyingRoyaltyFeePercentage, sellingRoyaltyFeePercentage);
    }

/**
     * @dev Allows the seller to cancel their own offer on a specific NFT.
     * @param _tokenId The ID of the NFT for which the offer is being canceled.
     * @param _offerId The ID of the offer to be canceled.
     * @param _seller The address of the seller canceling the offer.
     * @return A boolean indicating whether the offer cancellation was successful.
     *
     * This function is used by the seller to cancel their own offer on a specific NFT.
     * It verifies that the offer exists and that the caller is the rightful seller of the NFT.
     * If the checks pass, the function calls `doMiniCancel` to perform the actual cancellation.
     * After canceling the offer, the function emits a `cancelOffer` event with the relevant details.
     * The return value indicates whether the offer cancellation was successful.
 */
    function cancelOfferSeller(uint256 _tokenId, uint256 _offerId, address _seller) public returns (bool) {
        // Check if the offer exists (buyer address is not zero).
        require(NFT_OFFERS[_tokenId][_offerId]._buyer != address(0), "This offer does not exist");

        // Check if the caller is the rightful seller of the NFT.
        require(NFT_OFFERS[_tokenId][_offerId]._seller == _seller, "This address is not the seller of this NFT");

        // Get the buyer's address from the offer.
        address buyer = NFT_OFFERS[_tokenId][_offerId]._buyer;

        // Perform the offer cancellation.
        doMiniCancel(_tokenId, _offerId, buyer, true);

        // Emit a `cancelOffer` event to signal the offer cancellation by the seller.
        emit cancelOffer(_offerId, buyer, "seller");

        // Return true to indicate that the offer cancellation was successful.
        return true;
    }

/**
     * @dev Allows the seller to cancel all offers made on a specific NFT.
     * @param _tokenId The ID of the NFT for which all offers are being canceled.
     * @return A boolean indicating whether the cancellation of all offers was successful.
     *
     * This function is used by the seller to cancel all offers made on a specific NFT.
     * It first checks if there are any existing offers for the given NFT.
     * If offers are found, the function verifies that the caller is the rightful seller of the NFT.
     * Then, it iterates through all offers, and for each valid offer, it calls `doMiniCancel` to perform the cancellation.
     * After canceling all offers, the function emits a `cancelAllOffer` event with the relevant details.
     * The return value indicates whether the cancellation of all offers was successful.
 */
    function cancelAll(uint256 _tokenId) public returns (bool) {
        // Check if there are any existing offers for the given NFT.
        if (NFT_OFFERS[_tokenId].length > 0) {
            // Verify that the caller is the rightful seller of the NFT.
            require(msg.sender == NFT_OFFERS[_tokenId][0]._seller, "Not the seller of this NFT");

            address _buyerAddress = address(0);

            uint numberOfOffers = NFT_OFFERS[_tokenId].length;

            // Iterate through all offers for the given NFT.
            for (uint i = 0; i < numberOfOffers; i++) {
                // Check if the offer is valid (buyer address is not zero).
                if (NFT_OFFERS[_tokenId][0]._buyer != address(0)) {
                    // Get the buyer's address from the offer.
                    _buyerAddress = NFT_OFFERS[_tokenId][0]._buyer;

                    // Perform the offer cancellation.
                    doMiniCancel(_tokenId, 0, _buyerAddress, true);
                }
            }

            // Emit a `cancelAllOffer` event to signal the cancellation of all offers by the seller.
            emit cancelAllOffer(_tokenId, msg.sender);
        }

        // Return true to indicate that the cancellation of all offers was successful.
        return true;
    }

/**
     * @dev Monitors the duration of a specific offer on an NFT and cancels it if it has expired.
     * @param _tokenId The ID of the NFT for which the offer is being monitored.
     * @param _offerId The ID of the offer to be monitored for expiration.
     * @return A boolean indicating whether the monitoring process was successful.
     *
     * This function is used to monitor the duration of a specific offer made on an NFT.
     * It takes the `_tokenId` and `_offerId` as parameters and checks if the offer's duration
     * has already passed the current timestamp (block.timestamp).
     * If the offer has expired, the function cancels the offer by calling `doMiniCancel`.
     * After canceling the expired offer, the function emits an `expiredOffer` event with the relevant details,
     * including the buyer's address and the original duration of the offer.
     * The return value indicates whether the monitoring process was successful.
 */
    function monitorNFTOffer(uint256 _tokenId, uint256 _offerId) external returns (bool) {
        // Check if the offer has expired (current timestamp > offer's duration).
        if (NFT_OFFERS[_tokenId][_offerId]._duration < block.timestamp) {
            // The offer has expired, cancel it.

            // Get the buyer's address and original duration from the offer.
            address buyer = NFT_OFFERS[_tokenId][_offerId]._buyer;
            uint256 duration = NFT_OFFERS[_tokenId][_offerId]._duration;

            // Perform the offer cancellation.
            doMiniCancel(_tokenId, _offerId, buyer, true);

            // Emit an `expiredOffer` event to notify relevant parties about the expiration of the offer.
            emit expiredOffer(_tokenId, _offerId, buyer, duration);
        }

        // Return true to indicate that the monitoring process was successful.
        return true;
    }
 

/**
     * @dev Sets the seller fee percentage for offers on NFTs.
     * @param _feePercent The new percentage value of the seller fee.
     * @return A boolean indicating whether the seller fee was successfully updated.
     *
     * This function allows the contract owner to update the seller fee percentage for offers made on NFTs.
     * The `feePercent` parameter represents the new seller fee percentage to be set.
     * Only the contract owner can call this function (`onlyOwner` modifier).
     * The function sets the `SELLER_FEE_PERCENT` variable to the new value and emits a `changeFee` event
     * to notify observers about the change in seller fee.
     * The return value indicates whether the seller fee was successfully updated.
 */
    function setSellerFee(uint _feePercent) external onlyOwner returns (bool) {
        // Update the seller fee percentage with the new value.
        sellerFeePercent = _feePercent;

        // Emit a `changeFee` event to notify observers about the change in seller fee.
        emit changeFeePercentageValue(_feePercent, "sellerFeePercent");

        // Return true to indicate that the seller fee was successfully updated.
        return true;
    }


/**
     * @dev Sets the buyer fee percentage for offers on NFTs.
     * @param _feePercent The new percentage value of the buyer fee.
     * @return A boolean indicating whether the buyer fee was successfully updated.
     *
     * This function allows the contract owner to update the buyer fee percentage for offers made on NFTs.
     * The `_feePercent` parameter represents the new buyer fee percentage to be set.
     * Only the contract owner can call this function (`onlyOwner` modifier).
     * The function sets the `buyerFeePercent` variable to the new value and emits a `changeFeePercentageValue`
     * event to notify observers about the change in buyer fee.
     * The return value indicates whether the buyer fee was successfully updated.
 */
    function setBuyerFee(uint _feePercent) external onlyOwner returns (bool) {
        // Update the buyer fee percentage with the new value.
        buyerFeePercent = _feePercent;

        // Emit a `changeFeePercentageValue` event to notify observers about the change in buyer fee.
        emit changeFeePercentageValue(_feePercent, "buyerFeePercent");

        // Return true to indicate that the buyer fee was successfully updated.
        return true;
    }

/**
     * @dev View function to retrieve all the offers for a specific NFT token.
     * @param _tokenId The ID of the NFT token for which to retrieve the offers.
     * @return An array of 'offer' structs representing all the offers made on the specified NFT token.
     *
     * This function allows external callers to view all the offers made on a specific NFT token.
     * The function takes `_tokenId` as a parameter, which represents the ID of the NFT token for which to retrieve the offers.
     * The function returns an array of 'offer' structs, which contains information about each offer made on the specified NFT token.
     * The 'offer' struct has the following fields:
     *   - _offerID: The unique identifier of the offer.
     *   - _price: The price offered by the buyer for the NFT.
     *   - _tokenID: The ID of the NFT token to which the offer is made.
     *   - _duration: The duration (timestamp) until which the offer is valid.
     *   - _buyer: The address of the buyer who made the offer.
     *   - _seller: The address of the seller who owns the NFT.
     *   - _escrow: The address of the escrow contract associated with the offer.
     *   - _collectionID: The ID of the collection associated with the NFT token.
     *
     * The function is an external view function, meaning it does not modify the contract state and can be called without
     * incurring any gas costs. It provides a way for external parties to get a complete list of all the offers made on a
     * specific NFT token, which can be used for various purposes, such as displaying the offers on a user interface.
 */
    function viewAllOffer(uint _tokenId) external view returns (offer[] memory) {
        // Return the array of 'offer' structs representing all the offers made on the specified NFT token.
        return NFT_OFFERS[_tokenId];
    }
 

/**
     * @dev Private view function to check if a specific _buyer has made an offer on a given NFT token.
     * @param _buyer The address of the _buyer to check for an offer.
     * @param _tokenId The ID of the NFT token to check for the buyer's offer.
     * @return A boolean value indicating whether the _buyer has made an offer on the specified NFT token.
     * @return If the _buyer has made an offer, the function returns the index (offer ID) of the _buyer's offer in the NFT_OFFERS array.
     *         If the _buyer has not made any offer, the function returns (false, 0).
     *
     * This private view function is used internally to check if a specific buyer has made an offer on a given NFT token.
     * The function takes the `_buyer` address and `tokenId` as parameters.
     * It iterates through the 'offer' structs stored in the NFT_OFFERS mapping for the given `tokenId` and checks if any offer was made by the `buyer`.
     * If an offer is found, the function returns `true` and the index (offer ID) of the _buyer's offer in the NFT_OFFERS array.
     * If no offer is found for the _buyer, the function returns `false` and 0 as the index.
     *
     * Since this function is private and marked as view, it does not modify the contract state and can be called without
     * incurring any gas costs. It is used to determine whether a specific buyer has already made an offer on a given NFT token,
     * which is essential for preventing duplicate offers and ensuring that each buyer can only have one active offer on an NFT token.
 */
function checkIfOfferMade(address _buyer, uint256 _tokenId) private view returns (bool, uint) {
    // Iterate through the 'offer' structs stored in the NFT_OFFERS mapping for the given `tokenId`.
    for (uint i = 0; i < NFT_OFFERS[_tokenId].length; i++) {
        // If an offer is found with the same `buyer` address, return (true, i) indicating that the buyer has made an offer.
        if (NFT_OFFERS[_tokenId][i]._buyer == _buyer) {
            // Buyer has made an offer.
            return (true, i);
        }
    }
    // If no offer is found for the `_buyer`, return (false, 0).
    return (false, 0);
}


/**
     * @dev Private function to perform a mini cancellation of an offer made by a specific buyer on a given NFT token.
     * @param _tokenId The ID of the NFT token for which the offer is canceled.
     * @param _offerId The ID of the offer to be canceled.
     * @param _buyer The address of the buyer who made the offer.
     * @param _doRevert A boolean flag indicating whether to revert the SNC tokens to the buyer.
     * @return A boolean value indicating the success of the mini cancellation.
     *
     * This private function is used internally to perform a mini cancellation of an offer made by a specific buyer on a given NFT token.
     * The function uses the check-effects-interaction pattern to prevent reentrancy attacks.
     *
     * The function first performs checks to ensure that the specified `_offerId` corresponds to an offer made by the specified `_buyer`.
     * Then, it retrieves the Escrow contract associated with the offer and calculates the buyer's fee.
     * The offer is reset by overwriting its details with a blank offer struct, and the offer entry is deleted from the NFT_OFFERS mapping.
     *
     * If `_doRevert` is true, the function reverts the SNC tokens held in the Escrow contract back to the buyer.
     * First, it transfers the buyer's fee, followed by the remaining SNC tokens (if any) used to pay for the NFT price.
     *
     * After canceling the offer, the function checks if there are no more offers left for the NFT token.
     * If there are no more offers, it resets the NFT_OFFER_COMPLETED flag to false to indicate that the NFT has not been sold.
     *
     * Since this function is private, it can only be called internally and is not accessible outside the contract.
 */
function doMiniCancel(uint _tokenId, uint _offerId, address _buyer, bool _doRevert) private returns (bool) {
    /* checks */
    require(NFT_OFFERS[_tokenId][_offerId]._buyer == _buyer, "This offer was not made by this buyer");

    /* Effects */
    Escrow escrow = Escrow(NFT_OFFERS[_tokenId][_offerId]._escrow);
    // uint256 buyerFee = snc.balanceOf(address(escrow)) - NFT_OFFERS[_tokenId][_offerId]._price;

    // Reset the offer by overwriting its details with a blank offer struct.
    NFT_OFFERS[_tokenId][_offerId] = offer(
        _offerId,
        0,
        0,
        0,
        address(0),
        address(0),
        address(0),
        0
    );

    // Delete this entry and reset the offer ID to the current index.
    NFT_OFFERS[_tokenId][_offerId] = NFT_OFFERS[_tokenId][NFT_OFFERS[_tokenId].length - 1];
    NFT_OFFERS[_tokenId][_offerId]._offerID = _offerId;
    NFT_OFFERS[_tokenId].pop();

    // Check if there are no more offers left for this NFT token.
    if (NFT_OFFERS[_tokenId].length == 0) {
        // All buyers have removed their offers. Reset the has-accepted-offer flag.
        NFT_OFFER_COMPLETED[_tokenId] = false;
    }

    /* Interactions */
    if (_doRevert) {
        // Move SNC from escrow to the buyer. First, transfer the buyer's fee.
        escrow.transferFromEscrowtoUser(_buyer,(snc.balanceOf(address(escrow))));
        // Then, transfer any remaining SNC tokens used to pay for the NFT price.
        // escrow.transferFromEscrowtoUser(_buyer, buyerFee);
    }

    return true;
}

/**
     * @dev External function to change the address of the Royalty contract.
     * @param _newRoyaltyContract The new address of the Royalty contract to be set.
     * @return A boolean value indicating the success of changing the Royalty contract address.
     *
     * Only the contract owner can call this function to update the address of the Royalty contract.
     * The function requires that the new Royalty contract address is not the zero address (0x0).
     *
     * When the function is called, it sets the `royaltyContractAddress` to the `_newRoyaltyContract`.
     * It also updates the `royalty` variable to point to the new Royalty contract instance using the `_newRoyaltyContract` address.
     *
     * After updating the contract address, the function emits a `changeRoyaltyContract` event to notify listeners about the change.
     *
     * Note: It is important to verify that the new Royalty contract is correctly deployed and conforms to the expected interface
     *       before calling this function to ensure the proper functioning of the contract.
 */
    function changeRoyaltyContractAddress(address _newRoyaltyContract) external onlyOwner returns (bool) {
        require(_newRoyaltyContract != address(0), "Cannot set zero address");
        
        // Update the address of the Royalty contract
        royaltyContractAddress = _newRoyaltyContract;
        
        // Set the `royalty` variable to point to the new Royalty contract instance
        royalty = Royalty(_newRoyaltyContract);
        
        // Emit the event to notify listeners about the change
        emit changeRoyaltyAddress(_newRoyaltyContract);
        
        return true;
    }
   
/**
     * @dev Public view function to retrieve the address of the Royalty smart contract.
     * @return The address of the currently set Royalty smart contract.
     *
     * This function is a read-only function and can be called by anyone.
     * It simply returns the `royaltyContractAddress`, which holds the address of the Royalty smart contract
     * that is currently set by the contract owner using the `changeRoyaltyContractAddress` function.
     *
     * Callers can use this function to obtain the address of the Royalty contract and interact with it.
 */
    function getRoyaltySmartContractAddress() public view returns (address) {
        return royaltyContractAddress;
    }   

/**
     * @dev External function for the contract owner to change the address of the NFT (ERC-1155) contract.
     * @param _newNFTAddress The new address of the NFT (ERC-1155) contract to be set.
     * @return A boolean value indicating the success of the operation.
     *
     * This function is restricted to the contract owner only, as specified by the `onlyOwner` modifier.
     * The contract owner can call this function to change the address of the NFT (ERC-1155) contract to a new one.
     *
     * The function sets the `nft` variable to an instance of the ERC-1155 contract at the `_newNFTAddress`.
     * It also updates the `nftAddress` variable to the `_newNFTAddress`.
     * Before updating, the function checks if the NFT contract has a balance of 0 for token ID 0, which is used
     * as a validation to ensure that the provided contract is indeed an ERC-1155 contract.
     *
     * After successfully changing the NFT contract address, the function emits the `changeNFTAddress` event
     * to signal the update to external parties.
     *
     * Note: It is crucial to ensure that the new NFT contract being set follows the ERC-1155 standard,
     * otherwise the contract might not function correctly.
 */
    function changeNFTContractAddress(address _newNFTAddress) external onlyOwner returns (bool) {
        nft = IERC1155(_newNFTAddress);
        nftAddress = _newNFTAddress;
        require(nft.balanceOf(address(this), 0) == 0, "Invalid NFT Contract");
        emit changeNFTAddress(_newNFTAddress);
        return true;
    } 

/**
     * @dev External function for the contract owner to change the address of the SNC (ERC-20) contract.
     * @param _newSNCAddress The new address of the SNC (ERC-20) contract to be set.
     * @return A boolean value indicating the success of the operation.
     *
     * This function is restricted to the contract owner only, as specified by the `onlyOwner` modifier.
     * The contract owner can call this function to change the address of the SNC (ERC-20) contract to a new one.
     *
     * The function sets the `snc` variable to an instance of the ERC-20 contract at the `_newSNCAddress`.
     * It also updates the `sncAddress` variable to the `_newSNCAddress`.
     * Before updating, the function checks if the SNC contract has a balance of 0 for the contract itself.
     * This check serves as a validation to ensure that the provided contract is indeed an ERC-20 contract.
     *
     * After successfully changing the SNC contract address, the function emits the `changeSNCAddress` event
     * to signal the update to external parties.
     *
     * Note: It is important to ensure that the new SNC contract being set follows the ERC-20 standard,
     * otherwise the contract might not function correctly.
 */
    function changeSNCContractAddress(address _newSNCAddress) external onlyOwner returns (bool) {
        snc = IERC20(_newSNCAddress);
        sncAddress = _newSNCAddress;
        require(snc.balanceOf(address(this)) <= 0, "Invalid ERC20 SNC Contract address");
        emit changeSNCAddress(_newSNCAddress);
        return true;
    }
  
/**
     * @dev Public function to retrieve the addresses of the SNC (ERC-20) contract and the NFT contract.
     * @return A tuple containing the addresses of the SNC (ERC-20) contract and the NFT contract.
     *
     * This function allows anyone to retrieve the addresses of the SNC (ERC-20) contract and the NFT contract
     * currently being used by this contract. The function is marked as "view," indicating that it does not modify
     * the state of the contract and only reads the values of `sncAddress` and `nftAddress`.
     *
     * The function returns a tuple containing the two addresses, providing an easy way to access both addresses
     * at once. The addresses can then be used externally for various purposes, such as verifying the contracts'
     * deployment or interacting with them outside this contract.
 */
    function getSNCAndNFTAddresses() public view returns (address, address) {
        return (sncAddress, nftAddress);
    }    

    /**
     * @dev Public function to retrieve the NFT Offers details.
     * @return A tuple containing the NFT offers
     *
     * This function allows anyone to retrieve the NFT Offers details.
     * currently being used by this contract. The function is marked as "view," indicating that it does not modify
     * the state of the contract and only reads the values of `NFT_OFFERS`
     *
 */
    function getNFTOffers(uint256 _tokenId) public view returns (offer[]) {
        return NFT_OFFERS[_tokenId];
    }       
}