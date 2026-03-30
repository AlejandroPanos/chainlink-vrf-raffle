// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    /* Type variables */
    /**
     * @dev The NetworkConfig struct needs all the data that is present
     * in the Raffle constructor to pass to the deploy script.
     * Additionally, we pass:
     * 1. address link: address of the LINK token on current network
     * 2. address account: address used as the broadcaster for deployment transactions
     */
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        bytes32 keyHash;
        uint256 subId;
        uint32 callbackGasLimit;
        address vrfCoordinator;
        address link;
        address account;
    }

    /* State variables */
    NetworkConfig public activeNetworkConfig;
    uint256 private constant SEPOLIA_ID = 11155111;
    bytes32 public constant DEFAULT_KEYHASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    address public constant SEPOLIA_VRF = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    address public constant SEPOLIA_LINK_TOKEN = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address private constant SEPOLIA_ACCOUNT = 0x4E80efD8E18250aCD4B14C8e9F873985c3eD6b41;

    uint96 public constant BASE_FEE = 0.5 ether;
    uint96 public constant GAS_PRICE = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;
    address public constant ANVIL_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    /* Constructor */
    constructor() {
        if (block.chainid == SEPOLIA_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    /* Functions */
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            keyHash: DEFAULT_KEYHASH,
            subId: 0,
            callbackGasLimit: 500000,
            vrfCoordinator: SEPOLIA_VRF,
            link: SEPOLIA_LINK_TOKEN,
            account: SEPOLIA_ACCOUNT
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mock = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            keyHash: DEFAULT_KEYHASH,
            subId: 0,
            callbackGasLimit: 500000,
            vrfCoordinator: address(mock),
            link: address(link),
            account: ANVIL_DEFAULT_SENDER
        });
    }

    /* Getter function */
    function getConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
