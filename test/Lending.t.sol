// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {Lending} from "../src/Lending.sol";
import {MockToken} from "../src/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingTest is Test {
    Lending public lending;
    IERC20 public collateralToken;
    MockToken public mockToken;        
    address public user = address(1);

    function setUp() public {
        // Deploy a mock ERC20 token for testing
        collateralToken = new MockToken("CollateralToken", "CTK", address(this)); // Set the initial owner to the test contract

        // Cast collateralToken to MockToken
        mockToken = MockToken(address(collateralToken));

        // Initialize lending contract with parameters
        lending = new Lending(
            address(collateralToken),
            150, // Collateral ratio
            100, // Base variable borrow rate
            80,  // Optimal utilization rate
            150, // Excess utilization rate
            50   // Base stable borrow rate
        );

        // Mint tokens for the test contract with allowance
        uint256 initialSupply = 10000; // Set an initial supply for testing purposes
        mockToken.mint(address(this), initialSupply);

        // Set allowance for lending contract to transfer tokens
        uint256 allowanceAmount = 100000; // Set the allowance amount for testing purposes
        collateralToken.approve(address(lending), allowanceAmount);
        
        // Mint tokens for the user
        mockToken.mint(msg.sender, initialSupply);
        
        vm.startPrank(msg.sender);
        // Set allowance for the lending contract to transfer tokens on behalf of the user
        collateralToken.approve(address(lending), allowanceAmount);
        vm.stopPrank;
    }

    function test_DepositAndBorrow() public {
        // Deposit collateral
        lending.depositCollateral(1000);

        // Borrow funds against collateral
        lending.borrow(500);

        // Get user data
        (uint256 collateral, uint256 borrowedAmount) = lending.users(msg.sender);

        // Assert borrower's collateral and borrowed amount
        assertEq(collateral, 1000); // Collateral
        assertEq(borrowedAmount, 500);  // Borrowed amount
    }

    function test_RepayLoan() public {
        // Deposit collateral
        lending.depositCollateral(1000);

        // Borrow funds against collateral
        lending.borrow(500);

        // Get user data
        (uint256 collateral, uint256 borrowedAmount) = lending.users(msg.sender);

        // Assert borrower's borrowed amount before repayment
        assertEq(borrowedAmount, 500);

        // Repay loan
        lending.repayLoan(200);

        // Get user data after repayment
        (collateral, borrowedAmount) = lending.users(msg.sender);

        // Assert borrower's borrowed amount after repayment
        assertEq(borrowedAmount, 300);
    }

    function test_LiquidatePosition() public {
        // Deposit collateral
        lending.depositCollateral(1000);

        // Borrow funds against collateral
        lending.borrow(800);

        // Liquidate position
        lending.liquidatePosition(user);

        // Get user data after liquidation
        (uint256 collateral, uint256 borrowedAmount) = lending.users(user);

        // Assert borrower's borrowed amount after liquidation
        assertEq(borrowedAmount, 0);
    }
}
