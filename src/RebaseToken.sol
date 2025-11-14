// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Rebase Token
 * @author Jeremia Geraldi (Inspired by Ciara from Cyfrin Updraft Course)
 * @notice This is a cross-chain rebase token that incentivizes user to deposit into a vault
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate which is the global interest rate when the user is depositing in 
 */

contract RebaseToken is ERC20, Ownable, AccessControl{
    error RebaseToken__NewInterestRateIsLowerThanGlobalInterestRate(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private s_globalInterestRate = 5e10; // 0.0000005% per second
    uint256 public constant PRECISION = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimeStamp;

    event NewInterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {
    }

    function grantRole(address _account) external onlyOwner{
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @notice Set Interest Rate of the Contract
     * @notice Interest Rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner{
        // Set the interest rate
        if(_newInterestRate < s_globalInterestRate) revert RebaseToken__NewInterestRateIsLowerThanGlobalInterestRate(s_globalInterestRate, _newInterestRate);

        s_globalInterestRate = _newInterestRate;
        emit NewInterestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE){
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_globalInterestRate;
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE){
        // Handle latency and difference between the transaction and actual finality if the user really want to redeem all their tokens 
        if (_amount == type(uint256).max){
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice Transfer tokens from one user to another
     * @param _recipient The user address to transfer the token to
     * @param _amount The amount of token that will be transferred
     * @notice Return true if the transfer is successful
     */
    function transfer(address _recipient, uint256 _amount) public override returns(bool){
        if (_amount == type(uint256).max){
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0){
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        return super.transfer(_recipient, _amount);
    }

     /**
     * @notice Transfer tokens from one user to another
     * @param _sender The user address that want to transfer token to
     * @param _recipient The user address to transfer the token to
     * @param _amount The amount of token that will be transferred
     * @notice Return true if the transfer is successful
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns(bool){
        if (_amount == type(uint256).max){
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0){
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        return super.transferFrom(_sender, _recipient, _amount);
    }



    /**
     * @param _user The address of user that the balance will be looked up to
     * @notice Get user principal balance (the number of tokens that actually has been minted)
     * @notice Multiply principal balance with the interest that has accumulated in the time since the balance was last updated
     * @return The balance of the user including the interest
     */
    function balanceOf(address _user) public view override returns(uint256) {
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user)) / PRECISION;
    }

    function getUserInterestRate(address _user) external view returns(uint256) {
        return s_userInterestRate[_user];
    }

    /**
     * @param _user The address of user that the principle balance will be looked up to
     * @notice Get user principal balance (the number of tokens that actually has been minted) but not including the interest that has accrued since the last time user interacted with the protocol. 
     * @return The balance of the user without the interest
     */
    function getPrincipleBalanceOf(address _user) external view returns(uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @param _user The address of user that the balance will be looked up to
     * @notice Calculate the interest that has accumulated since the last update
     * @notice This is going to be linear growth with time
     * @return linearInterest The interest that has accumulated since last update
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns(uint256 linearInterest){
        // User Accumulated Interest = 1 + (Interest Rate * Time Elapsed)
        // balanceOf will be calculated like this: Principal Balance + (1 + (Interest Rate * Time Elapsed))
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimeStamp[_user];
        linearInterest = PRECISION + (s_userInterestRate[_user] * timeElapsed);
        return linearInterest;
    }

    /**
     * @param _user The user that will get their balance modified based on their interest
     * @notice Mint the accrued interest to the user since the last time they interacted with the protocol
     * @notice (1) First, find the balance of rebase token that have minted to a user -> Principle Balance
     * @notice (2) Calculate their current balance including any interest -> balanceOf
     * @notice (3) Calculate number of tokens that need to be minted to the user -> 2 - 1
     * @notice call _mint to update the user tokens
     * @notice set users last updated timestamp
     */
    function _mintAccruedInterest(address _user) internal {
        uint256 previousUserBalance = super.balanceOf(_user); // 1
        uint256 currentBalance = balanceOf(_user); // 2
        uint256 balanceIncrease = currentBalance - previousUserBalance; // 3
        s_userLastUpdatedTimeStamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }

    function getInterestRage() external view returns(uint256) {
        return s_globalInterestRate;
    }
}