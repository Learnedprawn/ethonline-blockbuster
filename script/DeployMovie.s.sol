// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {MovieFactory} from "../src/MovieFactory.sol";

contract MovieScript is Script {
    MovieFactory public movieFactory;

    // address deployer =
    //     vm.parseAddress("0x115fa80d1d00c38d88d2c024fe5c6f9d5ca34be3");

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        movieFactory = new MovieFactory();

        vm.stopBroadcast();
    }
}
