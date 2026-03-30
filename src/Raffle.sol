// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleNotOpened();
    error Raffle__NotEnoughTimeHasPassed();
    error Raffle__RaffleHasNoBalance();
    error Raffle__RaffleHasNoPlayers();
    error Raffle__TransferFailed();

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

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    State private s_state;

    /* Events */
    event NewRaffle(address indexed sender);
    event WinnerRequested(address indexed sender);
    event WinnerPicked(address indexed winner);

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
        s_players.push(payable(msg.sender));

        // Interactions
        emit NewRaffle(msg.sender);
    }

    function requestWinner() external {
        // Checks
        if (s_state != Raffle.State.Open) {
            revert Raffle__RaffleNotOpened();
        }

        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert Raffle__NotEnoughTimeHasPassed();
        }

        if (address(this).balance == 0) {
            revert Raffle__RaffleHasNoBalance();
        }

        if (s_players.length == 0) {
            revert Raffle__RaffleHasNoPlayers();
        }

        // Effects
        s_state = Raffle.State.Calculating;

        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        // Interactions
        emit WinnerRequested(msg.sender);
    }

    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    )
        internal
        override
    {
        // Effects
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        uint256 amount = address(this).balance;

        s_recentWinner = winner;
        s_state = Raffle.State.Open;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        // Interactions
        (bool success,) = winner.call{value: amount}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit WinnerPicked(winner);
    }

    /* Receive & Fallback */

    /* Getter functions */
}
