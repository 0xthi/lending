// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILending.sol";

/**
 * @title Lending
 * @dev A contract for lending and borrowing ERC20 tokens with collateral.
 */
contract Lending is ILending, Ownable {
    // Structure to store user data
    struct User {
        uint256 collateral; // Amount of collateral deposited by the user
        uint256 borrowedAmount; // Amount borrowed by the user
    }

    // ERC20 token used for collateral
    IERC20 public collateralToken;

    // Collateral ratio
    uint256 public collateralRatio;

    // Interest rate model parameters
    uint256 public baseVariableBorrowRate;
    uint256 public optimalUtilizationRate;
    uint256 public excessUtilizationRate;
    uint256 public baseStableBorrowRate;

    // Mapping of users
    mapping(address => User) public users;
    // Mapping of interest accrual time
    mapping(address => uint256) public lastInterestAccrualTime;

    /**
     * @dev Constructor to initialize the lending contract with parameters.
     * @param _collateralToken Address of the ERC20 token used as collateral.
     * @param _collateralRatio Ratio of collateral required for borrowing.
     * @param _baseVariableBorrowRate Base variable borrow rate.
     * @param _optimalUtilizationRate Optimal utilization rate.
     * @param _excessUtilizationRate Excess utilization rate.
     * @param _baseStableBorrowRate Base stable borrow rate.
     */
    constructor(
    address _collateralToken,
    uint256 _collateralRatio,
    uint256 _baseVariableBorrowRate,
    uint256 _optimalUtilizationRate,
    uint256 _excessUtilizationRate,
    uint256 _baseStableBorrowRate
) Ownable(msg.sender) {
    collateralToken = IERC20(_collateralToken);
    collateralRatio = _collateralRatio;
    baseVariableBorrowRate = _baseVariableBorrowRate;
    optimalUtilizationRate = _optimalUtilizationRate;
    excessUtilizationRate = _excessUtilizationRate;
    baseStableBorrowRate = _baseStableBorrowRate;
}


    /**
     * @dev Function to deposit collateral.
     * @param amount Amount of collateral to deposit.
     */
    function depositCollateral(uint256 amount) external {
        if (amount == 0) revert AMOUNT_LESS_THAN_0();

        // Transfer collateral tokens from owner to this contract
        if (!collateralToken.transferFrom(msg.sender, address(this), amount)) revert TRANSFER_FAILED();

        // Update owner's collateral balance
        users[msg.sender].collateral += amount;

        emit CollateralDeposited(msg.sender, amount);
    }

    /**
     * @dev Function to borrow funds against collateral.
     * @param amount Amount of tokens to borrow.
     */
    function borrow(uint256 amount) external {
        if (amount == 0) revert AMOUNT_LESS_THAN_0();

        // Ensure owner has sufficient collateral
        if (users[msg.sender].collateral * collateralRatio < users[msg.sender].borrowedAmount + amount) revert INSUFFICIENT_COLLATERAL();

        // Transfer borrowed tokens to owner
        // In a real implementation, you'd mint new tokens or transfer from a pool
        // For simplicity, we'll just emit an event here
        emit FundsBorrowed(msg.sender, amount);

        // Update owner's borrowed amount
        users[msg.sender].borrowedAmount += amount;
    }

    /**
     * @dev Function to calculate interest accrued on a loan.
     * @return interestAccrued The interest accrued on the loan.
     */
    function calculateInterest() external returns (uint256) {
        uint256 utilizationRate =
            users[msg.sender].borrowedAmount * 1e18 / users[msg.sender].collateral;

        // Calculate time elapsed since last interest accrual
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTime[msg.sender];

        // Update the last interest accrual time
        lastInterestAccrualTime[msg.sender] = block.timestamp;

        // Calculate interest based on utilization rate and time elapsed
        uint256 interestAccrued;
        if (utilizationRate <= optimalUtilizationRate) {
            // Linear increase from base rate to optimal rate
            uint256 interestRate =
                baseVariableBorrowRate +
                utilizationRate *
                (excessUtilizationRate - baseVariableBorrowRate) /
                optimalUtilizationRate;
            interestAccrued = (users[msg.sender].borrowedAmount * interestRate * timeElapsed) / (1e18 * 365 days);
        } else {
            // Above optimal utilization rate, charge a constant rate
            interestAccrued = (users[msg.sender].borrowedAmount * excessUtilizationRate * timeElapsed) / (1e18 * 365 days);
        }

        return interestAccrued;
    }


    /**
     * @dev Function to repay a loan.
     * @param amount Amount of tokens to repay.
     */
    function repayLoan(uint256 amount) external {
        if (amount == 0) revert AMOUNT_LESS_THAN_0();

        // Ensure user has sufficient balance to repay
        if (collateralToken.balanceOf(msg.sender) < amount) revert INSUFFICIENT_BALANCE();

        // Transfer tokens from owner to contract to repay the loan
        if (!collateralToken.transferFrom(msg.sender, address(this), amount)) revert TRANSFER_FAILED();

        // Reduce owner's borrowed amount
        users[msg.sender].borrowedAmount -= amount;

        // Emit repayment event
        emit LoanRepaid(msg.sender, amount);
    }

    /**
     * @dev Function to liquidate undercollateralized positions.
     * @param borrower Address of the borrower whose position to liquidate.
     */
    function liquidatePosition(address borrower) external {
        uint256 liquidationThreshold =
            users[borrower].collateral * collateralRatio;

        if (users[borrower].borrowedAmount > liquidationThreshold) revert POSITION_NOT_UNDERCOLLATERALIZED();

        // Liquidate entire borrowed amount
        emit Liquidation(borrower, users[borrower].borrowedAmount);
        users[borrower].borrowedAmount = 0;
    }

    /**
     * @dev Function to withdraw deposited tokens if the loan repaid.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawTokens(uint256 amount) external {
        if (amount == 0) revert AMOUNT_LESS_THAN_0();

        // Ensure owner has sufficient balance to withdraw
        if (collateralToken.balanceOf(address(this)) < amount) revert INSUFFICIENT_BALANCE();

        // Transfer tokens to owner
        if (!collateralToken.transfer(msg.sender, amount)) revert TRANSFER_FAILED();

        emit TokensWithdrawn(msg.sender, amount);
    }

    /**
    Edit functions
    */

    // Function to update collateral token address
    function setCollateralToken(address _collateralToken) external onlyOwner {
        collateralToken = IERC20(_collateralToken);
    }

    // Function to update collateral ratio
    function setCollateralRatio(uint256 _collateralRatio) external onlyOwner {
        collateralRatio = _collateralRatio;
    }

    // Function to update base variable borrow rate
    function setBaseVariableBorrowRate(uint256 _baseVariableBorrowRate) external onlyOwner {
        baseVariableBorrowRate = _baseVariableBorrowRate;
    }

    // Function to update optimal utilization rate
    function setOptimalUtilizationRate(uint256 _optimalUtilizationRate) external onlyOwner {
        optimalUtilizationRate = _optimalUtilizationRate;
    }

    // Function to update excess utilization rate
    function setExcessUtilizationRate(uint256 _excessUtilizationRate) external onlyOwner {
        excessUtilizationRate = _excessUtilizationRate;
    }

    // Function to update base stable borrow rate
    function setBaseStableBorrowRate(uint256 _baseStableBorrowRate) external onlyOwner {
        baseStableBorrowRate = _baseStableBorrowRate;
    }
}
