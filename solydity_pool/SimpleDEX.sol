// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleDEX is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed to, uint256 amountA, uint256 amountB);
    event TokenSwapped(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient reserves");

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be > 0");
        tokenA.transferFrom(msg.sender, address(this), amountAIn);

        uint256 amountBOut = getOutputAmount(amountAIn, reserveA, reserveB);
        require(amountBOut <= reserveB, "Not enough liquidity for B");

        reserveA += amountAIn;
        reserveB -= amountBOut;

        tokenB.transfer(msg.sender, amountBOut);

        emit TokenSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be > 0");
        tokenB.transferFrom(msg.sender, address(this), amountBIn);

        uint256 amountAOut = getOutputAmount(amountBIn, reserveB, reserveA);
        require(amountAOut <= reserveA, "Not enough liquidity for A");

        reserveB += amountBIn;
        reserveA -= amountAOut;

        tokenA.transfer(msg.sender, amountAOut);

        emit TokenSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    function getOutputAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) internal pure returns (uint256) {
        // Fórmula del producto constante sin comisión: (x + dx)(y - dy) = xy
        uint256 inputAmountWithFee = inputAmount; // puedes aplicar fee aquí si quieres
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = inputReserve + inputAmountWithFee;
        return numerator / denominator;
    }

    function getPrice(address _token) external view returns (uint256) {
        if (_token == address(tokenA)) {
            return reserveB * 1e18 / reserveA; // precio de A en términos de B
        } else if (_token == address(tokenB)) {
            return reserveA * 1e18 / reserveB; // precio de B en términos de A
        } else {
            revert("Unsupported token");
        }
    }
}
