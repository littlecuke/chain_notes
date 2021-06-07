###ERC20与ERC721详解

数字加密货币大致可以分为原生币（coin）和代币（token）两大类。前者如BTC、ETH等，拥有自己的区块链。后者如Tether、TRON、ONT等，依附于现有的区块链。市场上流通的基于以太坊的代币大都遵从ERC20协议。最近几个月间还出现了一种被称为ERC721的数字加密资产，例如CryptoKitties（参阅[block #24]）。所谓ERC20和ERC721究竟是什么呢？

#### ERC
首先，ERC是Ethereum Request for Comments的缩写，代表以太坊开发者提交的协议提案。它相当于是以太坊版的RFC（https://www.ietf.org/standards/rfcs/）。ERC后面的数字是议案的编号。

打算制定以太坊新标准的开发者可以在https://github.com/ethereum/EIPs/issues先创建一个EIP（Ethereum Improvement Proposal，以太坊改进提案），详细描述协议。经过公开审议之后，获得广泛认同的提案会被标准化，列入https://github.com/ethereum/EIPs。有些改动触及区块链共识，比如增加虚拟机操作符，属于核心层变更。而另一些提案则不涉及修改以太坊本身的代码，只是约定俗成的上层协议，它们通常被归类为ERC标准。


#### ERC20
ERC20可能是其中最广为人知的标准了。它诞生于2015年，到2017年9月被正式标准化。协议规定了具有可互换性（fungible）代币的一组基本接口，包括代币符号、发行量、转账、授权等。所谓可互换性（fungibility）指代币之间无差异，同等数量的两笔代币价值相等。交易所里流通的绝大部分代币都是可互换的，一单位的币无论在哪儿都价值一单位。

与之相对的则是非互换性（non-fungible）资产。比如CryptoKitties中的宠物猫就是典型的非互换性资产，因为每只猫各有千秋，而且由于不同辈分的稀缺性不同，市场价格也差异巨大。这种非标准化资产很长时间内都没有标准协议，直到2017年9月才出现ERC721提案，定义了一组常用的接口。ERC721至今仍旧处于草案阶段，但已经被不少dApp采用，甚至出现了专门的交易所（Y Combinator孵化的http://opensea.io）。


####ERC20代码详解

ERC20定义了三个<font color='red'> 可选函数 </font>：
```
	// 代币名称。比如"Sleepism Token"。

	function name() view returns (string name);

	// 代币符号。按惯例一般用全大写字母，比如“SLPT”。

	function symbol() view returns (string symbol);

	// 小数位数。不少代币采用与ETH一样的设定，也就是18位。

	// 这只影响用户界面中货币量的显示方式。代币本身都统一用uint256表示。

	function decimal() view returns (uint8 decimals);


	由于这三个函数都是返回常量，在Solidity中也可以用以下简略形式定义。solc编译器会自动生成与以上接口等价的字节码。

	string public name = "Sleepism Token";

	string public symbol = "SLPT";

	uint8 public decimal = 18;
```


ERC20定义了六个<font color="red"> 必须声明 </font>的函数：
```
	// 代币总量。

	function totalSupply() view returns (uint256 totalSupply);

	// 查询指定地址下的代币余额。

	function balanceOf(address _owner) view returns (uint256 balance);

	// 给指定地址转入指定量的代币，转账成功则返回true。

	// 如果源地址没有足够量的代币，函数应该抛出异常。

	// 即使转零个代币，也应该触发Transfer事件（下文中有解释）。

	function transfer(address _to, uint256 _value) returns (bool success);

	// 与transfer类似的转账函数。区别在于可以指定一个转出地址。

	// 如果当前地址得到了转出地址的授权，则可以代理转账操作。

	function transferFrom(address _from, address _to, uint256 _value)

	returns (bool success);

	// 授权指定地址特定的转账额度。

	// 被授权的地址可以多次调用transferFrom函数代替源地址转账，总值不超过_value。

	// 实际使用时，每次重设额度前应该先调用approve(_spender, 0)，

	// 等交易被确认后再调用approve(_spender, newAllowance)。

	// 如果直接调用一次approve，被授权地址有机会转出高出指定额度的代币。

	function approve(address _spender, uint256 _value) returns (bool success);

	// 查询指定授权地址剩余的转账额度。

	function allowance(address _owner, address _spender) view returns (uint256 remaining);

```

ERC20还定义了两个事件：
```
	// 转账事件。必须在成功转账（哪怕是零个代币）时触发。

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	// 授权事件。必须在成功授权时触发。

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

```

官方文档参见https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md。

####ERC721

ERC721与ERC20有些相似，但由于它管理的是非互换性资产（non-fungible token，简称NFT），所以函数语义并不一样。合约下每份ERC721资产都拥有一个uint256类型的独立编号（以下代码中的_tokenId）。

ERC721事件：

```
	// 转账事件。从_from地址转移_tokenId对应资产的所有权到_to地址时触发。

	event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

	// 授权转账事件。把_owner地址控制的_tokenId资产授权给_approved地址时触发。

	// 发生转账事件时，对应资产的授权地址应被清空。

	event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

	// 授权管理事件。_owner地址授权或取消授权_operator地址的管理权时触发。

	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

```

ERC721函数：

```
	// 查询_owner地址拥有的NFT总个数。

	function balanceOf(address _owner) external view returns (uint256);

	// 查询_tokenId资产的所属地址。

	function ownerOf(uint256 _tokenId) external view returns (address);

	// 将_from地址所拥有的_tokenId资产转移给_to地址。

	// 调用方必须是资产主人或是已被授权的地址，否则会抛出异常。

	function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

	// 与transferFrom类似的资产转移函数。

	// 它会额外检查_to地址和_tokenId的有效性，另外如果_to是合约地址，

	// 还会触发它的onERC721Received回调函数。

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

	// 与上述接口类似的资产转移函数。

	// 唯一不同点是可以传入额外的自定义参数。

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

	// 把_tokenId资产授权给_approved地址。

	function approve(address _approved, uint256 _tokenId) external payable;

	// 查询_tokenId资产对应的授权地址。

	function getApproved(uint256 _tokenId) external view returns (address);

	// 指定或撤销_operator地址的管理权限。

	function setApprovalForAll(address _operator, bool _approved) external;

	// 查询_operator地址是否已经获得_owner地址的管理权。

	function isApprovedForAll(address _owner, address _operator) external view returns (bool);

```

ERC721元数据接口（可选项）：

```
	// 资产名称。比如"Sleepism Collectible"。

	function name() external pure returns (string _name);

	// 资产符号。比如"SLPC"。

	function symbol() external pure returns (string _symbol);

	// 描述_tokenId资产的URI。指向一个符合ERC721元数据描述结构的JSON文件。

	function tokenURI(uint256 _tokenId) external view returns (string);

```

元数据描述结构如下所示：

```
	{
	    "title":"Sleepism Collectible Metadata",
	    "type":"object",
	    "properties":{
	        "name":{
	            "type":"string",
	            "description":"Sleep and his Half-brother Death"
	        },
	        "description":{
	            "type":"string",
	            "description":"A painting by John William Waterhouse"
	        },
	        "image":{
	            "type":"string",
	            "description":"https://i.imgur.com/sahhbd.png"
	        }
	    }
	}

```

ERC721枚举扩宽接口（可选项）：

```
	// 合约管理的总NFT数量。

	function totalSupply() external view returns (uint256);

	// 查询第_index个资产的编码。

	function tokenByIndex(uint256 _index) external view returns (uint256);

	// 查询_owner地址拥有的第_index个资产的编码。

	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

	符合ERC721协议的合约还需要符合ERC165规范，实现以下函数：

	// 查询合约是否实现了interfaceID对应的接口。

	function supportsInterface(bytes4 interfaceID) external view returns (bool);

```

interfaceID由bytes4(keccak256(函数签名))计算得到。有多个函数时，将全部byte4异或（xor）得到最终结果。详见ERC165标准文档（https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md）。

例如以下接受转账回调函数接口的interfaceID就是0xf0b9e5ba：


```
	interface ERC721TokenReceiver {
		function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);

	}

```

这是支持ERC721资产的钱包或交易平台需要实现的代码。发放ERC721资产的合约本身不需要处理。

ERC721官方文档参见https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md。

####相关ERC

ERC223是对ERC20的小改进，增加了tokenFallback函数，更好地处理错误情况。详见https://github.com/ethereum/EIPs/issues/223。

ERC621在ERC20的基础上添加了increaseSupply和decreaseSupply函数，控制代币总量的增减。详见https://github.com/ethereum/EIPs/pull/621。

更近期提出的ERC827则是增强了函数回调功能。详见https://github.com/ethereum/EIPs/issues/827。
