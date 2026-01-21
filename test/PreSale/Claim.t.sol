// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {PresaleTestBase} from "test/helpers/PresaleTestBase.t.sol";

/*
 forge coverage --fork-url https://1rpc.io/arb
 forge test -vvvv --fork-url https://1rpc.io/arb --match-test
*/
contract Claim is PresaleTestBase {
    function testClaim_RevertsIfAmountIsZero() public {
        vm.startPrank(buyer);
        vm.warp(startTime + 91 days);

        vm.expectRevert("NO_TOKENS_TO_CLAIM");
        presale.claim();
        
        vm.stopPrank();
    }

    function testClaim_RevertsIfPresaleNotEnded() public {
        vm.startPrank(buyer);
        IERC20(usdcAddress).approve(address(presale), 100e6);
        presale.buyWithStableCoins(usdcAddress, 100e6);

        vm.expectRevert("PRESLAE_NOT_ENDED");
        presale.claim();

        vm.stopPrank();
    }

    function testClaim_WorksCorrectly() public {
        vm.startPrank(buyer);
        IERC20(usdcAddress).approve(address(presale), 100e6);
        presale.buyWithStableCoins(usdcAddress, 100e6);
        uint256 expectedTokens_ = presale.userTokensBalance(buyer);

        vm.warp(startTime + 91 days);

        presale.claim();

        uint256 tokensClaimed_ = IERC20(address(presale.mockToken())).balanceOf(
            buyer
        );
        uint256 contractTokenBalanceOfUser_ = presale.userTokensBalance(buyer);
        assertEq(expectedTokens_, tokensClaimed_);
        assertEq(contractTokenBalanceOfUser_, 0);
        vm.stopPrank();
    }
}
