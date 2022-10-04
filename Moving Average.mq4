//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

#define MAGICMA  20131111
//--- Inputs
input double Lots          =0.01;
input double MaximumRisk   =0.02;
input int    MovingPeriod  =120;
input int    MovingShift   =0;
//--关闭订单允许的滑点
input int Slippage = 10;
//--- 加仓条件。达到利润百分比即加仓
input double ProfitPercentageForAddLot_1 =0.1;
input double ProfitPercentageForAddLot_2 =0.2;
//--- 加仓倍数。
input double AddLotMultiple_1 =2;
input double AddLotMultiple_2 =5;

//+------------------------------------------------------------------+
//| 计算已经打开的订单数量                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol,int orderType){
   int buys=0,sells=0;

   for(int i=0;i<OrdersTotal();i++){
   
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA){
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
      }
   }

   if(orderType == OP_BUY){
       return(buys);
   }
   if(orderType == OP_SELL){
       return(sells);
   }
   return buys + sells;   
}
  
//+------------------------------------------------------------------+
//| 计算手数                                       |
//+------------------------------------------------------------------+
double LotsOptimized(){
   double lot=Lots; 

   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
   return(lot);
}
  
//+------------------------------------------------------------------+
//| 打开订单                                 |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
  }
  

//+------------------------------------------------------------------+
//| 加仓                                 |
//+------------------------------------------------------------------+
void CheckAddLot()
  {
    //--- 总利润
    double orderProfitTotal;
    //--- 账户余额
    double accountBalance;
    int    res;
    int orderType;
    
    for(int i=0;i<OrdersTotal();i++)
    {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //计算总利润
      orderProfitTotal += OrderProfit();
      orderType = OrderType();
    }
     
   
     accountBalance = AccountBalance();
     orderProfitTotal += OrderProfit();
     //---总利润达到余额百分比之后加仓
     if(ProfitPercentageForAddLot_1>0 && orderProfitTotal/accountBalance>ProfitPercentageForAddLot_1){
          Print ( "总利润达到余额" , ProfitPercentageForAddLot_1,"加仓",AddLotMultiple_1);
          if(orderType==OP_BUY && CalculateCurrentOrders(Symbol(),OP_BUY)==1)
          {
              res=OrderSend(Symbol(),OP_BUY,LotsOptimized() * AddLotMultiple_1,Ask,3,0,0,"",MAGICMA,0,Blue);
          }
          if(orderType==OP_SELL && CalculateCurrentOrders(Symbol(),OP_SELL)==1)
          {
             res=OrderSend(Symbol(),OP_SELL,LotsOptimized() * AddLotMultiple_1,Bid,3,0,0,"",MAGICMA,0,Red);
          }
     }
     if(ProfitPercentageForAddLot_2>0 && orderProfitTotal/accountBalance>ProfitPercentageForAddLot_2){
          Print ( "总利润达到余额" , ProfitPercentageForAddLot_2,"加仓",AddLotMultiple_2);
          if(orderType==OP_BUY && CalculateCurrentOrders(Symbol(),OP_BUY)==2)
          {
              res=OrderSend(Symbol(),OP_BUY,LotsOptimized() * AddLotMultiple_2,Ask,3,0,0,"",MAGICMA,0,Blue);
          }
          if(orderType==OP_SELL && CalculateCurrentOrders(Symbol(),OP_SELL)==2)
          {
             res=OrderSend(Symbol(),OP_SELL,LotsOptimized() * AddLotMultiple_2,Bid,3,0,0,"",MAGICMA,0,Red);
          }
     }
     return;
}
 
//+------------------------------------------------------------------+
//| 关闭订单                                |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
   //--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
   //--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   //---筛选要关闭的订单
   for(int i=(OrdersTotal()-1);i>=0;i--){
   
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false){ 
         Print("不能选择订单 ", GetLastError());
         break;
      }
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()){
         continue;
      }
      bool res = true;
      
      if(OrderType()==OP_BUY){
         
         if(Open[1]>ma && Close[1]<ma){
            res = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage,Violet);
         }
      }
      if(OrderType()==OP_SELL){
         if(Open[1]<ma && Close[1]>ma){
             res = OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Violet);
         }
      }
      if (res == false){
         Print("ERROR - Unable to close the order - ", OrderTicket(), " - ", GetLastError());
      }
    }
}

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick(){

   if(Bars<100 || IsTradeAllowed()==false)
      return;

   if(CalculateCurrentOrders(Symbol(),-1)<5)
   {
      CheckForOpen();
   }
   CheckAddLot();
   CheckForClose();

}
//+------------------------------------------------------------------+
