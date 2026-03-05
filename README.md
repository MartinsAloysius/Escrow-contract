# Escrow Contract

> A simple, trustless escrow smart contract with built-in dispute resolution.

**Author:** Martins  
**License:** MIT  
**Solidity Version:** `^0.8.30`

---

## Overview

This contract allows a **buyer** to deposit funds into escrow, which are released to the **seller** upon confirmed delivery. If a dispute arises, a neutral **arbitrator** steps in to resolve it — with a 7-day resolution window — and earns a fee for doing so.

---

## Parties

| Role | Description |
|------|-------------|
| `buyer` | Deposits funds and can raise disputes |
| `seller` | Confirms delivery and receives payout |
| `arbitrator` | Resolves disputes and collects a fee |

---

## Contract States

```
AWAITING_PAYMENT → AWAITING_DELIVERY → COMPLETE
                                     ↘ DISPUTE → COMPLETE
```

| State | Description |
|-------|-------------|
| `AWAITING_PAYMENT` | Contract deployed, waiting for buyer to deposit |
| `AWAITING_DELIVERY` | Funds deposited, waiting for delivery confirmation |
| `COMPLETE` | Transaction finalized |
| `DISPUTE` | Buyer raised a dispute, awaiting arbitrator ruling |

---

## Constructor

```solidity
constructor(
    address _buyer,
    address _seller,
    address _arbitrator,
    uint256 _fee,
    int256 _resolution
)
```

Initialises the contract with the involved parties, arbitrator fee, and default dispute resolution value. Sets a default escrow amount of **5 ETH** and state to `AWAITING_PAYMENT`.

---

## Functions

### `deposit()`
```solidity
function deposit() external payable onlyBuyer
```
- Buyer deposits exactly the agreed `amount` (5 ETH default)
- Transitions state from `AWAITING_PAYMENT` → `AWAITING_DELIVERY`
- Emits `PaymentDeposited`

---

### `confirmDelivery()`
```solidity
function confirmDelivery() external onlySeller
```
- Seller confirms the item has been delivered
- Transfers full `amount` to the seller
- Transitions state to `COMPLETE`
- Emits `ItemDelivered`

---

### `raiseDispute()`
```solidity
function raiseDispute() external onlyBuyer
```
- Buyer can raise a dispute while state is `AWAITING_DELIVERY`
- Sets a **7-day dispute deadline** for the arbitrator
- Transitions state to `DISPUTE`
- Emits `DisputeRaised`

---

### `resolveDispute(int256 _resolution)`
```solidity
function resolveDispute(int256 _resolution) external
```
- Only callable by the `arbitrator`
- `_resolution` values:
  - `-1` → Refund buyer (minus arbitrator fee)
  - `0` → No decision
  - `1` → Pay seller (minus arbitrator fee)
- Arbitrator always receives their `fee`
- Transitions state to `COMPLETE`
- Emits `DisputeResolved`

---

## Events

| Event | Trigger |
|-------|---------|
| `PaymentDeposited(address buyer, uint256 amount)` | Buyer deposits funds |
| `ItemDelivered(address seller)` | Seller confirms delivery |
| `DisputeRaised(address buyer)` | Buyer raises a dispute |
| `DisputeResolved(address arbitrator, int256 resolution)` | Arbitrator resolves dispute |

---

## Errors

| Error | Cause |
|-------|-------|
| `NotBuyer()` | Caller is not the buyer |
| `NotSeller()` | Caller is not the seller |
| `NotArbitrator()` | Caller is not the arbitrator |
| `InvalidState()` | Function called in wrong contract state |
| `InvalidAmount()` | Incorrect deposit amount or invalid resolution value |
| `NoDispute()` | `resolveDispute` called when not in `DISPUTE` state |
| `TransferFailed()` | ETH transfer failed |

---

## Development & Testing

This project uses [Foundry](https://book.getfoundry.sh/).

```bash
# Clone the repo
git clone https://github.com/MartinsAloysius/Escrow-contract.git
cd Escrow-contract

# Install dependencies
forge install

# Build
forge build

# Run tests
forge test

# Run tests with verbosity
forge test -vvv
```

### Test Coverage

Tests are located in `test/EscrowTest.t.sol`. The test suite covers the following scenarios:

| Test | Description |
|------|-------------|
| `testDeposit` | Buyer deposits 5 ETH; verifies amount and state transitions to `AWAITING_DELIVERY` |
| `testConfirmDelivery` | Seller confirms delivery after deposit; verifies seller receives full 5 ETH payout |
| `testRaiseDispute` | Buyer raises a dispute; verifies `isDisputed` flag and state transitions to `DISPUTE` |
| `testResolveDisputeSeller` | Arbitrator rules in seller's favour; verifies seller receives `amount - fee` |
| `testResolveDisputeBuyer` | Arbitrator rules in buyer's favour; verifies buyer is refunded `amount - fee` |
| `testOnlyBuyerCanDeposit` | Non-buyer deposit attempt reverts with `NotBuyer` |
| `testOnlySellerCanConfirmDelivery` | Non-seller delivery confirmation reverts with `NotSeller` |
| `testCannotDepositTwice` | Second deposit attempt reverts due to invalid state |
| `testCannotConfirmDeliveryBeforeDeposit` | Delivery confirmation before deposit reverts |
| `testOnlyArbitratorCanResolveDispute` | Non-arbitrator dispute resolution reverts with `NotArbitrator` |
| `testInvalidStateTransitions` | Raising dispute before deposit reverts with `InvalidState` |
| `testResolveWithoutDispute` | Arbitrator resolving without active dispute reverts |

### Test Setup

```solidity
address buyer      = address(1);
address seller     = address(2);
address arbitrator = address(3);

uint256 fee        = 0.01 ether;
int256  resolution = 0; // No decision (default)
```

Each test starts with buyer and seller funded with **5 ETH** via `vm.deal`.

---

## Security Considerations

- Reentrancy risk is mitigated by zeroing `amount` before external calls in `resolveDispute`
- `confirmDelivery` transfers funds before emitting the event — consider moving the emit after the transfer check
- The default escrow amount is hardcoded to `5 ether` in the constructor — consider making this a constructor parameter for production use
- `disputeDeadline` is set but not enforced on-chain — consider adding a check in `resolveDispute`

---

## License

[MIT](./LICENSE)