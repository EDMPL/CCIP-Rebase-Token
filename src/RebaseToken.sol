// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Rebase Token
 * @author Jeremia Geraldi (Inspired by Ciara from Cyfrin Updraft Course)
 * @notice This is a cross-chain rebase token that incentivizes user to deposit into a vault
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate which is the global interest rate when the user is depositing in 
 */

contract RebaseToken is ERC20 {
    error RebaseToken__NewInterestRateIsLowerThanGlobalInterestRate(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private s_globalInterestRate = 5e10; // 0.0000005% per second
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimeStamp;

    event NewInterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {
    }

    /**
     * @notice Set Interest Rate of the Contract
     * @notice Interest Rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        // Set the interest rate
        if(_newInterestRate < s_globalInterestRate) revert RebaseToken__NewInterestRateIsLowerThanGlobalInterestRate(s_globalInterestRate, _newInterestRate);

        s_globalInterestRate = _newInterestRate;
        emit NewInterestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external{
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_globalInterestRate;
        _mint(_to, _amount);
    }

    /**
     * 
     * @param _user The address of user that the address will be looked up to
     * @notice Get user principal balance (the number of tokens that actually has been minted)
     * @notice Multiply principal balance with the interest that has accumulated in the time since the balance was last updated
     */
    function balanceOf(address _user) public view override returns(uint256) {
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user);
    }

    function getUserInterestRate(address _user) external view returns(uint256) {
        return s_userInterestRate[_user];
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(address user) internal view returns(uint256){
        
    }

    /**
     * 
     * @param user The user that will get their balance modified based on their interest
     * @notice (1) First, find the balance of rebase token that have minted to a user -> Principal Balance
     * @notice (2) Calculate their current balance including any interest -> balanceOf
     * @notice (3) Calculate number of tokens that need to be minted to the user -> 2 - 1
     * @notice call _mint to update the user tokens
     * @notice set users last updated timestamp
     */
    function _mintAccruedInterest(address user) internal {

        s_userLastUpdatedTimeStamp[user] = block.timestamp;

    }



    

}