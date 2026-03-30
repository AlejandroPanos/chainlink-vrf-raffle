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
    uint256 public constant SEND_VALUE = 1 ether;
    uint256 public constant LOWER_SEND_VALUE = 0.001 ether;

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

    /* Enter raffle tests */
    function testRevertsIfNotEnoughEthSent() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);

        // Act / Assert
        raffle.enterRaffle{value: LOWER_SEND_VALUE}();
    }

    function testRevertsIfStateNotOpened() public {
        // Arrange
        vm.prank(USER);
        raffle.enterRaffle{value: SEND_VALUE}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.requestWinner();

        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpened.selector);

        // Act / Assert
        raffle.enterRaffle{value: SEND_VALUE}();
    }

    function testPlayerGetsAddedToArray() public {
        // Arrange
        vm.prank(USER);

        // Act
        raffle.enterRaffle{value: SEND_VALUE}();

        // Assert
        assertEq(raffle.getPlayer(0), USER);
    }

    function testEmitsNewRaffleWhenRaffleEntered() public {
        // Arrange
        vm.prank(USER);

        // Act
        vm.expectEmit(true, false, false, false);
        emit NewRaffle(USER);

        // Assert
        raffle.enterRaffle{value: SEND_VALUE}();
    }

    /* Request winner tests */
    function testRevertsIfStateNotOpenedWhenCalled() public {
        // Arrange
        vm.prank(USER);
        raffle.enterRaffle{value: SEND_VALUE}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.requestWinner();

        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpened.selector);

        // Act / Assert
        raffle.requestWinner();
    }

    function testRevertsIfNotEnoughTimeHasPassed() public {
        // Arrange
        vm.prank(USER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.expectRevert(Raffle.Raffle__NotEnoughTimeHasPassed.selector);

        // Act / Assert
        raffle.requestWinner();
    }

    function testRevertsIfNoPlayersAddedToArray() public {
        // Arrange
        vm.prank(USER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.expectRevert(Raffle.Raffle__RaffleHasNoPlayers.selector);

        // Act / Assert
        raffle.requestWinner();
    }

    function testSetsStateToCalculating() public {
        // Arrange / Act
        vm.startPrank(USER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.requestWinner();
        vm.stopPrank();

        // Assert
        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.State.Calculating));
    }

    function testEmitsWinnerRequested() public {
        // Arrange
        vm.prank(USER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.expectEmit(true, false, false, false);
        emit WinnerRequested(USER);

        // Assert
        vm.prank(USER);
        raffle.requestWinner();
    }
}
