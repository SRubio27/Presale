// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {PresaleTestBase} from "test/helpers/PresaleTestBase.t.sol";

/*
 forge coverage --fork-url https://1rpc.io/arb
 forge test -vvvv --fork-url https://1rpc.io/arb --match-test
*/
contract Blacklist is PresaleTestBase {
    function testBlacklist_RevertsIfNotOwner() public {
        vm.startPrank(buyer);

        vm.expectRevert();
        presale.blackListUser(buyer);

        vm.expectRevert();
        presale.removeBlacklist(buyer);

        vm.stopPrank();
    }

    function testBlacklist_WorksCorrectly() public {
        vm.startPrank(owner);
        presale.blackListUser(buyer);
        bool isBlacklisted_ = presale.isBlacklisted(buyer);
        assertEq(isBlacklisted_, true);

        presale.removeBlacklist(buyer);
        isBlacklisted_ = presale.isBlacklisted(buyer);
        assertEq(isBlacklisted_, false);

        vm.stopPrank();
    }
}
