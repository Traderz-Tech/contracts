pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";

contract Cipher is Ownable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;

    event Trade(address trader, address subject, bool isBuy, uint256 coreAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);

    // coresSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public coresBalance;

    // coresSubject => Supply
    mapping(address => uint256) public coresSupply;

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getBuyPrice(address coresSubject, uint256 amount) public view returns (uint256) {
        return getPrice(coresSupply[coresSubject], amount);
    }

    function getSellPrice(address coresSubject, uint256 amount) public view returns (uint256) {
        return getPrice(coresSupply[coresSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address coresSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(coresSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(address coresSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(coresSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price - protocolFee - subjectFee;
    }

    function buyCores(address coresSubject, uint256 amount) public payable {
        uint256 supply = coresSupply[coresSubject];
        require(supply > 0 || coresSubject == msg.sender, "Only the cores' subject can buy the first core");
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        coresBalance[coresSubject][msg.sender] = coresBalance[coresSubject][msg.sender] + amount;
        coresSupply[coresSubject] = supply + amount;
        emit Trade(msg.sender, coresSubject, true, amount, price, protocolFee, subjectFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = coresSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellCores(address coresSubject, uint256 amount) public payable {
        uint256 supply = coresSupply[coresSubject];
        require(supply > amount, "Cannot sell the last core");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        require(coresBalance[coresSubject][msg.sender] >= amount, "Insufficient cores");
        coresBalance[coresSubject][msg.sender] = coresBalance[coresSubject][msg.sender] - amount;
        coresSupply[coresSubject] = supply - amount;
        emit Trade(msg.sender, coresSubject, false, amount, price, protocolFee, subjectFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = coresSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }
}