// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(config.vrfCoordinator).createSubscription();
        Raffle raffle = new Raffle(
            config.entranceFee, config.interval, config.keyHash, subId, config.callbackGasLimit, config.vrfCoordinator
        );

        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fundSubscription(subId, 5 ether);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).addConsumer(subId, address(raffle));
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
