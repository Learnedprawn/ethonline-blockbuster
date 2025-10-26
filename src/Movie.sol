// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IEntropyV2} from "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";

contract Movie is
    IEntropyConsumer,
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    Ownable,
    ERC20Permit
{
    IERC20 public immutable pyusd; // PYUSD token contract
    IEntropyV2 private s_entropy;
    address pyusdAddress = 0x177d17c1B7C3E7975B9E8762F9357835aa0C0240;
    uint256 PRECISION = 10 ** decimals();

    uint256 totalAmount;
    uint256 marginAmount;
    uint256 numOfAllotments;
    uint256 lotPrice;
    uint256 endTime;
    string public url;

    address[] allotmentList;
    address[] nonAllotmentList;
    address[] winners;

    event RequestResultCalculation(uint64 indexed sequenceNumber);
    event MintedWithPYUSD(
        address indexed buyer,
        uint256 pyusdAmount,
        uint256 mintedTokens
    );
    event WinnerSelected(address indexed winner, address indexed movieAddress);

    event Launch(string indexed newUrl);
    event Staked(
        address indexed staker,
        address indexed movie,
        uint256 numOfAllotments,
        string tokenName
    );

    constructor(
        address _initialOwner,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalAmount,
        uint256 _endTime,
        uint256 _numOfTotalAllotments
    )
        // string memory _url
        ERC20(_tokenName, _tokenSymbol)
        Ownable(_initialOwner)
        ERC20Permit(_tokenName)
    {
        pyusd = IERC20(pyusdAddress);
        totalAmount = _totalAmount;
        endTime = block.timestamp + _endTime;
        numOfAllotments = _numOfTotalAllotments;
        lotPrice = totalAmount / numOfAllotments;
        s_entropy = IEntropyV2(0x4821932D0CDd71225A6d914706A621e0389D7061);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function mintWithPYUSD(uint256 pyusdAmount) external {
        require(pyusdAmount > 0, "Amount must be > 0");

        uint256 tokenAmount = pyusdAmount; // conversion rate
        // require(
        //     tokenAmount + collectedAmount <= totalAmount,
        //     "Must be less than Total Amount "
        // );

        // transfer PYUSD from buyer to the token owner
        bool success = pyusd.transferFrom(
            msg.sender,
            address(this),
            pyusdAmount
        );
        require(success, "PYUSD transfer failed");

        // mint MovieTokens to the buyer
        // collectedAmount += tokenAmount;
        _mint(msg.sender, tokenAmount);

        emit MintedWithPYUSD(msg.sender, pyusdAmount, tokenAmount);
    }

    function stakeForAllotment(uint256 numberOfLots) external {
        // require(block.timestamp <= endTime, "End Time passed.");
        bool success = pyusd.transferFrom(
            msg.sender,
            address(this),
            numberOfLots * lotPrice
        );

        require(success, "PYUSD transfer failed");
        for (uint256 i = 0; i < numberOfLots; i++) {
            allotmentList.push(msg.sender);
        }
        emit Staked(msg.sender, address(this), numberOfLots, name());
    }

    function withdrawByOwnerAndRefund() external onlyOwner {
        uint256 contractBalance = pyusd.balanceOf(address(this));
        require(
            contractBalance >= totalAmount - marginAmount,
            "Contract Balance not yet reached Total Amount"
        );
        for (uint256 i = 0; i < nonAllotmentList.length; i++) {
            if (nonAllotmentList[i] != address(0)) {
                bool success = pyusd.transfer(nonAllotmentList[i], lotPrice);
                require(success, "PYUSD transfer failed");
            }
        }

        bool success = pyusd.transfer(owner(), totalAmount);
        require(success, "PYUSD transfer failed");
    }

    function launch(string memory newUrl) external onlyOwner {
        url = newUrl;

        emit Launch(newUrl);
    }

    function refund() external {
        uint256 contractBalance = pyusd.balanceOf(address(this));
        require(block.timestamp >= endTime, "End Time passed.");
        require(
            contractBalance >= totalAmount - marginAmount,
            "Contract Balance not reached Total Amount"
        );

        for (uint256 i = 0; i < allotmentList.length; i++) {
            bool success = pyusd.transfer(allotmentList[i], lotPrice);
            require(success, "PYUSD transfer failed");
        }
    }

    function calculateResultRandomly() external payable {
        require(block.timestamp >= endTime, "End Time Not yet Passed.");
        uint256 fee = s_entropy.getFeeV2();
        uint64 sequenceNumber = s_entropy.requestV2{value: fee}();

        emit RequestResultCalculation(sequenceNumber);
    }

    function entropyCallback(
        uint64 sequenceNumber,
        address provider,
        bytes32 randomNumber
    ) internal override {
        uint8 nonce = 0;
        nonAllotmentList = allotmentList;

        while (numOfAllotments != winners.length) {
            nonce++;
            uint256 newRandom = uint256(
                keccak256(abi.encodePacked(randomNumber, nonce))
            ) % nonAllotmentList.length;

            if (nonAllotmentList[newRandom] == address(0)) {
                continue;
            }

            winners.push(nonAllotmentList[newRandom]);
            emit WinnerSelected(nonAllotmentList[newRandom], address(this));
            nonAllotmentList[newRandom] = address(0);
        }
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    // Public functions
    function getEndTime() public view {
        block.timestamp + endTime;
    }

    function getEntropy() internal view override returns (address) {
        return address(s_entropy);
    }

    function getEntropyFees() public view returns (uint256) {
        return s_entropy.getFeeV2();
    }
}
