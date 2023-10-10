// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
  
  /**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

  // Import the IERC20 interface if not in the same file
  interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface SpunkyVestingContract {
    function addVestingSchedule(
        address _beneficiary,
        uint256 _vestedAmount,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) external;
}

contract SpunkySDXPresale is Ownable {
    string public name;
    IERC20 public spunkyToken;
    SpunkyVestingContract public vestingContract;
    uint256 public presalePriceCents = 1; 
    uint256 public constant CENTS_PER_DOLLAR = 10000; // 10000 cents per dollar
    uint256 public tokensSold;
    bool public presaleStarted;
    bool public presaleEnded;

    AggregatorV3Interface public priceFeed;

   address public constant WITHDRAWAL_ADDRESS = 0x3BC2A9C362e3b0852a92E07c18bf8B3412B893bD;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event PresaleStarted(bool presaleStarted);
    event PresaleEnded(bool presaleEnded);
    event PresalePriceUpdated(uint256 newPriceCents);

    constructor(address _vestingContractAddress, address _spunkyTokenAddress) 
    {
        name = "SpunkySDXPresale";
        spunkyToken = IERC20(_spunkyTokenAddress); //spunkysdx token address
        presaleStarted = false;
        presaleEnded = false;

         //Chainlink Aggregator contract address
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        vestingContract = SpunkyVestingContract(_vestingContractAddress);
    }

    modifier presaleActive() {
        require(presaleStarted, "Presale has not started");
        require(!presaleEnded, "Presale has ended");
        _;
    }

    // Function to start the presale
    function startPresale() external onlyOwner {
        require(!presaleStarted, "Presale already started");
        presaleStarted = true;
        emit PresaleStarted(presaleStarted);
    }

    // Function to end the presale
    function endPresale() external onlyOwner presaleActive {
        presaleEnded = true;
        emit PresaleEnded(presaleEnded);
    }

     function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed");
        return uint256(price);
    }

      // Function to buy tokens and then release on 25% of the 
    function buyTokens() public payable presaleActive {
         require(msg.value > 0, "No Ether sent");
        require(msg.sender != owner(), "Contract owner cannot participate");

        // Check if the presale is ongoing
        if (presaleStarted == true) {
            uint256 ethPrice = getETHPrice(); // Get the current ETH price in USD
            require(msg.sender != owner(), "Contract owner cannot participate");
            uint256 tokensToBuy = (msg.value * ethPrice * presalePriceCents) / (CENTS_PER_DOLLAR * 1 ether);

            // Check if the presale allocation is sufficient
            require(
                spunkyToken.balanceOf(address(this)) >= tokensToBuy,
                "Not enough presale tokens available"
            );

              // Check if the purchase would exceed the maximum holding
           uint256 totalSupply = spunkyToken.totalSupply();
           uint256 MAX_HOLDING = (totalSupply * 5) / 100;
           require(
             spunkyToken.balanceOf(msg.sender) + tokensToBuy <= MAX_HOLDING,
             "Purchase would exceed maximum holding per address"
           );

            // Calculate vested amounts
            uint256 immediateReleaseAmount = (tokensToBuy * 1) / 4;
            uint256 vestedAmount = (tokensToBuy * 3) / 4; // 75%
            
            // Transfer the immediate release portion to buyer
            spunkyToken.transfer(msg.sender, immediateReleaseAmount);

            // Set up the vesting schedule for the user's vested amount, over 5 months
            uint256 cliffDuration = 0; // No cliff for presale
            uint256 vestingDuration = 30 days * 5; // 5 months
            uint256 vestingStart = block.timestamp;
            uint256 vestingEnd = vestingStart + vestingDuration;
            uint256 vestingInterval = (vestingEnd - vestingStart) / 5; // 5 vesting periods
            uint256[] memory vestingAmounts = new uint256[](5);
            uint256[] memory vestingTimes = new uint256[](5);
            for (uint256 i = 0; i < 5; i++) {
                vestingAmounts[i] = vestedAmount / 5;
                vestingTimes[i] = vestingStart + (vestingInterval * i);
            }
             vestingContract.addVestingSchedule(
                msg.sender,
                vestedAmount,
                cliffDuration,
                vestingDuration
            );
            emit TokensPurchased(msg.sender, immediateReleaseAmount);
        } else {
            // If the presale is over, refund the Ether
            payable(msg.sender).transfer(msg.value);
        }
    }

     receive() external payable {
        buyTokens();
    }

    function updatePresalePrice(uint256 newPriceCents) external onlyOwner {
    require(newPriceCents > 0, "Price must be greater than zero");
    presalePriceCents = newPriceCents;
    emit PresalePriceUpdated(newPriceCents);
}

    // Function to withdraw Ether from the contract
    function withdrawEther() external onlyOwner {
        payable(WITHDRAWAL_ADDRESS).transfer(address(this).balance);
    }

    // Function to withdraw unsold tokens from the contract
    function withdrawTokens() external onlyOwner {
        uint256 remainingTokens = spunkyToken.balanceOf(address(this));
        spunkyToken.transfer(owner(), remainingTokens);
    }
}
