// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";




contract Escrow is ERC1155Holder {
    
    IERC1155 nft; //NFT contract address
    IERC20 token; //to hold the SNC token instance
    uint256 TOKEN_ID; //NFT token id being locked in this escrow contract
    

    constructor (address _nftContractAddress, uint256 _tokenId, address sncAddress) {
        nft = IERC1155(_nftContractAddress);
        TOKEN_ID = _tokenId;
        token = IERC20(sncAddress);
        require(token.balanceOf(address(this)) <= 0, "Invalid ERC20 Contract address");
        require(nft.balanceOf(address(this), _tokenId) <= 0, "Invalid NFT Contract");
        //give the creator of this contract the approval to transfer NFT
       // nft.setApprovalForAll(msg.sender, true);
    }
    //This function transfers Nft from escrow  to user
    function transferNFTFromEscrowtoUser(address userAddress) public returns (bool) {
        nft.safeTransferFrom(address(this), userAddress,  TOKEN_ID, 1, "");
        return true;
    }
    
    //This functions revert any wrong tokenId transferred back to specified address
    function revertNFT(address receiver) public returns (bool) {
        //check if the Escrow has this nft
        if(nft.balanceOf(address(this), TOKEN_ID) > 0) {
         nft.safeTransferFrom(address(this), receiver, TOKEN_ID, 1, "");
        }
        return true;
    }
    //This function transfers snc from escrow to user
    function transferFromEscrowtoUser(address userAddress, uint256 amount) public returns (bool) {
        require(token.balanceOf(address(this)) >= amount, "Insufficient SNC tokens");
        require(token.transfer(userAddress, amount), "Error while transferring from Escrow to user");
        return true;
    }
    
}