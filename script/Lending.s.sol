// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/MOCKERC20.sol";
import "../src/Lending.sol";

contract LendingDeploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy Mock ERC20 token for collateral
        MockToken collateralToken = new MockToken();
        console.log("Collateral token deployed at:", address(collateralToken));

        // Deploy Lending contract with the collateral token address
        Lending lending = new Lending(
            address(collateralToken), // Collateral token address
            150, // Collateral ratio
            100, // Base variable borrow rate
            80,  // Optimal utilization rate
            150, // Excess utilization rate
            50   // Base stable borrow rate
        );

        console.log("Lending Protocol deployed at:", address(lending));
    }
}
