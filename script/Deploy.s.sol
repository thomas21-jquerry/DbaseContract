// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";

import { IUniswapV2Factory } from "./../src/interfaces/UniswapV2/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "src/interfaces/UniswapV2/IUniswapV2Router02.sol";

import { WrappedPonzioTheCat } from "src/WrappedPonzioTheCat.sol";
import { PonzioTheCat } from "src/PonzioTheCat.sol";
import { Router } from "src/Router.sol";
import { Stake } from "src/Stake.sol";

/**
 * @title DeployScript
 */
contract Deploy is Script {
    function run()
        external
        returns (
            PonzioTheCat ponzio,
            Stake stake,
            Router router,
            WrappedPonzioTheCat wrappedPonzioTheCat,
            address uniV2PairAddr
        )
    {
        address DEPLOYER = vm.envAddress("DEPLOYER_ADDRESS");
        address WETH_ADDRESS = 0x4200000000000000000000000000000000000006;

        uint256 ethAmountUniV2 = 1 ether;
        require(address(DEPLOYER).balance >= ethAmountUniV2, "Invalid balance of ETH");

        vm.startBroadcast(DEPLOYER);

        ponzio = new PonzioTheCat();
        require(ponzio.balanceOf(DEPLOYER) == ponzio.INITIAL_SUPPLY(), "Invalid balance of PonzioTheCat");

        wrappedPonzioTheCat = new WrappedPonzioTheCat(ponzio);

        uniV2PairAddr = _createUniV2Pool(ponzio, ponzio.INITIAL_SUPPLY(), WETH_ADDRESS, ethAmountUniV2, DEPLOYER);

        router = new Router(uniV2PairAddr, address(ponzio));
        stake = new Stake(uniV2PairAddr, address(wrappedPonzioTheCat));

        ponzio.initialize(address(stake), uniV2PairAddr);

        vm.stopBroadcast();
    }

    function _createUniV2Pool(
        PonzioTheCat ponzio,
        uint256 ponzioAmount,
        address wethAddr,
        uint256 ethAmount,
        address deployer
    ) internal returns (address uniV2PairAddr_) {
        IUniswapV2Factory uniV2Factory = IUniswapV2Factory(0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6);
        IUniswapV2Router02 router = IUniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24);

        ponzio.approve(address(router), UINT256_MAX);
        router.addLiquidityETH{ value: ethAmount }(
            address(ponzio), ponzioAmount, ponzioAmount, ethAmount, deployer, block.timestamp + 10 minutes
        );

        uniV2PairAddr_ = uniV2Factory.getPair(address(ponzio), wethAddr);
    }
}
