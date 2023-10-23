create or replace procedure aggregateData(P_startDate date, P_endDate date ,PintervalType Varchar2)

as
begin
DECLARE p_sum_Hourly  NUMBER;
   
      V_Daily_Power_Factor NUMBER;
      V_Monthly_Power_Factor NUMBER;

     V_Daily_Peak_demand NUMBER;

     V_Monthly_Peak_demand NUMBER;
     V_Daily_OFF_Peak NUMBER;
     
     V_Monthly_OFF_Peak NUMBER;
     
     V_Daily_ON_Peak NUMBER;
     
     V_Monthly_ON_Peak NUMBER;

     CURSOR  DT_KEY_NB_List  is  select DT_KEY_NB from DATE_DAY_DIM d where d.dt between P_startDate and P_endDate;
     CURSOR  METER_KEY_NB_List is   select   METER_KEY_NB from METER_DIM ;


BEGIN

for  ibIntervalFacts  IN(

------   Get all Interval Fact by date range -------------------------------
select * from IB_INTERVAL_FACT f where f.METER_KEY_NB= METER_KEY_NB  and f.METER_READ_DT_KEY_NB= DT_KEY_NB) loop

---------  For power factor calculation --------------------------------------
IF(PItnv_Type="Power Factor") THEN

   V_Daily_Power_Factor:=ibIntervalFacts.INTV_DAY_AMT /ibIntervalFacts.KVA_DAY_AMT*100;
   
    V_Monthly_Power_Factor:=GET_Monthly_PowerFactor( METER_KEY_NB_List.METER_KEY_NB_List,DT_KEY_NB_List.DT_KEY_NB);


----------    For Peak Demand calculation --------------------------------------
elsif (PItnv_Type="KW Peak")Then


 V_Daily_Peak_demand:=ibIntervalFacts.PEAK_AMT;
 
 V_Monthly_Peak_demand:= GET_Monthly_Peak_Demand(METER_KEY_NB_List.METER_KEY_NB_List,DT_KEY_NB_List.DT_KEY_NB);


----------------- Delivered Time of Use on Peak-------------------------------------- 
elsif (PItnv_Type="DT ON PEAK")THEN

 V_Daily_ON_Peak:=ibIntervalFacts.PEAK_AMT;

 V_Daily_Peak_demand:=GET_Monthly_delON_Peak(METER_KEY_NB_List.METER_KEY_NB_List,DT_KEY_NB_List.DT_KEY_NB);

-------------------------------- Delivered Time of Use off Peak-------------------------------------- 
elsif (PItnv_Type="DT OFF PEAK")THEN
  V_Daily_OFF_Peak:=ibIntervalFacts.OFF_PEAK_AMT;
  
  V_Monthly_OFF_Peak:=GET_Monthly_delOFF_Peak(METER_KEY_NB_List.METER_KEY_NB_List,DT_KEY_NB_List.DT_KEY_NB);
  


end if;



end loop;






end;
/
