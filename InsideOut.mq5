//+------------------------------------------------------------------+
//|                                              InsideInsideOut.mq5 |
//|                                                      Mzimela S.T |
//|                                     mzimelasiyabonga00@gmail.com |
//|                                                                  |
//| This expert advisor uses bollinger bands , Stochaitic and        |
//| Moving Avarage indicators to enter or exit the market it can be  | 
//| used in any instrument, you can adjust stoploss and take profit  |
//| to better the results. email for more info or just read the code.|
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
CTrade ExtTrade;
CPositionInfo Extposition;
COrderInfo Extinfo;

#property copyright "Mzimela S.T"
#property link      "mzimelasiyabonga00@gmail.com"
#property version   "1.00"

//stops the lotsize to increment once balance * factor is reached.
int drawalFactor = 1000; 

double   osit = 100.00;
double    posit = NormalizeDouble(osit, 2);
double    deposit = 100.00;
double Deposit = NormalizeDouble(deposit, 2);
double max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
double  Lot, Lots;
double CurrentBallance, PreviousBallance;

double   iflots = min;
double   iflotsH = max;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int DrawalFactor = drawalFactor;
double  Withdrawal = Deposit * DrawalFactor;
int t1, t2;
double OrdTS;
double OrdTB;
input int Space = 100;//TP
int Test = 0; 
int sL = 50;//SL for Trend
int tP = 60 ; //Order TakeProfit
int      Kill2 = 0; //Suspend Trend
int      Kill = 0; //Suspend Bands(Current)
double pips;
double pip;
string prev = "";

int  Devident = (int)(posit / min);

int BHandle;  // handle for our BB indicator
int BHandle2;  // handle for our BB indicator
int BHandle3;  // handle for our BB indicator
int MaHandle;//Moving avarage handle
int MaHandle2;//Moving avarage handle
int Stock;//stochaitic handle

double stock1[];//array for stochaitic
double mva[];//array for moving avarage
double mva2[];//array for moving avarage

// dynamic arrays for numerical values of Bollinger Bands
double BBUp[], BBLow[], BBMidle[], BBUp2[], BBLow2[];
double BBMidle2[], BBUp3[], BBLow3[], BBMidle3[];



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initialises and gets values of indicators
   BHandle = iBands(_Symbol, PERIOD_H1, 20, 0, 1, PRICE_CLOSE);
   BHandle2 = iBands(_Symbol, PERIOD_H1, 20, 0, 2, PRICE_CLOSE);
   BHandle3 = iBands(_Symbol, PERIOD_H1, 50, 0, 2.5, PRICE_CLOSE);
   MaHandle = iMA(_Symbol, _Period, 200, 0, MODE_SMMA, PRICE_MEDIAN);
   MaHandle2 = iMA(_Symbol, PERIOD_M15, 34, 21, MODE_SMMA, PRICE_MEDIAN);
   Stock = iStochastic(_Symbol, PERIOD_H1, 100, 3, 3, MODE_SMA, 0);

