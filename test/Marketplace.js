const { expect } = require("chai");
const ethers = require("hardhat").ethers;
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const  Web3 = require('web3');
const config = require('../data')


describe("MarketPlace  contract", function () {
  //using hardhat fixtures
  async function deployContractFixture() {
        //Deploys contract to hardhat network
        const [owner] = await ethers.getSigners();
        /* Deploy the contracts */
        //SNC Tokens
        const snc = await ethers.getContractFactory('contracts/sncToken.sol:SNC');
        const _snc = await snc.connect(owner).deploy();
        
        //ROYALTY
        const Royalty = await ethers.getContractFactory('contracts/RoyaltyContract.sol:Royalty');
        const royalty = await Royalty.connect(owner).deploy();
        //MINTING
        const SncNft = await ethers.getContractFactory('contracts/NftMinting.sol:NFTMinter');
        const sncNft = await SncNft.connect(owner).deploy(owner.address, config.URI, owner.address);
        
        //MARKETPLACE
        const SncMarketPlace = await ethers.getContractFactory('contracts/Marketplace.sol:MarketSale');
        
        // Wait for the contract to be mined
        await royalty.deployed();
        await sncNft.deployed();
        await _snc.deployed()
        //Deploy marketplace after getting the sncNft address
        const sncMarketPlace = await SncMarketPlace.connect(owner).deploy(
          _snc.address, sncNft.address, config.CHANGE_FEE, config.BUYER_FEE, config.SELLER_FEE, royalty.address
        );
        await sncMarketPlace.deployed()
        //mint tokens first
        await sncNft.connect(owner).mint("testMetaData", (new Date()).getTime() + (86400), 1, "", "", "", 101, "active")
        //give approval for 
        await sncNft.connect(owner).setApprovalForAll(sncMarketPlace.address, true)
        // Fixtures can return anything you consider useful for your tests
        
        return {sncMarketPlace, _snc, owner, sncNft};
  }
  
  it("Verify putting up NFTs for sale", async function () {
    //importing the token via the fixtures
    const {sncMarketPlace, snc, owner, sncNft} = await loadFixture(deployContractFixture);
    //make the offer
    await sncMarketPlace.connect(owner).putForSale(
      sncMarketPlace.address,
      1,
      Web3.utils.toWei('9', 'ether'),
      (new Date()).getTime() + (86400),
      1,
      1 
    )
    expect((await sncMarketPlace.NFT_SALES(1)).tokenId).to.equal(1);
  });

  it("Verify Buyer fee is updating.", async function () {
    //importing the token via the fixtures
    const {sncMarketPlace} = await loadFixture(deployContractFixture);
    //try updating the price
    await sncMarketPlace.setBuyerFee(150)
    expect((await sncMarketPlace.BUYER_FEE_PERCENT())).to.equal(150);
  });

  it("Verify Seller fee is updating. ", async function () {
    //importing the token via the fixtures
    const {sncMarketPlace} = await loadFixture(deployContractFixture);
    //try updating the price
    await sncMarketPlace.setSellerFee(120)
    expect((await sncMarketPlace.SELLER_FEE_PERCENT())).to.equal(120);
  });

  it("Verify NFTs duration can be updated", async function () {
    //importing the token via the fixtures
    const {sncMarketPlace,snc ,owner} = await loadFixture(deployContractFixture);
    //make the offer
    await sncMarketPlace.connect(owner).putForSale(
      sncMarketPlace.address,
      1,
      Web3.utils.toWei('9', 'ether'),
      (new Date()).getTime() + (86400),
      1,
      1 
    )
    //try updating the price
    await sncMarketPlace.updateDuration(5000, 1)
    const _newDuration = (await sncMarketPlace.NFT_SALES(1)).duration
    expect(_newDuration).to.equal((_newDuration));
  });

  it("Verify NFT selling price can be updated.", async function () {
    //importing the token via the fixtures
    const {sncMarketPlace,snc ,owner} = await loadFixture(deployContractFixture);
    //make the offer
    await sncMarketPlace.connect(owner).putForSale(
      sncMarketPlace.address,
      1,
      Web3.utils.toWei('9', 'ether'),
      (new Date()).getTime() + (86400),
      1,
      1 
    )
    //try updating the price
    await sncMarketPlace.updateSalePrice(Web3.utils.toWei('70', 'ether'), 1)
    expect((await sncMarketPlace.NFT_SALES(1)).price).to.equal(Web3.utils.toWei('70', 'ether'));
  });

  it(`Verify NFT sale can be cancelled`, async function () {
    //importing the token via the fixtures
    const {sncMarketPlace, snc, owner, sncNft} = await loadFixture(deployContractFixture);
    //make the offer
    await sncMarketPlace.connect(owner).putForSale(
      sncMarketPlace.address,
      1,
      Web3.utils.toWei('9', 'ether'),
      (new Date()).getTime() + (86400),
      1,
      1 
    )
    //cancelling it
    await sncMarketPlace.cancelSale(1)
    expect((await sncNft.balanceOf(owner.address, 1))).to.equal(1);
 });

    it("Verify NFTs Fee address can be changed ", async function () {
      //importing the token via the fixtures
      const {sncMarketPlace, snc} = await loadFixture(deployContractFixture);
      //make the offer
      await sncMarketPlace.changeFeeAddress(sncMarketPlace.address)
      expect(await sncMarketPlace.CHANGE_FEE()).to.equal(sncMarketPlace.address);
  });
});