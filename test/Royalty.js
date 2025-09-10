const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("Royalty", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployRoyalty() {
    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2] = await ethers.getSigners();

    const royalty = await ethers.getContractFactory("Royalty");
    const Royalty = await royalty.deploy();

    return { Royalty, owner, addr1, addr2 };
  }

  describe("Deployment", function () {
    it("Should set the Deployer as the Owner", async function () {
      const { Royalty, owner } = await loadFixture(deployRoyalty);

      expect(await Royalty.owner()).to.equal(owner.address);
    });
    it("Should transfer ownership to another specified Address", async function () {
      const { Royalty, owner, addr1 } = await loadFixture(deployRoyalty);

      await Royalty.connect(owner).transferOwnership(addr1.address);
      expect(await Royalty.owner()).to.equal(addr1.address);
    });

    it("Should revert when non-owner tries to transfer ownership", async function () {
      const { Royalty, addr1, addr2 } = await loadFixture(deployRoyalty);

      await expect(
        Royalty.connect(addr1).transferOwnership(addr2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
  describe("Create FarmCollectionData", function () {
    it("Should create Farm Collection Data", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);

      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      const farmData = await Royalty.getFarmCollectionDetails(1);
      expect(farmData[0]).to.equal(1);
      expect(farmData[1]).to.equal(addr1.address);
      expect(farmData[2]).to.equal(150);
      expect(farmData[3]).to.equal(200);
    });

    it("Only owner can create Farm Collection Data", async function () {
      const { Royalty, owner, addr1 } = await loadFixture(deployRoyalty);
      const collectionId = 1;
      const buyingFeePercentage = 100; // 1.0%
      const sellingFeePercentage = 100; // 1.0%
      await expect(
        Royalty.connect(owner).CreateFarmCollectionData(
          collectionId,
          addr1.address,
          buyingFeePercentage,
          sellingFeePercentage
        )
      );
    });

    it("Should revert when creating a Farm Collection Data By Non Owner", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      const collectionId = 1;
      const buyingFeePercentage = 100; // 1.0%
      const sellingFeePercentage = 100; // 1.0%

      // Use addr1 as a non-owner caller
      await expect(
        Royalty.connect(addr1).CreateFarmCollectionData(
          collectionId,
          addr1.address,
          buyingFeePercentage,
          sellingFeePercentage
        )
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    it("Should revert when creating a farm collection with zero address", async function () {
      const { Royalty } = await loadFixture(deployRoyalty);
      await expect(
        Royalty.CreateFarmCollectionData(1, ZERO_ADDRESS, 150, 200)
      ).to.be.revertedWith("Farmowner must not be zero Address");
    });
  });

  describe("Functionality and Updations", function () {
    it("Should update buying fee percentage", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      const collectionId = 100;
      const newBuyingFeePercentage = 100; // 2.5%

      await Royalty.CreateFarmCollectionData(
        collectionId,
        addr1.address,
        100,
        200
      );
      await Royalty.updateBuyingFeePercentage(
        collectionId,
        newBuyingFeePercentage
      );

      const buyingFeePercentage = await Royalty.getBuyingFeePercentage(
        collectionId
      );
      expect(buyingFeePercentage).to.equal(newBuyingFeePercentage);
    });

    it("Should update selling fee percentage", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      const collectionId = 1;
      const newSellingFeePercentage = 300; // 3.0%

      await Royalty.CreateFarmCollectionData(
        collectionId,
        addr1.address,
        100,
        200
      );
      await Royalty.updateSellingFeePercentage(
        collectionId,
        newSellingFeePercentage
      );

      const sellingFeePercentage = await Royalty.getSellingFeePercentage(
        collectionId
      );
      expect(sellingFeePercentage).to.equal(newSellingFeePercentage);
    });

    it("Should update farm owner", async function () {
      const { Royalty, addr1, addr2 } = await loadFixture(deployRoyalty);
      const collectionId = 1;

      await Royalty.CreateFarmCollectionData(
        collectionId,
        addr1.address,
        100,
        200
      );
      await Royalty.updateFarmOwner(collectionId, addr2.address);

      const newFarmOwner = await Royalty.getFarmOwner(collectionId);
      expect(newFarmOwner).to.equal(addr2.address);
    });

    it("Should update the farm owner", async function () {
      const { Royalty, addr2, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      await Royalty.updateFarmOwner(1, addr2.address);
      const newOwner = await Royalty.getFarmOwner(1);
      expect(newOwner).to.equal(addr2.address);
    });

    it("Should revert when updating buying fee for non-existing farm collection", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      await expect(
        Royalty.updateBuyingFeePercentage(2, 150)
      ).to.be.revertedWith("Collection does not exist!");
    });

    it("Should revert when updating selling fee for non-existing farm collection", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      await expect(
        Royalty.updateSellingFeePercentage(2, 200)
      ).to.be.revertedWith("Collection does not exist!");
    });

    it("Should revert when updating farm owner for non-existing farm collection", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      await expect(
        Royalty.updateFarmOwner(2, addr1.address)
      ).to.be.revertedWith("Collection does not exist!");
    });

    it("Should revert when non-owner tries to update buying fee percentage", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      await expect(
        Royalty.connect(addr1).updateBuyingFeePercentage(1, 175)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert when non-owner tries to update selling fee percentage", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      await expect(
        Royalty.connect(addr1).updateSellingFeePercentage(1, 250)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert when non-owner tries to update farm owner", async function () {
      const { Royalty, addr1, addr2 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      await expect(
        Royalty.connect(addr1).updateFarmOwner(1, addr2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
  describe("Getters", function () {
    it("Should return the buying fee percentage", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 100);
      const buyingFee = await Royalty.getBuyingFeePercentage(1);
      expect(buyingFee).to.equal(150);
    });

    it("Should return the selling fee percentage", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      const sellingFee = await Royalty.getSellingFeePercentage(1);
      expect(sellingFee).to.equal(200);
    });

    it("Should return the farm owner address", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);

      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 100);
      const farmOwner = await Royalty.getFarmOwner(1);
      expect(farmOwner).to.equal(addr1.address);
    });

    it("Should return the details of a FarmeOwner", async function () {
      const { Royalty, addr1 } = await loadFixture(deployRoyalty);
      await Royalty.CreateFarmCollectionData(1, addr1.address, 150, 200);
      const farmDetails = await Royalty.getFarmCollectionDetails(1);
      expect(farmDetails[0]).to.equal(1);
      expect(farmDetails[1]).to.equal(addr1.address);
      expect(farmDetails[2]).to.equal(150);
      expect(farmDetails[3]).to.equal(200);
    });
  });
});
