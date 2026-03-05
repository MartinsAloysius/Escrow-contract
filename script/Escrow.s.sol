// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowScript is Script {
    Escrow public escrow;

    function run() public returns (Escrow) {
        address buyer = address(1);
        address seller = address(2);
        address arbitrator = address(3);
        uint256 fee = 0.01 ether;
        int256 resolution = 0; // No decision

        vm.startBroadcast();

        escrow = new Escrow(buyer, seller, arbitrator, fee, resolution);

        vm.stopBroadcast();

        return escrow;
    }
}