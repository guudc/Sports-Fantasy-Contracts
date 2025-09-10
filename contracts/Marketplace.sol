// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Escrow.sol";
import "./Royalty.sol";


contract MarketSale is Ownable {

    /* Variable declaration */
    address public SNC_ADDRESS;
    address public NFT_ADDRESS;
    /* COMMENT: What is this used for? */
    /* Answer: When ever we charge sellefee/buyerfee from user amount will go to this address*/
    address public CHANGE_FEE; 
    uint256 public SELLER_FEE_PERCENT;
    uint256 public BUYER_FEE_PERCENT;
    address public SMC5_Address;

    /* Smart contract variable object */
    IERC20 private snc;
    IERC1155 private nft;
    Royalty private Royalt1;

    /* Structs */
    struct sale {
        uint256 price;
        uint256 tokenId;
        uint256 duration;
        address buyer;
        address seller;
        address Escrow;
        address marketPlace;
        uint256 isPrimaryMarket;
        bool complete;
        uint256 collectionId;
    }

    /* Mappings */
    mapping(uint256 => sale) public NFT_SALES;
   
    /* Events */
    event onSale(address seller, uint price, uint duration, uint tokenId);
    event sold(address seller, address buyer, uint price, uint tokenId);
    //@cancelType: specifies if its cancelled by buyer or seller
    event expiredSale(uint tokenId, uint duration, address seller);
    event canceledSale(uint tokenId, address seller);
    //@_type: specifies what was updated
    event updatedSale(uint tokenId, address seller, string _type);
    event changeFee(uint newFee, string _type);
    event changeTreasury(address _address);
    event changeSMC5Address(address _address);

     //Onsold for royaltyfee
     event OnsoldSellerRoyaltfee(address seller, address Farmowner, uint price, uint tokenId); 

     event OnsoldBuyerRoyaltfee(address buyer, address Farmowner, uint price, uint tokenId); 

     event OnsoldBuyerfee(address seller, address buyer, uint price, uint tokenId); 

      //emit events
     event OnsoldSellerFee(address seller, address buyer, uint price, uint tokenId);

    event ChangeNftAddress(address nftAddress);
    event ChangeSNCAddress(address sncAddress);

    

    /*
        @params buyerFee and sellerFee : in percentage, uses a multiplier of 100 as the bps
        i.e 1.5% should be represented as 150 and 100% should be represented as 10000
    */
    constructor (address sncAddress, address nftAddress, address _changeFee, uint256 buyerFee, uint256 sellerFee ,address SMC5address) {
        /* COMMENT: this can be moved in first line */
         /* Answer: Yes we moved to first line */
          //verifying the contract address
       
        snc = IERC20(sncAddress);
        nft = IERC1155(nftAddress);
        //setting the address
        //require(snc.balanceOf(address(this)) == 0, "Invalid ERC20 SNC Contract address");
        //require(nft.balanceOf(address(this), 0) == 0, "Invalid NFT Contract");

        CHANGE_FEE = _changeFee;
        SNC_ADDRESS = sncAddress;
        NFT_ADDRESS = nftAddress;
        SMC5_Address =  SMC5address;
        Royalt1 = Royalty(SMC5address);
        BUYER_FEE_PERCENT = buyerFee;
        SELLER_FEE_PERCENT = sellerFee;
        //setting owner
        _transferOwnership(msg.sender);             
    }

    /*
        This function put up an NFT for sale. It must be called by
        the seller of it to work. The function assumes that the caller of
        this function is the seller.
        @params duration: in seconds
        isPrimaryMarket - Passed 1
    */
    function putForSale(
        address marketPlace,
        uint256 tokenId,
        uint256 price,
        uint256 duration,
        uint256 isPrimaryMarket,
        uint256 collectionid
    ) public returns (bool) {
        /*
            The seller must give approval for this contract to spend it NFT token
            This can only be achieved via the NFT smart contract
        */
        require(nft.balanceOf(msg.sender, tokenId) == 1,"NFT does not exist!");
        //check if this NFT has been put on sale already
        require(NFT_SALES[tokenId].seller == address(0), "This NFT is on sale already");
        //move the NFT to the _Escrow  
        Escrow _escrow = new _Escrow(NFT_ADDRESS, tokenId, SNC_ADDRESS);
        //create a sale struct
        NFT_SALES[tokenId] = sale(
            price,
            tokenId,
            duration,
            address(0),
            msg.sender,
            address(_escrow),
            marketPlace,
            isPrimaryMarket,
            false,
            collectionid
        );
        //move the NFT to the _Escrow
        nft.safeTransferFrom(msg.sender, address(_escrow),  tokenId, 1, "");
        if(duration != 0) {
            //Not using infinite wait
            duration =  duration;
        }
        
        emit onSale(msg.sender, price, duration, tokenId);
        return true;
    }

    function getTotalBuyingAmount(uint256 tokenId) public view returns (uint256){
        uint256 cId = NFT_SALES[tokenId].collectionId;
        (,,
         uint256 buyingRoyaltyFeePercentage,
        ) =  Royalt1.getFarmOwnerdetails(cId);
        uint256 priceOfNFT = NFT_SALES[tokenId].price;

        uint256 _royaltyFee = (priceOfNFT * buyingRoyaltyFeePercentage) / 10000;
        uint256 _buyerFee = (priceOfNFT * BUYER_FEE_PERCENT) / 10000;

        uint256 _totalBuyingFee = priceOfNFT + _royaltyFee + _buyerFee;

        return _totalBuyingFee;


    }

     function calculateTotalBuyerFee(uint256 tokenId) public view returns (uint256){
        uint256 cId = NFT_SALES[tokenId].collectionId;
        (, ,
         uint256 buyingRoyaltyFeePercentage,
         ) =  Royalt1.getFarmOwnerdetails(cId);
        uint256 priceOfNFT = NFT_SALES[tokenId].price;

        uint256 _royaltyFee = (priceOfNFT * buyingRoyaltyFeePercentage) / 10000;
        uint256 _buyerFee = (priceOfNFT * BUYER_FEE_PERCENT) / 10000;

        uint256 _totalBuyerFee = _royaltyFee + _buyerFee;

        return _totalBuyerFee;


    }

    function getBuyerFee(uint256 tokenId) public view returns (uint256){
        require(NFT_SALES[tokenId].seller != address(0), "This NFT is not on sale");
        uint256 priceOfNFT = NFT_SALES[tokenId].price;
        uint256 _buyerFee = (priceOfNFT * BUYER_FEE_PERCENT) / 10000;

        return _buyerFee;

    }
     function getSellerFee(uint256 tokenId) public view returns (uint256){
        require(NFT_SALES[tokenId].seller != address(0), "This NFT is not on sale");
        uint256 priceOfNFT = NFT_SALES[tokenId].price;
        uint256 _sellerFee = (priceOfNFT * SELLER_FEE_PERCENT) / 10000;

        return _sellerFee;

    }

    function getRoyaltyBuyerFee(uint256 tokenId) public view returns (uint256){
        require(NFT_SALES[tokenId].seller != address(0), "This NFT is not on sale");
        uint256 cId = NFT_SALES[tokenId].collectionId;
        (,,
         uint256 buyingRoyaltyFeePercentage,
         ) =  Royalt1.getFarmOwnerdetails(cId);
         uint256 priceOfNFT = NFT_SALES[tokenId].price;

        uint256 _royaltyFee = (priceOfNFT * buyingRoyaltyFeePercentage) / 10000;

        return _royaltyFee;

    }

    function getRoyaltySellerFee(uint256 tokenId) public view returns (uint256){
        require(NFT_SALES[tokenId].seller != address(0), "This NFT is not on sale");
        uint256 cId = NFT_SALES[tokenId].collectionId;
        (,,
         ,
         uint256 sellingRoyaltyFeePercentage) =  Royalt1.getFarmOwnerdetails(cId);
         uint256 priceOfNFT = NFT_SALES[tokenId].price;

        uint256 _royaltyFee = (priceOfNFT * sellingRoyaltyFeePercentage) / 10000;

        return _royaltyFee;

    }


    /*
        This function helps buy NFT.  
        The function assumes that the caller of this function is the buyer.
    */
     function monitorNftSale(uint256 tokenId) public returns (bool) {
        //only work if not using infinite duration
        bool flag = false;
        if(NFT_SALES[tokenId].duration != 0){
            if(NFT_SALES[tokenId].duration >= block.timestamp){
                return false;
            }
            //has expired, revert back to seller
            uint256 duration = NFT_SALES[tokenId].duration;
            address seller = NFT_SALES[tokenId].seller;
            Escrow _escrow = _Escrow(NFT_SALES[tokenId].Escrow);
            NFT_SALES[tokenId] = sale(
            0,
                0,
                0,
                address(0),
                address(0),
                address(0),
                address(0),
                0,
                false,
                0
            );
            escrow.transferNftFromEscrowtoUser(seller);
            //delete the NFT SALE DATA
            flag = true;
            emit expiredSale(tokenId, duration, seller);
        }
        return flag;
    }
    //this function must be called from the buyer
    function buyNft(
        address buyerAddress,
        uint256 tokenId,
        uint256 sncAmount,
        uint256 buyerFee
       
     
    ) external returns(bool) {
        //check if the seller has put this NFT on sale
        require(NFT_SALES[tokenId].seller != address(0), "This NFT is not on sale");
        //check if the NFT is still on sale based on duration, only if it does not uses infinite duration
        require(buyerAddress == msg.sender, "The caller of this function is not the same as the buyer address");
        if(monitorNftSale(tokenId)){
            return false;
        }
        uint256 cId = NFT_SALES[tokenId].collectionId;
        ( ,address farmOwner,
          ,) =  Royalt1.getFarmOwnerdetails(cId);

        uint256 _totalBuyingAmount = sncAmount + buyerFee;

        uint256 _checkTotalBuyingAmount = getTotalBuyingAmount(tokenId);

        require(_totalBuyingAmount == _checkTotalBuyingAmount , "Total buying amount is not correct!");
        Escrow _escrow = _Escrow(NFT_SALES[tokenId].Escrow);
        require(snc.transferFrom(msg.sender, address(_escrow) , _totalBuyingAmount), "Unable to transfer SNC tokens to escrow");
        require(_escrow.transferNftFromEscrowtoUser(buyerAddress), "Unable to transfer NFT from escrow to user");
        uint256 isNFTINPrimaryMarket = NFT_SALES[tokenId].isPrimaryMarket;
        uint256 _sellingAmount = NFT_SALES[tokenId].price;
        address _seller = NFT_SALES[tokenId].seller;

        //using the checks-effects-interactions
        NFT_SALES[tokenId] = sale(
                0,
                0,
                0,
                address(0),
                address(0),
                address(0),
                address(0),
                0,
                false,
                0
        );

        if(isNFTINPrimaryMarket==0){

            uint256 _sellerFee = getSellerFee(tokenId);
            uint256 _royaltySellerFee = getRoyaltySellerFee(tokenId);
            
            _sellingAmount = _sellingAmount - _sellerFee - _royaltySellerFee;

            require(_escrow.transferFromEscrowtoUser(_seller, _sellingAmount), "Unable to transfer from Escrow to user");
            emit sold(_seller, buyerAddress, _sellingAmount, tokenId);
            require(_escrow.transferFromEscrowtoUser(CHANGE_FEE, _sellerFee),"Unable to transfer from Escrow to user") ;
            emit OnsoldSellerFee(_seller, farmOwner, _sellerFee, tokenId);
            require(_escrow.transferFromEscrowtoUser(farmOwner, _royaltySellerFee), "Unable to transfer from Escrow to user");
            emit OnsoldSellerRoyaltfee(_seller, farmOwner, _royaltySellerFee, tokenId);
            require(_escrow.transferFromEscrowtoUser(CHANGE_FEE, getBuyerFee(tokenId)), "Unable to transfer from Escrow to user");
            emit OnsoldBuyerfee(_seller, buyerAddress, getBuyerFee(tokenId), tokenId);
            require(_escrow.transferFromEscrowtoUser(farmOwner, getRoyaltyBuyerFee(tokenId)), "Unable to transfer from Escrow to user");
            emit OnsoldBuyerRoyaltfee(buyerAddress, farmOwner, getRoyaltyBuyerFee(tokenId), tokenId);

        }
        else{


            require(_escrow.transferFromEscrowtoUser(_seller, _sellingAmount), "Unable to transfer from Escrow to user");
            emit sold(_seller, buyerAddress, _sellingAmount, tokenId);
            require(_escrow.transferFromEscrowtoUser(CHANGE_FEE, getBuyerFee(tokenId)), "Unable to transfer from Escrow to user");
            emit OnsoldBuyerfee(_seller, buyerAddress, getBuyerFee(tokenId), tokenId);
            require(_escrow.transferFromEscrowtoUser(farmOwner, getRoyaltyBuyerFee(tokenId)), "Unable to transfer from Escrow to user");
            emit OnsoldBuyerRoyaltfee(buyerAddress, farmOwner, getRoyaltyBuyerFee(tokenId), tokenId);
        }


        
     
        
        return true;
    }   
    /* Utilities functions */

    /*
        This function monitors NFT sale. 
        Revert sale if duration is expended.
    */
   
    /*
        This function sets the buyer fee
        can only be called by the owner of the smart contract
        @params feePercent: the buyer fee in terms of percent(0-100)
    */
     /* COMMENT: I think that we should allow zero? @Matic */
     /* Answer: Yes we are now allowing it to zero */
    function setBuyerFee(uint feePercent) external onlyOwner returns(bool) {
        BUYER_FEE_PERCENT = feePercent;
        emit changeFee(feePercent, "BUYER FEE PERCENT");
        return true;
    }
    /*
        This function update the duration of sale
        can only be called by the seller of the NFT.
        It adds this new duration to the previous duration, it assumes
        that this function is called by the seller
        @params duration: in seconds
        returns new duration
    */

     /* COMMENT: duration why to we have timestamp + duration not only end of sale timestamp @Matic */
     /* Answer:  Previously it was not updated code now we are passing duration perfectly*/
    function updateDuration(uint duration, uint256 tokenId) external returns(uint) {
        require(NFT_SALES[tokenId].seller == msg.sender, "Not the seller of this NFT");
        if(NFT_SALES[tokenId].duration != 0){
            require(NFT_SALES[tokenId].duration >= block.timestamp, "NFT Sale has expired");
        }  
        //update the duration
        if(NFT_SALES[tokenId].duration != 0){
             if(duration != 0) {
                 NFT_SALES[tokenId].duration = duration;
             }
             else {
                 //using zero duration
                 NFT_SALES[tokenId].duration = 0;
             }
        }
        else {
            //was using zero duration earlier
            if(duration != 0) {
                 NFT_SALES[tokenId].duration = duration;
             }
             else {
                 //using zero duration
                 NFT_SALES[tokenId].duration = 0;
             }
        }   
        emit updatedSale(tokenId, NFT_SALES[tokenId].seller, "UPDATE DURATION"); 
        return  NFT_SALES[tokenId].duration;
    }
    /*
        This function update the price  of the NFT
        can only be called by the seller of the NFT.
    */
     /* COMMENT: Price must be grater than 0 */
     /* Answer: Yes we are checking price must me greater then 0 */
    function updateSalePrice(uint price, uint256 tokenId) external returns(bool) {
        require(price > 0, "Cannot set price to zero");
        require(NFT_SALES[tokenId].seller == msg.sender, "Not the seller of this NFT");
        if(NFT_SALES[tokenId].duration != 0){
            require(NFT_SALES[tokenId].duration >= block.timestamp, "NFT Sale has expired");
        }  
        //update the duration
        NFT_SALES[tokenId].price = price;
        emit updatedSale(tokenId, NFT_SALES[tokenId].seller, "UPDATE PRICE");
        return true;
    }
    /*
        This function sets the seller fee
        can only be called by the owner of the smart contract
        @params feePercent: the seller fee in terms of percent(0-100)
    */
     /* COMMENT: I think that we should allow zero? @Matic */
     /* Answer: Yes we are Allowing it to zero*/
    function setSellerFee(uint feePercent) external onlyOwner returns(bool) {
       SELLER_FEE_PERCENT = feePercent;
        emit changeFee(feePercent, "SELLER FEE PERCENT");
        return true;
    }
    /*
        This function cancels a sale
        can only be called by the owner of the smart contract
    */
    function cancelSale(uint tokenId) external returns(bool) {
        require(NFT_SALES[tokenId].seller == msg.sender, "Not the seller of this NFT");
        Escrow _escrow = Escrow(NFT_SALES[tokenId].Escrow);
        NFT_SALES[tokenId] = sale(
            0,
                0,
                0,
                address(0),
                address(0),
                address(0),
                address(0),
                0,
                false,
                0
        );
        _escrow.transferNftFromEscrowtoUser(msg.sender);
        emit canceledSale(tokenId, msg.sender);
        return true;
    }
    /*
        This function sets the change_fee address
        can only be called by the owner of the smart contract
    */
    function changeFeeAddress(address _changeFee) external onlyOwner returns(bool) {
        require(_changeFee != address(0), "Cannot set zero address");
        CHANGE_FEE = _changeFee;
        emit changeTreasury(_changeFee);
        return true;
    }
    /*
        Returns buyer fee 
    */
     /* COMMENT: why do we have only getBuyer fee not also seller? */
     /* Answer : Buyer fee is added in the code*/
    function getBuyerFee() public view returns(uint256) {
        return BUYER_FEE_PERCENT;
    }

    function getSellerFee() public view returns(uint256) {
        return SELLER_FEE_PERCENT;
    }


   
    
    // Change SMC5 address
    function ChangeSMC5address(address _Smc5address)external onlyOwner returns(bool){
        require(_Smc5address != address(0), "Cannot set zero address");
        SMC5_Address = _Smc5address;
        emit changeSMC5Address(SMC5_Address);
        return true; 
    }

    // Get SMC5 address
    function getSMC5address() public view returns(address){
         return SMC5_Address;

    }

    // Change NFT Contract address
    function changeNftAddress(address nftAddress) external  onlyOwner returns(bool){
        nft = IERC1155(nftAddress);
        NFT_ADDRESS = nftAddress;
        require(nft.balanceOf(address(this), 0) <= 0, "Invalid NFT Contract");
        emit ChangeNftAddress(nftAddress);
        return true;
    }
    // Change SNC contract Address
    function changeSNCAddress(address sncAddress) external onlyOwner returns( bool ){
        snc = IERC20(sncAddress);
        SNC_ADDRESS = sncAddress;
        require(snc.balanceOf(address(this)) <= 0, "Invalid ERC20 SNC Contract address");
        emit ChangeSNCAddress(sncAddress);
        return true;
    }


    function getSNCAndNftAddresses() public view returns (address, address) {
        return (SNC_ADDRESS,  NFT_ADDRESS);
    }

}