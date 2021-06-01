// SPDX-License-Identifier:GPL-3.0
//源代码是根据 GPL 3.0 版许可的


pragma solidity >=0.4.16 <0.9.0;
//指定源代码是为 Solidity 0.4.16 版或更高版本的语言编写的，但不包括 0.9.0 版。

contract SimpleStorage{

	uint storgData;

	function set(uint  x) public{
		storgData = x;
	}

	function get(uint x) public view returns(uint){
		return storgData;
	}
}