// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(
        uint256 initialMintAmount_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, initialMintAmount_);
    }
}
