// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {PYUSD} from "../src/PYUSD.sol";

contract PYUSDScript is Script {
    PYUSD public pyusd;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        pyusd = new PYUSD();

        vm.stopBroadcast();
    }
}
