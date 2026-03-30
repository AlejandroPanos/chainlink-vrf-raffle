// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Raffle {
    /* Errors */
    error Raffle__RaffleCurrentlyCalculating();

    /* Type declarations */
    enum State {
        Open,
        Calculating
    }

    /* State variables */
    address private immutable i_owner;

    /* Events */
    event NewRaffle(address indexed sender);

    /* Constructor */
    constructor() {
        i_owner = msg.sender;
    }

    /* Functions */
    function enterRaffle() external {}

    /* Getter functions */
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
