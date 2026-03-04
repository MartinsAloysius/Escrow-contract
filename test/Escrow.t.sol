// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow public escrow;

    address buyer = address(1);
    address seller = address(2);
    address arbitrator = address(3);

    uint256 fee = 0.01 ether;
    int256 resolution = 0; // No decision

    function setUp() public {
        escrow = new Escrow(buyer, seller, arbitrator, fee, resolution);

        vm.deal(buyer, 5 ether);
    }

    function testDeposit() public {
        vm.prank(buyer);
        escrow.deposit{value: 5 ether}();

        assertEq(escrow.amount(), 5 ether);
        assertEq(uint256(escrow.currentState()), 1); // AWAITING_DELIVERY

    }

    function testConfirmDelivery() public {
        vm.prank(buyer);
        escrow.deposit{value: 5 ether}();

        vm.prank(seller);
        escrow.confirmDelivery();

        assertEq(address(seller).balance, 5 ether);
        assertEq(uint256(escrow.currentState()), 2); // COMPLETE
    }

    function testRaiseDispute() public {
        vm.prank(buyer);
        escrow.deposit{value: 5 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        assertTrue(escrow.isDisputed());
        assertEq(uint256(escrow.currentState()), 3); // DISPUTE
    }

    function testResolveDispute() public {
        vm.prank(buyer);
        escrow.deposit{value: 5 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbitrator);
        escrow.resolveDispute(1); // Favor seller

        assertEq(address(seller).balance, 5 ether - fee);
        assertEq(uint256(escrow.currentState()), 2); // COMPLETE
    }

    function testResolveDspute() public {
        vm.prank(buyer);
        escrow.deposit{value: 5 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbitrator);
        escrow.resolveDispute(-1); // Favor buyer

        assertEq(address(buyer).balance, 5 ether - fee);
        assertEq(uint256(escrow.currentState()), 2); // COMPLETE
    }




  
}
