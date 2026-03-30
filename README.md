# Raffle

A provably fair, on-chain raffle contract built on Solidity. Players enter by paying an entrance fee, and after a configurable interval a verifiable random winner is selected using Chainlink VRF V2.5 and paid the entire pot. The randomness is cryptographically provable and tamper-proof, making the outcome impossible to manipulate. Multi-network deployment is handled automatically via HelperConfig with full mock infrastructure for local development.

---

## What It Does

- Players enter the raffle by paying a fixed entrance fee in ETH
- The raffle remains open until the configured interval has elapsed
- Anyone can trigger the winner selection once the interval has passed
- Chainlink VRF V2.5 provides verifiable randomness for winner selection
- The winner receives the entire pot in a single transfer
- The raffle resets automatically after each round, ready for the next
- Direct ETH transfers to the contract are rejected

---

## Project Structure

```
.
├── src/
│   └── Raffle.sol                          # Main contract
├── script/
│   ├── DeployRaffle.s.sol                  # Foundry deploy script
│   └── HelperConfig.s.sol                  # Network configuration and mock deployment
└── test/
    ├── Unit/
    │   └── TestRaffle.t.sol                # Unit tests
    └── mocks/
        ├── VRFCoordinatorV2_5Mock.sol      # Chainlink VRF coordinator mock
        └── LinkToken.sol                   # Mock LINK token for local testing
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Install dependencies and build

```bash
forge install
forge build
```

### Run tests

```bash
forge test
```

### Run tests with gas report

```bash
forge test --gas-report
```

### Run tests with coverage

```bash
forge coverage
```

### Deploy to a local Anvil chain

In one terminal, start Anvil:

```bash
anvil
```

In another terminal, run the deploy script:

```bash
forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Deploy to Sepolia

