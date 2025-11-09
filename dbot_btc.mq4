//+------------------------------------------------------------------+
//|                                                       dtrade.mq4 |
//|                                    Dbright Software Developments |
//|                                           https://dbrightdev.com |
//+------------------------------------------------------------------+
#property copyright "Dbright Software Developments"
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
//Things to do involve saving last entry on a 4 array variable
int OnInit()
  {
//---
  Alert("System is currently running on ", Symbol());
  Comment("Dbot has started ",GetTickCount());
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
   // Take the process step by step
   string market = Symbol();
   Comment("Currently running on ",market," ",GetTickCount());
   //double ema = iMA(market,tf,50,0,MODE_EMA,PRICE_CLOSE,0);
   double zigzag = iCustom(market,tf,"zigzag",0,0);
   double atr = iATR(market,tf,14,0);
   
   double ema50 = iMA(market,tf,50,0,MODE_EMA,PRICE_CLOSE,0), ema21 = iMA(market,tf,21,0,MODE_EMA,PRICE_CLOSE,0), ema200 = iMA(market,tf,200,0,MODE_EMA,PRICE_CLOSE,0);
   double e1 = 0, e2 = 0;
   //Main Operation
   double cp = iClose(market,tf,0);

   if(cp > ema50){
      //Buy operation
      for(int i = 1; i < Bars; i++){
         zigzag = iCustom(market,tf,"zigzag",0,i);
         if(zigzag != 0){
            ema50 = iMA(market,tf,50,0,MODE_EMA,PRICE_CLOSE,i);
            ema200 = iMA(market,tf,200,0,MODE_EMA,PRICE_CLOSE,i);
            //atr = iATR(market,PERIOD_M30,14,i);
            if(ema50 > zigzag && iClose(market,tf,i) > zigzag && ema200 > ema50 ){
               e1 = zigzag;
               //marketOrder(market,OP_BUY,lotsize,e1,i);
               for(int p = i + 1; p < Bars; p++){
                  zigzag = iCustom(market,tf,"zigzag",0,p);
                  if(zigzag != 0){
                     ema50 = iMA(market,tf,50,0,MODE_EMA,PRICE_CLOSE,p);
                     if(zigzag > ema50 && zigzag > iClose(market,tf,p)){
                        //buy operation
                        e2 = zigzag;
                        marketOrder(market,OP_BUY,e2,p);
                     }
                     break;
                  }
               }
            }
            break;
         }
      }
   }
   else if(cp < ema50){
      //Sell operation
      for(int i = 1; i < Bars; i++){
         zigzag = iCustom(market,tf,"zigzag",0,i);
         if(zigzag != 0){
            ema50 = iMA(market,tf,50,0,MODE_EMA,PRICE_CLOSE,i);
            ema200 = iMA(market,tf,200,0,MODE_EMA,PRICE_CLOSE,i);
            //atr = iATR(market,PERIOD_M30,14,i);
            if(ema50 < zigzag && iClose(market,tf,i) < zigzag && ema200 < ema50){
               e1 = zigzag;
               //marketOrder(market,OP_SELL,lotsize,e1,i);
               for(int p = i + 1; p < Bars; p++){
                  zigzag = iCustom(market,tf,"zigzag",0,p);
                  if(zigzag != 0){
                     ema50 = iMA(market,tf,50,0,MODE_EMA,PRICE_CLOSE,p);
                     if(zigzag > ema50 && zigzag > iClose(market,tf,p)){
                        //sell operation
                        e2 = zigzag;
                        marketOrder(market,OP_SELL,e2,p);
                     }
                     break;
                  }
               }
            }
            break;
         }
      }
   }
   breakeven();
   //removeTrade();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//Write the code on mql5 and save yourself all the useless troubles and over thinking

void marketOrder(string market, ENUM_ORDER_TYPE order,double zigzag,int shift){
   if(OrdersTotal() < total_market){
      double atr = iATR(market,tf,14,0);
      double atr2 = iATR(market,tf,14,shift);
      bool permit = true;
      int t = 0;     
      double tp = 8 * atr, sl = 4 * atr;
      double tp2 = 4 * atr2, sl2 = 4 * atr2;
      double cp = iClose(market,tf,0);
      double ema = iMA(market,tf,200,0,MODE_EMA,PRICE_CLOSE,shift);
      double ema2 = iMA(market,tf,200,0,MODE_EMA,PRICE_CLOSE,0);
      int l_t = 0;
      for(int i = 0; i < OrdersTotal(); i++){
         if(OrderSelect(i,SELECT_BY_POS)){
            if(market == OrderSymbol() || zigzag == l_zigzag){
               permit = false;
            }
         }
      }
      if(zigzag > ema && order != OP_BUY && cp > ema2){
         permit = false;
      }
      else if(zigzag < ema && order != OP_SELL && cp < ema2){
         permit = false;
      }
      if(permit){
         if(order == OP_SELL){
            tp = MathAbs(cp - tp);
            sl = MathAbs(cp + sl);   
            tp2 = MathAbs(zigzag - tp2);
            sl2 = MathAbs(zigzag + sl2);        
            //t = OrderSend(market,OP_SELLSTOP,lotsize,zigzag,8,sl2,tp2,mdesc);
            //t = OrderSend(market,OP_SELLLIMIT,lotsize,zigzag,8,sl2,tp2,mdesc);
            t = OrderSend(market,OP_SELL,lotsize,Bid,8,sl,tp,mdesc);
            t = OrderSend(market,OP_SELL,lotsize,Bid,8,sl2,tp2,mdesc);
            if(t < 1){
               Print(market," Failed to Sell");
            }
            else if(t > 2){
               l_zigzag = zigzag;
            }
         }
         else if(order == OP_BUY){
            tp = MathAbs(cp + tp);
            sl = MathAbs(cp - sl);
            tp2 = MathAbs(zigzag + tp2);
            sl2 = MathAbs(zigzag - sl2);
            //t = OrderSend(market,OP_BUYSTOP,lotsize,zigzag,8,sl2,tp2,mdesc);
            //t = OrderSend(market,OP_BUYLIMIT,lotsize,zigzag,8,sl2,tp2,mdesc);
            t = OrderSend(market,OP_BUY,lotsize,Ask,8,sl,tp,mdesc);
            t = OrderSend(market,OP_BUY,lotsize,Ask,8,sl2,tp2,mdesc);
            if(t < 1){
               Print(market," Failed to Buy");
               /*t = OrderSend(market,OP_BUY,lotsize,zigzag,8,sl,tp,mdesc);
               if(t > 2){
                  l_zigzag = zigzag;
                  OrderDelete(l_t);
                  l_t = t;
               }*/
            }
            else if(t > 2){
               l_zigzag = zigzag;
               //OrderDelete(l_t);
               //l_t = t;
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
            if(OrderType() == OP_BUY){
              if(OrderClosePrice() > be && OrderClosePrice() > th){
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),be,OrderTakeProfit(),0)){
                     Alert(OrderSymbol()," now has a breakeven");
                  }
               }
            }else if(OrderType() == OP_SELL){
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