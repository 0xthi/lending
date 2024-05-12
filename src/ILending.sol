// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILending {
    // Events
    event CollateralDeposited(address indexed user, uint256 amount);
    event FundsBorrowed(address indexed user, uint256 amount);
    event Liquidation(address indexed borrower, uint256 amountLiquidated);
    event LoanRepaid(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);

    // Errors
    error AMOUNT_LESS_THAN_0();
    error TRANSFER_FAILED();
    error INSUFFICIENT_COLLATERAL();
    error INSUFFICIENT_BALANCE();
    error POSITION_NOT_UNDERCOLLATERALIZED();

    // View functions
    function users(address userAddress) external view returns (uint256 collateral, uint256 borrowedAmount);
    function calculateInterest() external returns (uint256);

    // State variables
    function collateralToken() external view returns (address);
    function collateralRatio() external view returns (uint256);
    function baseVariableBorrowRate() external view returns (uint256);
    function optimalUtilizationRate() external view returns (uint256);
    function excessUtilizationRate() external view returns (uint256);
    function baseStableBorrowRate() external view returns (uint256);

    // External functions
    function depositCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repayLoan(uint256 amount) external;
    function liquidatePosition(address borrower) external;
    function withdrawTokens(uint256 amount) external;
}
