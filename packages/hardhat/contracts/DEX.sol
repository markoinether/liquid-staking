pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {

  using SafeMath for uint256;
  IERC20 token;
  IERC20 tender;

  uint256 public totalLiquidity;
  mapping (address => uint256) public liquidity;

  constructor(address token_addr, address tender_addr) public {
    token = IERC20(token_addr);
    tender = IERC20(tender_addr);
  }

function init(uint256 tokens) public returns (uint256) {
  require(totalLiquidity==0,"DEX:init - already has liquidity");
  totalLiquidity = tokens;
  liquidity[msg.sender] = totalLiquidity;
  require(token.transferFrom(msg.sender, address(this), tokens));
  require(tender.transferFrom(msg.sender, address(this), tokens));
  return totalLiquidity;
  }

function tokenBalance() public view returns (uint256) {
  return token.balanceOf(address(this));
}

function tenderBalance() public view returns (uint256) {
  return tender.balanceOf(address(this));
}

function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 input_amount_with_fee = input_amount.mul(997);
  uint256 numerator = input_amount_with_fee.mul(output_reserve);
  uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
  return numerator / denominator;
  }

  function priceStable(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 input_amount_with_fee = input_amount.mul(997);
  uint256 numerator = input_amount_with_fee.mul(output_reserve);
  uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
  return numerator / denominator;
  }


function getSpotPrice() public view returns (uint256) {
  uint256 numerator = token.balanceOf(address(this));
  uint256 denominator = tender.balanceOf(address(this));
  return numerator.mul(1e18).div(denominator);
}

function tenderToToken(uint256 tenders) public returns (uint256) {
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this));
  uint256 token_bought = price(tenders, tender_reserve, token_reserve);
  token.transfer(msg.sender, token_bought);
  require(tender.transferFrom(msg.sender, address(this), tenders));
  return token_bought;
}
function tokenToTender(uint256 tokens) public returns (uint256) {
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this));
  uint256 tender_bought = price(tokens, token_reserve, tender_reserve);
  tender.transfer(msg.sender, tender_bought);
  require(token.transferFrom(msg.sender, address(this), tokens));
  return tender_bought;
}

function deposit() public payable returns (uint256) {
  uint256 eth_reserve = address(this).balance.sub(msg.value);
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 token_amount = (msg.value.mul(token_reserve) / eth_reserve).add(1);
  uint256 liquidity_minted = msg.value.mul(totalLiquidity) / eth_reserve;
  liquidity[msg.sender] = liquidity[msg.sender].add(liquidity_minted);
  totalLiquidity = totalLiquidity.add(liquidity_minted);
  require(token.transferFrom(msg.sender, address(this), token_amount));
  return liquidity_minted;
}
function withdraw(uint256 amount) public returns (uint256, uint256) {
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 eth_amount = amount.mul(address(this).balance) / totalLiquidity;
  uint256 token_amount = amount.mul(token_reserve) / totalLiquidity;
  liquidity[msg.sender] = liquidity[msg.sender].sub(eth_amount);
  totalLiquidity = totalLiquidity.sub(eth_amount);
  msg.sender.transfer(eth_amount);
  require(token.transfer(msg.sender, token_amount));
  return (eth_amount, token_amount);
}

}
