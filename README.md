# Sport Fantasy Contracts Demo

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

# Escrow Smart Contract

This project provides a simple **Escrow contract** that manages the transfer of **ERC1155 NFTs** and **ERC20 tokens**. It ensures assets are safely held in escrow until explicitly released to a user.


## Features

* **ERC1155 NFT Escrow**
  Locks a specific NFT (by `tokenId`) in the contract until released.

* **ERC20 Token Escrow**
  Holds ERC20 tokens (e.g., SNC tokens) and transfers them securely to a specified user.

* **Revert Functionality**
  Allows reverting NFTs mistakenly deposited back to a chosen receiver.

---

## Requirements

* Solidity `^0.8.20`
* OpenZeppelin contracts:

  * `IERC20`
  * `IERC1155`
  * `ERC1155Holder`

Install via npm:

```bash
npm install @openzeppelin/contracts
```

---

## Contract Overview

### Constructor

```solidity
constructor(address _nftContractAddress, uint256 _tokenId, address sncAddress)
```

* `_nftContractAddress`: Address of the ERC1155 NFT contract.
* `_tokenId`: ID of the NFT to be locked in escrow.
* `sncAddress`: Address of the ERC20 token (SNC) contract.

---

### Functions

#### 1. Transfer NFT from Escrow to User

```solidity
function transferNFTFromEscrowtoUser(address userAddress) public returns (bool)
```

* Transfers the locked NFT to the specified `userAddress`.

---

#### 2. Revert NFT

```solidity
function revertNFT(address receiver) public returns (bool)
```

* Returns the NFT back to the `receiver` if it exists in escrow.

---

#### 3. Transfer ERC20 Tokens from Escrow

```solidity
function transferFromEscrowtoUser(address userAddress, uint256 amount) public returns (bool)
```

* Transfers the given `amount` of ERC20 tokens from escrow to the `userAddress`.
* Requires that the escrow contract holds enough tokens.

---

## Usage Example

### Deployment

Deploy the contract by passing:

* ERC1155 NFT contract address
* NFT token ID to lock
* ERC20 (SNC) token contract address

Example (using Hardhat):

```javascript
const Escrow = await ethers.getContractFactory("Escrow");
const escrow = await Escrow.deploy(nftAddress, tokenId, sncTokenAddress);
await escrow.deployed();
```

### Transferring NFT to User

```javascript
await escrow.transferNFTFromEscrowtoUser(userAddress);
```

### Reverting NFT

```javascript
await escrow.revertNFT(receiverAddress);
```

### Transferring ERC20 Tokens

```javascript
await escrow.transferFromEscrowtoUser(userAddress, amount);
```

---

## Security Notes

* Ensure the contract holds the NFT and/or tokens before attempting transfers.
* Only trusted parties should call the transfer functions (currently no access control).
* Consider adding **ownership** or **role-based access control** for production use.

---

## License

This project is licensed under the [MIT License](LICENSE).

---
 