//---if handle returns Invalid RESULTS
   if(BHandle < 0 || BHandle2 < 0 || BHandle3 < 0 || MaHandle < 0 || MaHandle2 
        < 0 || Stock < 0)
     {
      printf("Error Creating Handles for indicators - error: ", GetLastError(), "!!");
     }
   if((_Digits == 5) || (_Digits < 4))
     {
      pips = _Point * 10;
     }
   if(_Digits == 4)
     {
      pips = _Point;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(BHandle);
   IndicatorRelease(BHandle2);
   IndicatorRelease(BHandle3);
   IndicatorRelease(MaHandle);
   IndicatorRelease(MaHandle2);
   IndicatorRelease(Stock);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyLots()
  {
//Modify lots size to increase/decrease as the ballance increases/decrease
   double AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double MyAccBallance = Deposit;
   if(AccountBalance < Withdrawal)
     {
      MyAccBallance = AccountBalance;
     }
   if(AccountBalance >= Withdrawal)
     {
      MyAccBallance = Deposit;
     }
   double x = MyAccBallance / Devident;
   Lots = NormalizeDouble(x, 2);
   if(Lots < iflots)
      Lots = iflots;
  }

//+------------------------------------------------------------------+
int TotalOpenOders()
  {
//calculates total number of open trades for current symbol
   int total = PositionsTotal();
   int count = 0;
   if(total > 0)
     {
      for(int cnt = 0; cnt <= total - 1; cnt++)
        {
         if(PositionGetTicket(cnt))
           {
            if((PositionGetString(POSITION_SYMBOL) == _Symbol) &&
               (PositionGetString(POSITION_COMMENT) == "internal"))
              {
               count++;
              }
           }
        }
     }
   return(count);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenT()
  {
//Open trades when conditions are met
   if(TotalOpenOders() == 0)
     {

      MqlRates mrate[];
      ArraySetAsSeries(BBUp, true);
      ArraySetAsSeries(BBLow, true);
      ArraySetAsSeries(BBMidle, true);
      ArraySetAsSeries(BBUp2, true);
      ArraySetAsSeries(BBLow2, true);
      ArraySetAsSeries(BBMidle2, true);
      ArraySetAsSeries(BBUp3, true);
      ArraySetAsSeries(BBLow3, true);
      ArraySetAsSeries(BBMidle3, true);
      ArraySetAsSeries(mrate, true);
      ArraySetAsSeries(stock1, true);
      if(CopyRates(_Symbol, _Period, 0, 4, mrate) != 4)
        {
         printf("Error copying rates/history data - error!!!: ");
         return;
        }
      //--- Copy the new values of our indicators to buffers (arrays) using the handle
      if(CopyBuffer(BHandle3, 0, 0, 4, BBMidle3) < 0
         || CopyBuffer(BHandle3, 1, 0, 4, BBUp3) < 0
         || CopyBuffer(BHandle3, 2, 0, 4, BBLow3) < 0
         || CopyBuffer(BHandle, 0, 0, 4, BBMidle) < 0
         || CopyBuffer(BHandle, 1, 0, 4, BBUp) < 0
         || CopyBuffer(BHandle, 2, 0, 4, BBLow) < 0
         || CopyBuffer(BHandle2, 0, 0, 4, BBMidle2) < 0
         || CopyBuffer(BHandle2, 1, 0, 4, BBUp2) < 0
         || CopyBuffer(BHandle2, 2, 0, 4, BBLow2) < 0
         || CopyBuffer(MaHandle, 0, 0, 4, mva) < 0
         || CopyBuffer(MaHandle2, 0, 0, 4, mva2) < 0
         || CopyBuffer(Stock, 0, 0, 4, stock1) < 0)
        {
         printf("Error copying indicator Buffers - error:");
         return;
        }

      //BUY CONDITIONS
      // bool B_1 = (mrate[2].close < BBUp[2]);
      bool B_1 = (mrate[1].close > BBUp[1]);
      bool B_3 = (mrate[2].close < BBUp[2]);
      bool B_2 = (mrate[3].close < BBUp[3]);
      bool B_4 = (Bid1() > BBMidle[0] && Ask1() > BBUp[1]);
      bool B_5 = (mrate[1].close < BBUp2[1]);
      bool B_6 = ((mrate[1].high < BBUp2[1]) &&
                  (mrate[1].low > BBLow2[1]));
      bool B_7 = (BBLow[2] > mva[2]);
      // bool B_7 = Kill==0;
      bool B_8 = (mrate[2].close > BBUp[2]);
      bool B_9 = (mrate[1].close > BBUp[1]);
      double highest = 1;
      int index = iHighest(_Symbol, PERIOD_M15, MODE_CLOSE, 400, 2);
      if(index != -1)
         highest = iHigh(_Symbol, PERIOD_M15, index);
      double lowest = 1;
      int index2 = iLowest(_Symbol, PERIOD_M15, MODE_CLOSE, 400, 2);
      if(index2 != -1)
         lowest = iLow(_Symbol, PERIOD_M15, index2);


      bool B_10 = (Ask1() >= (highest + 5 * pips));

      //SELL CONDITIONS
      //bool B_1S = (mrate[2].close > BBLow[2]);
      bool B_1S = (mrate[2].close > BBLow[2]);
      bool B_2S = (mrate[3].close > BBLow[3]);
      bool B_3S = (mrate[1].close < BBLow[1]);
      bool B_4S = (Ask1() < BBMidle[0] && Bid1() < BBLow[0]);
      bool B_5S = (mrate[1].close > BBLow2[1]);
      bool B_7S = (BBUp[2] < mva[2]);
      // bool B_7S = Kill ==0;
      bool B_8S = (mrate[2].close < BBLow[2]);
      bool B_9S = (mrate[1].close < BBLow[1]);
      bool B_10S = ((lowest - 5 * pips) >= Bid1());


      bool condition1 = (B_1 && B_2 && B_3 && B_4 && B_5 && B_6 && B_7 && B_10);
      bool condition2 = (B_4 && B_7 && B_8 && B_9 && B_10);
      bool condition3 = (Test == 1);

      //BUY
      if((condition1 || condition2 || condition3) && (Kill2 == 0) &&
         (TotalOpenOders() == 0))
        {
         OrdTB = Ask1();
         t2 = 0;
         if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&
            Bars(_Symbol, _Period) > 100)
           {
            double sl = 0;//Bid1() - sL * pips;
            ExtTrade.PositionOpen(_Symbol, ORDER_TYPE_BUY, Lots,
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, "internal");
            ExtTrade.PositionOpen(_Symbol, ORDER_TYPE_BUY, Lots * 2,
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, 0, "internal");
           }

        }
      //SELL
      bool condition1S = (B_1S && B_2S && B_3S && B_4S && B_5S && B_6 && B_7S && B_10S);
      bool condition2S = (B_4S && B_7S && B_8S && B_9S && B_10S);
      bool condition3S = (Test == 2);

      if((condition1S || condition2S || condition3S) && (Kill2 == 0) &&
         (TotalOpenOders() == 0))
        {
         OrdTS = Bid1();
         t2 = 0;
         if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && Bars(_Symbol, _Period) > 100)
           {
            double sl = 0;// Ask1() + sL * pips;
            ExtTrade.PositionOpen(_Symbol, ORDER_TYPE_SELL, Lots,
                                  SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0, "internal");
            ExtTrade.PositionOpen(_Symbol, ORDER_TYPE_SELL, Lots * 2,
                                  SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, 0, "internal");
           }


        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MDFY()
  {
// modifies open trades
   MqlRates mrate[];
   ArraySetAsSeries(BBUp2, true);
   ArraySetAsSeries(BBLow2, true);
   ArraySetAsSeries(BBMidle2, true);
   ArraySetAsSeries(mrate, true);
   if(CopyRates(_Symbol, _Period, 0, 4, mrate) != 4)
     {
      printf("Error copying rates/history data - error!!!: ");
      return;
     }
//--- Copy the new values of our indicators to buffers (arrays) using the handle
   if(CopyBuffer(BHandle2, 0, 0, 4, BBMidle2) < 0
      || CopyBuffer(BHandle2, 1, 0, 4, BBUp2) < 0
      || CopyBuffer(BHandle2, 2, 0, 4, BBLow2) < 0
      || CopyBuffer(MaHandle2, 0, 0, 1, mva2) < 0)
     {
      printf("Error copying indicator Buffers - error:");
      return;
     }
//Close Buy
   bool B3 = Ask1() <= mva2[0];
//Close Sell
   bool B3S = Bid1() >= mva2[0];


   int total = PositionsTotal();
   for(int cnt = total - 1; cnt >= 0 ; cnt--)
     {

      if((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) &&
         (PositionGetString(POSITION_SYMBOL) == _Symbol)
         && (PositionGetString(POSITION_COMMENT) == "internal"))
        {
         if(B3)
           {
            ExtTrade.PositionClose(Extposition.Ticket(), 3);
           }
        }
      if((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) &&
         (PositionGetString(POSITION_SYMBOL) == _Symbol)
         && (PositionGetString(POSITION_COMMENT) == "internal"))
        {
         if(B3S)
           {
            ExtTrade.PositionClose(Extposition.Ticket(), 3);
           }
        }
      ulong tic = PositionGetTicket(cnt);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) &&
         (PositionGetString(POSITION_SYMBOL) == _Symbol) && OrdTS > 0
         && (PositionGetString(POSITION_COMMENT) == "internal") &&
         PositionGetTicket(cnt))
        {
         if(((OrdTS - Ask1()) >= tP * pips))
           {
            if((t2 == 0) && PositionGetDouble(POSITION_VOLUME)  == 2)
              {
               if(!ExtTrade.PositionModify(tic,
                                           NormalizeDouble(Ask1() + 10 * pips, _Digits), Extinfo.TakeProfit()))
                 {
                  return;
                 }
               t2 = 1;
              }
           }
        }
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) &&
         (PositionGetString(POSITION_SYMBOL) == _Symbol) && OrdTB > 0 &&
         (PositionGetString(POSITION_COMMENT) == "internal") && PositionGetTicket(cnt))
        {
         if((Bid1() - OrdTB) >= tP * pips)
           {
            if((t2 == 0) && PositionGetDouble(POSITION_VOLUME)  == 2)
              {
               if(!ExtTrade.PositionModify(tic,
                                           NormalizeDouble(Bid1() - 10 * pips, _Digits), Extinfo.TakeProfit()))
                 {
                  return;
                 }
               t2 = 1;
              }
           }
        }


     }
  }


