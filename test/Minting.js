// NFTMinter.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContract, loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("NFTMinter", function () {
  // Load the fixture that deploys the contract and sets up the initial state
  async function nftdeploy() {
    const [admin, user1, user2] = await ethers.getSigners();
    const  uri = "https://example";
    const NFTMinter = await ethers.getContractFactory("NFTMinter");
    const nftMinter = await NFTMinter.deploy(user1.address,uri,admin.address);
   // await nftMinter.deployed();
    return { admin, user1, user2, nftMinter };
  }

describe("Deployment", function () {
      
    it("Should set the right owner", async function () {
      const {admin, user1, user2, nftMinter  } = await loadFixture(nftdeploy);
//console.log("nftMinter.address",nftMinter);
      expect(await nftMinter.owner()).to.equal(admin.address);
    });

    it("should mint a new NFT and retrieve its metadata", async function () {
        const {admin, user1, user2, nftMinter  } = await loadFixture(nftdeploy);
      //  console.log("nftMinter.address",nftMinter);


        // Mint a new NFT
        await nftMinter.mint(
          "NFT Metadata",
          1722080911,
          1,
          "Module Type",
          "Module Manufacturer",
          "Image Link",
          12345,
          "NFT Status"
        );
     // Wait for the transaction to be mined
 
       const token = 1;
 
        // Get NFT metadata using the tokenId
        const metadata = await nftMinter.getMetaData(token);
    
        // Verify metadata matches the one provided during minting
        expect(metadata).to.equal("NFT Metadata");
      });
      it("should update NFT status", async function () {
        const { user1, nftMinter } = await loadFixture(nftdeploy);
    
        // Mint a new NFT
        await nftMinter.mint(
            "NFT Metadata",
            1722080911,
            1,
            "Module Type",
            "Module Manufacturer",
            "Image Link",
            12345,
            "NFT Status"
          );
       // Wait for the transaction to be mined
   
         const token = 1;
    
        // Update NFT status
        await nftMinter.updateNFTStatus("Updated Status", token);
        //const createdNFT = await myContract.nfts(tokenId);
        // Get updated NFT status using the tokenId
        const updatedStatus = await nftMinter.NFT_DATA(token);
   // console.log("updatedStatus",updatedStatus)
        // Verify status is updated
        expect(updatedStatus.nftStatus).to.equal("Updated Status");
      });

});
it("should update image link for an NFT", async function () {
    const { user1, nftMinter } = await loadFixture(nftdeploy);

    // Mint a new NFT
    await nftMinter.mint(
      "NFT Metadata",
      1722080911,
      1,
      "Module Type",
      "Module Manufacturer",
      "Image Link",
      12345,
      "NFT Status"
    );
    const token = 1;
    // Update NFT image link
    await nftMinter.updateImagelink("New Image Link", token);

    // Get updated image link using the tokenId
    const updatedImageLink = await nftMinter.getImagelink(token);

    // Verify image link is updated
    expect(updatedImageLink).to.equal("New Image Link");
  });

  it("should update owner history for an NFT", async function () {
    const {admin, user1, user2, nftMinter  } = await loadFixture(nftdeploy);

    // Mint a new NFT
    const tokenId = await nftMinter.mint(
      "NFT Metadata",
      1722080911,
      1,
      "Module Type",
      "Module Manufacturer",
      "Image Link",
      12345,
      "NFT Status"
    );
    const token = 1;
    // Update owner history
    await nftMinter.updateOwnersHistory(user1.address, token);

    // Get owner history using the tokenId
    const ownerHistory = await nftMinter.OwnerHistory(token);

    // Verify owner history is updated
    expect(ownerHistory.userAddress).to.equal(user1.address);
  });

  it("should burn an expired NFT", async function () {
    const {admin, user1, user2, nftMinter  } = await loadFixture(nftdeploy);

    // Mint a new NFT with a short duration (1 second)
    await nftMinter.mint(
      "NFT Metadata",
      1690464426, // Expiration in 1 second
      1,
      "Module Type",
      "Module Manufacturer",
      "Image Link",
      12345,
      "NFT Status"
    );

    // Wait for the NFT to expire
    await new Promise((resolve) => setTimeout(resolve, 2000));
   
    const token = 1;
    // Try to burn the NFT (should succeed)
    const burnTx = await nftMinter.connect(user1).burn(token);
//console.log("burnTx",burnTx.from)
    // Check if the Burn address with the user's address
   
    expect(burnTx.from).to.equal(user1.address);
  });

  it("should not burn a non-expired NFT", async function () {
 const {admin, user1, user2, nftMinter  } = await loadFixture(nftdeploy);

    // Mint a new NFT with a long duration (10000 seconds)
    await nftMinter.mint(
      "NFT Metadata",
      1722080911, // Expiration in 10000 seconds
      1,
      "Module Type",
      "Module Manufacturer",
      "Image Link",
      12345,
      "NFT Status"
    );
const token = 1;
    // Try to burn the NFT (should fail)
    await expect(nftMinter.connect(user1).burn(token)).to.be.revertedWith("Expiration date not reached yet");
  });
  it("should update NFT duration", async function () {
    const { user1, nftMinter } = await loadFixture(nftdeploy);

    // Mint a new NFT
  await nftMinter.mint(
      "NFT Metadata",
      1690464426,
      1,
      "Module Type",
      "Module Manufacturer",
      "Image Link",
      12345,
      "NFT Status"
    );
    const token = 1;
    // Update NFT duration
    await nftMinter.updateNftDuration(1722080911, token);
    
    // Get updated NFT duration using the tokenId
    const updatedDuration = await nftMinter.getDuration(token);

    // Verify duration is updated
    expect(updatedDuration).to.equal(1722080911);
  });

  it("should set the treasury address by the contract owner", async () => {
// Call the setHouseAddress function with a new address
    const { user1, nftMinter } = await loadFixture(nftdeploy);
     await nftMinter.setHouseAddress(user1.address);
 // Check if the TREASURY_ADDRESS variable has been updated with the new address
    const updatedTreasuryAddress = await nftMinter.TREASURY_ADDRESS();
    expect(updatedTreasuryAddress).to.equal(user1.address);
  });

  it("should not allow non-owner to set the treasury address", async () => {
   // Call get another address
   const { user1, nftMinter ,user2} = await loadFixture(nftdeploy);
    
    await expect(
        nftMinter.connect(user2).setHouseAddress(user1.address)
    ).to.be.revertedWith("Ownable: caller is not the owner");

    // Check if the TREASURY_ADDRESS variable is still the same as the initial treasury address
    const currentTreasuryAddress = await nftMinter.TREASURY_ADDRESS();
    expect(currentTreasuryAddress).to.equal(user1.address);
  });

});