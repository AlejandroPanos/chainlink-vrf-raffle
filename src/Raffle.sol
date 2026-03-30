// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleNotOpened();

    /* Type declarations */
    enum State {
        Open,
        Calculating
    }

    /* State variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash; // Gas lane
    uint256 private immutable i_subId;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    address[] private s_players;
    uint256 private s_lastTimeStamp;
    State private s_state;

    /* Events */
    event NewRaffle(address indexed sender);

    /* Constructor */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 keyHash,
        uint256 subId,
        uint32 callbackGasLimit,
        address vrfCoordinator
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = keyHash;
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
    }

    /* Functions */
    function enterRaffle() external payable {
        // Checks
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }

        if (s_state != Raffle.State.Open) {
            revert Raffle__RaffleNotOpened();
        }

        // Effects
        s_players.push(msg.sender);

        // Interactions
        emit NewRaffle(msg.sender);
    }

    function requestWinner() external {
        // Checks

        // Effects

        // Interactions
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}

    /* Getter functions */
}
