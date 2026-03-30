// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract TestRaffle is Test {
    /* Instantiate new contracts */
    Raffle raffle;
    HelperConfig helperConfig;

    /* Local variables */
    address USER = makeAddr("USER");
    uint256 public constant DEAL = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    bytes32 keyHash;
    uint256 subId;
    uint32 callbackGasLimit;
    address vrfCoordinator;

    /* Events */
    event NewRaffle(address indexed sender);
    event WinnerRequested(address indexed sender);
    event WinnerPicked(address indexed winner);

    /* Set up function */
    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (raffle, helperConfig) = deploy.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        keyHash = config.keyHash;
        callbackGasLimit = config.callbackGasLimit;
        subId = config.subId;
        vrfCoordinator = config.vrfCoordinator;
        vm.deal(USER, DEAL);
    }

    /* General testing functions */
    function testRaffleStartsInOpenState() public view {
        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.State.Open));
    }
}
