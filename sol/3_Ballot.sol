
pragma solidity >=0.7.0 <0.9.0;

//////////////////////////////
// ########  投票合约
// 以下的合约有一些复杂，但展示了很多Solidity的语言特性。它实现了一个投票合约。 当然，电子投票的主要问题是如何将投票权分配给正确的人员以及如何防止被操纵。 
// 我们不会在这里解决所有的问题，但至少我们会展示如何进行委托投票，同时，计票又是 自动和完全透明的 。
// 我们的想法是为每个（投票）表决创建一份合约，为每个选项提供简称。 然后作为合约的创造者——即主席，将给予每个独立的地址以投票权。
// 地址后面的人可以选择自己投票，或者委托给他们信任的人来投票。
// 在投票时间结束时，winningProposal() 将返回获得最多投票的提案。
//////////////////////////////

// @Title: 委托投票
contract Ballot{

	// 投票人
	struct Voter{
		// 计票的权重
		uint weight;
		// true:已投票
		bool voted; 
		// 被委托人
		address delegata;
		// 投票提案的索引
		uint vote;
	}

	// 提案的类型
	struct Proposal{
		// 简称
		bytes32 name;
		// 得票数
		uint voteCount;

	}

	address public chairPerson;

	// 存储地址和Voter
	mapping(address => Voter) public voters;

	// Proposal 数组
	Proposal[] public proposals;

	// 构造方法  
	constructor(byte32[] memory porpssalNames){
		chairPerson = msg.sender;
		voters[chairPerson].weight = 1;
		for (uint i = 0; i < porpssalNames.length; i++) {
			// `Proposal({...})` 创建一个临时 Proposal 对象，
            // `proposals.push(...)` 将其添加到 `proposals` 的末尾
            Proposal.push(Proposal({
            	name: porpssalNames[i],
            	voteCount:0
        	}));
		}
	}

	// 授权 `voter` 对这个（投票）表决进行投票
    // 只有 `chairperson` 可以调用该函数。
	function giveRightToVote(address voter) public{
        // 若 `require` 的第一个参数的计算结果为 `false`，
        // 则终止执行，撤销所有对状态和以太币余额的改动。
        // 在旧版的 EVM 中这曾经会消耗所有 gas，但现在不会了。
        // 使用 require 来检查函数是否被正确地调用，是一个好习惯。
        // 你也可以在 require 的第二个参数中提供一个对错误情况的解释。
		require(
				voter == chairPerson,
				"only chairPerson can give right to vote."
			);
		require(
				!voters[voter].voted,
				"The voter already voted."
			);
		require(voters[voter].weight == 0);
		voters[voter].weight = 1;
	}

    /// 把你的投票委托到投票者 `to`。like ： a 委托b 投票，a的状态会变为已投票，b的权重会加一，由b去投票
    // https://zhuanlan.zhihu.com/p/112286983  storage & memory 
    // 简单概述 ： memory 内存 修改时并不会修改存储的元素，sotrage 存储 修改时会修改状态变量的值
	///////////////////////////////////////////////////////////
	//     require、 assert 与if 的区别
	// 这行代码：
	// if(msg.sender != owner) { throw; }
	// 完全等价于如下三种形式：
	// if(msg.sender != owner) { revert(); }
	// assert(msg.sender == owner);
	// require(msg.sender == owner);
	///////////////////////////////////////////////////////////
	function delegate(address to)public{
		// 引用
		Voter storage sender = voters[msg.sender];
		require(!sender.voted,"you already voted.")

		require(to != msg.sender,"Self-delegation is disallowed.")

       // 委托是可以传递的，只要被委托者 `to` 也设置了委托。
        // 一般来说，这种循环委托是危险的。因为，如果传递的链条太长，
        // 则可能需消耗的gas要多于区块中剩余的（大于区块设置的gasLimit），
        // 这种情况下，委托不会被执行。
        // 而在另一些情况下，如果形成闭环，则会让合约完全卡住。

        // address(0)空地址 类似于 null 、nil 之类的
		while(voters[to].delegation != address(0)){
			to = voters[to].delegationl;
            // 不允许闭环委托
			require(to != msg.sender,"Found loop in delegation.");
		}

        // `sender` 是一个引用, 相当于对 `voters[msg.sender].voted` 进行修改
		sender.voted = true;
		sender.delegate = to;

		Voter storage delegate_ = voters[to];
		if(delegate_.voted){
            // 若被委托者已经投过票了，直接增加得票数
			proposals[delegate_.vote].voteCount += sender.weight;
		}else{
			// 若被委托者还没投票，增加委托者的权重
			delegate_.weight += sender.weight;
		}

	}

    /// 把你的票(包括委托给你的票)，
    /// 投给提案 `proposals[proposal].name`.
	function vote(uint proposal) public{
		Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // 如果 `proposal` 超过了数组的范围，则会自动抛出异常，并恢复所有的改动
        proposals[proposal].voteCount += sender.weight;
	}

	// 统计获得最多投票的提案
	function winningProposal()public view returns(uint winnningProposal_){
			uint winnningProposalCount = 0;
			for(uint i = 0; i< proposal.length; i++){
				if(proposal[i].voteCount > winnningProposalCount){
					winnningProposalCount = proposal[i].voteCount;
					winnningProposal_ = i;
				}
			}
	}

    // 调用 winningProposal() 函数以获取提案数组中获胜者的索引，并以此返回获胜者的名称
    function winnerName()public view returns(bytes32 winnerName_){
    	winnerName_ = proposals[winningProposal()].name;
    }

}









