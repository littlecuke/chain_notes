// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;


/// @title 简单拍卖
/// @author wuxh
/// @notice 
/// @dev 以下简单的拍卖合约的总体思路是每个人都可以在投标期内发送他们的出价。 
/// @dev 出价已经包含了资金/以太币，来将投标人与他们的投标绑定。 
/// @dev 如果最高出价提高了（被其他出价者的出价超过），之前出价最高的出价者可以拿回她的钱。 
/// @dev 在投标期结束后，受益人需要手动调用合约来接收他的钱 - 合约不能自己激活接收
contract SimpleAuction{

	address payable public beneficiary;

	// unix 时间戳 or 时间段（秒）
	uint public auctionEnd;
	
	// 最高出价人
	address public highestBidder;
	// 最高出价
	uint public highestBid;


	mapping(address => uint) pendingReturns;

	// 拍卖结束标识符
	// 拍卖结束后禁止所有变更
	bool endEd;

	//变更触发事件
	// 有新的出价
	event HighestBidIncreased(address bidder,uint amount);
	// 拍卖结束
	event AuctionEnded(address winner,uint amount);

	 // 以下是所谓的 natspec 注释，可以通过三个斜杠来识别。
    // 当用户被要求确认交易时将显示。

    /// 以受益者地址 `_beneficiary` 的名义，
    /// 创建一个简单的拍卖，拍卖时间为 `_biddingTime` 秒。
    constructor(uint _biddingTime,address payable _beneficiary){
    		beneficiary = _beneficiary;
    		//矿工拿到一个当前时间，然后开始打包，打包的区块的block.timestemp就是矿工提供的那个时间，打包后再进行广播确认
    		// 这里的合约代码讲不通 快时间是固定的 这么加时间参数会越来越大
    		auctionEnd = block.timestamp + _biddingTime;
    }

    //竞拍
    /// 对拍卖进行出价，具体的出价随交易一起发送。
    /// 如果没有在拍卖中胜出，则返还出价。
    function bid()public payable{
		// 参数不是必要的。因为所有的信息已经包含在了交易中。
        // 对于能接收以太币的函数，关键字 payable 是必须的。

    	//判断时间是否已经截止
    	require(block.timestamp <= auctionEnd,"Auction alredy ended.");
    	//判断出价价格是否是否小于目前最高
    	require(msg.value > highestBid,"there already is a highestBid bid.");

		// 存放最高出价
    	if(highestBid != 0){
    		// 返还出价时，简单地直接调用 highestBidder.send(highestBid) 函数，
            // 是有安全风险的，因为它有可能执行一个非信任合约。
            // 更为安全的做法是让接收方自己提取金钱。
    		pendingReturns[highestBidder] +=highestBid;
    	}

    	highestBidder = msg.sender;
    	highestBid = msg.value;	

    	emit HighestBidIncreased(msg.sender,msg.value);
    }

    // 取回出价（目前价格高出之前出价价格时）
    function withdraw() public returns (bool){
    	// 判断是否超出之前出价
    	uint amount = pendingReturns[msg.sender];
    	if(amount > 0){
    		// 这里很重要，首先要设零值。
            // 因为，作为接收调用的一部分，
            // 接收者可以在 `send` 返回之前，重新调用该函数。
            // ？？？换成锁会不会好一点
    		pendingReturns[msg.sender] = 0;

    		if(!payable(msg.sender).send(amount)){
    			// 这里不需抛出异常，只需重置未付款
    			pendingReturns[msg.sender] = amount;
    			return false;
    		}

    	}
    	return true;

    }

    // 拍卖结束、把最高价发给受益人
    function auctionEnded() public {
    	// 检查时间
    	require(block.timestamp >= auctionEnd,"Auction not yet ended.");
    	require(!endEd,"auctionend has already bean called.");
    	// 设置结束

    	endEd = true;
    	emit AuctionEnded(highestBidder,highestBid);
    	// 交互

    	beneficiary.transfer(highestBid);
    }
}

/// @notic ERC20 token标准介绍了一种Transfer事件以及一个transfer()方法。
// 它们的调用语法不完全相同：
// transfer(address to, uint value);
// Transfer(address from, address to, uint256 _value);

// 但是这种相似足够引起混淆。
// 对未来的Solidity程序员来说这是一个很严重的问题，必须避免意外地将外部调用函数映射到一个
// 名字相似的事件上，而这导致了去年的DAO攻击。有人建议在事件名前面加上Log前缀来标识以避免将函数和事件混淆，但是最后还是决定引进一个新的关键字emit。

// 所以：
// event Transfer(address from, address to, uint256 _value);
// // …
// Transfer(from, to, value);
// 就变为了：

// event Transfer(address from, address to, uint256 _value);
// // …
// emit Transfer(from, to, value);

// 这就能够让函数调用和事件日志之间具备了语义上的不同。