//+------------------------------------------------------------------+
double Ask1()
  {
//returns the ask price
   double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);  // Ask price
   return Ask;
  }
//+------------------------------------------------------------------+
//|            Return current Bid price                              |
//+------------------------------------------------------------------+
double Bid1()
  {
//returns the bid price
   double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);  // Ask price
   return Bid;
  }

//+------------------------------------------------------------------+
void CloseT()
  {
//close all open trades
   while(TotalOpenOders() > 0)
     {
      int total = PositionsTotal();

      for(int cnt = total - 1; cnt >= 0 ; cnt--)
        {
         if(PositionGetTicket(cnt) && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) &&
            (PositionGetString(POSITION_SYMBOL) == _Symbol) &&
            (PositionGetString(POSITION_COMMENT) == "internal"))
           {
            ExtTrade.PositionClose(Extposition.Ticket(), 3);
           }
         if(PositionGetTicket(cnt) && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) &&
            (PositionGetString(POSITION_SYMBOL) == _Symbol) &&
            (PositionGetString(POSITION_COMMENT) == "internal"))
           {
            ExtTrade.PositionClose(Extposition.Ticket(), 3);
           }
        }
     }
   return;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   MyLots();//initialise trading volume
   main();//trading function
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void main()
  {
   OpenT();//open trades
   MDFY();//modify open trades
  }