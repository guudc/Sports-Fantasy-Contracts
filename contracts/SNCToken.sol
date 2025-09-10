// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SNC is ERC20 {
    constructor(address house) ERC20("MyToken", "USDT") {
        _mint(house, 10000 * 10 ** decimals());
    }
}