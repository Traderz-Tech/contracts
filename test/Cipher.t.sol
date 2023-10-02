// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Cipher.sol";

contract CipherTest is Test {

    Cipher cipher;

    function setUp() public {
        cipher = new Cipher();

        cipher.setFeeDestination(address(this));
        cipher.setProtocolFeePercent(50000000000000000);
        cipher.setSubjectFeePercent(50000000000000000);
    }

    function testSetParams() public {
        assertEq(cipher.protocolFeeDestination(), address(this));
        assertEq(cipher.protocolFeePercent(), 50000000000000000);
        assertEq(cipher.subjectFeePercent(), 50000000000000000);
    }

    function testBuySellcores() public {
        cipher.buyCores{value: 1 ether}(address(this), 1);
        assertEq(cipher.coresBalance(address(this), address(this)), 1);
        assertEq(cipher.coresSupply(address(this)), 1);

        cipher.buyCores{value: 1 ether}(address(this), 1);

        assertEq(cipher.coresBalance(address(this), address(this)), 2);
        assertEq(cipher.coresSupply(address(this)), 2);

        cipher.sellCores(address(this), 1);
        assertEq(cipher.coresBalance(address(this), address(this)), 1);
        assertEq(cipher.coresSupply(address(this)), 1);
    }

    receive() external payable{}

    fallback() external payable{}
}
