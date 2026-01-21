// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Presale} from "src/Presale.sol";

/*
 forge coverage --fork-url https://1rpc.io/arb
 forge test -vvvv --fork-url https://1rpc.io/arb --match-test
*/
contract PresaleTestBase is Test {
    Presale public presale;
    uint256 startTime = block.timestamp;
    uint256 endingTime = startTime + 90 days;
    uint256 maxSellingAmount = 3000000 * 1e18;
    uint256[][3] phases;

    address owner = vm.addr(1);
    address fundsReceiver = vm.addr(2);
    address buyer = 0x517f9c341F5Ed8fB0F2b1C4318d74aF9ac3306Ac;
    address usdtAddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address usdcAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address oracleEthUsd = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

    // vm.warp(timestamp) para saltar a un timestamp en especifico
    // vm.roll(blockNumber) para movernos a traves de bloques
    function setUp() public {
        phases[0] = [1000000 * 1e18, 5 * 1e3, startTime + 30 days];
        phases[1] = [2000000 * 1e18, 1 * 1e4, startTime + 60 days];
        phases[2] = [maxSellingAmount, 15 * 1e4, startTime + 90 days];

        vm.startPrank(owner);

        presale = new Presale(
            usdtAddress, // Usdt
            usdcAddress, // Usdc
            // 0x986C9367f1B3fcF578929b9903987D7b0d2631d1, // R27
            fundsReceiver, // fundsReceiver
            oracleEthUsd, // Oracle of eth price in USD
            maxSellingAmount,
            startTime,
            endingTime,
            3000000 * 1e18, // 30 millones con
            "Rubinhos",
            "SRG",
            phases
        );
        vm.stopPrank();

        uint256 BIG_AMOUNT = 10_000_000 * 1e6; // 10M USDC

        vm.deal(buyer, 100000000000000 ether);
        deal(usdcAddress, buyer, BIG_AMOUNT);
        deal(usdtAddress, buyer, BIG_AMOUNT);
    }

    function testConstructor() public {
        vm.startPrank(owner);

        assertEq(presale.owner(), address(owner));
        assertEq(
            presale.mockToken().balanceOf(address(presale)),
            3000000 * 1e18
        );
        vm.stopPrank();
    }
}
