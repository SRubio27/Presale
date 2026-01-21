// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {PresaleTestBase} from "test/helpers/PresaleTestBase.t.sol";

/*
 forge coverage --fork-url https://1rpc.io/arb
 forge test -vvvv --fork-url https://1rpc.io/arb --match-test
*/
contract PhaseLogic is PresaleTestBase {
    function testPhaseLogic_UsesCorrectPricePerPhase() public {
        vm.startPrank(buyer);
        uint256 currentPhase_ = presale.currentPhase();

        uint256 pricePerToken_ = phases[currentPhase_][1];
        uint256 amountToBuy = 5000e6;
        uint256 tokenAmount = (amountToBuy * (10 ** 18)) / pricePerToken_;

        IERC20(usdcAddress).approve(address(presale), amountToBuy);
        presale.buyWithStableCoins(usdcAddress, amountToBuy);

        uint256 userTokenBalance_ = presale.userTokensBalance(buyer);
        assertEq(userTokenBalance_, tokenAmount);
        vm.stopPrank();
    }

    function testPhaseLogic_IncreasePhaseByTime() public {
        vm.startPrank(buyer);
        uint256 phaseBefore_ = presale.currentPhase();
        vm.warp(startTime + 31 days);
        IERC20(usdcAddress).approve(address(presale), 1e6);
        presale.buyWithStableCoins(usdcAddress, 1e6);
        uint256 phaseAfter_ = presale.currentPhase();

        assert(phaseAfter_ - phaseBefore_ == 1);

        vm.stopPrank();
    }

    function testPhaseLogic_IncreaseWhenSupplyExceeded() public {
        vm.startPrank(buyer);
        uint256 phaseBefore_ = presale.currentPhase();

        uint256 amountToChangePhase = (phases[phaseBefore_][1] *
            phases[phaseBefore_][0]) /
            (10 ** 18 - ERC20(usdcAddress).decimals() * 1e6);

        IERC20(usdcAddress).approve(address(presale), 5000 * 1e6);
        presale.buyWithStableCoins(usdcAddress, amountToChangePhase);

        uint256 phaseAfter_ = presale.currentPhase();

        assertEq(phaseAfter_ - phaseBefore_, 1);
        vm.stopPrank();
    }
}