Before deploying to Sepolia, create and fund a VRF subscription at [vrf.chain.link](https://vrf.chain.link), then update the `subId` in `HelperConfig.s.sol` with your subscription ID.

```bash
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

After deploying, add your contract address as a consumer on the Chainlink VRF dashboard.

---

## Contract Overview

### Raffle Lifecycle

```
Open -> Calculating -> Open -> ...
```

- Open: players can enter, waiting for the interval to elapse
- Calculating: winner selection in progress, new entries blocked

### State

| Variable                | Type                | Description                                    |
| ----------------------- | ------------------- | ---------------------------------------------- |
| `i_entranceFee`         | `uint256`           | Fixed ETH amount required to enter             |
| `i_interval`            | `uint256`           | Minimum seconds between rounds                 |
| `i_keyHash`             | `bytes32`           | Chainlink gas lane key hash                    |
| `i_subId`               | `uint256`           | Chainlink VRF subscription ID                  |
| `i_callbackGasLimit`    | `uint32`            | Gas limit for the VRF callback                 |
| `s_players`             | `address payable[]` | Current round participants                     |
| `s_lastTimeStamp`       | `uint256`           | Timestamp of the last round start              |
| `s_recentWinner`        | `address`           | Address of the most recent winner              |
| `s_state`               | `State`             | Current raffle state (Open or Calculating)     |
| `NUM_WORDS`             | `uint32`            | Number of random words requested (1)           |
| `REQUEST_CONFIRMATIONS` | `uint16`            | Block confirmations before VRF fulfillment (3) |

### Functions

| Function                                 | Visibility          | Description                                                                                |
| ---------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------ |
| `enterRaffle()`                          | `external payable`  | Enters the caller into the current round. Requires minimum ETH and Open state.             |
| `requestWinner()`                        | `external`          | Triggers winner selection. Requires Open state, elapsed interval, and at least one player. |
| `fulfillRandomWords(uint256, uint256[])` | `internal override` | VRF callback. Selects winner, transfers pot, resets state.                                 |
| `getEntranceFee()`                       | `external view`     | Returns the entrance fee in wei                                                            |
| `getInterval()`                          | `external view`     | Returns the round interval in seconds                                                      |
| `getKeyHash()`                           | `external view`     | Returns the Chainlink gas lane key hash                                                    |
| `getSubId()`                             | `external view`     | Returns the VRF subscription ID                                                            |
| `getCallbackGasLimit()`                  | `external view`     | Returns the VRF callback gas limit                                                         |
| `getNumWords()`                          | `external pure`     | Returns the number of random words requested                                               |
| `getReqConfirmations()`                  | `external pure`     | Returns the required block confirmations                                                   |
| `getRaffleState()`                       | `external view`     | Returns the current State enum value                                                       |
| `getPlayer(uint256)`                     | `external view`     | Returns the player address at a given index                                                |
| `getPlayersLength()`                     | `external view`     | Returns the number of current players                                                      |
| `getRecentWinner()`                      | `external view`     | Returns the most recent winner address                                                     |
| `getLastTimestamp()`                     | `external view`     | Returns the timestamp of the last round start                                              |
| `getContractBalance()`                   | `external view`     | Returns the current ETH balance of the contract                                            |

### Custom Errors

| Error                                | When It Triggers                                               |
| ------------------------------------ | -------------------------------------------------------------- |
| `Raffle__NotEnoughEthSent()`         | ETH sent is below the entrance fee                             |
| `Raffle__RaffleNotOpened()`          | enterRaffle() or requestWinner() called when not in Open state |
| `Raffle__NotEnoughTimeHasPassed()`   | requestWinner() called before the interval has elapsed         |
| `Raffle__RaffleHasNoPlayers()`       | requestWinner() called with no players in the array            |
| `Raffle__RaffleHasNoBalance()`       | requestWinner() called with zero contract balance              |
| `Raffle__TransferFailed()`           | ETH transfer to the winner fails                               |
| `Raffle__NoDirectTransfersAllowed()` | ETH sent directly via receive() or fallback()                  |

### Events

| Event                                     | When It Emits                           |
| ----------------------------------------- | --------------------------------------- |
| `NewRaffle(address indexed sender)`       | A player successfully enters the raffle |
| `WinnerRequested(address indexed sender)` | Winner selection is triggered           |
| `WinnerPicked(address indexed winner)`    | A winner is selected and paid           |

---

## HelperConfig

Handles network detection and VRF infrastructure configuration automatically.

| Network       | Chain ID | Behaviour                                                                                  |
| ------------- | -------- | ------------------------------------------------------------------------------------------ |
| Sepolia       | 11155111 | Uses real Chainlink VRF coordinator at 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B          |
| Anvil (local) | 31337    | Deploys VRFCoordinatorV2_5Mock and LinkToken, creates and funds subscription automatically |

The deploy script handles subscription creation, funding, and consumer registration automatically on Anvil. On Sepolia these steps are performed manually via the Chainlink VRF dashboard.

---

## Tests

29 tests covering all contract functions and post-settlement state.

### General

| Test                          | What It Checks                   |
| ----------------------------- | -------------------------------- |
| `testRaffleStartsInOpenState` | Raffle initialises in Open state |

### enterRaffle()

| Test                                  | What It Checks                                      |
| ------------------------------------- | --------------------------------------------------- |
| `testRevertsIfNotEnoughEthSent`       | Reverts when ETH sent is below the entrance fee     |
| `testRevertsIfStateNotOpened`         | Reverts when raffle is in Calculating state         |
| `testPlayerGetsAddedToArray`          | Player address is stored in the players array       |
| `testEmitsNewRaffleWhenRaffleEntered` | NewRaffle event is emitted with the correct address |

### requestWinner()

| Test                                  | What It Checks                                            |
| ------------------------------------- | --------------------------------------------------------- |
| `testRevertsIfNotEnoughTimeHasPassed` | Reverts when interval has not elapsed                     |
| `testRevertsIfNoPlayersAddedToArray`  | Reverts when no players have entered                      |
| `testSetsStateToCalculating`          | State changes to Calculating after a successful call      |
| `testEmitsWinnerRequested`            | WinnerRequested event is emitted with the correct address |

### fulfillRandomWords()

| Test                                       | What It Checks                                                |
| ------------------------------------------ | ------------------------------------------------------------- |
| `testFulfillRandomWordsPicksWinner`        | Correct winner is selected from the players array             |
| `testFulfillRandomWordsPicksWinnerAndPays` | Contract balance is zero after the winner is paid             |
| `testRecentWinnerGetsSetProperly`          | Recent winner address is stored correctly                     |
| `testRaffleStateGetsBackToOpened`          | State resets to Open after settlement                         |
| `testPlayerArrayResetsToZeroLength`        | Players array is cleared after settlement                     |
| `testLastTimestampResets`                  | Last timestamp is updated after settlement                    |
| `testEmitsWinnerPicked`                    | WinnerPicked event is emitted with the correct winner address |

### Getter functions

| Test                                       | What It Checks                                        |
| ------------------------------------------ | ----------------------------------------------------- |
| `testGetEntranceFee`                       | Entrance fee matches config value                     |
| `testGetInterval`                          | Interval matches config value                         |
| `testGetKeyHash`                           | Key hash matches config value                         |
| `testGetCallbackGasLimit`                  | Callback gas limit matches config value               |
| `testGetNumWords`                          | Number of words is 1                                  |
| `testGetReqConfirmations`                  | Request confirmations is 3                            |
| `testGetRaffleStateIsOpenOnDeploy`         | Initial state is Open                                 |
| `testGetLastTimestamp`                     | Last timestamp is set at deployment                   |
| `testGetContractBalanceIsZeroOnDeploy`     | Initial balance is zero                               |
| `testGetRecentWinnerIsZeroAddressOnDeploy` | Recent winner is zero address on deploy               |
| `testGetPlayerReturnsCorrectAddress`       | Player address is retrievable by index                |
| `testGetSubId`                             | Subscription ID is greater than zero after deployment |

---

## Dependencies

- [Chainlink VRF V2.5](https://docs.chain.link/vrf) — verifiable random number generation
- [Solady ERC20](https://github.com/vectorized/solady) — mock LINK token implementation

---

## License

MIT
