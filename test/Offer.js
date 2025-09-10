const { expect } = require("chai");
const ethers = require("hardhat").ethers;
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const  Web3 = require('web3');



describe("Offer contract", function () {
  // //using hardhat fixtures
  async function deployContractFixture() {
        const [owner, userAddress, otherAddress, houseAddress, changeFee,user1Address,farmOwner] = await ethers.getSigners();
        const snc = await ethers.getContractFactory("SNC");
        const nft = await ethers.getContractFactory("NFTMinter");
        const offer = await ethers.getContractFactory("Offer");
        const royalty = await ethers.getContractFactory("Royalty");
        const sncToken = await snc.deploy(userAddress.address);
        const nftToken = await nft.deploy(owner.address,"sunContract",owner.address);
        const royaltyContract = await royalty.deploy();
        const offerToken = await offer.deploy(sncToken.address,  nftToken.address, changeFee.address, 100, 100, royaltyContract.address,userAddress.address);
        await sncToken.connect(userAddress).transfer(otherAddress.address,  Web3.utils.toWei('500', 'ether'))
        await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('9', 'ether'));
        await nftToken.mint("SunContract", (new Date(Date())).getTime(),1,"solar", "sun", "imagelink", 12345, "primary");
        await nftToken.setApprovalForAll(offerToken.address, true);
        return {sncToken, royaltyContract, nftToken, offerToken, owner, userAddress, otherAddress, houseAddress, changeFee,user1Address, farmOwner};
  }

  it("1. Verifying that Buyers can send buy request for NFTs to the seller", async function () {
     const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress, changeFee} = await loadFixture(deployContractFixture);
     const duration = (new Date(Date())).getTime() + 50000
     await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
     const raw = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
     const data = raw.data;
     const tokenId = parseInt(data.substring(394,458),16);
     expect(tokenId).to.equal(1);
  });
  
  it("2. Verifying that seller can accept the offer", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee,user1Address,farmOwner} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(userAddress).transfer(user1Address.address,Web3.utils.toWei('500', 'ether'));
    await sncToken.connect(user1Address).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,farmOwner.address,100,100 );
    const makeOffer = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('2', 'ether'), 1);
    const data = makeOffer.data;
    parseInt(data.substring(394,458),16);
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('101', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('2.02', 'ether'), 1);
    await offerToken.connect(user1Address).makeOffer(1, Web3.utils.toWei('102', 'ether'), duration, user1Address.address, owner.address,  Web3.utils.toWei('2.04', 'ether'), 1);
    await offerToken.connect(owner).acceptOffer(1,0,owner.address,true);
    await offerToken.viewAllOffer(1);
    expect(await sncToken.balanceOf(otherAddress.address)).to.equal(Web3.utils.toWei('500', 'ether'));
  });


  it("3. Verifying that seller can cancel the offer particular offer", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee,user1Address} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(userAddress).transfer(user1Address.address,Web3.utils.toWei('500', 'ether'));
    await sncToken.connect(user1Address).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,otherAddress.address,100,100 );
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('101', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('2.02', 'ether'), 1);
    const cancelOfferSeller = await offerToken.connect(owner).cancelOfferSeller(1,0,owner.address);
    expect(await sncToken.balanceOf(otherAddress.address)).to.equal(Web3.utils.toWei('500', 'ether'));
  
  });


  it("4. Verifying that seller can cancel the all offers", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee,user1Address, farmOwner} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).transfer(user1Address.address,Web3.utils.toWei('500', 'ether'));
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(user1Address).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,farmOwner.address,100,100 );
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('2', 'ether'), 1);
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('101', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('2.02', 'ether'), 1);
    await offerToken.connect(user1Address).makeOffer(1, Web3.utils.toWei('102', 'ether'), duration, user1Address.address, owner.address,  Web3.utils.toWei('2.04', 'ether'), 1);
    await offerToken.connect(owner).cancelAll(1);
    expect(await sncToken.balanceOf(otherAddress.address)).to.equal(Web3.utils.toWei('500', 'ether'));
  });

  it("5. Verifying that buyer can cancel the offers", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    const makeOffer = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data = makeOffer.data;
    const tokenId = parseInt(data.substring(394,458),16);
    const cancelOfferBuyer = await offerToken.connect(owner).cancelOfferBuyer( userAddress.address, tokenId);
    expect(cancelOfferBuyer.confirmations).to.equal(1);
  });

  it("6. Verifying the monitorNFTOffer Function is working", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    const makeOffer = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data = makeOffer.data;
    const tokenId = parseInt(data.substring(394,458),16);
    const monitorNftOffer = await offerToken.connect(owner).monitorNFTOffer(tokenId,0);
    expect(monitorNftOffer.confirmations).to.equal(1);
  });


  it("7. Verifying that owner can set the seller fee", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const setSellerFee = await offerToken.connect(userAddress).setSellerFee(150);
    expect(setSellerFee.confirmations).to.equal(1);
  });



  it("8. Verifying that owner can set the buyer fee", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const setBuyerFee = await offerToken.connect(userAddress).setBuyerFee(150);
    expect(setBuyerFee.confirmations).to.equal(1);
  });

  
  it("9. Verifying that owner can change Royalty Smart Contract address", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const ChangeSMC5address = await offerToken.connect(userAddress).changeRoyaltyContractAddress(otherAddress.address);
    expect(ChangeSMC5address.confirmations).to.equal(1);
  });

    
  it("10. Verifying that owner can change NFT Smart Contract address", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const changeNftAddress = await offerToken.connect(userAddress).changeNFTContractAddress(nftToken.address);
    expect(changeNftAddress.confirmations).to.equal(1);
  });

  it("11. Verifying that owner can change SNC Smart Contract address", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const changeSNCAddress = await offerToken.connect(userAddress).changeSNCContractAddress(sncToken.address);
    expect(changeSNCAddress.confirmations).to.equal(1);
  });


  it("12. Verifying that wrong seller cannot accept the offer", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    const makeOffer = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data = makeOffer.data;
    const tokenId = parseInt(data.substring(394,458),16);
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,otherAddress.address,100,100 );
    try {
      await offerToken.connect(userAddress).acceptOffer(tokenId,0,owner.address,true);
      // If the above line doesn't throw an error, the test should fail
      expect.fail('This function can only be called by the seller of this NFT');
    } catch (error) {
      expect(error.message).to.include('This function can only be called by the seller of this NFT');  
    }
  });


  it("13. Verifying that buyer can make an offer with token ID that does not exists", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    try {
      await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
      // If the above line doesn't throw an error, the test should fail
      expect.fail('NFT does not exist!');
    } catch (error) {
      expect(error.message).to.include('NFT does not exist!');  
    }
   
  });

  it("14. Verifying the offer contract, It should return an empty array for a token with no offers", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    const makeOffer = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data = makeOffer.data;
    const tokenId = parseInt(data.substring(394,458),16);
    const viewAllOffer = await offerToken.viewAllOffer(2);
    expect(viewAllOffer).to.be.an('array').that.is.empty;
   });


   it("15. Verify when seller accepts the offer seller's NFT will move to the escrow account.", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    const makeOffer = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data = makeOffer.data;
    const tokenId = parseInt(data.substring(394,458),16);4
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,otherAddress.address,100,100 );
    await offerToken.connect(owner).acceptOffer(tokenId,0,owner.address,true);
    expect(await nftToken.balanceOf(userAddress.address , 1)).to.equal(1);  
  });

  it("16. Verify correct transaction fees is appilied on the seller NFTs when offer is accepted by the seller.", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    const makeOffer = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data = makeOffer.data;
    const tokenId = parseInt(data.substring(394,458),16);4
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,otherAddress.address,100,100 );
    await offerToken.connect(owner).acceptOffer(tokenId,0,owner.address,true);
    expect(await sncToken.balanceOf(owner.address)).to.equal(Web3.utils.toWei('98', 'ether'));
  });

  it("17. Verify SNC and transaction fees is credited to the sellers account and fees will be credited to the house after sell is executed.", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('204', 'ether'));
    const makeOffer1 = await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data1 = makeOffer1.data;
    const tokenId_1 = parseInt(data1.substring(394,458),16);
    await nftToken.mint("Sun1", (new Date(Date())).getTime(),1,"solar", "sun", "imagelink", 12345, "primary");
    const makeOffer2 = await offerToken.connect(userAddress).makeOffer(2, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const data2 = makeOffer2.data;
    const tokenId_2 = parseInt(data2.substring(394,458),16);
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,otherAddress.address,100,100 );
    await offerToken.connect(owner).acceptOffer(tokenId_1,0,owner.address,true);
    expect(await sncToken.balanceOf(owner.address)).to.equal(Web3.utils.toWei('98', 'ether'));  
  });

  it("18. Verify after accepting one offer seller can be able to reject all the other offers. ", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,otherAddress.address,100,100 );
    await offerToken.connect(owner).acceptOffer(1,0,owner.address,true);
    await offerToken.cancelAll(1)
    const recent_offer = await offerToken.viewAllOffer(1);
    expect(await recent_offer.length).to.equal(0);
  });

  it("19. Verify after sell is successfully completed than SNC, Nft and fees will be transferred to Seller , Buyer and house respectively", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,otherAddress.address,100,100 );
    await offerToken.connect(owner).acceptOffer(1,0,owner.address,true);
    const recent_offer = await offerToken.viewAllOffer(1);
    expect(await nftToken.balanceOf(userAddress.address , 1)).to.equal(1);  
  });

  it("20. Verify due to any reason sell is cancelled than snc , nft and fees will be returned back to the buyer , seller and house respectively", async function () {
    const {sncToken, nftToken, offerToken, owner, userAddress, otherAddress, houseAddress} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await offerToken.cancelAll(1)
    expect(await nftToken.balanceOf(owner.address , 1)).to.equal(1);  
  });
  
  it("21. Verify due to any reason sell is cancelled than snc , nft and fees will be returned back to the buyer , seller and house respectively, but not in the escrow account.", async function () {
    const {sncToken, nftToken, offerToken, owner, userAddress, otherAddress, houseAddress} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    await offerToken.connect(owner).cancelOfferSeller(1,0,owner.address);
    expect(await nftToken.balanceOf(owner.address , 1)).to.equal(1);  
  });

  
  it("22. Verify After cancelling the offer, offer should not show in the activity page.", async function () {
    const {sncToken, nftToken, offerToken, owner, userAddress, otherAddress, houseAddress} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const _escrow = (await offerToken.NFT_OFFERS(1, 0)).escrow;
    await offerToken.cancelOfferSeller(1, 0, owner.address)
    const recent_offer = await offerToken.viewAllOffer(1);
    expect(recent_offer.length).to.equal(0);
  });

  it("23.verify after cancelling the offer SNC and transaction fees should return to the Buyers and house wallet respectively from escrow account.", async function () {
    const {sncToken, nftToken, offerToken, owner, userAddress, otherAddress, houseAddress} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1); 
    const _escrow = (await offerToken.NFT_OFFERS(1, 0))._escrow;
    await offerToken.cancelOfferSeller(1, 0, owner.address)
    expect(await sncToken.balanceOf(_escrow)).to.equal(0);
  });

  it("24. Verify correct Amount of SNC and fees is returend to buyers and house wallet after offer is rejected. ", async function () {
    const {sncToken, nftToken, offerToken, owner, userAddress, otherAddress, houseAddress} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('1', 'ether'), 1);
    const _escrow = (await offerToken.NFT_OFFERS(1, 0))._escrow;
    await offerToken.cancelOfferBuyer(userAddress.address, 1)
    expect(await sncToken.balanceOf(userAddress.address)).to.equal(Web3.utils.toWei('9500', 'ether'));
  });


  it("25. Verifying that all buyers who had made an offer for an NFT and once seller accept the one offer, every buyer got their amount back", async function () {
    const {sncToken, royaltyContract,  nftToken, offerToken, owner, userAddress, otherAddress, houseAddress,changeFee,user1Address,farmOwner} = await loadFixture(deployContractFixture);
    const duration = (new Date(Date())).getTime() + 50000
    await sncToken.connect(userAddress).approve(offerToken.address, Web3.utils.toWei('102', 'ether'));
    await sncToken.connect(userAddress).transfer(user1Address.address,Web3.utils.toWei('500', 'ether'));
    await sncToken.connect(user1Address).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await sncToken.connect(otherAddress).approve(offerToken.address, Web3.utils.toWei('105', 'ether'));
    await royaltyContract.connect(owner).CreateFarmCollectionData(1,farmOwner.address,100,100 );
    await offerToken.connect(userAddress).makeOffer(1, Web3.utils.toWei('100', 'ether'), duration, userAddress.address, owner.address,  Web3.utils.toWei('2', 'ether'), 1);
    await offerToken.connect(otherAddress).makeOffer(1, Web3.utils.toWei('101', 'ether'), duration, otherAddress.address, owner.address,  Web3.utils.toWei('2.02', 'ether'), 1);
    await offerToken.connect(owner).acceptOffer(1,0,owner.address,true);
    expect(await sncToken.balanceOf(user1Address.address)).to.equal(Web3.utils.toWei('500', 'ether'));
    expect(await sncToken.balanceOf(otherAddress.address)).to.equal(Web3.utils.toWei('500', 'ether'));

  });


 
  });