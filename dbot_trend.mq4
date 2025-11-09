//+------------------------------------------------------------------+
//|                                                   dbot_trend.mq4 |
//|                                                              DSD |
//|                                           https://dbrightdev.com |
//+------------------------------------------------------------------+
#property copyright "DSD"
#property link      "https://dbrightdev.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
extern ENUM_TIMEFRAMES tf = NULL; //Time Frame
extern string mdesc = "dtrade";
extern double risk = 0.01;
double l_zigzag = 0;
extern int total_market = 10;
extern double lotsize = 0.01;


int OnInit()
  {
//---
   //---
  Alert("System is currently running on ", Symbol());
  Comment("Dbot has started ",GetTickCount());
//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Alert(reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   string market = Symbol();
   Comment("Currently running on ",market," ",GetTickCount());
   double rsi = iRSI(market,tf,21,PRICE_CLOSE,1), 
      macd = iMACD(market,tf,8,21,8,PRICE_CLOSE,MODE_MAIN,1), signal = iMACD(market,tf,8,21,8,PRICE_CLOSE,MODE_SIGNAL,1),
      ema13 = iMA(market,tf,13,0,MODE_EMA,PRICE_CLOSE,1), ema21 = iMA(market,tf,21,0,MODE_EMA,PRICE_CLOSE,1), 
      ema55 = iMA(market,tf,55,0,MODE_EMA,PRICE_CLOSE,1),
      ema13h4 = iMA(market,PERIOD_H1,13,0,MODE_EMA,PRICE_CLOSE,1), ema21h4 = iMA(market,PERIOD_H1,21,0,MODE_EMA,PRICE_CLOSE,1), 
      ema55h4 = iMA(market,PERIOD_H1,55,0,MODE_EMA,PRICE_CLOSE,1);
   
   if(rsi > 50 && macd > 0 && macd > signal){
      if(ema13 > ema21 && ema21 > ema55 && ema13h4 > ema21h4 && ema21h4 > ema55h4){
         if(iOpen(market,tf,0) > iClose(market,tf,0)){
            marketOrder(market,OP_BUY);
         }
      }
   }else if(rsi < 50 && macd < 0 && macd < signal){
      if(ema13 < ema21 && ema21 < ema55 && ema13h4 > ema21h4 && ema21h4 > ema55h4){
         if(iOpen(market,tf,0) < iClose(market,tf,0)){
            marketOrder(market,OP_SELL);
         }
      }
   }
   
   breakeven(); 
  }
//+------------------------------------------------------------------+

void marketOrder(string market, ENUM_ORDER_TYPE order){
   if(OrdersTotal() < total_market){
      double atr = iATR(market,tf,14,0);
      
      bool permit = true;
      int t = 0;     
      double tp = 8 * atr, sl = 4 * atr;
      
      double cp = iClose(market,tf,0);
      
      
      int l_t = 0;
      for(int i = 0; i < OrdersTotal(); i++){
         if(OrderSelect(i,SELECT_BY_POS)){
            if(market == OrderSymbol() || order == OrderType()){
               permit = false;
            }
         }
      }
      
      if(permit){
         if(order == OP_SELL){
            tp = MathAbs(cp - tp);
            sl = MathAbs(cp + sl);   
            
            t = OrderSend(market,OP_SELL,lotsize,Bid,8,sl,tp,mdesc);
            //t = OrderSend(market,OP_SELL,lotsize,Bid,8,sl2,tp2,mdesc);
            if(t < 1){
               Print(market," Failed to Sell");
            }
            
         }
         else if(order == OP_BUY){
            tp = MathAbs(cp + tp);
            sl = MathAbs(cp - sl);
            
            t = OrderSend(market,OP_BUY,lotsize,Ask,8,sl,tp,mdesc);
            //t = OrderSend(market,OP_BUY,lotsize,Ask,8,sl2,tp2,mdesc);
            if(t < 1){
               Print(market," Failed to Buy");
               
            }
            
         }
      }
   }
}


void breakeven(){
   double be = 0;
   double th = 0;
   for(int i = 0; i < OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS)){
        if(OrderComment() == mdesc){
            be = (OrderClosePrice() + OrderOpenPrice()) / 2.0;
            th = (OrderTakeProfit() + OrderOpenPrice()) / 2.0;
            if(OrderType() == OP_BUY && OrderOpenPrice() > OrderStopLoss()){
              if(OrderClosePrice() > be && OrderClosePrice() > th){
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),be,OrderTakeProfit(),0)){
                     Alert(OrderSymbol()," now has a breakeven");
                  }
               }
            }else if(OrderType() == OP_SELL && OrderOpenPrice() < OrderStopLoss()){
               if(OrderClosePrice() < be && OrderClosePrice() < th){
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),be,OrderTakeProfit(),0)){
                     Alert(OrderSymbol()," now has a breakeven");
                  }
               }
            }
        }
        
      }
      
   }
}