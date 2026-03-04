// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions



//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

/** 
* @title A sample Escrow contract
* @author Martins
* @notice This contract is a simple implementation of an escrow service. It allows a buyer to deposit funds, which can be withdrawn by the seller once the conditions of the sale are met. The contract also includes a dispute resolution mechanism to handle any disagreements between the buyer and seller.
* @dev Implements a simple escrow contract where a buyer can deposit funds, and a seller can withdraw them once the conditions are met. The contract also includes a dispute resolution mechanism.
*/

contract Escrow {
    /* Errors */
    error NotBuyer();
    error NotSeller();
    error NotArbitrator();
    error InvalidState();
    error InvalidAmount();
    error NoDispute();
    error TransferFailed();

    uint256 public amount;
    uint256 public deliveryDeadline;
    uint256 public disputeDeadline;
    int256 public disputeResolution; // -1 for buyer, 0 for no decision, 1 for seller
    uint256 private immutable fee; // Fee for the arbitrator
    
    address public buyer;
    address public seller;
    address public arbitrator;
    bool public isDisputed;

    /* Type Declarations */
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTE}
    State public currentState;  


    constructor(address _buyer, address _seller, address _arbitrator, uint256 _fee, int256 _resolution) {
        buyer = _buyer;
        seller = _seller;
        arbitrator = _arbitrator;
        fee = _fee;
        disputeResolution = _resolution;

        currentState = State.AWAITING_PAYMENT;
    }

    /* Events */
    event PaymentDeposited(address indexed buyer, uint256 amount);
    event ItemDelivered(address indexed seller);
    event DisputeRaised(address indexed buyer);
    event DisputeResolved(address indexed arbitrator, int256 resolution);

    /* Modifiers */
    modifier onlyBuyer() {
        if (msg.sender != buyer) revert NotBuyer();
        _;

    }

    modifier onlySeller() {
        if (msg.sender != seller) revert NotSeller();
        _;
    }

    function deposit() external payable onlyBuyer {
        if (currentState != State.AWAITING_PAYMENT) revert InvalidState();
        if (msg.value <= 0) revert InvalidAmount();

        amount = msg.value;

        currentState = State.AWAITING_DELIVERY;

        emit PaymentDeposited(msg.sender, msg.value);
    }

    function confirmDelivery() external onlySeller {
        if (currentState != State.AWAITING_DELIVERY) revert InvalidState();
       uint256 payout = amount;
       currentState = State.COMPLETE;
   
         (bool success, ) = seller.call{value: payout}("");
      if (!success) revert TransferFailed();

        emit ItemDelivered(msg.sender);
    }

    function raiseDispute() external onlyBuyer {
       if (currentState != State.AWAITING_DELIVERY) revert InvalidState();

        disputeDeadline = block.timestamp + 7 days; // Arbitrator has 7 days to resolve the dispute
        currentState = State.DISPUTE;

        emit DisputeRaised(msg.sender);
    }   

    function resolveDispute(int256 _resolution) external {
        if (msg.sender != arbitrator) revert NotArbitrator();
        if (currentState != State.DISPUTE) revert NoDispute();
        if (_resolution < -1 || _resolution > 1) revert InvalidAmount();

        uint256 payout = amount - fee; // Deduct fee for arbitrator
        uint256 arbitratorFee = fee; 

        
        amount = 0;

        disputeResolution = _resolution;
        currentState = State.COMPLETE;

        

        if (_resolution == -1) {
            // Refund buyer
            (bool success, ) = payable(buyer).call{value: payout}("");
            require (success);
        } else if (_resolution == 1) {
            // Pay seller
            (bool success, ) = payable(seller).call{value: payout}("");
            require (success);
        }

        (bool success2, ) = payable(arbitrator).call{value: arbitratorFee}("");
        require (success2);

        disputeResolution = _resolution;

        emit DisputeResolved(msg.sender, _resolution);
    }

    





    
}