// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Movie} from "./Movie.sol";

/// @title MovieFactory
/// @notice Deploys MovieToken contracts and stores registry
contract MovieFactory is Ownable {
    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    struct MovieInfo {
        address tokenAddress;
        address owner;
        string name;
        string symbol;
        uint256 totalAmount;
    }

    MovieInfo[] private movies;

    event MovieTokenCreated(
        address indexed tokenAddress,
        address indexed owner,
        string name,
        string symbol,
        uint256 totalAmount,
        uint256 endTime,
        uint256 numOfTotalAllotments // string memory url
    );

    constructor() Ownable(msg.sender) {}

    /// @notice Create a MovieToken for a movie project
    /// @param name token name
    /// @param symbol token symbol
    function createMovieToken(
        string memory name,
        string memory symbol,
        uint256 totalAmount,
        uint256 endTime,
        uint256 numOfTotalAllotments // string memory url
    ) external {
        Movie token = new Movie(
            msg.sender,
            name,
            symbol,
            totalAmount,
            endTime,
            numOfTotalAllotments
        );

        movies.push(
            MovieInfo({
                tokenAddress: address(token),
                owner: msg.sender,
                name: name,
                symbol: symbol,
                totalAmount: totalAmount
            })
        );

        emit MovieTokenCreated(
            address(token),
            msg.sender,
            name,
            symbol,
            totalAmount,
            endTime,
            numOfTotalAllotments
        );
    }

    function totalMovies() external view returns (uint256) {
        return movies.length;
    }

    function getMovieByIndex(
        uint256 index
    ) external view returns (MovieInfo memory) {
        // require(index < movies.length, "Index out of bounds");
        return movies[index];
    }
}
