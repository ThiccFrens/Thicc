//  SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract THICCETH is IERC20 {
    using SafeMath for uint256;
    using Address for address;

    address constant ThiccFund = 0x8b694C1c3339B77148614A0334D93453873a0148;
    address constant Competitions = 0x29c7D6de798821013f6Bfd9EB82BC81814DCC745;
    address private GameRewards = 0x683dea848582eC23efbfF4bbE9F870C5C238844F;
    address constant Marketing = 0x33663752493958b7A7B19De530bd03582326C484;
    address constant ProjectExpansion = 0xCF3584eD03Fb17637981b77d9a352C793EA8d7Ad;
    address private stakingReward= 0x5eF52D199F2d5cb5Fd5af0e104FD05Dc7E7E0B36;


    // here we store Token holder who have more than one THICC token.
    address[] private TokenHolders;
    // here we store partner contract address.
    address private PartnerContractAddress;
    // here we store the NFT holder address
    address private nftContractAddress;
    // here we store bridge contract address.
    address private ethBridgeContract;

    uint256 constant holderFeePercent = 2;
    uint256 constant nftHolderFeePercent = 2;
    uint256 constant partnerHoldersFeePercent = 5;
    uint256 constant GameRewardPercent = 1;

    address private immutable owner;

    mapping(address => bool) private _isBots;
    mapping(address => bool) private _HolderExist;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 constant minimumTokenHolder = 1 * (10**_decimals);
    uint256 private constant MAX = ~uint256(0);
    // total supply is ten trillion
    uint256 constant _tTotal = 10000000000000 * 10**_decimals; 
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string constant _name = "Thicc Token";
    string constant _symbol = "THICC";
    uint8 constant _decimals = 9;

    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    // This _liquidityFee is for normal user
    uint256 private _liquidityFee = 10;
    // This _botliquidityFee is for bot
    uint256 constant _botliquidityFee = 30;

    uint256 private _previousLiquidityFee = _liquidityFee;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool tradingOpen = false;

    constructor() {
        owner = _msgSender();

        uint256 rToken = _rTotal / 100;
        uint256 tToken = _tTotal / 100;

        uint256 rTokenOnePercent = rToken * 1;
        uint256 tTokenOnePercent = tToken * 1;

        uint256 rTokenTwoPercent = rToken * 2;
        uint256 tTokenTwoPercent = tToken * 2;

        uint256 rTokenFourPercent = rToken *4 ;
        uint256 tTokenFourPercent = tToken *4 ;

        uint256 rTokenEightPercent = rToken * 8;
        uint256 tTokenEightPercent = tToken * 8;

        uint256 rTokenEightyPercent = rToken * 80;
        uint256 tTokenEightyPercent = tToken * 80;

        _rOwned[_msgSender()] = rTokenEightyPercent;
        emit Transfer(address(0), _msgSender(), tTokenEightyPercent);

         _rOwned[stakingReward] = rTokenEightPercent;
        emit Transfer(address(0),stakingReward, tTokenEightPercent);


        _rOwned[ThiccFund] = rTokenOnePercent;
        emit Transfer(address(0), ThiccFund, tTokenOnePercent);

        _rOwned[Competitions] = rTokenOnePercent;
        emit Transfer(address(0), Competitions, tTokenOnePercent);

        _rOwned[GameRewards] = rTokenFourPercent;
        emit Transfer(address(0), GameRewards, tTokenFourPercent);

        _rOwned[Marketing] = rTokenTwoPercent;
        emit Transfer(address(0), Marketing, tTokenTwoPercent);

        _rOwned[ProjectExpansion] = rTokenFourPercent;
        emit Transfer(address(0), ProjectExpansion, tTokenFourPercent);
        TokenHolders.push(ThiccFund);
        TokenHolders.push(Competitions);
        TokenHolders.push(GameRewards);
        TokenHolders.push(Marketing);
        TokenHolders.push(ProjectExpansion);
        TokenHolders.push(stakingReward);

    }

    function initContract() external onlyOwner {
        // Uniswap V2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[ThiccFund] = true;
        _isExcludedFromFee[Competitions] = true;
        _isExcludedFromFee[GameRewards] = true;
        _isExcludedFromFee[Marketing] = true;
        _isExcludedFromFee[ProjectExpansion] = true;
        _isExcludedFromFee[stakingReward] = true;
        _isExcludedFromFee[nftContractAddress] = true;
        _isExcludedFromFee[PartnerContractAddress] = true;
        
    }

    function openTrading() external onlyOwner {
        _liquidityFee = _previousLiquidityFee;
        _taxFee = _previousTaxFee;
        tradingOpen = true;
    }
    function getPartnerContract() external view returns(address){
        return PartnerContractAddress;

    }
    function getNFTContract() external view returns(address){
        return nftContractAddress;
        
    }
    function getEthBridgeContract() external view returns(address){
        return ethBridgeContract;
        
    }
    function getStakingReward() external view returns(address){
        return stakingReward;
    }

    function ContractOwner() public view virtual returns (address) {
        return owner;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    modifier onlyOwner() {
        require(
            ContractOwner() == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    modifier zeroAddress(address _account) {
        require(_account != address(0), "address can't be zero address");
        _;
    }

    // This function is used to change bridge Contract address
    function addBridgeContract(address _bridgeAddress)
        external
        onlyOwner
        zeroAddress(_bridgeAddress)
    {
        ethBridgeContract = _bridgeAddress;
        _isExcludedFromFee[_bridgeAddress]= true;

    }

    // This function is used to change GameRewards address
    function GameRewardsContract(address _changeGameRewardAddress)
        external
        onlyOwner
        zeroAddress(_changeGameRewardAddress)
    {
        GameRewards = _changeGameRewardAddress;
        _isExcludedFromFee[_changeGameRewardAddress]= true;
    }
    function stakingRewardContract(address _changeStakingAddress) external onlyOwner zeroAddress(_changeStakingAddress){
        stakingReward=_changeStakingAddress;
        _isExcludedFromFee[_changeStakingAddress]= true;
        
             

    }

    // here we add/change partner contract address
    function addPartnerContractAddress(address _partnerContractaddress)
        external
        onlyOwner
        zeroAddress(_partnerContractaddress)
        returns (bool)
    {
        PartnerContractAddress = _partnerContractaddress;
        _isExcludedFromFee[_partnerContractaddress]= true;

        return true;
    }

    // here we add bot address manually
    function BotAddress(address _BotAddress)
        external
        zeroAddress(_BotAddress)
        onlyOwner
        returns (bool)
    {
        _isBots[_BotAddress] = true;
        return true;
    }

    // here we add token holder manually to the TokenHolders
    function addTokenHolders(address _tokenHolders)
        external
        onlyOwner
        zeroAddress(_tokenHolders)
        returns (bool)
    {
        TokenHolders.push(_tokenHolders);
        _HolderExist[_tokenHolders] = true;

        return true;
    }

    // This function is used to change/add the NFT holder address.
    function addNftContractAddress(address _nftContractAddress)
        external
        onlyOwner
        zeroAddress(_nftContractAddress)
        returns (address)
    {
        nftContractAddress = _nftContractAddress;
        return nftContractAddress;
    }

    // This function is used to clean token holder manually
    function cleanOldTokenHolders(uint256 size) external onlyOwner {
        address deleteaddress;
        for (uint256 i = 0; i < size; i++) {
            deleteaddress = TokenHolders[i];
            _HolderExist[deleteaddress] = false;
        }
        uint256 j = 0;
        for (uint256 i = size; i < TokenHolders.length; i++) {
            TokenHolders[j] = TokenHolders[i];
            j++;
        }
        for (uint256 k = 0; k < size; k++) {
            TokenHolders.pop();
        }
    }

    //Removing the holder on demand or only creator can call this function in case he thinks some of the liquidity pool or other address should be removed.
    function _removeHolder(address holderAddress) private returns (bool) {
        uint256 holderindex = TokenHolders.length;
        for (uint256 i = 0; i < TokenHolders.length; i++) {
            if (TokenHolders[i] == holderAddress) {
                holderindex = i;
                break;
            }
        }
        if (holderindex == TokenHolders.length) {
            return false;
        }
        if (TokenHolders.length == 1) {
            TokenHolders.pop();
            _HolderExist[holderAddress] = false;
            return true;
        } else if (holderindex == TokenHolders.length - 1) {
            TokenHolders.pop();
            _HolderExist[holderAddress] = false;
            return true;
        } else {
            for (uint256 i = holderindex; i < TokenHolders.length - 1; i++) {
                TokenHolders[i] = TokenHolders[i + 1];
            }
            TokenHolders.pop();
            _HolderExist[holderAddress] = false;
            return true;
        }
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return _tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);

        uint256 balanceOfUser = balanceOf(recipient);
        balanceOfUser = balanceOfUser + amount;

        if (
            balanceOfUser >= minimumTokenHolder &&
            !_isBots[recipient] &&
            !_HolderExist[recipient]
        ) {
            TokenHolders.push(recipient);
            _HolderExist[recipient] = true;
        }
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (msg.sender != ethBridgeContract) {
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
        }
        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal, "Amount greater than rTotal");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = _tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "Cannot approve zero address");
        require(spender != address(0), "Cannot approve zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool isBot = false;

        // buy
        if (
            from == uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_isExcludedFromFee[to]
        ) {
            require(tradingOpen, "Trading not yet enabled.");
        }

        if (!_isBots[from] && _HolderExist[from]) {
            uint256 beforeTransferBalance = balanceOf(from);
            uint256 remainingTokenBalance = beforeTransferBalance - amount;
            if (remainingTokenBalance < minimumTokenHolder) {
                _removeHolder(from);
            }
        }

        bool takeFee = false;

        //take fee only on swaps
        if (
            (from == uniswapV2Pair || to == uniswapV2Pair) &&
            !(_isExcludedFromFee[from] || _isExcludedFromFee[to])
        ) {
            takeFee = true;
        }

        if (_isBots[from] || _isBots[to]) {
            isBot = true;
        }

        _tokenTransfer(from, to, amount, takeFee, isBot);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee,
        bool isBot
    ) private {
        if (!takeFee) _removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, isBot);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, isBot);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, isBot);
        } else {
            _transferStandard(sender, recipient, amount, isBot);
        }

        if (!takeFee) _restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isBot
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount, isBot);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (isBot) {
            _takeBotLiquidity(tLiquidity);
        } else {
            _takeLiquidity(tLiquidity);
        }

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isBot
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount, isBot);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isBot
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount, isBot);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isBot
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount, isBot);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, bool isBot)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount, isBot);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount, bool isBot)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = _calculateTaxFee(tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(tAmount, isBot);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // here we calculate the actual distribution of 10% and 30% liquidity fee
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 onePercentRate = tLiquidity / 10;
        uint256 tLiquidityHolder = onePercentRate * holderFeePercent;
        uint256 tLiquidityPartnerHolder = onePercentRate *
            partnerHoldersFeePercent;
        uint256 tLiquidityNftHolder = onePercentRate * nftHolderFeePercent;
        uint256 tLiquidityGameAmount = onePercentRate * GameRewardPercent;

        // here we calculate 2% liquidity for token holder
        uint256 currentRate = _getRate();
        uint256 rLiquidityHolder = tLiquidityHolder.mul(currentRate);
        uint256 rLiquidityPerHolder = rLiquidityHolder / TokenHolders.length;
        uint256 tLiquidityPerHolder = tLiquidityHolder / TokenHolders.length;
        // here we calculate 5% liquidity for partner holder
        uint256 rLiquidityPartner = tLiquidityPartnerHolder.mul(currentRate);

        // here we calculate 1% liquidity for staking contract.

        uint256 rLiquidityGame = tLiquidityGameAmount.mul(currentRate);

        // here we calculate 2% liquidity for NFT holder

        uint256 rLiquidityNFT = tLiquidityNftHolder.mul(currentRate);

        // here we transfer 2% to NFT contract address
        _rOwned[nftContractAddress] = _rOwned[nftContractAddress].add(
            rLiquidityNFT
        );

        _tOwned[nftContractAddress] = _tOwned[nftContractAddress].add(
            tLiquidityNftHolder
        );

        // here we transfer 1% to game contract address (buy and sell).
        _rOwned[GameRewards] = _rOwned[GameRewards].add(
            rLiquidityGame
        );

        _tOwned[GameRewards] = _tOwned[GameRewards].add(
            tLiquidityGameAmount
        );

        //  here we transfer 2% to token holders

        for (uint256 i = 0; i < TokenHolders.length; i++) {
            _rOwned[TokenHolders[i]] = _rOwned[TokenHolders[i]].add(
                rLiquidityPerHolder
            );

            _tOwned[TokenHolders[i]] = _tOwned[TokenHolders[i]].add(
                tLiquidityPerHolder
            );
        }
        //  here we transfer 5% to PartnerContractAddress  holders

        _rOwned[PartnerContractAddress] = _rOwned[PartnerContractAddress].add(
            rLiquidityPartner
        );
        _tOwned[PartnerContractAddress] = _tOwned[PartnerContractAddress].add(
            tLiquidityPartnerHolder
        );
    }

    function _takeBotLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquiditybotHolder = tLiquidity.mul(currentRate);
        uint256 rLiquidityPerbotHolder = rLiquiditybotHolder /
            TokenHolders.length;
        uint256 tLiquidityPerbotHolder = tLiquidity / TokenHolders.length;

        for (uint256 i = 0; i < TokenHolders.length; i++) {
            _rOwned[TokenHolders[i]] = _rOwned[TokenHolders[i]].add(
                rLiquidityPerbotHolder
            );

            _tOwned[TokenHolders[i]] = _tOwned[TokenHolders[i]].add(
                tLiquidityPerbotHolder
            );
        }
    }

    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function _calculateLiquidityFee(uint256 _amount, bool isBot)
        private
        view
        returns (uint256)
    {
        if (isBot) {
            return _amount.mul(_botliquidityFee).div(10**2);
        } else {
            return _amount.mul(_liquidityFee).div(10**2);
        }
    }

    function _removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function _restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}
}
