// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {OlympiaMemberNFT} from "../src/OlympiaMemberNFT.sol";
import {DGovernor} from "../src/DGovernor.sol";
import {Timelock} from "../src/Timelock.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract DeployOlympia is Script {
    function run() external {
        address deployer = msg.sender;
        console.log("Deployer:", deployer);

        vm.startBroadcast();

        // 1. Deploy soulbound membership NFT
        OlympiaMemberNFT nft = new OlympiaMemberNFT(deployer);
        console.log("OlympiaMemberNFT:", address(nft));

        // 2. Deploy Timelock (60s delay for testnet, deployer as initial admin)
        address[] memory empty = new address[](0);
        Timelock timelock = new Timelock(60, empty, empty, deployer);
        console.log("Timelock:", address(timelock));

        // 3. Deploy Governor
        DGovernor governor = new DGovernor(nft, timelock);
        console.log("DGovernor:", address(governor));

        // 4. Grant roles: Governor = proposer, anyone = executor
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 cancellerRole = timelock.CANCELLER_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(cancellerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // anyone can execute

        // 5. Mint member NFT to deployer (first member)
        uint256 tokenId = nft.mint(deployer);
        console.log("Minted member NFT #%d to deployer", tokenId);

        vm.stopBroadcast();

        console.log("--- Deployment Summary ---");
        console.log("OlympiaMemberNFT:", address(nft));
        console.log("Timelock:", address(timelock));
        console.log("DGovernor:", address(governor));
    }
}
