// SPDX-License-Identifier: MIT LICENSE

/*
███████╗██╗░░░██╗██╗██╗░░░░░██╗░░██╗░█████╗░███╗░░██╗░██████╗░░██████╗
██╔════╝██║░░░██║██║██║░░░░░██║░██╔╝██╔══██╗████╗░██║██╔════╝░██╔════╝
█████╗░░╚██╗░██╔╝██║██║░░░░░█████═╝░██║░░██║██╔██╗██║██║░░██╗░╚█████╗░
██╔══╝░░░╚████╔╝░██║██║░░░░░██╔═██╗░██║░░██║██║╚████║██║░░╚██╗░╚═══██╗
███████╗░░╚██╔╝░░██║███████╗██║░╚██╗╚█████╔╝██║░╚███║╚██████╔╝██████╔╝
╚══════╝░░░╚═╝░░░╚═╝╚══════╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░╚═════╝░╚═════╝░
*/

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes fuctions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract EVIL is ERC20, ERC20Burnable, Ownable, AutomationCompatibleInterface {
    
    uint public counter;
    uint public immutable interval;
    uint public lastTimeStamp;
    int public currentPrice;
    address[] public funders;
    AggregatorV3Interface internal priceFeed;
    uint public updateInterval;
    
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => bool) controllers;
    uint private _totalSupply=150000000*10**18;
    uint256 private MAXSUP;
    uint256 constant MAXIMUMSUPPLY=150000000*10**18;

    constructor() ERC20("EVIL", "EKT") { 
        // Sets the keeper update interval.
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        counter = 0;
        // set the price feed address to
        // MATIC/USD Price Feed Contract Address on Polygon: https://polygonscan.com/address/0xF9680D99D6C9589e2a93a78A04A279e509205945
        // or the MockPriceFeed Contract
        priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        currentPrice = getLatestPrice();
        _mint(msg.sender, 21666666 * 10 ** 18);
    }

    function count() external {
        counter = counter +1;
    }

    function getLatestPrice() public view returns (int) { 
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = "";
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
        }
    }

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require((MAXSUP+amount)<=MAXIMUMSUPPLY,"Maximum supply has been reached");
        _totalSupply = _totalSupply.add(amount);
        MAXSUP=MAXSUP.add(amount);
        _balances[to] = _balances[to].add(amount);
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public  pure returns (uint256) {
        return MAXIMUMSUPPLY;
    }
}